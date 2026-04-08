#!/bin/sh
#
# Post-build filesystem adjustments
#

###############################################################################
# Safety
###############################################################################
set -e

###############################################################################
# Helpers
###############################################################################
fatal() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo "[INFO] $*"
}

###############################################################################
# Preconditions
###############################################################################
# TARGET_DIR is provided by Buildroot and points to the root filesystem
[ -n "${TARGET_DIR:-}" ] || fatal "TARGET_DIR is not set"
[ -d "$TARGET_DIR" ] || fatal "TARGET_DIR does not exist: $TARGET_DIR"

###############################################################################
# Volatile directories
###############################################################################
# We need a /volatile to mount our /etc /var and /run
info "Creating volatile directories"

mkdir -p "${TARGET_DIR}/volatile"
mkdir -p "${TARGET_DIR}/run/lock/subsys"

###############################################################################
# Log directory handling
###############################################################################
# Create the /data/log directory if it doesn't exist
# Then redirect /var/log to /data/log to persist logs on /data
info "Redirecting /var/log to /data/log"

mkdir -p "${TARGET_DIR}/data/log"

# Remove the /var/log directory if it exists
rm -rf "${TARGET_DIR}/var/log"

# Create a symbolic link from /var/log to /data/log
ln -sf /data/log "${TARGET_DIR}/var/log"

###############################################################################
# Init script ordering
###############################################################################
# Change the order to let /data be mounted before rsyslog
info "Adjusting rsyslog init script order"

if [ -f "${TARGET_DIR}/etc/init.d/S01rsyslogd" ]; then
    mv "${TARGET_DIR}/etc/init.d/S01rsyslogd" \
       "${TARGET_DIR}/etc/init.d/S10rsyslogd"
fi

###############################################################################
# SSH host key permissions
###############################################################################
# Change the permissions for ssh key
info "Fixing SSH host key permissions"

if [ -f "${TARGET_DIR}/etc/ssh/ssh_host_rsa_key" ]; then
    chmod 600 "${TARGET_DIR}/etc/ssh/ssh_host_rsa_key"
fi

###############################################################################
# Application-specific directories
###############################################################################
info "Creating application directories"

mkdir -p "${TARGET_DIR}/usr/DLC2ng"
mkdir -p "${TARGET_DIR}/usr/network"

###############################################################################
# Init script cleanup
###############################################################################
# Remove default nginx init script (we use S99nginx from overlay)
info "Removing default nginx init script"

rm -f "${TARGET_DIR}/etc/init.d/S50nginx"

info "Post-build filesystem adjustments complete"
