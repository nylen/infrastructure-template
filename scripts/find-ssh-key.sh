#!/usr/bin/env bash

# This script finds and prints the filename of a valid ProjectName SSH key
# that is loaded into memory using ssh-agent.

set -e

cd "$(dirname "$0")"
cd ..

if [ ! -f keys/ssh_authorized_keys_ROOT.txt ]; then
	echo "ERROR: keys/ssh_authorized_keys_ROOT.txt file not found!" >&2
	echo "Put SSH public keys into this file, and they will be given ROOT access" >&2
	echo "to new servers created by this process." >&2
	exit 1
fi

keys_loaded=$(ssh-add -l)

while read key_valid; do
	fp_valid=$(echo "$key_valid" | ssh-keygen -lf - | cut -d' ' -f1,2,4)
	while read fp_with_name_loaded; do
		fp_loaded=$(echo "$fp_with_name_loaded" | cut -d' ' -f1,2,4)
		name_loaded=$(echo "$fp_with_name_loaded" | cut -d' ' -f3)
		if [ "$fp_valid" = "$fp_loaded" ]; then
			name_loaded_short=${name_loaded#$HOME/}
			if [ "$name_loaded_short" != "$name_loaded" ]; then
				name_loaded="~/$name_loaded_short"
			fi
			echo "$name_loaded"
			exit 0
		fi
	done < <(echo "$keys_loaded")
done < keys/ssh_authorized_keys_ROOT.txt

echo "ERROR: No valid SSH key found!" >&2
echo "You need to load your ProjectName SSH key into ssh-agent, for example:" >&2
echo "ssh-add ~/.ssh/your_projectname_rsa" >&2
exit 1
