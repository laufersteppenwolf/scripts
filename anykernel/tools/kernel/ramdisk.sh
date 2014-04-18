#!/sbin/sh

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /


echo "Editing ramdisk if needed...";
echo ""

sed -i 's/ro.adb.secure=1/ro.adb.secure=0/' /tmp/ramdisk/default.prop

sed -i 's/ro.secure=1/ro.secure=0/' /tmp/ramdisk/default.prop

rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/
find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
cd /
rm -rf /tmp/ramdisk

