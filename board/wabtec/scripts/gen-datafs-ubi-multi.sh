#!/bin/sh
#
# Generate a multi-volume UBI /data image from per-volume skeletons.
#
# For each volume: prepare directory, apply permissions via fakeroot +
# makedevs, normalize timestamps, build UBIFS image. Then combine all
# .ubifs into a single data.ubi via genimage.
#
# Reproducibility: SOURCE_DATE_EPOCH, LC_ALL=C, per-volume deterministic
# UUIDs.

set -eu

###############################################################################
# Reproducibility
###############################################################################
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-946684800}"
export SOURCE_DATE_EPOCH
export LC_ALL=C

###############################################################################
# Helpers
###############################################################################
fatal() { echo "[FATAL] $*" >&2; exit 1; }
info()  { echo "[INFO] $*"; }

require_dir()  { [ -d "$1" ] || fatal "Missing directory: $1"; }
require_file() { [ -f "$1" ] || fatal "Missing file: $1"; }
require_exec() { [ -x "$1" ] || fatal "Missing or non-executable: $1"; }

###############################################################################
# Arguments
###############################################################################
if [ $# -lt 1 ]; then
    echo "Usage: $0 <output_dir> [jffs2_opts...]" >&2
    exit 1
fi

output_dir="$1"
shift

###############################################################################
# Paths
###############################################################################
script_dir="$(cd "$(dirname "$0")" && pwd -P)"
board_dir="$(cd "${script_dir}/.." && pwd -P)"
common_dir="${board_dir}/common"

host_dir="${output_dir}/host"
work_dir="${output_dir}/data-multi-volumes"
images_dir="${output_dir}/images"

skeleton_base="${common_dir}/skeleton_data_volumes"

###############################################################################
# Volume list (REQ_CYBER_EDCU_016549, 2026-04-21 consensus)
###############################################################################
# name:size_mb:type (static or dynamic)
# Total: 264 MB
# project_datafs is declared in MR1 but only mounted in MR2 (FLM+CBM bind).
VOLUMES="
project_a:32:static
project_b:32:static
project_datafs:64:dynamic
upload:64:dynamic
download:48:dynamic
security:4:dynamic
log:16:dynamic
system_dyn:4:dynamic
"

###############################################################################
# Preconditions
###############################################################################
require_dir "$output_dir"
require_dir "$common_dir"
require_dir "$skeleton_base"
require_exec "${host_dir}/bin/fakeroot"
require_exec "${host_dir}/usr/bin/makedevs"
require_exec "${host_dir}/sbin/mkfs.ubifs"
require_exec "${host_dir}/bin/genimage"

###############################################################################
# Step 1: Generate device table fragments
###############################################################################
info "Generating per-volume device tables from users_table.txt"
device_tables_dir="${work_dir}/device_tables"
rm -rf "${work_dir}"
mkdir -p "${work_dir}"
python3 "${script_dir}/gen-datafs-skeletons.py" "${common_dir}" "${device_tables_dir}"

###############################################################################
# Step 2: Prepare per-volume directories + fakeroot + mkfs.ubifs
###############################################################################
info "Preparing volumes"
ubifs_dir="${work_dir}/ubifs"
mkdir -p "${ubifs_dir}"

fakeroot_script="${work_dir}/fakeroot-all.sh"

# Write fakeroot script header
printf '#!/bin/sh\nset -e\n' > "${fakeroot_script}"
printf 'export SOURCE_DATE_EPOCH=%s\n' "${SOURCE_DATE_EPOCH}" >> "${fakeroot_script}"
printf 'export LC_ALL=C\n\n' >> "${fakeroot_script}"

for entry in ${VOLUMES}; do
    vol=$(echo "$entry" | cut -d: -f1)
    size_mb=$(echo "$entry" | cut -d: -f2)

    vol_work="${work_dir}/vol-${vol}"
    vol_skeleton="${skeleton_base}/${vol}"
    vol_devtable="${device_tables_dir}/device_table_data-${vol}.txt"

    # Prepare volume directory
    rm -rf "${vol_work}"
    mkdir -p "${vol_work}"

    if [ -d "${vol_skeleton}" ]; then
        cp -a "${vol_skeleton}/." "${vol_work}/"
    fi

    # Remove .empty placeholder files
    find "${vol_work}" -name '.empty' -delete 2>/dev/null || true

    # Calculate max LEB count: size_bytes / LEB_size
    leb_count=$(( size_mb * 1024 * 1024 / 126976 ))

    # Append volume processing to fakeroot script. The ${SOURCE_DATE_EPOCH}
    # in the find line is intentionally kept literal so it expands when the
    # fakeroot script runs, not now.
    {
        printf 'echo "[FAKEROOT] Volume: %s"\n' "${vol}"
        printf 'chown -R 0:0 "%s"\n' "${vol_work}"
        # shellcheck disable=SC2016
        printf 'find "%s" -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +\n' "${vol_work}"

        if [ -f "${vol_devtable}" ]; then
            printf '"%s/usr/bin/makedevs" -d "%s" "%s"\n' "${host_dir}" "${vol_devtable}" "${vol_work}"
        fi

        printf 'echo "[FAKEROOT] mkfs.ubifs: %s (%s MB, %s LEBs)"\n' "${vol}" "${size_mb}" "${leb_count}"
        printf '"%s/sbin/mkfs.ubifs" \\\n' "${host_dir}"
        printf '    -d "%s" \\\n' "${vol_work}"
        printf '    -e 126976 -m 2048 \\\n'
        printf '    -c %s \\\n' "${leb_count}"
        printf '    -x none \\\n'
        printf '    -o "%s/data-%s.ubifs"\n\n' "${ubifs_dir}" "${vol}"
    } >> "${fakeroot_script}"
done

chmod 0755 "${fakeroot_script}"

info "Running fakeroot (all volumes)"
"${host_dir}/bin/fakeroot" -- "${fakeroot_script}"

###############################################################################
# Step 3: Generate genimage config for ubinize
###############################################################################
info "Generating genimage configuration"

genimage_runtime_cfg="${work_dir}/genimage-runtime.cfg"

# Flash definition
cat > "${genimage_runtime_cfg}" <<'CFGEOF'
flash nand-dlcnext {
    pebsize   = 0x20000
    lebsize   = 0x1f000
    numpebs   = 2808
    minimum-io-unit-size = 0x800
    vid-header-offset    = 0x800
    sub-page-size        = 0x800
}

image data.ubi {
    ubi {
        extraargs = "-Q 1"
    }
    flashtype = "nand-dlcnext"
CFGEOF

# Volume partitions
for entry in ${VOLUMES}; do
    vol=$(echo "$entry" | cut -d: -f1)
    size_mb=$(echo "$entry" | cut -d: -f2)
    vol_type=$(echo "$entry" | cut -d: -f3)

    {
        printf '\n    partition %s {\n' "${vol}"
        printf '        image = "data-%s.ubifs"\n' "${vol}"
        printf '        size = %sM\n' "${size_mb}"
        if [ "${vol_type}" = "static" ]; then
            printf '        read-only = true\n'
        fi
        printf '    }\n'
    } >> "${genimage_runtime_cfg}"
done

printf '}\n' >> "${genimage_runtime_cfg}"

###############################################################################
# Step 4: Run genimage
###############################################################################
info "Running genimage"
genimage_tmp="${work_dir}/genimage-tmp"
rm -rf "${genimage_tmp}"
mkdir -p "${genimage_tmp}"

PATH="${host_dir}/bin:${host_dir}/sbin:${PATH}"
export PATH

"${host_dir}/bin/genimage" \
    --config "${genimage_runtime_cfg}" \
    --rootpath "${work_dir}" \
    --inputpath "${ubifs_dir}" \
    --outputpath "${images_dir}" \
    --tmppath "${genimage_tmp}"

info "UBI image generated: $(ls -lh "${images_dir}/data.ubi")"

###############################################################################
# Step 5: Compress for first-boot embedding
###############################################################################
# data.ubi.gz is later copied into target_dir by post-build.sh so it lands
# in the rootfs as /usr/share/data.ubi.gz. We deliberately do not write it
# to the source rootfs_overlay tree: the source overlay is copied into
# target_dir BEFORE post-build.sh runs, so writing here would only land in
# the rootfs of the NEXT build, never the current one.
info "Compressing UBI image"
gzip -9 -c "${images_dir}/data.ubi" > "${images_dir}/data.ubi.gz"

###############################################################################
# Done
###############################################################################
info "Multi-volume data.ubi generation complete (8 volumes)"
