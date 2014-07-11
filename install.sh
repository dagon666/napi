#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

BIN_dir='/usr/bin'
SHARED_dir='/usr/share'

declare -ar bin_files=( 'subotage.sh' 'napi.sh' )
declare -ar shared_files=( 'napi_common.sh' )

#
# replace the common path in given file
#
replace_path() {
	local file="$1"
	local path="$2"

	local token='NAPI_COMMON_PATH'
	local replacement="${token}=\"$path\""

	# that's because busybox sed doesn't support suffixes
	cp "$file" "${file}.orig"
	sed -i "s|${token}=|${replacement}|" "$file"	
}


#
# check if given directory exists and is writable
#
is_writable() {
	local rv=255
	local path="$1"
	[ -d "$path" ] && [ -w "$path" ] && rv=0
	return $rv
}


#
# verify destination dir
#
check_dirs() {
	declare -a dirs=( "$BIN_dir" "$SHARED_dir" )
	local d=''

	for d in "${dirs[@]}"; do
		if ! is_writable "$d"; then
			echo "katalog [$d] niedostepny do zapisu - okresl inny"
			usage
			exit -1
		fi
	done
}


#
# print help
#
usage() {
	echo
	echo "install.sh [<opcje>]"
	echo "opcje:"
	echo
	echo -e "\t --bindir - kat. w ktorym zostana zainst. pliki wykonywalne (dom. $BIN_dir)"
	echo -e "\t --shareddir - kat. w ktorym zostana zainst. biblioteki (dom. $SHARED_dir)"
	echo
}


# print help if when requested explicitly 
[ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && 
        usage &&
        exit -1

while [ $# -gt 0 ]; do
	case "$1" in
		"-h" | "--help" )
			usage
			exit -1
			;;

		"--bindir" )
			shift
			[ -z "$1" ] && 
				echo "BLAD: Podaj katalog do ktorego zainstalowac pliki wykonywalne" &&
				exit -1
			BIN_dir="$1"
			;;

		"--shareddir" )
			shift
			[ -z "$1" ] && 
				echo "BLAD: Podaj katalog do ktorego zainstalowac biblioteki" &&
				exit -1
			SHARED_dir="$1"
			;;
	esac

	shift
done

echo "BIN_dir : [$BIN_dir]"
echo "SHARED_dir : [$SHARED_dir]"

# check dirs
check_dirs 

# install shared first
mkdir -p "$SHARED_dir/napi"
for f in "${shared_files[@]}"; do
	cp -v "$f" "$SHARED_dir/napi"
done

# install executables now
for f in "${bin_files[@]}"; do
	replace_path "$f" "$SHARED_dir/napi"
	cp -v "$f" "$BIN_dir"

	# restore original files if we've got backups
	[ -e "${f}.orig" ] && mv "${f}.orig" "$f"
done

