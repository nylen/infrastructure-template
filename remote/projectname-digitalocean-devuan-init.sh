#!/usr/bin/env bash

# This script performs essential "first steps" for configuring a new server.
# Other configuration should be managed through `ansible`.

set -e
set -x

# Wait for cloudinit to finish, we need to override some of the things it wants
# to do (root password expiry)
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
	sleep 1
done

mkdir -p /projectname/server-setup/


###
# Disable the root password
###

passwd -d root
chage -d 3 -M -1 root # un-expire password (DigitalOcean wants it changed)

echo done > /projectname/server-setup/01-no-root-passwd


###
# Set up root's authorized SSH keys
###

# Back up old authorized_keys, if applicable
if [ -f /root/.ssh/authorized_keys ]; then
	cp -va /root/.ssh/authorized_keys /projectname/old_authorized_keys
	chmod 600 /projectname/old_authorized_keys
fi

# Copy the keys to /root/.ssh/authorized_keys
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
cp /projectname/ssh_keys_ROOT.txt /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo done > /projectname/server-setup/02-root-ssh-keys


###
# Upgrade packages
###

apt-get update
apt-get upgrade -y

echo done > /projectname/server-setup/03-apt-get-upgrade


###
# Install essential packages
###

apt-get install -y build-essential ufw git vim-nox joe fail2ban tmux

echo done > /projectname/server-setup/04-apt-get-install-essentials


###
# Configure firewall
###

if [ ! -f /projectname/server-setup/_block-ssh ]; then
	ufw allow 22/tcp
fi
ufw enable

echo done > /projectname/server-setup/05-ufw


###
# Devuan migration: set up and reboot
###

apt-get install -y sysvinit-core
after_reboot=$(cat <<'EOF'
#!/usr/bin/env bash

set -e
set -x


###
# Devuan migration: after reboot
###

apt-get purge -y systemd

sources_list=$(cat <<APT
deb http://deb.devuan.org/merged ascii main
deb http://deb.devuan.org/merged ascii-updates main
deb http://deb.devuan.org/merged ascii-security main
deb http://deb.devuan.org/merged ascii-backports main
APT
)
echo "$sources_list" > /etc/apt/sources.list

apt-get update
apt-get install -y devuan-keyring --allow-unauthenticated
apt-get update
apt-get dist-upgrade -y

apt-get purge -y systemd-shim
apt-get autoremove -y --purge
apt-get autoclean

rm /etc/cron.d/migrate-to-devuan

echo done > /projectname/server-setup/07-migrate-to-devuan-2


###
# Enable SSH
###

rm -f /projectname/server-setup/_block-ssh
ufw allow 22/tcp

echo done > /projectname/server-setup/08-enable-ssh


###
# All done!
###

echo v2019-10-09 > /projectname/server-setup/99-done


EOF
)
echo "$after_reboot" > /projectname/migrate-to-devuan.sh
chmod 700 /projectname/migrate-to-devuan.sh
touch /projectname/migrate-to-devuan.log
chmod 600 /projectname/migrate-to-devuan.log
echo '
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
@reboot root /projectname/migrate-to-devuan.sh > /projectname/migrate-to-devuan.log 2>&1
' > /etc/cron.d/migrate-to-devuan

echo done > /projectname/server-setup/06-migrate-to-devuan-1

reboot
