#!/bin/bash
# Usage info
show_help() {
cat << EOL

Usage: . build.sh [-h -n -r -c -ncc -d -j #]
Compile CM11 with options to not repo sync, to make clean (or else make installclean),
to automatically upload the build, to not use ccache or to use a custom number of jobs.

Default behavior is to sync and make installclean.

    -h   | --help           display this help and exit
    -n   | --nosync         do not sync
    -r   | --release        upload the build after compilation
    -c   | --clean          make clean instead of installclean
    -ncc | --no_ccache		build without ccache
    -d   | --debug          show some debug info
    -j #                    set a custom number of jobs to build

EOL
}

# Configurable parameters
ccache_dir=$HOME/ccache/CM11
ccache_log=$HOME/ccache/CM11/ccache.log
jobs_sync=30
jobs_build=20
rom=cm
rom_version=11
device_codename="p880"
make_command="bacon"
dropbox_path="$HOME/Dropbox/Android/CM11"


# Reset all variables that might be set
nosync=0
noccache=0
release=0
clean=0
help=0
debug=0
nightly=0
dropbox=0
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
        -j)
			shift
            jobs_build=$1
            shift
            ;;
        -c | --clean)
            clean=1
            shift
            ;;
        -d | --dropbox)
            dropbox=1
            shift
            ;;            
        --debug)
            debug=1
            shift
            ;;
        --device)
			shift
            device_codename=$1
            shift
            ;; 
        --makecommand)
			shift
            make_command=$1
            shift
            ;; 
        --rom)
			shift
            rom=$1
            shift
            ;;
        --romversion)
			shift
            rom_version=$1
            shift
            ;;
        --nightly)
            nightly=1
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

if [[ $help = 0 ]]; then		# skip the build if help is set


if [[ $noccache = 0 ]]; then		# use ccache by default
echo ''
echo '##########'
echo 'setting up ccache'
echo '##########'
echo ''
export USE_CCACHE=1
export CCACHE_DIR=$ccache_dir
export CCACHE_LOGFILE=$ccache_log
fi

echo ''
echo '##########'
echo 'setup environment'
echo '##########'
echo ''
. build/envsetup.sh					# set up the environment

echo ''
echo '##########'
echo 'syncing up'
echo '##########'
echo ''
if [[ $nosync = 1 ]]; then
	echo 'skipping sync'
else
	repo sync -j$jobs_sync -d
fi

# In case we have several devices to compile...
for i in $device_codename
do

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
echo "lunch $device_codename"
echo '##########'
echo ''
lunch $rom""_$device_codename-eng

if [[ $clean = 0 ]]; then		# make installclean only if "make clean" wasn't issued
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

if [[ $debug = 1 ]]; then
	echo "Number of jobs: $jobs_build"
	echo ''
fi

time make -j$jobs_build $make_command	# build with the desired -j value

# resetting ccache
export USE_CCACHE=0

zipname=$(ls out/target/product/$device_codename/$rom-$rom_version-*.zip | sed "s/out\/target\/product\/${device_codename}\///" )
if [[ $debug = 1 ]]; then
	echo '##########'
	echo 'zipname'
	echo '##########'
	echo ''
	echo $zipname
fi

if [[ $dropbox = 1 ]]; then
	echo ''
	echo '##########'
	echo 'copying build to Dropbox'
	echo '##########'
	cp ./out/target/product/$device_codename/$zipname "$dropbox_path/$zipname"
fi

if [[ $release = 1 ]]; then		# upload the compiled build
	echo ''
	echo '##########'
	echo 'uploading build'
	echo '##########'
if [[ $nightly = 1 ]]; then
		scp ./out/target/product/$device_codename/$zipname goo.im:public_html/CM11/$zipname &	# upload via ssh too goo.im servers
	else
		scp ./out/target/product/$device_codename/$zipname goo.im:public_html/CM11/$zipname 	# upload via ssh too goo.im servers
		echo ''
	fi
done
fi
