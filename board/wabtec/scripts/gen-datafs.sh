#!/bin/sh
# This script creates a basic data filesystem using a dedicated skeleton
# The skeleton is in board/wabtec/common/skeleton_data

output_dir=$1
shift
jffs2_opts=$@

host_dir=$output_dir/host
target_dir=$output_dir/target
slash_data_custom=$output_dir/slash-data-custom
images_dir=$output_dir/images

#remove the string --with-xattr from the jffs2_opts
jffs2_sumtool_opts=$(echo $jffs2_opts | sed 's/--with-xattr//')
#remove the -s 0x???? from the jffs2_opts
jffs2_sumtool_opts=$(echo $jffs2_sumtool_opts | sed 's/-s 0x[0-9]*//')
echo "jffs2_sumtool_opts=$jffs2_sumtool_opts"

rm -rf $slash_data_custom
mkdir $slash_data_custom
cp -r board/wabtec/common/skeleton_data $slash_data_custom/data
echo "chown -R 0:0 ${slash_data_custom}/data" >> $slash_data_custom/fakeroot.sh
echo "${host_dir}/usr/bin/makedevs -d board/wabtec/common/device_table_data.txt ${slash_data_custom}/data" >> $slash_data_custom/fakeroot.sh
echo "${host_dir}/sbin/mkfs.jffs2 ${jffs2_opts} -d ${slash_data_custom}/data -o ${output_dir}/data.jffs2.nosummary">> $slash_data_custom/fakeroot.sh
echo "${host_dir}/sbin/sumtool ${jffs2_sumtool_opts} -i ${output_dir}/data.jffs2.nosummary -o ${images_dir}/data.jffs2" >> $slash_data_custom/fakeroot.sh
echo "rm -f ${output_dir}/data.jffs2.nosummary" >> $slash_data_custom/fakeroot.sh
cat $slash_data_custom/fakeroot.sh
chmod a+x $slash_data_custom/fakeroot.sh
${host_dir}/bin/fakeroot -- $slash_data_custom/fakeroot.sh
