#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2014 Tomasz Wisniewski aka 
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.ul
# 
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

########################################################################
########################################################################
########################################################################

BIN_dir='/usr/bin'
DEST_dir=''
SHARED_dir='/usr/share'

declare -ar bin_files=( 'subotage.sh' 'napi.sh' )
declare -ar shared_files=( 'libnapi_common.sh' )

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

    # had to get rid of the in-place editing flag to
    # provide more inter system compatibility
	sed "s|${token}=|${replacement}|" "${file}.orig" > "$file"
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
		if ! is_writable "$DEST_dir$d"; then
			echo "katalog [$DEST_dir$d] niedostepny do zapisu - okresl inny"
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
	echo -e "\t --destdir - tymcz. prefiks, do ktorego zostana skopiowane pliki"
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

		"--destdir" )
			shift
			DEST_dir="$1"
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


#
# strip trailing slash from the path declarations
#
strip_trailing_slash() {
    sed 's/\/*$//'
}


BIN_dir=$(echo "$BIN_dir" | strip_trailing_slash)
DEST_dir=$(echo "$DEST_dir" | strip_trailing_slash)
SHARED_dir=$(echo "$SHARED_dir" | strip_trailing_slash)

echo "BIN_dir : [$BIN_dir]"
echo "DEST_dir : [$DEST_dir]"
echo "SHARED_dir : [$SHARED_dir]"

# check dirs
check_dirs

# install shared first
mkdir -p "$DEST_dir$SHARED_dir/napi"
for f in "${shared_files[@]}"; do
	cp -v "$f" "$DEST_dir$SHARED_dir/napi"
done

# install executables now
for f in "${bin_files[@]}"; do
	replace_path "$f" "$SHARED_dir/napi"
	cp -v "$f" "$DEST_dir$BIN_dir"

	# restore original files if we've got backups
	[ -e "${f}.orig" ] && mv "${f}.orig" "$f"
done

