#!/bin/sh
#
# Create a UBIFS /data filesystem and wrap it into a UBI volume
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

require_dir() {
    [ -d "$1" ] || fatal "Missing directory: $1"
}

require_file() {
    [ -f "$1" ] || fatal "Missing file: $1"
}

require_exec() {
    [ -x "$1" ] || fatal "Missing or non-executable: $1"
}

###############################################################################
# Arguments
###############################################################################
if [ "$#" -lt 1 ]; then
    fatal "Usage: $0 <output_dir>"
fi

output_dir=$1

###############################################################################
# Paths
###############################################################################
script_dir="$(cd "$(dirname "$0")" && pwd -P)"

board_dir="$(cd "${script_dir}/.." && pwd -P)"
common_dir="${board_dir}/common"

host_dir="${output_dir}/host"
#target_dir="${output_dir}/target"
work_dir="${output_dir}/slash-data-custom"
images_dir="${output_dir}/images"

fakeroot_script="${work_dir}/fakeroot.sh"
ubinize_cfg="${output_dir}/ubinize.cfg"

skeleton_dir="${common_dir}/skeleton_data"
device_table="${common_dir}/device_table_data.txt"

###############################################################################
# Preconditions
###############################################################################
require_dir "$output_dir"
require_dir "$host_dir"
require_dir "$images_dir"
require_dir "$skeleton_dir"

require_file "$device_table"

require_exec "${host_dir}/bin/fakeroot"
require_exec "${host_dir}/usr/bin/makedevs"
require_exec "${host_dir}/sbin/mkfs.ubifs"
require_exec "${host_dir}/sbin/ubinize"

###############################################################################
# Prepare working directory
###############################################################################
info "Preparing working directory"

rm -rf "$work_dir"
mkdir -p "$work_dir"

cp -a "$skeleton_dir" "$work_dir/data"

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
    -d "${device_table}" \
    "${work_dir}/data"

echo "[FAKEROOT] Create UBIFS image"
"${host_dir}/sbin/mkfs.ubifs" \
    -d "${work_dir}/data" \
    -e 0x1f000 \
    -c 2048 \
    -m 0x800 \
    -x none \
    -o "${output_dir}/data.ubifs"

echo "[FAKEROOT] Done"
EOF

chmod 0755 "$fakeroot_script"

info "Running fakeroot script"
cat "$fakeroot_script"
"${host_dir}/bin/fakeroot" -- "$fakeroot_script"

###############################################################################
# UBI configuration
###############################################################################
info "Generating ubinize configuration"

# Fixed UBI volume size
fixed_size="128MiB"

cat > "$ubinize_cfg" <<EOF
[ubifs]
mode=ubi
image=${output_dir}/data.ubifs
vol_id=0
vol_size=${fixed_size}
vol_type=dynamic
vol_name=data
vol_flags=autoresize
EOF

cat "$ubinize_cfg"

###############################################################################
# Generate UBI image
###############################################################################
info "Generating UBI image"

"${host_dir}/sbin/ubinize" \
    -o "${images_dir}/data.ubi" \
    -m 0x800 \
    -p 0x20000 \
    -s 2048 \
    "$ubinize_cfg"

info "UBI image successfully generated:"
info " -> ${images_dir}/data.ubi"

###############################################################################
# Optional cleanup (left disabled on purpose for debugging)
###############################################################################
# rm -f "${output_dir}/data.ubifs"
# rm -f "$ubinize_cfg"

