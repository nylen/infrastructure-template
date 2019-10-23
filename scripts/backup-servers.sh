#!/bin/bash

set -e

cd "$(dirname "$0")"
cd ..
cd backups

# Uncomment if you have databases to back up:
#. db-credentials.sh

if [ \
	-z "$DO_DB_HOST" -o \
	-z "$DO_DB_PORT" -o \
	-z "$DO_DB_USER" -o \
	-z "$DO_DB_PASS" \
]; then
	# Uncomment if you have databases to back up:
	#echo "Missing DB credentials!"
	#exit 1
fi

backup_files() {
	host="$1"
	user="$2"
	path="$3"
	echo >&2
	echo "+ backup_files $host $user $path" >&2
	mkdir -p "./files/$host/$user/$path/"
	rsync -rltvz --delete \
		"${host}_${user}:$path/" \
		"./files/$host/$user/$path/"
}

backup_file() {
	host="$1"
	user="$2"
	path="$3"
	file="$4"
	echo >&2
	echo "+ backup_file $host $user $path $file" >&2
	mkdir -p "./files/$host/$user/$path/"
	rsync -ltv \
		"${host}_${user}:$path/$file" \
		"./files/$host/$user/$path/"
}

backup_do_db() {
	host="$1"
	db="$2"
	echo >&2
	echo "+ backup_do_db $host $db" >&2
	mkdir -p "./db/$host/"
	ssh -C "$host" \
		"mysqldump $db -u'$DO_DB_USER' -p'$DO_DB_PASS' -h'$DO_DB_HOST' -P'$DO_DB_PORT' --skip-extended-insert --set-gtid-purged=OFF" \
		> "./db/$host/$db.sql"
}

# pre-initialize all needed SSH conditions
for host in \
	projectname.www_ROOT \
	projectname.www_wwwfiles \
; do
	ssh $host true &
done

backup_files projectname.www ROOT /var/log/apache2

backup_files projectname.www wwwfiles .ssh

# it's OK if some of these tasks fail
set +e
# bash history for root
backup_file projectname.www        ROOT        . .bash_history
# bash history for non-root users
backup_file projectname.www        wwwfiles    . .bash_history
# disallow failures again
set -e

#backup_do_db projectname.www_ROOT dbname
