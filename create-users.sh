#!/bin/bash

test -f /etc/users.list || exit 0

while read id username hash groups; do
        # Skip, if user already exists
        grep ^$username /etc/passwd && continue
        # Create group
        addgroup --gid $id $username
        # Create user
        useradd -m -u $id -s /bin/bash -g $username $username
        # Set password
        echo "$username:$hash" | /usr/sbin/chpasswd -e
        # Add supplemental groups
        if [ $groups ]; then
                usermod -aG $groups $username
        fi
        ### fix to start chromium in a Docker container, see https://github.com/ConSol/docker-headless-vnc-container/issues/2
        echo "CHROMIUM_FLAGS='--no-sandbox --start-maximized --user-data-dir'" > /home/$username/.chromium-browser.init
        chown $username /home/$username/.chromium-browser.init

        # Remove and readd the user cert store for Chromium to avoid password prompts
        if [[ -d /home/$username/.pki/nssdb ]]; then
          rm -rf /home/$username/.pki/nssdb
        fi
        mkdir -p /home/$username/.pki/nssdb
        
        chown -R $username /home/$username
        chown -R $username /mnt/spyder

done < /etc/users.list
