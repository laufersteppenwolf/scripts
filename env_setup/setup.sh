#!/bin/bash
# Usage info

show_help() {
cat << EOL

Usage: . setup.sh [-a|--automated]
Setup the complete build environment including all needed files/packages

Default behavior is to ask before installing anything.

    -h   	| --help           Display this help and exit
    -a   	| --automated      Don't ask for anything and do everything completely automated.
    -j # 	| --java #			Specify the desired Java version
    -e   	| --extended		Install some extended, useful packages
    -s ".."	| --special ".."	Install some user-defined packages. If several packages are desired, please list them within ""
    --no-java					Don't install java at all
    --no-sdk					Don't install the Android SDK

Javaversions to be specified:
	1	Oracle JDK 6 (default)
	2	OpenJDK 6
	3	OpenJDK 7
	
EOL
}

function note() {
	echo ""
	echo "************************"
	echo "*Installing $1 "
	echo "************************"
	echo ""
	sleep 2
}

function skip() {
	echo ""
	echo "************************"
	echo "*Skipping $1 "
	echo "************************"
	echo ""
	sleep 2
}

# Reset all variables that might be set
local_dir=$PWD

auto=0
skip=0
debug=0
java_set=0
extended=0
nojava=0
nosdk=0
special=""

# Tunables

extra=""			# Add here some extra packages to install
use_ccache=1
ccache_size="10G"
make_jobs=4
java_package=1		# Default value


while :
do
    case $1 in
        -h | --help)
             show_help
             skip=1
             break
            ;; 
        -a | --automated)
             auto=1
             shift
            ;;
        -d | --debug)
             debug=1
             shift
            ;;
        -j | --java)
             java_package=$2
             java_set=1
             shift
            ;;
        -e | --extended)
             extended=1
             shift
            ;;
        -s | --special)
             special=$2
             shift
            ;;
        --no-java)
             nojava=1
             shift
            ;;
        --no-sdk)
             nosdk=1
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


if [[ $auto = 0 || $java_set = 0 ]]; then
	echo "Please specify the Java version you would like me to install by typing the number:"
	echo ""
	echo "1)  Oracle JDK 6"
	echo "2)  OpenJDK 6"
	echo "3)  OpenJDK 7"
	echo ""
	read java_package
fi

if [[ $nojava != 1 ]]; then
if [[ $java_package = 1 ]]; then
java="jdk-6u45-linux-x64.bin"
javaversion=45
else if [[ $java_package = 2 ]]; then
java_packages="openjdk-6-jre icedtea6-plugin openjdk-6-jdk"
else if [[ $java_package = 3 ]]; then
java_packages="openjdk-7-jre icedtea-7-plugin openjdk-7-jdk"
fi
fi
fi
fi

if [[ $skip = 0 ]]; then		# skip the install if help is set

# Define the Parameter to append to the command
if [[ $auto = 1 ]]; then
auto_param_ubuntu="-y"
auto_param_arch="--noconfirm"
else
auto_param_ubuntu=""
auto_param_arch=""
fi


# Find the distro and define the correct install command
distro=$(cat /etc/issue | cut -d " " -f1)
if [[ $distro = Ubuntu ]]; then
install="sudo apt-get install $auto_param_ubuntu"
else if [[ $distro = Arch ]]; then
install="sudo pacman -S $auto_param_arch"
else
install="exit"
fi
fi

# Show some debug info
if [[ $debug = 1 ]]; then
echo ""
echo "Distro is $distro "
echo "auto_param_ubuntu is $auto_param_ubuntu "
echo "auto_param_arch is $auto_param_arch "
echo "install is $install "
echo "jobs is $make_jobs "
echo "ccache size is $ccache_size"
note testing 
fi

note Ccache
$install ccache
if [[ $use_ccache = 1 ]]; then
echo "export USE_CCACHE=1" >> ~/.bashrc
ccache -M $ccache_size
fi

if [[ $nojava != 1 ]]; then
if [[ $java_package = 1 ]]; then
	note "Oracle JDK 6"
	if [[ $distro = Ubuntu ]]; then
	mkdir tmp
	cd tmp
	wget http://www.reucon.com/cdn/java/$java
	chmod u+x $java
	./$java
	sudo mkdir -p /opt/Oracle_Java
	sudo cp -a jdk1.6.0_$javaversion/ /opt/Oracle_Java/
	sudo chown -R root:root /opt/Oracle_Java/*
	cd $local_dir
	rm -rf tmp

	sudo update-alternatives --install "/usr/bin/java" "java" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/java" 1
	sudo update-alternatives --install "/usr/bin/javac" "javac" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/javac" 1
	sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/javaws" 1
	sudo update-alternatives --install "/usr/bin/jar" "jar" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/jar" 1 
	sudo update-alternatives --install "/usr/lib/mozilla/plugins/mozilla-javaplugin.so" "mozilla-javaplugin.so" "/opt/Oracle_Java/jdk1.6.0_$javaversion/jre/lib/amd64/libnpjp2.so" 1 

	sudo update-alternatives --set "java" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/java"
	sudo update-alternatives --set "javac" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/javac"
	sudo update-alternatives --set "javaws" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/javaws"
	sudo update-alternatives --set "jar" "/opt/Oracle_Java/jdk1.6.0_$javaversion/bin/jar" 
	sudo update-alternatives --set "mozilla-javaplugin.so" "/opt/Oracle_Java/jdk1.6.0_$javaversion/jre/lib/amd64/libnpjp2.so" 

	else if [[ $distro = Arch ]]; then
	git clone https://github.com/laufersteppenwolf/oracle_java6_archlinux_x64.git tmp
	cd tmp
	sudo pacman -U $auto_param_arch ./jre6-6u45-1-x86_64.pkg.tar.xz
	sudo pacman -U $auto_param_arch ./jdk6-6u45-1-x86_64.pkg.tar.xz
	cd $local_dir
	rm -rf tmp
	echo "export JAVA_HOME=/opt/java6" >> ~/.bashrc
	fi
	fi
	
else if [[ $java_package = 2 ]]; then
	note "OpenJDK 6"
	$install $java_packages

else if [[ $java_package = 3 ]]; then
	note "OpenJDK 7"
	$install $java_packages

fi
fi
fi

else
	skip Java
fi

note GIT
$install git

note repo
$install curl
if [ ! -d ~/bin ]; then
mkdir -p ~/bin
fi
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

note "Various build tools"
if [[ $distro = Ubuntu ]]; then
$install bison build-essential curl flex git-core gnupg gperf libesd0-dev libncurses5-dev libsdl1.2-dev \
		 libwxgtk2.8-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev \
		 g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev gcc tar htop iostat

else if [[ $distro = Arch ]]; then		 
$install gvfs gvfs-mtp gvfs-gphoto2 lib32-readline htop wget \
		 gnupg flex bison gperf sdl wxgtk squashfs-tools \
		 curl ncurses zlib schedtool perl-switch zip unzip libxslt \
		 python2-virtualenv gcc-multilib lib32-zlib lib32-ncurses 
fi
fi

note Python
if [[ $distro = Ubuntu ]]; then
$install python
else if [[ $distro = Arch ]]; then
$install python2
ln -s /usr/bin/python2 ~/bin/python
ln -s /usr/bin/python2-config ~/bin/python-config
# echo 'alias python="python2"' >> ~/.bashrc
fi
fi

if [[ $nosdk != 1 ]]; then
note SDK
mkdir tmp
cd tmp
wget http://dl.google.com/android/adt/22.6.2/adt-bundle-linux-x86_64-20140321.zip
if [ -d ~/adt-bundle ]; then
rm -rf ~/adt-bundle
fi
mkdir ~/adt-bundle
mv adt-bundle-linux-x86_64-20140321.zip ~/adt-bundle/adt.zip
cd ~/adt-bundle
unzip adt.zip
mv -f adt-bundle-linux-x86_64-20140321/* .
rm -rf ./adt-bundle-linux-x86_64-20140321
echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile
echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
rm -rf adt.zip
cd $local_dir
rm -rf tmp

else
	skip SDK
fi

if [[ extended = 1 ]]; then
	note "extended packages"
	
	$install ssh iostat bmon htop
	
	note Geany
	$install geany
	
	note "Dev-host commandline tool"
	curl https://raw.githubusercontent.com/GermainZ/dev-host-cl/master/devhost.py > ~/bin/devhost
	chmod +x ~/bin/devhost

	if [[ $distro = Arch ]]; then
		$install android-udev
	fi
fi

if [[ $special || $extra ]]; then
note "user-defined packages"
	
	if [[ $special ]]; then
		$install $special
	fi
	if [[ $extra ]]; then
		$install $extra
	fi
fi

echo ""
echo "*******************"
echo " All done!"
echo "*******************"
echo ""
echo "For more info about setting up an Android environment"
echo "make sure to check in here:  http://source.android.com/source/initializing.html"
echo ""
fi
