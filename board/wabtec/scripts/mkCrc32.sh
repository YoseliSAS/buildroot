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

#
# The CRC32 field is located at offset 24 in the uImage header and spans 4 bytes.
# We read exactly 4 bytes starting at this offset and format each byte as a
# two-digit hexadecimal value, concatenated without separators.
#
# Options:
#   -s24       start reading at byte offset 24
#   -n4        read exactly 4 bytes
#   -e '4/1'   process 4 units of 1 byte each
#              and print each byte using "%02X"
#
# This approach reads the whole 32-bit field in a single hexdump invocation,
# making the intent explicit (one 4-byte field) and avoiding multiple calls.

hexdump -n4 -s24 -e '4/1 "%02X"' "$uimage" >"$output"

info "CRC32 written to: $output"
