#!/usr/bin/env python2

import os, sys

# https://stackoverflow.com/a/33532002/106302
from inspect import getsourcefile
current_dir = os.path.dirname(os.path.abspath(getsourcefile(lambda: 0)))
sys.path.insert(0, current_dir[:current_dir.rfind(os.path.sep)])

import utils
sys.path.pop(0)

def list_servers_and_users(tfstate, list_root_only = False):
    for server in utils.list_servers(tfstate):
        server_name = server['_name']
        if list_root_only:
            users = ['root']
        else:
            users = server['_module_outputs'].get('projectname_users', [])
        for user in users:
            print "%s:%s:%s" % (
                server_name,
                user,
                server['_public_ip'],
            )

def main():
    tfstate = utils.get_terraform_state()
    list_root_only = len(sys.argv) > 1 and sys.argv[1] == 'root'
    list_servers_and_users(tfstate, list_root_only)

if __name__ == '__main__':
    main()
