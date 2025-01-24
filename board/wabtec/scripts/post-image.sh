#!/bin/sh

# This script is executed to add padding to the uImage to align it on
# BR2_TARGET_ROOTFS_JFFS2_EBSIZE.

# Once the padding is done, it calculates crc16 and crc32 checksums for the uImage.

# Display the arguments passed to the script
echo "post-image.sh $@"

# Example: post-image.sh /home/jm/Projects/wabtec/buildroot/output/images /home/jm/Projects/wabtec/buildroot/configs/wabtec_dlcnext_defconfig
# First argument is the output/images directory
images_dir=$1

# output directory must be fouund from the images directory
output_dir=$(dirname $images_dir)

# Next argument is the JFFS options in the form "-e 0x20000 --with-xattr -p -b -n"
#jffs2 options are all the arguments passed to the script after $1
shift
jffs2_opts="$@"

echo "JFFS2 options: $jffs2_opts"

# Get the basedir of the script from the $0 argument
basedir=$(dirname $0)
echo "basedir=$basedir"

m68k-linux-objcopy -O binary ${images_dir}/vmlinux ${images_dir}/image.bin
mkimage -A m68k -O linux -T kernel -C none -a 0x41002000 -e 0x41002000 -n "Linux-54418" -d ${images_dir}/image.bin ${images_dir}/uImage

${basedir}/pad-uimage.sh $images_dir $jffs2_opts
${basedir}/gen-datafs.sh $output_dir $jffs2_opts
${basedir}/gen-datafs-ubi.sh $output_dir $jffs2_opts

# Calculate the crc16 and crc32 checksums for the uImage
# crc16:
# @$(call MESSAGE,"Generating CRC16 checksum files")
# @rm -f $(BINARIES_DIR)/*.crc16
# @rm -f $(BINARIES_DIR)/*.crc32
# @python support/scripts/crc16.py -w $(BINARIES_DIR)/*
# @$(call MESSAGE,"Generating CRC32 checksum files for uImage")
# @support/scripts/mkCrc32.sh $(BINARIES_DIR)

echo "Generating CRC16 checksum files"
rm -f "$images_dir"/*.crc16
rm -f "$images_dir"/*.crc32
python3 ${basedir}/crc16.py -w "${images_dir}/*"
echo "Generating CRC32 checksum files for uImage"
${basedir}/mkCrc32.sh "$images_dir"
