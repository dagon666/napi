#!/bin/bash

function test_tool
{
	eval "$2" > /dev/null 2> /tmp/tmp_result

	if [[ -s /tmp/tmp_result ]]; then
		echo "[ERROR] $1"
		rm -rf /tmp/tmp_result
		exit
	else
		echo "[OK] $1"
	fi
	
	rm -rf /tmp/tmp_result
}


test_tool "cut" "echo abc 123 efg | cut -d ' ' -f 1"
test_tool "sed" "echo abc 123 efg | sed 's/^[a-z]*//'"
test_tool "head" "echo abc\n123\nefg | head -n 1"
test_tool "awk" "echo abc 123 efg | awk '{ print $1 }'"
test_tool "grep" "echo abc 123 efg | grep -i 'abc'"

