# DLC-Next /data partition layout

Status: Consolidated 2026-04-21 (REQ_CYBER_EDCU_016549)

This document defines the segmentation of the `/data` MTD partition (mtd6)
into multiple UBI volumes. It is the reference for build-time
(`gen-datafs-ubi-multi.sh`, `gen-datafs-skeletons.py`, `data_dirs.txt`)
and runtime (`S01mountdata`, `S08mountvolatile`) code.

## Why segmentation

The historical layout used a single UBIFS volume `data` mounted at `/data`
with autoresize. Three problems:

1. **No resource isolation.** An FTP upload flood, a syslog runaway, or a
   FLM producer in tight loop can fill the entire `/data` and take down
   unrelated services.
2. **No A/B banking for project overlay.** A project overlay update is a
   risky in-place operation. A failed update can leave the system in a
   state where the project overlay is inconsistent and the BSP must be
   reinstalled.
3. **No isolation of security configuration.** Security config currently
   lives next to FTP uploads and user data. A bug in an unrelated service,
   or a malicious file uploaded via FTP, can corrupt it.

## Volume layout

Per the 2026-04-21 review with R. Beaujouan and M. Puret. Total 264 MB
on the data MTD partition.

| Volume          | Size  | Type    | Mount point             | Notes                                        |
|-----------------|-------|---------|-------------------------|----------------------------------------------|
| project_a       | 32 MB | static  | (bank A, A/B switching) | Project overlay bank A                       |
| project_b       | 32 MB | static  | (bank B, A/B switching) | Project overlay bank B                       |
| project_datafs  | 64 MB | dynamic | /data/project_datafs    | FLM + CBM + project shared data (bound MR1)  |
| upload          | 64 MB | dynamic | /data/upload            | FTP incoming                                 |
| download        | 48 MB | dynamic | /data/download          | FTP outgoing                                 |
| security        |  4 MB | dynamic | /data/security          | Security configuration                      |
| log             | 16 MB | dynamic | /data/log               | Persistent logs (rsyslog, logrotate)         |
| system_dyn      |  4 MB | dynamic | /data/system            | resolv.conf, faillock, random-seed (DLC2NG)  |
| **Total**       | **264 MB** |    |                         |                                              |

## Notes per volume

- `project_a` / `project_b` are **mini-rootfs banks** (mirror the rootfs
  directory layout). Selected by U-Boot env `proj_overlay_status` (a or b)
  read at runtime by `S01mountdata`. Mounted read-only at
  `/run/project_overlay`, then bind-mounted to `/usr/DLC2ng` (and any
  other top-level dir in MR2 via auto-discovered overlayfs).
- `project_datafs` holds **FLM and CBM history** that must persist across
  bank switches. Mounted at `/data/project_datafs` in MR1, with bind
  compat `mount --bind /data/project_datafs/flm /data/flm` and same for
  cbm, so applicative code keeps using the legacy paths unchanged.
- `system_dyn` holds **dynamic system files** (not project data): future
  `resolv.conf` cache, PAM faillock, and on DLC2NG the persistent
  random-seed (busybox `seedrng`). DLC-Next does not need a persistent
  random-seed because it has the imx-rngc HW RNG. A future rootfs version
  sentinel (reintroduced in MR2) will trigger a wipe of `system_dyn` on
  rootfs library version change.

## Differences vs the previous proposal

- Volume `flm` of the WIP layout is dropped. FLM (and CBM) data live in
  `project_datafs` from MR1 onward, bind-mounted to the legacy paths.
- Volume `security` shrinks from 32 MB to 4 MB. Real security payload is
  ~68 KB (security_package + backup); 4 MB leaves headroom while
  respecting UBIFS overhead on small volumes (~620 KB minimum).
- Volume `log` shrinks from 32 MB to 16 MB. logrotate keeps 5 uncompressed
  files of ~500 KB per facility (messages + security.log) ~= 6 MB,
  16 MB leaves headroom.
- `ld.so.cache` no longer lives in a runtime-writable volume. It is
  pre-generated at build time by `post-build.sh` and embedded in the
  read-only rootfs (commit 583dabd508 on integration).
- `/data/indent/serial` is dropped. The DCU serial number lives in the
  internal EEPROM (per Mickael Puret 2026-04-21), not in `/data`.

## DLC2NG swap (forward-looking, not yet allocated)

DLC2NG (MCF54415, 128 MB RAM, no HW RNG) is expected to need a swap
region on a **raw MTD** (outside the UBI image) when a future package
installer cannot decompress `.up` archives entirely in RAM. The current
installer extracts to flash (`/data/upload`) so swap is not needed for
this flow, but the requirement may resurface for project-specific
installers.

The software side is in place and self-gating:

  - `BR2_SYSTEM_NEEDS_SWAP` Kconfig flag, selected by `BR2_BOARD_DLC2NG`
  - `CONFIG_MKSWAP=y` in `busybox-minimal.config`
  - `S02swap-mtd` init script, which scans `/proc/mtd` for a partition
    literally named `"swap"`, runs `mkswap` if the SWAPSPACE2 magic is
    absent, then `swapon`. No "swap" label = silent no-op.

The hardware side (a "swap" partition in the U-Boot env `bootargs`
mtdparts) is not currently declared on any shipping board, so the
script is dormant. DLC-Next (256 MB RAM) does not need swap.

If a future hardware revision allocates a "swap" partition (typically
by adjusting the U-Boot env on the target, no buildroot change needed),
`S02swap-mtd` will pick it up at the next boot.

## Reproducibility

`gen-datafs-ubi-multi.sh` honors `SOURCE_DATE_EPOCH` and uses
`LC_ALL=C` for stable file ordering. `mkfs.ubifs` is patched (see
`package/mtd/0001-mkfs.ubifs-reproducible-UUID-...patch`) to use a fixed
UUID and clamped timestamps when `SOURCE_DATE_EPOCH` is set.

`device_table_data-<volume>.txt` files are generated dynamically from
`users_table.txt` plus `data_dirs.txt`, eliminating the historical UID
drift between the manually maintained `device_table_data.txt` and the
authoritative user table.
