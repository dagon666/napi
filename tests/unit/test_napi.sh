#!/bin/bash

declare -r SHUNIT_TESTS=1

#
# source the code of the original script
#
. ../../napi.sh 2>&1 > /dev/null


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

	g_verbosity=$verbosity
	output=$($printer '' $str)
	lines=$(echo $output | grep "0: $str" | wc -l)
	assertEquals "$printer with verbosity = $verbosity" 1 $lines

	output=$($printer 123 $str)
	lines=$(echo $output | grep "123: $str" | wc -l)
	assertEquals "$printer with verbosity = $verbosity, specified line number" 1 $lines

	g_verbosity=1
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
	g_verbosity=0
	output=$(_warning "warning message" | grep "WARNING" | wc -l)
	assertEquals "warning message format" 0 $output
	g_verbosity=1
}


#
# test error printing routine
#
test_error() {
	local output=$(_error "error message" | grep "ERROR" | wc -l)
	assertEquals "error message format" 1 $output
	g_verbosity=0
	output=$(_error "error message" | grep "ERROR" | wc -l)
	assertEquals "error message format" 1 $output
	g_verbosity=1

}


#
# test msg printing routine
#
test_msg() {
	local output=$(_msg "message" | grep " - message" | wc -l)
	assertEquals "message format" 1 $output
	g_verbosity=0
	output=$(_msg "message" | grep " - message" | wc -l)
	assertEquals "message format" 0 $output
	g_verbosity=1
}


#
# test status printing routine
#
test_status() {
	local output=$(_status 'INFO' "message" | grep "INFO" | wc -l)
	assertEquals "status format" 1 $output
	g_verbosity=0
	output=$(_status 'INFO' "message" | grep "INFO" | wc -l)
	assertEquals "message format" 0 $output
	g_verbosity=1
	
}


#
# test redirection to stderr
#
test_to_stderr() {
	local output=$(echo test | to_stderr 2> /dev/null | wc -l)
	assertEquals "to_stderr output redirection" 1 $output
	g_logfile='file.log'
	output=$(echo test | to_stderr 2> /dev/null | wc -l )
	assertEquals "to_stderr output redirection with logfile" 0 $output
	g_logfile='none'

}


#
# test logfile redirection
#
test_logfile() {
	g_logfile='file.log'
	local e=0
	redirect_to_logfile

	[ -e "$g_logfile" ] && e=1
	
	assertEquals 'log file existence' 1 $e
	redirect_to_stdout
	unlink "$g_logfile"
	g_logfile='none'
}


#
# test case conversion routine
#
test_lcase() {
	local output=$(echo TEST | lcase)
	assertEquals 'lcase upper to lower' 'test' $output
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
# test the language listing routine
#
test_list_languages() {
	local lc=0
	lc=$(list_languages | wc -l)
	assertEquals 'counting list language output' 37 $lc
}


#
# test the language verification routine
#
test_verify_languages() {
	local status=0
	local idx=0
	idx=$(verify_language "PL")
	status=$?

	assertEquals 'verifying polish' $RET_OK $status
	assertNotEquals 'verifying index' 0 $idx

	idx=$(verify_language "ENG")
	status=$?
	assertEquals 'verifying english' $RET_OK $status 
	assertNotEquals 'verifying eng index' 0 $idx 

	idx=$(verify_language "NOT_EXISTING")
	status=$?
	assertEquals 'verifying not existing' $RET_PARAM $status 

	idx=$(verify_language "XXX")
	status=$?
	assertEquals 'verifying not existing' $RET_FAIL $status 
}


#
# test the language normalization routine
#
test_normalize_lang() {
	local lang=''
	lang=$(normalize_language 1)
	assertEquals 'verifying 3 letter code' 'ENG' $lang

	lang=$(normalize_language 1)
	assertEquals 'verifying 2 letter code' 'ENG' $lang

	lang=$(normalize_language 24)
	assertEquals 'verifying 2 letter code' 'PL' $lang
}


#
# test - verify tool presence routine
#
test_verify_tool_presence() {
	local presence=0
	presence=$(verify_tool_presence 'bash')
	assertNotEquals 'verifying bash presence' 0 ${#presence}

	presence=$(verify_tool_presence 'strange_not_existing_tool')
	assertEquals 'verifying bogus tool' 0 ${#presence}
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


#
# verify the configure_cmds routine
#
test_configure_cmds() {
	# linux 
	configure_cmds
	assertEquals 'check md5 for linux' 'md5sum' "$g_cmd_md5"
	assertEquals 'check stat for linux' 'stat -c%s' "$g_cmd_stat"

	g_system[0]="darwin"
	configure_cmds
	assertEquals 'check md5 for darwin' 'md5' "$g_cmd_md5"
	assertEquals 'check stat for darwin' 'stat -f%z' "$g_cmd_stat"

	g_system[0]="other"
	configure_cmds
	assertEquals 'check md5 for unknown' 'md5sum' "$g_cmd_md5"
	assertEquals 'check stat for unknown' 'stat -c%s' "$g_cmd_stat"
}


#
# verify tools verification routine
#
test_verify_tools() {

	declare -a m_miss=( bash=1 not_existing=1 )
	declare -a m_opt=( bash=1 abc=0 xxx=0 ls=0 )
	local status=0

	m_miss=( $(verify_tools ${m_miss[@]}) )
	status=$?
	assertEquals 'mandatory missing' $RET_FAIL $status

	m_opt=( $(verify_tools ${m_opt[@]}) )
	status=$?
	assertEquals 'all optionals' $RET_OK $status


	local v=$(lookup_value 'ls' ${m_opt[@]} )
	assertEquals 'optional found' 1 $v

	local v=$(lookup_value 'abc' ${m_opt[@]} )
	assertEquals 'optional missing' 0 $v
}


#
# check the get extension routine
#
test_get_ext() {

	local ext=''

	ext=$(get_sub_ext 'subrip')
	assertEquals 'checking subrip extension' 'srt' "$ext"
	
	ext=$(get_sub_ext 'mpl2')
	assertEquals 'checking subrip extension' 'txt' "$ext"
}


#
# verify the fps detectors counting routine
#
test_count_fps_detectors() {
	local c=0

	declare -a tmp=( ${g_tools[@]} )

	c=$(count_fps_detectors)
	assertEquals 'default no of fps detectors' 0 $c

	g_tools=( $(modify_value 'mediainfo' 1 ${g_tools[@]}) )
	c=$(count_fps_detectors)
	assertEquals 'no of fps detectors' 1 $c

	g_tools=( ${tmp[@]} )
}


# shunit call
. shunit2
