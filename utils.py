from __future__ import print_function

import sys, json, os
from subprocess import Popen, PIPE

TERRAFORM_PATH    = os.environ.get('ANSIBLE_TF_BIN', 'terraform')
TERRAFORM_DIR     = os.environ.get('ANSIBLE_TF_DIR', os.getcwd())
TERRAFORM_WS_NAME = os.environ.get('ANSIBLE_TF_WS_NAME', 'default')

def printerr(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_terraform_state():
    encoding = 'utf-8'
    tf_workspace = [TERRAFORM_PATH, 'workspace', 'select', TERRAFORM_WS_NAME]
    proc_ws = Popen(tf_workspace, cwd=TERRAFORM_DIR, stdout=PIPE, stderr=PIPE, universal_newlines=True)
    out_ws, err_ws = proc_ws.communicate()
    if err_ws != '':
        sys.stderr.write(str(err_ws)+'\n')
        sys.exit(1)
    else:
        tf_command = [TERRAFORM_PATH, 'state', 'pull', '-input=false']
        proc_tf_cmd = Popen(tf_command, cwd=TERRAFORM_DIR, stdout=PIPE, stderr=PIPE, universal_newlines=True)
        out_cmd, err_cmd = proc_tf_cmd.communicate()
        if err_cmd != '':
            sys.stderr.write(str(err_cmd)+'\n')
            sys.exit(1)
        else:
            return json.loads(out_cmd, encoding='utf-8')

def list_servers(tfstate):
    inventory = {'_meta': {'hostvars': {}}}

    for module in tfstate['modules']:
        try:
            server = module['resources']['digitalocean_droplet.this']['primary']

            outputs = {k: v['value'] for k, v in module['outputs'].items()}
            server['_module_outputs'] = outputs

            attributes = server['attributes']

            # The DigitalOcean provider presents tags as a list
            server['_tags'] = {}
            for k, v in attributes.iteritems():
                if k[:5] == 'tags.' and k != 'tags.#':
                    p = v.split(':', 2)
                    server['_tags'][p[0]] = p[1]

            if not 'Type' in server['_tags']:
                utils.printerr(json.dumps(attributes))
                utils.printerr('Server ID %s has no Type' % server['id'])
                continue

            if 'name' in attributes:
                server['_name'] = attributes['name']
            else:
                utils.printerr(json.dumps(attributes))
                utils.printerr('Server ID %s has no name' % server['id'])
                continue

            server['_public_ip'] = attributes['ipv4_address']

            yield server

        except KeyError:
            # something else, e.g. 'root' module
            pass
