#!/usr/bin/env python3
"""Generate per-volume device_table_data fragments from users_table.txt.

Reads users_table.txt (Buildroot format) and data_dirs.txt (static dirs),
produces one device_table_data-<volume>.txt per volume with correct
uid/gid/mode entries for makedevs.

This replaces the manually maintained device_table_data.txt which had
drifted from users_table.txt (wrong UIDs for FTP users).

Usage:
    gen-datafs-skeletons.py <common_dir> <output_dir>

    common_dir: board/wabtec/common/ (contains users_table.txt, data_dirs.txt)
    output_dir: where to write device_table_data-<volume>.txt files
"""

import os
import sys

# Mapping from /data/<prefix> to volume name.
# The longest matching prefix wins.
VOLUME_MAP = {
    "/data/upload":       "upload",
    "/data/download":     "download",
    "/data/security":     "security",
    "/data/log":          "log",
    "/data/var/log":      "log",         # legacy path, maps to log too
    "/data/system":       "system_dyn",  # volume name differs from mount point
    "/data/project_datafs": "project_datafs",
}


def parse_users_table(path):
    """Parse Buildroot users_table.txt, yield (username, uid, gid, home)."""
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            fields = line.split()
            if len(fields) < 6:
                continue
            username = fields[0]
            uid = int(fields[1])
            # group name is fields[2], gid is fields[3]
            gid = int(fields[3])
            home = fields[5]
            if home == "-":
                continue
            yield username, uid, gid, home


def home_to_volume(home):
    """Map a home path to a volume name, or None if not under /data."""
    if not home.startswith("/data/"):
        return None
    # Try longest prefix match
    best = None
    best_len = 0
    for prefix, vol in VOLUME_MAP.items():
        if home.startswith(prefix) and len(prefix) > best_len:
            best = vol
            best_len = len(prefix)
    return best


def home_to_volume_relative(home):
    """Return the path of `home` relative to its volume mount point."""
    for prefix in sorted(VOLUME_MAP.keys(), key=len, reverse=True):
        if home.startswith(prefix):
            rel = home[len(prefix):]
            return rel if rel else "/"
    return "/"


def parse_data_dirs(path):
    """Parse data_dirs.txt, yield (volume, path, type, mode, uid, gid)."""
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            fields = line.split()
            if len(fields) < 6:
                continue
            yield fields[0], fields[1], fields[2], fields[3], fields[4], fields[5]


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <common_dir> <output_dir>", file=sys.stderr)
        sys.exit(1)

    common_dir = sys.argv[1]
    output_dir = sys.argv[2]

    users_table_path = os.path.join(common_dir, "users_table.txt")
    data_dirs_path = os.path.join(common_dir, "data_dirs.txt")

    # Collect entries per volume
    # Format: { volume_name: [(path, type, mode, uid, gid), ...] }
    volumes = {}

    # Static directories from data_dirs.txt
    for vol, path, typ, mode, uid, gid in parse_data_dirs(data_dirs_path):
        volumes.setdefault(vol, []).append((path, typ, mode, uid, gid))

    # User home directories from users_table.txt
    for username, uid, gid, home in parse_users_table(users_table_path):
        vol = home_to_volume(home)
        if vol is None:
            continue
        rel = home_to_volume_relative(home)
        # Home directory entry: owned by user, group, mode 750
        volumes.setdefault(vol, []).append((rel, "d", "750", str(uid), str(gid)))

    # Write per-volume device table files
    # User entries override static entries for the same path (fixes the
    # historical UID drift where device_table_data.txt had wrong UIDs).
    os.makedirs(output_dir, exist_ok=True)

    for vol, entries in sorted(volumes.items()):
        outpath = os.path.join(output_dir, f"device_table_data-{vol}.txt")
        # Build a dict keyed by path; later entries (user homes) overwrite
        # earlier entries (static dirs).
        merged = {}
        for path, typ, mode, uid, gid in entries:
            merged[path] = (path, typ, mode, uid, gid)
        with open(outpath, "w") as f:
            f.write(f"# Auto-generated device table for volume: {vol}\n")
            f.write("# Source: users_table.txt + data_dirs.txt\n")
            f.write("# Do not edit manually.\n")
            f.write("#\n")
            f.write("# <name>\t\t\t<type>\t<mode>\t<uid>\t<gid>\t<major>\t<minor>\t<start>\t<inc>\t<count>\n")
            for path in sorted(merged.keys()):
                _, typ, mode, uid, gid = merged[path]
                f.write(f"{path}\t\t\t{typ}\t{mode}\t{uid}\t{gid}\t-\t-\t-\t-\t-\n")
        print(f"  Generated {outpath} ({len(merged)} entries)")

    print(f"Done: {len(volumes)} volume device tables generated.")


if __name__ == "__main__":
    main()
