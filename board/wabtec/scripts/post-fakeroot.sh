#!/bin/sh

# We need a /volatile to mount our /etc /var and /run
mkdir -p "${TARGET_DIR}/volatile"

mkdir -p "${TARGET_DIR}/run/lock/subsys"

# Create the /data/log directory if it doesn't exist
mkdir -p "${TARGET_DIR}/data/log"
# Remove the /var/log directory if it exists
rm -rf "${TARGET_DIR}/var/log"
# Create a symbolic link from /var/log to /data/log
ln -sf /data/log "${TARGET_DIR}/var/log"

# Change the order to let /data beeing mounted before rsyslog
mv "${TARGET_DIR}/etc/init.d/S01rsyslogd" "${TARGET_DIR}/etc/init.d/S10rsyslogd"

# Change the permissions for ssh key
chmod 600 "${TARGET_DIR}/etc/ssh/ssh_host_rsa_key"
