#!/usr/bin/env bash

# This script updates the configuration of all servers using Ansible.

set -e

cd "$(dirname "$0")"
cd ..

if [ -z "$VIRTUAL_ENV" ]; then
	echo 'No Python virtual environment is loaded!'
	echo 'You need to run `. bin/activate` in your current shell.'
	exit 1
fi

ssh_key=$(scripts/find-ssh-key.sh)

playbook="$1"
if [ -z "$playbook" ]; then
	playbook=ansible/main.yml
fi

ANSIBLE_CONFIG=ansible/ansible.cfg \
	ansible-playbook \
	--inventory=terraform-inventory.py \
	--private-key="$ssh_key" \
	--forks=12 \
	"$playbook" \
	-v
