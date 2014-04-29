#!/bin/sh

###### defines ######

local_dir=$PWD
defconfig=cyanogenmod_x3_defconfig
jobs=32

###### defines ######
echo '#############'
echo 'making clean'
echo '#############'
make clean                                                                 # clean the sources
rm -rf out                                                                 # clean the output folder
echo '#############'
echo 'making defconfig'
echo '#############'
make $defconfig
echo '#############'
echo 'making zImage'
echo '#############'
time make -j$jobs
echo '#############'
echo 'copying files to ./out'
echo '#############'
echo ''
mkdir -p out/modules                                                       # make dirs for zImage and modules
cp arch/arm/boot/zImage out/zImage                                         # copy zImage
# Find and copy modules
find -name '*.ko' | xargs -I {} cp {} ./out/modules/
cp -r out/* ~/smb/kernel/out/                                              # copy zImage and modules to a network drive
echo 'done'
echo ''
if [ -d arch/arm/boot/zImage ]; then
echo '#############'
echo 'Making Anykernel zip'
echo '#############'
echo ''
cd ~/smb/kernel/out/                                                       # cd to the network drive
. pack_cwm.sh                                                              # execute the script to make an anykernel updater zip
if [[ $1 = -d ]]; then
cp $zipname ~/Dropbox/Android/kernel/$zipname
echo "Copying $zipname to Dropbox"
fi
cd $local_dir                                                              # cd back to the old dir
echo ''
echo '#############'
echo 'build finished successfully'
echo '#############'
else
echo '#############'
echo 'build failed!'
echo '#############'
fi
