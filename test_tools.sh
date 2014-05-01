#!/bin/bash

function test_tool
{
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


test_tool "cut" "echo abc 123 efg | cut -d ' ' -f 1"
test_tool "sed" "echo abc 123 efg | sed 's/^[a-z]*//'"
test_tool "head" "echo abc\n123\nefg | head -n 1"
test_tool "awk" "echo abc 123 efg | awk '{ print $1 }'"
test_tool "grep" "echo abc 123 efg | grep -i 'abc'"
test_tool "tr" "echo abc 123 efg | tr 'abc' 'xxx' | grep -i 'xxx'"
test_tool "printf" "printf '%s' abcdef | grep -i 'abc'"
test_tool "wget" "wget --help | grep -i 'wget'"
test_tool "find" "mkdir -p /tmp/test/xxx && find /tmp/test -type d -name xxx | grep -i 'xxx' ; rm -rf /tmp/test"
test_tool "dd" "dd status=none if=/dev/urandom count=32"
test_tool "seq" "seq 32 64 | grep -i 50"
test_tool "iconv" "echo x | iconv"
