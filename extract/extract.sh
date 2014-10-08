#!/bin/bash
#
# Use the appropriate extract command for the archive

debug=0


for file in $@
do

override=""
extension=""

override=$(echo ${file} | grep .tar.gz)

if [[ ${debug} != 0 ]]; then
	echo "File is  ${file}"
	echo "Override is  ${override}"
fi

if [[ ${override} != "" ]]; then			# Override for special cases
	extension="tar.gz"
fi

if [[ ${extension} = "" ]]; then						# Allow overrides
	extension=$(echo ${file} | awk -F . '{print $NF}')
fi


# Actual extracting commands...
case ${extension} in
	"tar.gz")
		echo "Extracting .${extension} file..."
		tar -xzf ${file}
		echo "Done!"
		;;
	"gz")
		echo "Extracting .${extension} file..."
		gunzip ${file}
		echo "Done!"
		;;
	"tar")
		echo "Extracting .${extension} file..."
		tar -xf ${file}
		echo "Done!"
		;;
	"bz2")
		echo "Extracting .${extension} file..."
		bunzip2 ${file}
		echo "Done!"
		;;
	"zip")
		echo "Extracting .${extension} file..."
		unzip ${file}
		echo "Done!"
		;;
    *)  # no more options, archive unknown
        echo "Unknown archive format   ${extension}"
        echo "Aborting.."
        ;;	
esac

done
