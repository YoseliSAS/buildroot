#!/bin/sh
#
# Post-image processing:
#  - generate uImage
#  - pad uImage to JFFS2 erase block size
#  - generate data filesystems
#  - compute CRC16 and CRC32
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

require_exec() {
    [ -x "$1" ] || fatal "Missing or non-executable: $1"
}

###############################################################################
# Arguments
###############################################################################
# Display the arguments passed to the script (for traceability/debug)
echo "post-image.sh $*"

# Example:
# post-image.sh \
#   /home/user/project/output/images \
#   -e 0x20000 --with-xattr -p -b -n
#
# First argument is the output/images directory
# Next arguments are the JFFS2 options in the form:
#   "-e 0x20000 --with-xattr -p -b -n"
#
# JFFS2 options are all the arguments passed to the script after $1
# and are forwarded verbatim to the downstream scripts.

if [ "$#" -lt 1 ]; then
    fatal "Usage: $0 <images_dir> [jffs2 options]"
fi

images_dir=$1
shift
# "$@" now contains only the mkfs.jffs2 options

info "JFFS2 options: $(printf '%s ' "$@")"

###############################################################################
# Paths
###############################################################################
# Resolve script location (do not rely on CWD)
script_dir="$(cd "$(dirname "$0")" && pwd -P)"

# Output directory is derived from the images directory
output_dir="$(cd "${images_dir}/.." && pwd -P)"

###############################################################################
# Preconditions
###############################################################################
[ -d "$images_dir" ] || fatal "Missing images directory: $images_dir"

require_exec "${script_dir}/pad-uimage.sh"
require_exec "${script_dir}/gen-datafs.sh"
require_exec "${script_dir}/gen-datafs-ubi.sh"

command -v m68k-linux-objcopy >/dev/null 2>&1 || fatal "m68k-linux-objcopy not found"
command -v mkimage >/dev/null 2>&1 || fatal "mkimage not found"
command -v python3 >/dev/null 2>&1 || fatal "python3 not found"

###############################################################################
# Generate uImage
###############################################################################
info "Generating uImage"

m68k-linux-objcopy \
    -O binary \
    "${images_dir}/vmlinux" \
    "${images_dir}/image.bin"

mkimage \
    -A m68k \
    -O linux \
    -T kernel \
    -C none \
    -a 0x41002000 \
    -e 0x41002000 \
    -n "Linux-54418" \
    -d "${images_dir}/image.bin" \
    "${images_dir}/uImage"

###############################################################################
# Post-processing
###############################################################################
# Padding and filesystem generation reuse the same JFFS2 options
info "Padding uImage"
"${script_dir}/pad-uimage.sh" "$images_dir" "$@"

info "Generating JFFS2 data filesystem"
"${script_dir}/gen-datafs.sh" "$output_dir" "$@"

info "Generating UBI data filesystem"
"${script_dir}/gen-datafs-ubi.sh" "$output_dir" "$@"

###############################################################################
# Checksums
###############################################################################
info "Generating CRC16 checksum files"
rm -f "${images_dir}"/*.crc16 "${images_dir}"/*.crc32

python3 "${script_dir}/crc16.py" -w "${images_dir}"/*

info "Generating CRC32 checksum files for uImage"
"${script_dir}/mkCrc32.sh" "$images_dir"

info "Post-image processing complete"
