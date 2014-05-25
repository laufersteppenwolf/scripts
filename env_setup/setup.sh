#!/bin/bash
# Usage info

show_help() {
cat << EOL

Usage: . setup.sh [-a|--automated]
Setup the complete build environment including all needed files/packages

Default behavior is to ask before installing anything.

    -h   	| --help			Display this help and exit
    -a   	| --automated			Don't ask for anything and do everything completely automated.
    -j # 	| --java #			Specify the desired Java version
    -e   	| --extended			Install some extended, useful packages
    -s ".."	| --special ".."		Install some user-defined packages. If several packages are desired, please list them within ""
    --no-java					Don't install java at all
    --no-sdk					Don't install the Android SDK
    -c		| --check			Run a check on what's currently installed
    -n		| --needed			Only install packages that are not yet installed (default)
    -f		| --forced			Force (re-)install of all packages

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

function detected() {
	echo ""
	echo "$1 is already installed"
	echo ""
}

function missing() {
	echo ""
	tput setaf 1
	echo "$1 is not installed"
	tput sgr0
	echo ""
}

function getDistro() {
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
}

function check() {
	getDistro
	
	jdk=""
	oracle=""
	openjdk7=""
	openjdk6=""
	oraclejdk6=""
	
	if [[ -a /usr/bin/python2 || -a /usr/bin/python2.7 ]]; then
		detected "Python 2"
		nopython=1
	else
		missing "Python 2"
	fi
	
	if [[ -a /usr/bin/git ]]; then
		detected "Git"
		nogit=1
	else
		missing "Git"
	fi
	
	if [[ -a ~/bin/repo ]]; then
		detected "repo"
		norepo=1
	else
		missing "repo"
	fi
	
	if [[ -a /usr/bin/ccache ]]; then
		detected "Ccache"
		noccache=1
	else
		missing "Ccache"
	fi

	if [[ -d ~/adt-bundle ]]; then
		detected "Android SDK"
		nosdk=1
	else
		missing "Android SDK"
	fi
	
if [[ $distro = Ubuntu ]]; then	
	javaver=$(java -version &> test; cat test | grep version | cut -d ' ' -f3 | sed 's/"//' | cut -d '.' -f1,2 && rm test)
	jdk=$(sudo find /usr/ | grep jdk)										# Find better/faster way
	oracle=$(sudo find /usr/ | grep "oracle/jre/bin")						# Find better/faster way
	if [[ $javaver = "1.7" && $jdk != "" ]]; then
		detected "Java JDK 1.7"
		detect_nojava=3
	fi
	if [[ $javaver = "1.6" && $jdk != "" ]]; then
		if [[ $oracle != "" ]]; then
			detected "Oracle Java JDK 6"
			detect_nojava=1
		fi
		if [[ $oracle = "" ]]; then
			detected "OpenJDK 6"
			detect_nojava=2
		fi
	fi		
fi
if [[ $distro = Arch ]]; then
	openjdk7=$(pacman -Q | grep jdk7-openjdk)
	openjdk6=$(pacman -Q | grep jdk6-openjdk)
	oraclejdk6=$(pacman -Q | grep 'jdk6 ')

	if [[ $openjdk7 != "" ]]; then
		detected "Java JDK 1.7"
		detect_nojava=3
	fi
	if [[ $openjdk6 != "" ]]; then
		detected "OpenJDK 6"
		detect_nojava=2
	fi
	if [[ $oraclejdk6 != "" ]]; then
		detected "Oracle Java JDK 6"
		detect_nojava=1
	fi
fi


	if [[ -a /usr/bin/geany ]]; then
		detected "Geany"
		nogeany=1
	else
		missing "Geany"
	fi

	if [[ -a ~/bin/devhost ]]; then
		detected "Dev-host commandline tool"
		nodevhost=1
	else
		missing "Dev-host commandline tool"
	fi
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
detect_nojava=0
nopython=0
nogit=0
norepo=0
noccache=0
nogeany=0
nodevhost=0
needed=1
forced=0
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
        -c | --check)
			 skip=1
             check
             shift
            ;; 
        -n | --needed)
             needed=1
#             check
             shift
            ;;
        -f | --forced)
             needed=0
             forced=1
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


if [[ $skip = 0 ]]; then		# skip the install if help is set

if [[ $forced != 1 ]]; then
	check
	getDistro
else
	needed=0					# Make sure needed is not set
	tput setaf 1
	echo ""
	echo "***********************************************"
	echo "* Forcing (re-) installation of all packages! *"
	echo "***********************************************"
	echo ""
	tput sgr0
	sleep 3
	getDistro
fi

if [[ $nojava != 1 ]]; then
	if [[ $auto = 0 || $java_set = 0 ]]; then
		echo "Please specify the Java version you would like to have installed by typing the number:"
		echo ""
		echo "1)  Oracle JDK 6"
		echo "2)  OpenJDK 6"
		echo "3)  OpenJDK 7"
		echo ""
		read java_package
	fi
fi

if [[ $distro = Arch && $java_package = 2 ]]; then
	tput setaf 1
	echo "You are attempting to install openJDK 6"
	echo "openJDK6, however, is no longer supported by Arch Linux"
	echo "which is why this script will install Oracle's JDK6 instead!"
	echo ""
	tput sgr0
	java_package=1
	sleep 3
fi

if [[ $java_package = $detect_nojava ]]; then
	if [[ $needed = 1 ]]; then
		nojava=1
	fi
fi

if [[ $debug = 1 ]]; then
	echo "************************"
	echo "java_package is $java_package "
	echo "detect_nojava is $detect_nojava "
	echo "************************"
	sleep 5
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

if [[ $noccache != 1 ]]; then
	note Ccache
	$install ccache
	if [[ $use_ccache = 1 ]]; then
		echo "export USE_CCACHE=1" >> ~/.bashrc
		ccache -M $ccache_size
	fi
else
	skip Ccache
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
		cd	$local_dir
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

if [[ $nogit != 1 ]]; then
	note Git
	$install git
else
	skip Git
fi

if [[ $norepo != 1 ]]; then
	note repo
	$install curl
	if [ ! -d ~/bin ]; then
		mkdir -p ~/bin
	fi
	curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
	chmod a+x ~/bin/repo
else
	skip repo
fi

note "Various build tools"
if [[ $distro = Ubuntu ]]; then
	$install bison build-essential curl flex git-core gnupg gperf libesd0-dev libncurses5-dev libsdl1.2-dev \
			libwxgtk2.8-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev \
			g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-gplv2-dev lib32z1-dev gcc tar htop

else if [[ $distro = Arch ]]; then		 
	$install gvfs gvfs-mtp gvfs-gphoto2 lib32-readline htop wget \
			gnupg flex bison gperf sdl wxgtk squashfs-tools \
			curl ncurses zlib schedtool perl-switch zip unzip libxslt \
			python2-virtualenv gcc-multilib lib32-zlib lib32-ncurses 
	fi
fi

if [[ $nopython != 1 ]]; then
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
else
	skip Python
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
	
	if [[ $nogeany != 1 ]]; then
		note Geany
		$install geany
	else
		skip Geany
	fi
	
	if [[ $nodevhost != 1 ]]; then
		note "Dev-host commandline tool"
		curl https://raw.githubusercontent.com/GermainZ/dev-host-cl/master/devhost.py > ~/bin/devhost
		chmod +x ~/bin/devhost
	else
		skip "Dev-host commandline tool"
	fi


	note "ADB drivers"
	if [[ $distro = Arch ]]; then
		$install android-udev
	else if [[ $distro = Ubuntu ]]; then
			$install android-tools-adb android-tools-fastboot android-tools-fsutils
		fi
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
