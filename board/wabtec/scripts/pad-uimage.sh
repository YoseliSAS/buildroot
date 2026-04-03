#!/bin/sh
#
# Add padding to uImage to align it on the JFFS2 erase block size
# (BR2_TARGET_ROOTFS_JFFS2_EBSIZE)- The uImage is padded with 0x00 bytes
#

###############################################################################
# Safety
###############################################################################
set -eu

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
# Arguments
###############################################################################
if [ "$#" -lt 1 ]; then
    fatal "Usage: $0 <output_dir> [mkfs.jffs2 options]"
fi

output_dir=$1
shift

###############################################################################
# Resolve script directory (for consistency with other scripts)
###############################################################################
#script_dir="$(cd "$(dirname "$0")" && pwd -P)"

###############################################################################
# Defaults
###############################################################################
# Default erase block size if not found in arguments
ebsize="0x20000"

###############################################################################
# Parse jffs2 options to extract erase block size (-e)
###############################################################################
while [ "$#" -gt 0 ]; do
    case "$1" in
        -e)
            shift
            [ "$#" -gt 0 ] || fatal "Missing value after -e"
            ebsize=$1
            ;;
    esac
    shift
done

info "Erase block size: ${ebsize}"

###############################################################################
# Files
###############################################################################
uimage="${output_dir}/uImage"

[ -f "$uimage" ] || fatal "Missing uImage: $uimage"

###############################################################################
# Get uImage size
###############################################################################
uimage_size=$(stat -c '%s' "$uimage")

info "uImage size before padding: $uimage_size"

###############################################################################
# Compute padding
###############################################################################
# Convert ebsize (hex) to decimal for arithmetic
ebsize_dec=$((ebsize))

remainder=$((uimage_size % ebsize_dec))

if [ "$remainder" -eq 0 ]; then
    info "No padding needed"
    exit 0
fi

padding_size=$((ebsize_dec - remainder))

info "Padding size: $padding_size bytes"

###############################################################################
# Apply padding
###############################################################################
dd if=/dev/zero bs=1 count="$padding_size" >>"$uimage" status=none

###############################################################################
# Verify result
###############################################################################
new_size=$(stat -c '%s' "$uimage")

info "uImage size after padding: $new_size"
