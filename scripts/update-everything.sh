#!/usr/bin/env bash

# This script applies any changes using Terraform, and then updates the
# configuration of all servers using Ansible.

set -e

if [ -z "$VIRTUAL_ENV" ]; then
	echo 'No Python virtual environment is loaded!'
	echo 'You need to run `. bin/activate` in your current shell.'
	exit 1
fi

cd "$(dirname "$0")"
cd ..

terraform get
terraform apply
scripts/run-ansible-playbooks.sh
