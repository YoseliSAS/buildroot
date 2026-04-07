#!/bin/sh
#
# Extract CRC32 from uImage header
# CRC32 field is located at offset 24 (4 bytes)
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
if [ "$#" -ne 1 ]; then
    fatal "Usage: $0 <images_dir>"
fi

images_dir=$1
uimage="${images_dir}/uImage"
output="${images_dir}/uImage.crc32"

###############################################################################
# Preconditions
###############################################################################
[ -f "$uimage" ] || fatal "Missing uImage: $uimage"
command -v hexdump >/dev/null 2>&1 || fatal "hexdump not found"

###############################################################################
# Extract CRC32
###############################################################################
info "Extracting CRC32 from uImage header"

hexdump -n1 -s24 -e '"%02X"' "$uimage" >"$output"
{
    hexdump -n1 -s25 -e '"%02X"' "$uimage"
    hexdump -n1 -s26 -e '"%02X"' "$uimage"
    hexdump -n1 -s27 -e '"%02X"' "$uimage"
} >>"$output"

info "CRC32 written to: $output"
