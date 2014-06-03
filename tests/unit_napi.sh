#!/bin/bash

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

declare -r SHUNIT_TESTS=1

#
# path to the test env root
#
declare -r g_assets_path="${1:-/home/vagrant}"


#
# unit test environment root
#
declare -r g_ut_root='unit_test_env'

################################################################################

#
# source the code of the original script
#
. ../napi.sh 2>&1 > /dev/null

################################################################################

#
# tests env setup
#
oneTimeSetUp() {
	# create env
	mkdir -p "$g_assets_path/$g_ut_root"
	
	# the space in the file name is deliberate
	cp -v "$g_assets_path/napi_test_files/av1.dat" "$g_assets_path/$g_ut_root/av1 file.avi"
}


#
# tests env tear down
#
oneTimeTearDown() {
	# clear the env
	rm -rfv "$g_assets_path/$g_ut_root"
}

################################################################################

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

	g_system[0]="linux"
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


#
# test get_fps routine with various fps detectors
#
test_get_fps() {
	local fps=0
	fps=$(get_fps 'doesnt_matter' 'doesnt_matter.avi')
	assertEquals 'get fps without tools' 0 $fps

	declare -a tmp=( ${g_tools[@]} )

	if [ -n "$(builtin type -P mediainfo)" ]; then
		g_tools=( $(modify_value 'mediainfo' 1 ${g_tools[@]}) )
		fps=$(get_fps 'mediainfo' 'doesnt_matter.avi')
		assertNotEquals 'get fps with mediainfo' 0 $fps
	fi

	if [ -n "$(builtin type -P mediainfo)" ]; then
		g_tools=( $(modify_value 'mediainfo' 1 ${g_tools[@]}) )
		fps=$(get_fps 'mediainfo' "$g_assets_path/$g_ut_root/av1 file.avi")
		assertNotEquals "get fps with mediainfo" 0 ${fps:-0}
	fi

	if [ -n "$(builtin type -P mplayer)" ]; then
		g_tools=( $(modify_value 'mplayer' 1 ${g_tools[@]}) )
		fps=$(get_fps 'mplayer' "$g_assets_path/$g_ut_root/av1 file.avi")
		assertNotEquals 'get fps with mplayer' 0 ${fps:-0}
	fi

	if [ -n "$(builtin type -P mplayer2)" ]; then
		g_tools=( $(modify_value 'mplayer2' 1 ${g_tools[@]}) )
		fps=$(get_fps 'mplayer2' "$g_assets_path/$g_ut_root/av1 file.avi")
		assertNotEquals "get fps with mplayer2" 0 ${fps:-0}
	fi

	if [ -n "$(builtin type -P ffmpeg)" ]; then
		g_tools=( $(modify_value 'ffmpeg' 1 ${g_tools[@]}) )
		fps=$(get_fps 'ffmpeg' "$g_assets_path/$g_ut_root/av1 file.avi")
		assertNotEquals 'get fps with ffmpeg' 0 ${fps:-0}
	fi


	g_tools=( ${tmp[@]} )
}


#
# test the argument parsing routine
# 
test_parse_argv() {

	local status=0
	declare -a cp_g_abbrev=( "${g_abbrev[@]}" )
	
	parse_argv -a 2>&1 > /dev/null
	status=$?
	assertEquals "checking for failure without parameter value" $RET_FAIL $status

	parse_argv -a ABBREV 2>&1 > /dev/null
	status=$?
	assertEquals "checking for success (-a)" $RET_OK $status
	assertEquals "checking for abbreviation" "ABBREV" "${g_abbrev[0]}"

	g_abbrev=( ${cp_g_abbrev[@]} )

	parse_argv -b 123 2>&1 > /dev/null
	status=$?
	assertEquals "checking for success (-b)" $RET_OK $status
	assertEquals "checking for size" 123 $g_min_size
	g_min_size=0

	# test complex command
	parse_argv -c \
		-d \
		-s \
		--stats \
		--move \
		-C utf8 \
		-e sub \
		-I other \
		-l log \
		-L EN \
		-u john \
		-p doe \
		-S my_hook.sh \
		-v 3 \
		-f subrip \
		-P ffmpeg \
		-o PREFIX_ \
		--conv-abbrev CONV \
		-F 32 \
		file1.avi file2.avi 2>&1 > /dev/null

	assertEquals 'checking cover flag' 1 $g_cover
	assertEquals 'checking delete_orig flag' 1 $g_delete_orig
	assertEquals 'checking skip flag' 1 $g_skip
	assertEquals 'checking stats flag' 1 $g_stats_print
	assertEquals 'checking copy tool' 'mv' $g_cmd_cp
	assertEquals 'checking charset' 'utf8' $g_charset
	assertEquals 'checking extension' 'sub' $g_default_ext
	assertEquals 'checking id' 'other' ${g_system[2]}
	assertEquals 'checking logfile' 'log' $g_logfile
	assertEquals 'checking lang' 'EN' $g_lang
	assertEquals 'checking user' 'john' ${g_cred[0]}
	assertEquals 'checking passwd' 'doe' ${g_cred[1]}
	assertEquals 'checking hook' 'my_hook.sh' $g_hook
	assertEquals 'checking verbosity' 3 $g_verbosity
	assertEquals 'checking format' 'subrip' $g_sub_format
	assertEquals 'checking fps tool' 'ffmpeg' $g_fps_tool
	assertEquals 'checking prefix' 'PREFIX_' $g_orig_prefix
	assertEquals 'checking forks' 32 ${g_system[1]}
	assertEquals 'checking conv abbreviation' "CONV" "${g_abbrev[1]}"
	assertEquals 'checking paths' 'file1.avi' ${g_paths[0]}
	assertEquals 'checking paths 2' 'file2.avi' ${g_paths[1]}


	# restore default settings
}

# shunit call
. shunit2
