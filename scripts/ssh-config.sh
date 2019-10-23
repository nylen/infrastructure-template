#!/usr/bin/env bash

# This script prints a block of text suitable for inclusion into ~/.ssh/config
# to connect to ProjectName servers.

set -e

cd "$(dirname "$0")"
cd ..

if [ "$1" = "ROOT" ]; then
	username="root"
	echo "# WARNING: You're generating a ROOT ssh configuration!" >&2
	echo "# You should ALMOST NEVER need to make changes to servers directly." >&2
	echo "# If you're not sure about this, please ask for help." >&2
	echo "# Press Enter to continue or Ctrl+C to exit." >&2
	read i
	echo "" >&2
	user_arg=root
else
	user_arg=
fi

ssh_key=$(scripts/find-ssh-key.sh)
servers_and_users=$(scripts/list-servers-and-users.py $user_arg)

if [ "$username" = root ]; then
	echo '### BEGIN PROJECTNAME *ROOT* SSH CONFIG'
else
	echo '### BEGIN PROJECTNAME SSH CONFIG'
fi
echo

while read server; do
	server_name=$(echo "$server" | cut -d: -f1)
	username=$(echo "$server" | cut -d: -f2)
	server_hostname=$(echo "$server" | cut -d: -f3)
	if [ "$username" = root ]; then
		echo "# ssh ${server_name}_ROOT"
		echo "Host ${server_name}_ROOT"
	else
		echo "# ssh ${server_name}_${username}"
		echo "Host ${server_name}_${username}"
	fi
	echo "    Hostname $server_hostname"
	echo "    User $username"
	echo "    IdentityFile $ssh_key"
	echo "    IdentitiesOnly yes"
	echo "    ControlPath ~/.ssh/controlmasters/%r@%h:%p"
	echo "    ControlMaster auto"
	echo "    ControlPersist 10m"
	if [ "$username" != root ]; then
		echo "    ForwardAgent yes"
	fi
	echo
done < <(echo "$servers_and_users")

if [ "$username" = root ]; then
	echo '### END PROJECTNAME *ROOT* SSH CONFIG'
else
	echo '### END PROJECTNAME SSH CONFIG'
fi
