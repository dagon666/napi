#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab


########################################################################
########################################################################
########################################################################

#  Copyright (C) 2017 Tomasz Wisniewski aka
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


test_tool() {
	eval "$2" > /tmp/tmp_result 2> /tmp/tmp_err

	if [[ -s /tmp/tmp_err ]]; then
		echo "[ERROR] $1"
		cat /tmp/tmp_err
	elif [[ -s /tmp/tmp_result ]]; then
		echo "[OK] $1"
	else
		echo "[ERROR] $1: Unexpected result"
	fi

	rm -rf /tmp/err
	rm -rf /tmp/tmp_result
}

test_local_array() {
	declare -a a=( 1 2 3 4 5 )
	local i=0

	for i in $(seq 0 4); do
		echo $i >> /tmp/test.la
	done

	if [[ $(wc -l /tmp/test.la | cut -d ' ' -f 1) -eq 5 ]]; then
		echo "[OK] local arrays"
	else
		echo "[ERROR] Your shell has problems with local arrays"
	fi
	rm /tmp/test.la
}


test_tool "cut" "echo abc 123 efg | cut -d ' ' -f 1"
test_tool "sed" "echo abc 123 efg | sed 's/^[a-z]*//'"
test_tool "head" "echo abc\n123\nefg | head -n 1"
test_tool "awk" "echo abc 123 efg | awk '{ print $1 }'"
test_tool "grep" "echo abc 123 efg | grep -i 'abc'"
test_tool "tr" "echo abc 123 efg | tr 'abc' 'xxx' | grep -i 'xxx'"
test_tool "printf" "printf '%s' abcdef | grep -i 'abc'"
test_tool "wget" "wget --help | grep -i 'wget'"
test_tool "find" "mkdir -p /tmp/test/xxx && find /tmp/test -type d -name xxx | grep -i 'xxx' ; rm -rf /tmp/test"
test_tool "seq" "seq 32 64 | grep -i 50"
test_tool "dd" "dd if=/dev/urandom count=32 bs=1k of=/tmp/test.dd 2> /dev/null && stat /tmp/test.dd && rm /tmp/test.dd"
test_tool "iconv" "echo x | iconv"
test_tool "mktemp" "mktemp -t tmp.XXXXXXXX"
test_tool "file" "file /bin/bash"

# other
test_local_array
