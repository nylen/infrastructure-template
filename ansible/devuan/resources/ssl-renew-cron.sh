#!/usr/bin/env bash

(
	date
	echo
	/www/ssl/certs/renew.sh 2>&1
	code=$?
	echo
	echo "Exit code: $code"
) > /www/ssl/certs/renew.log

chmod 600 /www/ssl/certs/renew.log
