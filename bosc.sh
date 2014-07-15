#!/bin/bash

#  Copyright (C) 
# 2014 - Tomasz Wisniewski dagon666
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


#
# @brief performs a 64bit number correction stored in g_hi and g_lo global vars
#
os_hash_correct_64bit() {
	local pow32=$(( 1 << 32 ))

	while [ "$g_lo" -ge $pow32 ]; do
		g_lo=$(( g_lo - pow32 ))
		g_hi=$(( g_hi + 1 ))
	done
	while [ "$g_hi" -ge $pow32 ]; do
		g_hi=$(( g_hi - pow32 ))
	done
}


#
# @brief hashes a 64k file segment
#
os_hash_part() {
	
	local file="$1"
	local curr=0
	local dsize=$((8192*8))

	local bytes_at_once=2048
	local groups=$(( (bytes_at_once / 8) - 1 ))
	local k=0
	local i=0
	local offset=0
	declare -a num=()

	while [ "$curr" -lt "$dsize" ]; do
		num=( $(od -t u1 -An -N "$bytes_at_once" -w$bytes_at_once -j "$curr" "$file") )

		for k in $(seq 0 $groups); do

			offset=$(( k * 8 ))

			g_lo=$(( g_lo + \
				num[$(( offset + 0 ))] + \
				(num[$(( offset + 1 ))] << 8) + \
				(num[$(( offset + 2 ))] << 16) + \
				(num[$(( offset + 3 ))] << 24) ))

			g_hi=$(( g_hi + \
				num[$(( offset + 4 ))] + \
				(num[$(( offset + 5 ))] << 8) + \
				(num[$(( offset + 6 ))] << 16) + \
				(num[$(( offset + 7 ))] << 24) ))

			os_hash_correct_64bit
		done

		curr=$(( curr + bytes_at_once ))
	done
}


#
# @brief calculates a hash of a given file
#
os_hash_file() {
	g_lo=0
	g_hi=0

	local file="$1"
	local size=$(stat -c%s "$file")
	local offset=$(( size - 65536 ))

	local part1=$(mktemp part1.XXXXXXXX)
	local part2=$(mktemp part2.XXXXXXXX)

	dd if="$file" bs=8192 count=8 of="$part1" 2> /dev/null
	dd if="$file" skip="$offset" bs=1 of="$part2" 2> /dev/null

	os_hash_part "$part1"
	os_hash_part "$part2"

	g_lo=$(( g_lo + size ))
	os_hash_correct_64bit

	unlink "$part1"
	unlink "$part2"

	printf "%08x%08x\n" $g_hi $g_lo
}

os_hash_file "breakdance.avi"
echo "8e245d9679d31e12 <- should be" 

os_hash_file "dummy.bin"
echo "61f7751fc2a72bfb <- should be" 

