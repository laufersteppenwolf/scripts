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
release=0
clean=0
help=0

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
        -r | --release)
            release=1
            shift
            ;;
        -c | --clean)
            clean=1
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

echo '##########'
echo 'syncing up'
echo '##########'
#reset frameworks base to properly sync and apply the patch without errors
cd frameworks/base
git reset --hard HEAD
cd  ~/CM11
echo '##########'

if [[ $nosync = 1 ]]; then
echo 'skipping sync'
else
repo sync -j20 -d
fi

echo '##########'
echo 'applying double-press power patch'
echo '##########'
cp ./WindowManager-Fix-double-press-power-button.patch ./frameworks/base/WindowManager-Fix-double-press-power-button.patch
cd frameworks/base
git apply WindowManager-Fix-double-press-power-button.patch
cd  ~/CM11
echo '##########'
echo 'setup environment'
echo '##########'
. build/envsetup.sh

if [[ $clean = 1 ]]; then
echo '##########'
echo 'make clean'
echo '##########'
make clean
fi

echo '##########'
echo 'lunch p880'
echo '##########'
lunch cm_p880-eng

if [[ $clean = 0 ]]; then
echo '##########'
echo 'make installclean'
echo '##########'
make installclean
fi
echo '##########'
echo 'build'
echo '##########'
time make -j32 bacon

if [[ $release = 1 ]]; then
	scp ~/CM11/out/target/product/p880/cm-11-$(date -u +%Y%m%d)-UNOFFICIAL-p880.zip goo.im:public_html/CM11/cm-11-$(date -u +%Y%m%d)-UNOFFICIAL-p880.zip
fi
fi
