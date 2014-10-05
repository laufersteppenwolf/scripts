#!/sbin/sh
/tmp/mkbootimg --kernel /tmp/zImage --ramdisk /tmp/ramdisk-new.cpio.gz --base 10000000 --pagesize 2048 --ramdiskaddr 01000000 -o /tmp/newboot.img
