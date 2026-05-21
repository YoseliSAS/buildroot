#!/bin/sh

set -e

# We need a /volatile to mount our /etc /var and /run
mkdir -p "${TARGET_DIR}/volatile"

mkdir -p "${TARGET_DIR}/run/lock/subsys"
mkdir -p "${TARGET_DIR}/home"

# Create mount point directories for the multi-volume /data layout.
# These directories serve as mount points for the UBI volumes created
# by gen-datafs-ubi-multi.sh. S01mountdata mounts volumes on top of them.
# Layout per 2026-04-21 consensus (REQ_CYBER_EDCU_016549).
mkdir -p "${TARGET_DIR}/data/upload"
mkdir -p "${TARGET_DIR}/data/download"
mkdir -p "${TARGET_DIR}/data/security"
mkdir -p "${TARGET_DIR}/data/log"
mkdir -p "${TARGET_DIR}/data/system"
mkdir -p "${TARGET_DIR}/data/project_datafs"
mkdir -p "${TARGET_DIR}/data/flm"

# Remove legacy /data/var created by Buildroot from users_table.txt
# (systemLog home = /data/var/log, unused path not matching any real app)
rm -rf "${TARGET_DIR}/data/var"

# Persistent syslog: /var/log -> /data/log symlink.
# The UBI log volume is mounted at /data/log by S01mountdata.
# The symlink survives the overlayfs on /var (visible in the merged view).
rm -rf "${TARGET_DIR}/var/log"
ln -sf /data/log "${TARGET_DIR}/var/log"

# Change the order to let /data be mounted before rsyslog
if [ -f "${TARGET_DIR}/etc/init.d/S01rsyslogd" ]; then
    mv "${TARGET_DIR}/etc/init.d/S01rsyslogd" "${TARGET_DIR}/etc/init.d/S10rsyslogd"
fi

# Change the permissions for ssh key
if [ -f "${TARGET_DIR}/etc/ssh/ssh_host_rsa_key" ]; then
    chmod 600 "${TARGET_DIR}/etc/ssh/ssh_host_rsa_key"
fi

# Create project overlay fallback directory (used when no A/B bank is active)
mkdir -p "${TARGET_DIR}/usr/DLC2ng"
mkdir -p "${TARGET_DIR}/usr/network"
