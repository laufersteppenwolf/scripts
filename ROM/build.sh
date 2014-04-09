#!/bin/sh
# Usage info
show_help() {
cat << EOL

Usage: .build.sh [-hnrc]
Compile CM11 with options to not repo sync, to make clean (or else make installclean)
or to automatically upload the build.

Default behavior is to sync and make installclean.

    -h | --help          display this help and exit
    -n | --nosync        do not sync
    -r | --release       upload the build after compilation
    -c | --clean         make clean instead of installclean

EOL
}

# Reset all variables that might be set
nosync=0
noccache=0
release=0
clean=0
help=0
debug=0
zipname=""

while :
do
    case $1 in
        -h | --help)
             show_help
             help=1
             break
            ;;
        -n | --nosync)
            nosync=1
            shift
            ;;
        -ncc | --no_ccache)
            noccache=1
            shift
            ;;
        -r | --release)
            release=1
            shift
            ;;
        -c | --clean)
            clean=1
            shift
            ;;
        -d | --debug)
            debug=1
            shift
            ;; 
        --) # End of all options
            shift
            break
            ;;
        *)  # no more options. Stop while loop
            break
            ;;	
    esac
done

if [[ $help = 0 ]]; then

# Define the future zipname, 'cause if we start the build 23:59 on day 1
# day 1 will be used for the zip, but day 2 would be used for the upload command
zipname=cm-11-$(date -u +%Y%m%d)-UNOFFICIAL-p880.zip

if [[ $debug = 1 ]]; then
	echo '##########'
	echo 'future zipname'
	echo '##########'
	echo ''
	echo $zipname
fi

if [[ $noccache = 0 ]]; then
echo ''
echo '##########'
echo 'setting up ccache'
echo '##########'
echo ''
export USE_CCACHE=1
export CCACHE_DIR=/home/laufersteppenwolf/ccache/CM11
export CCACHE_LOGFILE=/home/laufersteppenwolf/ccache/CM11/ccache.log
fi

echo ''
echo '##########'
echo 'setup environment'
echo '##########'
echo ''
. build/envsetup.sh

echo ''
echo '##########'
echo 'syncing up'
echo '##########'
echo ''
#reset frameworks base to properly sync and apply the patch without errors
cd frameworks/base
git reset --hard HEAD
croot
echo ''
echo '##########'
echo ''
if [[ $nosync = 1 ]]; then
	echo 'skipping sync'
else
	repo sync -j30 -d
fi

echo ''
echo '##########'
echo 'applying double-press power patch'
echo '##########'
echo ''
cp ./WindowManager-Fix-double-press-power-button.patch ./frameworks/base/WindowManager-Fix-double-press-power-button.patch
cd frameworks/base
git apply WindowManager-Fix-double-press-power-button.patch
rm WindowManager-Fix-double-press-power-button.patch
croot

if [[ $clean = 1 ]]; then
	echo ''
	echo '##########'
	echo 'make clean'
	echo '##########'
	echo ''
	make clean
fi

echo ''
echo '##########'
echo 'lunch p880'
echo '##########'
echo ''
lunch cm_p880-eng

if [[ $clean = 0 ]]; then
	echo ''
	echo '##########'
	echo 'make installclean'
	echo '##########'
	echo ''
	make installclean
fi

echo ''
echo '##########'
echo 'build'
echo '##########'
echo ''
time make -j20 bacon

# resetting ccache
export USE_CCACHE=0

if [[ $release = 1 ]]; then
	echo ''
	echo '##########'
	echo 'uploading build'
	echo '##########'
	scp ./out/target/product/p880/$zipname goo.im:public_html/CM11/$zipname
	echo ''
fi
fi
