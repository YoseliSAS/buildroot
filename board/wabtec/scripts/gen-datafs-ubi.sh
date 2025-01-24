#!/bin/sh
# This script creates a basic data filesystem in UBIFS format and then wraps it in a UBI volume

output_dir=$1
host_dir=$output_dir/host
target_dir=$output_dir/target
slash_data_custom=$output_dir/slash-data-custom
images_dir=$output_dir/images

rm -rf $slash_data_custom
mkdir $slash_data_custom
cp -r board/wabtec/common/skeleton_data $slash_data_custom/data
echo "chown -R 0:0 ${slash_data_custom}/data" >> $slash_data_custom/fakeroot.sh
echo "${host_dir}/usr/bin/makedevs -d board/wabtec/common/device_table_data.txt ${slash_data_custom}/data" >> $slash_data_custom/fakeroot.sh

# Generate the UBIFS image
echo "${host_dir}/sbin/mkfs.ubifs -d ${slash_data_custom}/data -e 0x1f000 -c 2048 -m 0x800 -x none -o ${output_dir}/data.ubifs" >> $slash_data_custom/fakeroot.sh

# Run the fakeroot script to create the UBIFS image
chmod a+x $slash_data_custom/fakeroot.sh
cat $slash_data_custom/fakeroot.sh
${host_dir}/bin/fakeroot -- $slash_data_custom/fakeroot.sh

# Set a fixed size for the UBI volume, for example, 128M
fixed_size="128MiB"

# Create UBI config with the fixed volume size
ubinize_cfg=$output_dir/ubinize.cfg
echo "[ubifs]" > $ubinize_cfg
echo "mode=ubi" >> $ubinize_cfg
echo "image=${output_dir}/data.ubifs" >> $ubinize_cfg
echo "vol_id=0" >> $ubinize_cfg
echo "vol_size=$fixed_size" >> $ubinize_cfg
echo "vol_type=dynamic" >> $ubinize_cfg
echo "vol_name=data" >> $ubinize_cfg
echo "vol_flags=autoresize" >> $ubinize_cfg

# Generate the UBI image
${host_dir}/sbin/ubinize -o ${images_dir}/data.ubi -m 0x800 -p 0x20000 -s 2048 $ubinize_cfg
cat $ubinize_cfg

# Clean up
#rm -f ${output_dir}/data.ubifs
#rm -f $ubinize_cfg

