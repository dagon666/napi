#!/bin/bash

BIN_dir='/usr/bin'
SHARED_dir='/usr/share/napi'

#
# replace the common path in given file
#
replace_path() {
	declare -a files=( 'napi.sh' 'subotage.sh' )
	declare -a files=( 'napi.sh' )
	local token='NAPI_COMMON_PATH'

	local file="$1"
	local path="$2"
	local f=''
	local replacement="${token}=\"$path\""

	for f in "${files[@]}"; do
		sed -i~ "s|${token}=|${replacement}|" "$file"
	done
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
# print help
#
usage() {

	echo "install.sh [<opcje>]"
	echo
	echo "opcje:"
	echo
	echo -e "\t --bindir - kat. w ktorym zostana zainst. pliki wykonywalne (dom. $BIN_dir)"
	echo -e "\t --shareddir - kat. w ktorym zostana zainst. biblioteki (dom. $SHARED_dir)"
	echo
}


# print help if no args or when requested explicitly 
[ $# -lt 1 ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] && 
        usage &&
        exit -1



# replace_path "subotage.sh" "/tmp"

