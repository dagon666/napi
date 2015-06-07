#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

################################################################################

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

################################################################################

#
# source common unit lib
#
. lib/unit_common.sh

#
# source the code of the original script
#
. "$g_install_path/napi/libnapi_common.sh" 2>&1 > /dev/null

################################################################################

#
# tests env setup
#
oneTimeSetUp() {
	_prepare_env
}


#
# tests env tear down
#
oneTimeTearDown() {
	_purge_env
}

################################################################################

test_count_lines() {
	local result=0;
	result=$(echo -e "line1\nline2\nline3" | count_lines)
	assertEquals "checking count_lines output" 3 "$result"
}


test_lcase() {
	local result=0;
	result=$(echo -e "UPPER_CASE_STR" | lcase)
	assertEquals "checking lcase output" "upper_case_str" "$result"
}


test_strip_newline() {
	local result=0;
	result=$(echo -e "line1\r\nline2" | strip_newline | count_lines)
	assertEquals "checking strip_newline output" 0 "$result"
}


#
# test extension extraction/strip routine
#
test_get_ext() {
    local fn='file with spaces.abc.txt'
    local ext=$(get_ext "$fn")
    local file=$(strip_ext "$fn")

    assertEquals 'verify extension' 'txt' "$ext"
    assertEquals 'verify filename' 'file with spaces.abc' "$file"
}


#
# test array of key & values, value extraction routine
#
test_get_values() {
    local fn='key=value'
    local key=$(get_key "$fn")
    local value=$(get_value "$fn")

    assertEquals 'verify key' 'key' "$key"
    assertEquals 'verify value' 'value' "$value"
}


#
# test array of key & values, lookup routines
#
test_lookup_values() {
    declare -a arr=( key1=value1 key2=value2 a=b x=123 )
    local v=''
    local s=0

    v=$(lookup_value 'x' "${arr[*]}" )
    assertEquals 'looking up value - array decayed into string' 123 $v
    
    v=$(lookup_value 'x' ${arr[@]} )
    assertEquals 'looking up value - array' 123 $v

    v=$(lookup_value 'not_existing' ${arr[@]} )
    s=$?
    assertEquals 'return value' $RET_FAIL $s
    
    v=$(lookup_value 'not existing' ${arr[@]} )
    s=$?
    assertEquals 'return value' $RET_FAIL $s
}


#
# test array lookup index routine for given value
#
test_lookup_keys() {
    declare -a arr=( value1 value2 a b x 123 )
    local v=''
    local s=0

    v=$(lookup_key '123' ${arr[@]} )
    assertEquals 'looking up key - array' 5 $v

    v=$(lookup_key 'not_existing' ${arr[@]} )
    s=$?
    assertEquals 'return value' $RET_FAIL $s
    
    v=$(lookup_key 'not existing' ${arr[@]} )
    s=$?
    assertEquals 'return value' $RET_FAIL $s
}


#
# test array of key & values, value modification routine
#
test_modify_value() {
    declare -a arr=( key1=0 key2=1 key3=abc )
    local value=''

    arr=( $(modify_value 'key1' 123 ${arr[@]}) )
    value=$(lookup_value 'key1' ${arr[@]})
    assertEquals 'modified value for key1' 123 $value

    arr=( $(modify_value 'key4' 444 ${arr[@]}) )
    value=$(lookup_value 'key4' ${arr[@]})
    assertEquals 'modified value for key4' 444 $value
}


#
# test status retrieving function
#
test_get_http_status() {
    local status=0
    status=$(echo "HTTP/1.1 302 Moved Temporarily" | get_http_status | cut -d ' ' -f 2)
    assertEquals 'checking http status' 302 $status
}


#
# test the generic blit function
#
test_blit() {
	g_output[$___FORK]=0
	g_output[$___CNT]=8
	local output=''
	output=$(_blit "some message" | grep "00:0008 some message" | wc -l)
	assertEquals "testing blit function and output format" 1 "$output"

	_blit "abc" > /dev/null

	assertEquals "checking the fork id status" 0 ${g_output[$___FORK]}
	assertEquals "checking the msg cnt" 9 ${g_output[$___CNT]}
}


#
# general function to test printing routines
#
_test_printers() {
    local printer="$1"
    local verbosity=$2
    local rv=0
    local str='empty line variable'
    local output=$($printer '' $str)
    rv=$?
    assertEquals "$printer return value - always success" $RET_OK $rv

    local lines=$(echo $output | grep "0: $str" | wc -l)
    assertEquals "$printer with default verbosity" 0 $lines

    g_output[$___VERBOSITY]=$verbosity
    output=$($printer '' $str)
    lines=$(echo $output | grep "0: $str" | wc -l)
    assertEquals "$printer with verbosity = $verbosity" 1 $lines

    output=$($printer 123 $str)
    lines=$(echo $output | grep "123: $str" | wc -l)
    assertEquals "$printer with verbosity = $verbosity, specified line number" 1 $lines

    g_output[$___VERBOSITY]=1
}


#
# test debug printing routine
#
test_debug() {
    _test_printers '_debug' 3
}


#
# test into printing routine
#
test_info() {
    _test_printers '_info' 2
}


#
# test warning printing routine
#
test_warning() {
    local output=$(_warning "warning message" | grep "WARNING" | wc -l)
    assertEquals "warning message format" 1 $output
    g_output[$___VERBOSITY]=0
    output=$(_warning "warning message" | grep "WARNING" | wc -l)
    assertEquals "warning message format" 0 $output
    g_output[$___VERBOSITY]=1
}


#
# test error printing routine
#
test_error() {
    local output=$(_error "error message" 2>&1 | grep "ERROR" | wc -l)
    assertEquals "error message format 1" 1 $output
    g_output[$___VERBOSITY]=0

    output=$(_error "error message" 2>&1 | grep "ERROR" | wc -l)
    assertEquals "error message format 2" 1 $output
    g_output[$___VERBOSITY]=1

}


#
# test msg printing routine
#
test_msg() {
    local output=$(_msg "message" | grep " - message" | wc -l)
    assertEquals "message format" 1 $output
    g_output[$___VERBOSITY]=0
    output=$(_msg "message" | grep " - message" | wc -l)
    assertEquals "message format" 0 $output
    g_output[$___VERBOSITY]=1
}


#
# test status printing routine
#
test_status() {
    local output=$(_status 'INFO' "message" | grep "INFO" | wc -l)
    assertEquals "status format" 1 $output
    g_output[$___VERBOSITY]=0
    output=$(_status 'INFO' "message" | grep "INFO" | wc -l)
    assertEquals "message format" 0 $output
    g_output[$___VERBOSITY]=1
}


#
# test redirection to stderr
#
test_to_stderr() {

    # should go to stderr leaving stdout clean
    local output=$(echo test | to_stderr 2>&1 | wc -l)
    assertEquals "to_stderr output redirection" 1 $output

    # should go to stdout leaving stderr clean
    g_output[$___LOG]='file.log'
    output=$(echo test | to_stderr | wc -l )
    assertEquals "to_stderr output redirection with logfile" 1 $output

    g_output[$___LOG]='none'

}


#
# test logfile redirection
#
test_logfile() {
    g_output[$___LOG]="$g_assets_path/$g_ut_root/logfile.txt"
    local e=0
    redirect_to_logfile

    [ -e "${g_output[$___LOG]}" ] && e=1
    
    assertEquals 'log file existence' 1 $e
    redirect_to_stdout

    unlink "${g_output[$___LOG]}"
    g_output[$___LOG]='none'
}


#
# test float operations
#
test_floats() {
	local status=0

	float_lt "2.0" "3.0"
	status=$?
	assertEquals "lt 1" 0 "$status"

	float_lt "3.0" "3.0"
	status=$?
	assertNotEquals "lt 2" 0 "$status"

	float_le "3.0" "3.0"
	status=$?
	assertEquals "le 1" 0 "$status"

	float_le "3.1" "3.0"
	status=$?
	assertNotEquals "le 2" 0 "$status"

	float_ge "3.0" "3.0"
	status=$?
	assertEquals "ge 1" 0 "$status"

	float_ge "4.0" "3.0"
	status=$?
	assertEquals "ge 2" 0 "$status"

	float_ge "2.0" "3.0"
	status=$?
	assertNotEquals "ge 2" 0 "$status"

	float_gt "3.0" "3.0"
	status=$?
	assertNotEquals "gt 1" 0 "$status"

	float_gt "4.0" "3.0"
	status=$?
	assertEquals "gt 2" 0 "$status"

	float_eq "4.0" "3.0"
	status=$?
	assertNotEquals "eq 1" 0 "$status"

	float_eq "3.0" "3.0"
	status=$?
	assertEquals "eq 1" 0 "$status"
}


#
# test - verify tool presence routine
#
test_verify_tool_presence() {
    local presence=0
    verify_tool_presence 'bash'
	presence=$?
    assertEquals 'verifying bash presence' 0 $presence

	verify_tool_presence 'strange_not_existing_tool'
    presence=$?
    assertNotEquals 'verifying bogus tool' 0 $presence
}


#
# test - verify tool presence routine
#
test_verify_function_presence() {
    local presence=0
    verify_function_presence 'not_existing_function'
	presence=$?
    assertEquals 'verifying not_existing_function presence' $RET_UNAV "$presence"

    verify_function_presence 'test_verify_function_presence'
    presence=$?
    assertEquals 'verifying existing function' $RET_OK "$presence"
}


#
# test system specific functions
#
test_system_tools() {
    local system=$(uname | tr '[A-Z]' '[a-z]')
    local cores=$(lscpu | grep "^CPU(s)" | rev | cut -d ' ' -f 1)

    local ds=$(get_system)
    local dc=$(get_cores)

    assertEquals 'check the system detection routine' $system $ds
    assertEquals 'check the system core counting routine' $cores $dc
}


# shunit call
. shunit2
