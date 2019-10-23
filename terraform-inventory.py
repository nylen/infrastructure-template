#!/usr/bin/env python2

# Forked from https://github.com/nbering/terraform-inventory/blob/master/terraform.py

from inspect import getsourcefile
import sys, json, os

import utils

SERVER_FILTER = os.environ.get('SERVER_FILTER', '')
servers_already_filtered = {}
if SERVER_FILTER == '':
    SERVER_FILTER = []
else:
    SERVER_FILTER = SERVER_FILTER.split(',')

def read_authorized_ssh_keys():
    current_dir = os.path.dirname(os.path.abspath(getsourcefile(lambda: 0)))
    keys_file = os.path.join(current_dir, 'keys', 'ssh_authorized_keys_ROOT.txt')
    return open(keys_file).read()

def add_instance_to_group(inventory, group, server, outputs):
    if len(SERVER_FILTER) > 0:
        if server['_name'] in SERVER_FILTER:
            if server['_name'] not in servers_already_filtered:
                utils.printerr('Including server in inventory: %s' % server['_name'])
                servers_already_filtered[server['_name']] = True
        else:
            if server['_name'] not in servers_already_filtered:
                utils.printerr('Omitting server from inventory: %s' % server['_name'])
                servers_already_filtered[server['_name']] = True
            return inventory

    if not group in inventory:
        inventory[group] = {
            'hosts': [],
            'vars': {
                'ansible_ssh_user': 'root',
                'projectname_ssh_keys': read_authorized_ssh_keys(),
            }
        }

    projectname_hostnames = (
        outputs.get('projectname_hostnames_proxied', []) +
        outputs.get('projectname_hostnames_unproxied', [])
    )
    projectname_hostnames_full = map(
        lambda h: (h + '.projectname.com').replace('@.', ''),
        projectname_hostnames
    )

    inventory[group]['hosts'].append(server['_name'])
    inventory['_meta']['hostvars'][server['_name']] = {
        'ansible_host': server['_public_ip'],
        'projectname_users': outputs.get('projectname_users', []),
        'projectname_hostnames': projectname_hostnames,
        'projectname_hostnames_full': projectname_hostnames_full,
    }

    return inventory

# See:
# https://github.com/geerlingguy/ansible-for-devops/blob/9cce4d16/dynamic-inventory/custom/inventory.py#L35-L57
def state_to_inventory(tfstate):
    inventory = {'_meta': {'hostvars': {}}}

    for server in utils.list_servers(tfstate):
        outputs = server['_module_outputs']

        # Set up ansible groups by server type (projectname_X)
        inventory = add_instance_to_group(
            inventory,
            server['_tags']['Type'],
            server,
            outputs,
        )

        # Set up ansible groups by server role (projectname_X_Role_Y)
        for role in outputs['projectname_roles']:
            inventory = add_instance_to_group(
                inventory,
                server['_tags']['Type'] + '_Role_' + role,
                server,
                outputs,
            )

    return inventory

def main():
    tfstate = utils.get_terraform_state()
    inventory = state_to_inventory(tfstate)
    sys.stdout.write(json.dumps(inventory, indent=4))

if __name__ == '__main__':
    main()
