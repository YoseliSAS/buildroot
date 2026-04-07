#!/bin/sh
#
# Create a JFFS2 /data filesystem image from a skeleton, using fakeroot
#

###############################################################################
# Safety settings
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

require_file() {
    [ -f "$1" ] || fatal "Missing file: $1"
}

require_dir() {
    [ -d "$1" ] || fatal "Missing directory: $1"
}

require_exec() {
    [ -x "$1" ] || fatal "Missing or non-executable: $1"
}

###############################################################################
# Arguments
###############################################################################
if [ "$#" -lt 1 ]; then
    fatal "Usage: $0 <output_dir> [mkfs.jffs2 options...]"
fi

output_dir=$1
shift
# "$@" now contains only the mkfs.jffs2 options

###############################################################################
# Path resolution
###############################################################################
script_dir="$(cd "$(dirname "$0")" && pwd -P)"

board_dir="$(cd "${script_dir}/.." && pwd -P)"
common_dir="${board_dir}/common"

host_dir="${output_dir}/host"
images_dir="${output_dir}/images"
work_dir="${output_dir}/slash-data-custom"
fakeroot_script="${work_dir}/fakeroot2.sh"

###############################################################################
# Preconditions
###############################################################################
require_dir "$output_dir"
require_dir "$common_dir"
require_dir "${common_dir}/skeleton_data"

require_exec "${host_dir}/bin/fakeroot"
require_exec "${host_dir}/usr/bin/makedevs"
require_exec "${host_dir}/sbin/mkfs.jffs2"
require_exec "${host_dir}/sbin/sumtool"

require_file "${common_dir}/device_table_data.txt"

###############################################################################
# Prepare sumtool options (filtered mkfs options)
###############################################################################
sumtool_opts=""

sumtool_opts=$(
    printf '%s ' "$@" |
    sed -E \
        -e 's/--with-xattr([[:space:]]|$)/\1/g' \
        -e 's/-s[[:space:]]+0x[0-9a-fA-F]+//g'
)

info "mkfs.jffs2 opts : $(printf '%s ' "$@")"
info "sumtool opts    : $sumtool_opts"

###############################################################################
# Prepare working directory
###############################################################################
info "Preparing working directory"

rm -rf "$work_dir"
mkdir -p "$work_dir"

cp -a "${common_dir}/skeleton_data" "${work_dir}/data"

###############################################################################
# Generate fakeroot script
###############################################################################
cat > "$fakeroot_script" <<EOF
#!/bin/sh
set -e

echo "[FAKEROOT] Fix ownership"
chown -R 0:0 "${work_dir}/data"

echo "[FAKEROOT] Create device nodes"
"${host_dir}/usr/bin/makedevs" \
    -d "${common_dir}/device_table_data.txt" \
    "${work_dir}/data"

echo "[FAKEROOT] Create JFFS2 image (no summary)"
"${host_dir}/sbin/mkfs.jffs2" \
    ${@+"$@"} \
    -d "${work_dir}/data" \
    -o "${output_dir}/data.jffs2.nosummary"

echo "[FAKEROOT] Add JFFS2 summary"
"${host_dir}/sbin/sumtool" \
    ${sumtool_opts} \
    -i "${output_dir}/data.jffs2.nosummary" \
    -o "${images_dir}/data.jffs2"

echo "[FAKEROOT] Cleanup"
rm -f "${output_dir}/data.jffs2.nosummary"

echo "[FAKEROOT] Done"
EOF

chmod 0755 "$fakeroot_script"

###############################################################################
# Execute fakeroot
###############################################################################
info "Running fakeroot"
"${host_dir}/bin/fakeroot" -- "$fakeroot_script"

info "JFFS2 data image successfully generated:"
info " -> ${images_dir}/data.jffs2"
