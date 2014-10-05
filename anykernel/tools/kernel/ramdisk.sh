#!/sbin/sh

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/

echo "Unpacking ramdisk"
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /

echo "Copying modules to ramdisk for KitKat support"
if busybox [ -d ./lib/modules ]; then
    rm -rf /tmp/ramdisk/lib    # Delete all Modules so we have only our modules inside the ramdisk
fi

mkdir /tmp/ramdisk/lib/
#find -name '/system/lib/modules/*.ko' | xargs {} cp {} /tmp/ramdisk/lib/modules/
cp -r /system/lib/modules/* /tmp/ramdisk/lib/modules

echo "Editing ramdisk if needed...";
echo ""

sed -i 's/ro.adb.secure=1/ro.adb.secure=0/' /tmp/ramdisk/default.prop

sed -i 's/ro.secure=1/ro.secure=0/' /tmp/ramdisk/default.prop


rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/

echo "Repacking ramdisk"
find . | cpio -o -H newc | gzip > ../ramdisk-new.cpio.gz
cd /
#rm -rf /tmp/ramdisk

