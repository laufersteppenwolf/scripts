#!/bin/bash

###### defines ######

local_dir=$PWD

###### defines ######
echo '#############'
echo 'making clean'
echo '#############'
make clean
rm -rf out
echo '#############'
echo 'making defconfig'
echo '#############'
make pxa986_lt02wifi_werewolf_defconfig
echo '#############'
echo 'making zImage'
echo '#############'
time make -j20
echo '#############'
echo 'copying files to ./out'
echo '#############'
echo ''
mkdir out
mkdir out/modules
cp arch/arm/boot/zImage out/zImage
# Find and copy modules
find ./drivers -name '*.ko' | xargs -I {} cp {} ./out/modules/
find ./crypto -name '*.ko' | xargs -I {} cp {} ./out/modules/

#cp drivers/scsi/scsi_wait_scan.ko out/modules/scsi_wait_scan.ko
#cp drivers/usb/serial/baseband_usb_chr.ko out/modules/baseband_usb_chr.ko
#cp crypto/tcrypt.ko out/modules/tcrypt.ko
#cp drivers/net/usb/raw_ip_net.ko out/modules/raw_ip_net.ko

cp -r out/* ~/tab3/anykernel_packing/
echo 'done'
echo ''
if [ -a arch/arm/boot/zImage ]; then
echo '#############'
echo 'Making Anykernel zip'
echo '#############'
echo ''
cd ~/tab3/anykernel_packing
. pack_cwm.sh
if [[ $1 = -d ]]; then
cp ~/tab3/out/"$zipname" ~/Dropbox/Android/SGT3/stock_kk/"$zipname"
echo "Copying $zipname to Dropbox"
fi
cd $local_dir
echo ''
echo '#############'
echo 'build finished successfully'
echo '#############'
else
echo '#############'
echo 'build failed!'
echo '#############'
fi
