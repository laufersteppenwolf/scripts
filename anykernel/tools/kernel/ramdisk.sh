#!/sbin/sh

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /


echo "Editing ramdisk if needed...";
echo ""

ramdiskversion=$(find /tmp/ramdisk/init.x3.rc -type f | xargs grep -oh "import init.x3.cpu.rc");

if [ "$ramdiskversion" = 'import init.x3.cpu.rc' ]; then
	echo "Replacing the complete files";
	rm -rf /tmp/ramdisk/init.x3.rc
	rm -rf /tmp/ramdisk/init.x3.cpu.rc
	cp /tmp/init.x3.rc /tmp/ramdisk/init.x3.rc
	chmod 644 /tmp/ramdisk/init.x3.rc
	echo "Files replaced!"
else


	param=$(find /tmp/ramdisk/init.x3.rc -type f | xargs grep -oh "/sys/module/cpu_tegra/parameters/system_mode");

	if [ "$param" = '/sys/module/cpu_tegra/parameters/system_mode' ]; then
		echo "Reverting ASUS CPU parameters";
		sed -i 's/    chown system system \/sys\/module\/cpu_tegra\/parameters\/system_mode/    chown system system \/sys\/module\/cpu_tegra\/parameters\/force_disable_edp/' /tmp/ramdisk/init.x3.rc
		sed -i 's/    chown system system \/sys\/module\/cpu_tegra\/parameters\/pwr_cap_limit_1/    chown system system \/sys\/module\/cpu_tegra\/parameters\/force_policy_max/' /tmp/ramdisk/init.x3.rc
		sed -i 's/    chown system system \/sys\/module\/cpu_tegra\/parameters\/pwr_cap_limit_2/    chown system system \/sys\/module\/cpu_tegra\/parameters\/is_enable_boost_load_shaper/' /tmp/ramdisk/init.x3.rc
		sed -i '/    chown system system \/sys\/module\/cpu_tegra\/parameters\/pwr_cap_limit_3/d' /tmp/ramdisk/init.x3.rc
		sed -i '/    chown system system \/sys\/module\/cpu_tegra\/parameters\/pwr_cap_limit_4/d' /tmp/ramdisk/init.x3.rc
		echo "Done!"
	else
		echo "No ASUS CPU parameters found!";
	fi

	prop=$(find /tmp/ramdisk/init.x3.rc -type f | xargs grep -oh "setprop sys.cpu.mode");

	if [ "$prop" = 'setprop sys.cpu.mode' ]; then
		echo "Deleting ASUS CPU prop";
		sed -i '/# Setup CPU for "balanced" mode/d' /tmp/ramdisk/init.x3.rc
		sed -i '/setprop sys.cpu.mode 1/d' /tmp/ramdisk/init.x3.rc
		echo "Done!"
	else
		echo "No ASUS CPU prop found!";
	fi

fi ###### ramdiskversion ######

sed -i 's/ro.adb.secure=1/ro.adb.secure=0/' /tmp/ramdisk/default.prop

sed -i 's/ro.secure=1/ro.secure=0/' /tmp/ramdisk/default.prop

sed -i 's/write \/proc\/sys\/kernel\/dmesg_restrict 1/write \/proc\/sys\/kernel\/dmesg_restrict 0/' /tmp/ramdisk/init.rc

rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/
find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
cd /
rm -rf /tmp/ramdisk

