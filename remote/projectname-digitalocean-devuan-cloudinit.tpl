#cloud-config

# vim: ft=yaml et ts=2 sw=2

# Block access to SSH (until server setup is done)
# This runs at init priority 01, before /etc/init.d/ssh (priority 03)
# Disabling SSH using update-rc.d instead did not work (TODO why?)
bootcmd:
  - |
    set -x
    if [ ! -f /projectname/server-setup/99-done ]; then
      touch /projectname/server-setup/_block-ssh
      [ -f /usr/sbin/ufw ] || apt-get install ufw
      ufw delete allow 22/tcp
      ufw enable
    fi

# Write init script and root SSH keys
write_files:
  - encoding: b64
    content: "${ssh_keys_ROOT_txt}"
    owner: root:root
    path: /projectname/ssh_keys_ROOT.txt
    permissions: '0600'
  - encoding: b64
    content: "${init_sh}"
    owner: root:root
    path: /projectname/init.sh
    permissions: '0700'

# https://www.digitalocean.com/community/questions/cloud-init-change-order-of-module-execution
# Doesn't appear to be a problem now, but could be in the future...
runcmd:
  - |
    set -x
    (
      while [ ! -f /projectname/init.sh ]; do
        sleep 1
      done
      /projectname/init.sh
    ) &
