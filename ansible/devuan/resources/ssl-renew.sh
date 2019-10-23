#!/usr/bin/env bash

set -e

# Permissions check

( cd /www/ssl/certs/ ) || exit 1

# Settings

account_private_key="/www/ssl/certs/user.key"
domain_private_key="/www/ssl/certs/server.key"
account_contact="mailto:james@projectname.com"

csr_file="/www/ssl/certs/domains.csr"

openssl_csr_config="/www/ssl/certs/openssl-csr.cnf"

acme_dir="/www/ssl/acme-challenge/"
ACME_TINY="/www/ssl/acme-tiny/acme_tiny.py"

cert_file="/www/ssl/certs/domains.crt"
cert_file_tmp="$cert_file.tmp"

hostnames_file="/www/ssl/hostnames"

if [ ! -r "$hostnames_file" ]; then
	echo "Hostnames file not readable: $hostnames_file"
	exit 1
fi

domains=
while read domain; do
	if [ ! -z "$domains" ]; then
		domains="$domains,"
	fi
	domains="${domains}DNS:${domain}"
done < "$hostnames_file"

if [ -z "$domains" ]; then
	echo "No domain names registered for this server!"
	exit 1
fi

echo "domains: $domains"

# Generate a certificate signing request for multiple domains
# https://github.com/diafygi/acme-tiny#step-3-make-your-website-host-challenge-files

echo "Generating CSR $csr_file ..."

touch "$openssl_csr_config"
chmod 600 "$openssl_csr_config"
cat /etc/ssl/openssl.cnf > "$openssl_csr_config"
cat <<EOF >> "$openssl_csr_config"
[SAN]
subjectAltName=$domains
EOF

touch "$csr_file"
chmod 600 "$csr_file"
openssl req -new -sha256 \
	-key "$domain_private_key" \
	-subj '/' -reqexts SAN \
	-config "$openssl_csr_config" \
	> "$csr_file"

echo "Requesting certificate $cert_file ..."

# Get the certificate and move it into place atomically

touch "$cert_file_tmp"
chown root:www-data "$cert_file_tmp"
chmod 640 "$cert_file_tmp"
"$ACME_TINY" \
	--account-key "$account_private_key" \
	--contact "$account_contact" \
	--csr "$csr_file" \
	--acme-dir "$acme_dir" \
	> "$cert_file_tmp"

mv "$cert_file_tmp" "$cert_file"

# Finally, reload the webserver

/etc/init.d/apache2 reload
