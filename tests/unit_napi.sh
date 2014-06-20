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
shift


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
	origPATH="$PATH"
    mkdir -p "$g_assets_path/$g_ut_root"
    mkdir -p "$g_assets_path/$g_ut_root/bin"
    mkdir -p "$g_assets_path/$g_ut_root/sub dir"

	export PATH="$g_assets_path/$g_ut_root/bin:$PATH"
    
    # the space in the file name is deliberate
    cp -v "$g_assets_path/napi_test_files/av1.dat" "$g_assets_path/$g_ut_root/av1 file.avi"
    cp -v "$g_assets_path/napi_test_files/av2.dat" "$g_assets_path/$g_ut_root/av2 file.avi"
    cp -v "$g_assets_path/napi_test_files/av1.dat" "$g_assets_path/$g_ut_root/sub dir/av3 file.avi"
}


#
# tests env tear down
#
oneTimeTearDown() {
    # clear the env
    rm -rfv "$g_assets_path/$g_ut_root"

	# restore original PATH
	export PATH="$origPATH"
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
# test the generic blit function
#
test_blit() {
	g_system[3]=0
	g_system[4]=8
	local output=''
	output=$(_blit "some message" | grep "00:0008 some message" | wc -l)
	assertEquals "testing blit function and output format" 1 "$output"

	_blit "abc" > /dev/null

	assertEquals "checking the fork id status" 0 ${g_system[3]}
	assertEquals "checking the msg cnt" 9 ${g_system[4]}
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
    g_logfile="$g_assets_path/$g_ut_root/logfile.txt"
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
    verify_tool_presence 'bash'
	presence=$?
    assertEquals 'verifying bash presence' 0 $presence

	verify_tool_presence 'strange_not_existing_tool'
    presence=$?
    assertNotEquals 'verifying bogus tool' 0 $presence
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

	# let's prepare wget mock
    ln -sf "/vagrant/tests/mocks/wget_help" "$g_assets_path/$g_ut_root/bin/wget"
	export SUPPORT_S=0
	export SUPPORT_POST=0

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

	# checking wget capabilities detection
    g_system[0]="linux"
	configure_cmds
	assertEquals "0 wget check for lack of -S" 'wget -q -O' "${g_cmd_wget[0]}"
	assertEquals "0 wget no post support" 0 ${g_cmd_wget[1]}

	export SUPPORT_S=0
	export SUPPORT_POST=1
	configure_cmds
	assertEquals "1 wget check for lack of -S" 'wget -q -O' "${g_cmd_wget[0]}"
	assertEquals "1 wget post support" 1 ${g_cmd_wget[1]}

	export SUPPORT_S=1
	export SUPPORT_POST=0
	configure_cmds
	assertEquals "2 wget check for -S" 'wget -q -S -O' "${g_cmd_wget[0]}"
	assertEquals "2 wget no post support" 0 ${g_cmd_wget[1]}

	export SUPPORT_S=1
	export SUPPORT_POST=1
	configure_cmds
	assertEquals "3 wget check for lack of -S" 'wget -q -S -O' "${g_cmd_wget[0]}"
	assertEquals "3 wget no post support" 1 ${g_cmd_wget[1]}
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
test_get_sub_ext() {

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
        assertNotEquals 'get fps with mediainfo - bogus file' 0 "$fps"
    fi

    if [ -n "$(builtin type -P mediainfo)" ]; then
        g_tools=( $(modify_value 'mediainfo' 1 ${g_tools[@]}) )
        fps=$(get_fps 'mediainfo' "$g_assets_path/$g_ut_root/av1 file.avi")
        assertNotEquals "get fps with mediainfo" 0 "${fps:-0}"
    fi

    if [ -n "$(builtin type -P mplayer)" ]; then
        g_tools=( $(modify_value 'mplayer' 1 ${g_tools[@]}) )
        fps=$(get_fps 'mplayer' "$g_assets_path/$g_ut_root/av1 file.avi")
        assertNotEquals 'get fps with mplayer' 0 "${fps:-0}"
    fi

    if [ -n "$(builtin type -P mplayer2)" ]; then
        g_tools=( $(modify_value 'mplayer2' 1 ${g_tools[@]}) )
        fps=$(get_fps 'mplayer2' "$g_assets_path/$g_ut_root/av1 file.avi")
        assertNotEquals "get fps with mplayer2" 0 "${fps:-0}"
    fi

    if [ -n "$(builtin type -P ffmpeg)" ]; then
        g_tools=( $(modify_value 'ffmpeg' 1 ${g_tools[@]}) )
        fps=$(get_fps 'ffmpeg' "$g_assets_path/$g_ut_root/av1 file.avi")
        assertNotEquals 'get fps with ffmpeg' 0 "${fps:-0}"
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

    # save original settings
    cp_g_cover=$g_cover
    cp_g_nfo=$g_nfo
    cp_g_delete_orig=$g_delete_orig
    cp_g_skip=$g_skip
    cp_g_stats_print=$g_stats_print
    cp_g_cmd_cp=$g_cmd_cp
    cp_g_charset=$g_charset
    cp_g_default_ext=$g_default_ext
    cp_g_logfile=$g_logfile
    cp_g_lang=$g_lang
    cp_g_hook=$g_hook
    cp_g_verbosity=$g_verbosity
    cp_g_sub_format=$g_sub_format
    cp_g_fps_tool=$g_fps_tool
    cp_g_orig_prefix=$g_orig_prefix

    cp_g_system=( ${g_system[@]} )
    cp_g_cred=( ${g_cred[@]} )
    cp_g_abbrev=( ${g_abbrev[@]} )

    # test complex command
    parse_argv -c \
        -n \
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
    assertEquals 'checking cover flag' 1 $g_nfo
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
    g_cover=$cp_g_cover
    g_nfo=$cp_g_nfo
    g_delete_orig=$cp_g_delete_orig
    g_skip=$cp_g_skip
    g_stats_print=$cp_g_stats_print
    g_cmd_cp=$cp_g_cmd_cp
    g_charset=$cp_g_charset
    g_default_ext=$cp_g_default_ext
    g_logfile=$cp_g_logfile
    g_lang=$cp_g_lang
    g_hook=$cp_g_hook
    g_verbosity=$cp_g_verbosity
    g_sub_format=$cp_g_sub_format
    g_fps_tool=$cp_g_fps_tool
    g_orig_prefix=$cp_g_orig_prefix

    g_system=( ${cp_g_system[@]} )
    g_cred=( ${cp_g_cred[@]} )
    g_abbrev=( ${cp_g_abbrev[@]} )
    g_paths=(  )
}


#
# test verify_credentials routine
#
test_verify_credentials() {
    local status=0

    verify_credentials '' '' 2>&1 > /dev/null
    status=$?
    assertEquals 'success on lack of parameters' $RET_OK $status

    verify_credentials 'some user' '' 2>&1 > /dev/null
    status=$?
    assertEquals 'failure on lack of password' $RET_PARAM $status

    verify_credentials '' 'some password' 2>&1 > /dev/null
    status=$?
    assertEquals 'failure on lack of password' $RET_PARAM $status

    verify_credentials 'some user' 'some password' 2>&1 > /dev/null
    status=$?
    assertEquals 'success when both parameters provided' $RET_OK $status
}


#
# test encoding verification routine
#
test_verify_encoding() {
    local cp_path="$PATH"
    local status=0

    verify_encoding 'default'
    status=$?
    assertEquals 'default encoding' $RET_OK $status

    verify_encoding 'utf8'
    status=$?
    assertEquals 'utf8 encoding' $RET_OK $status

    verify_encoding 'BOGUS'
    status=$?
    assertNotEquals 'bogus encoding' $RET_OK $status

    PATH=/bin
    verify_encoding 'utf8'
    status=$?
    PATH=$cp_path
    assertNotEquals 'simulating tools absence' $RET_OK $status
}


#
# test the id verification routine
#
test_verify_id() {
    local status=0
    declare -a cp_g_tools=( ${g_tools[@]} )
	declare -a cp_g_system=( ${g_system[@]} )

    g_system[2]='pynapi'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'success for pynapi' $RET_OK $status

    g_system[2]='NapiProjekt'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjekt - no 7z' $RET_BREAK $status

    g_system[2]='NapiProjektPython'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjektPython - no 7z' $RET_BREAK $status

    g_system[2]='other'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'other - failure 7z marked as absent' $RET_BREAK $status

    # faking 7z presence
    g_tools=( 7z=1 )
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'other - failure 7z marked as present' $RET_OK $status

    g_system[2]='NapiProjektPython'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjektPython - no base64 & awk' $RET_BREAK $status

    g_tools=( 7z=1 base64=1 awk=1 )
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'success for NapiProjektPython - 7z & base64 & awk' $RET_OK $status

    g_system[2]='unknown_system'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'unknown_system - failure' $RET_PARAM $status

    g_tools=( ${cp_g_tools[@]} )
	g_system=( ${cp_g_system[@]} )
}


#
# test format verification routine
#
test_verify_format() {
    local status=0
    declare -a cp_g_tools=( ${g_tools[@]} )
    local cp_g_sub_format=$g_sub_format

    # verify default format
    verify_format
    status=$?
    assertEquals 'success for format default' $RET_OK $status
    
    # format ok - no subotage.sh
    g_sub_format='subrip'
    verify_format 2>&1 > /dev/null
    status=$?
    assertEquals 'failure due to lack of subotage.sh' $RET_PARAM $status

    g_tools=( subotage.sh=1 )
    g_sub_format='subrip'
    verify_format 2>&1 > /dev/null
    status=$?
    assertEquals 'format ok, subotage present' $RET_OK $status

    g_sub_format='bogus_format'
    verify_format 2>&1 > /dev/null
    status=$?
    assertEquals 'format unknown, subotage present' $RET_PARAM $status

    g_tools=( ${cp_g_tools[@]} )
    g_sub_format=$cp_g_sub_format
}


#
# fps tool verification
#
test_verify_fps_tool() {
    local status=0
    declare -a cp_g_tools=( ${g_tools[@]} )

    verify_fps_tool
    status=$?
    assertEquals 'no tools available, tool = default' $RET_OK $status
    
    g_fps_tool='unsupported_tool'
    verify_fps_tool 2>&1 > /dev/null
    status=$?
    assertEquals 'checking unsupported tool' $RET_PARAM $status

    g_fps_tool='mediainfo'
    verify_fps_tool 2>&1 > /dev/null
    status=$?
    assertEquals 'checking supported, absent tool' $RET_PARAM $status

    g_tools=( mediainfo=1 )
    verify_fps_tool 2>&1 > /dev/null
    status=$?
    assertEquals 'checking supported, present tool' $RET_OK $status
    
    # restore original values
    g_tools=( ${cp_g_tools[@]} )
    g_fps_tool='default'
}


#
# test verify argv routine
#
test_verify_argv() {
    local status=0
    local cp_g_charset=$g_charset
    local cp_g_fps_tool=$g_fps_tool
    local cp_g_sub_format=$g_sub_format
    declare -a cp_g_cred=( ${g_cred[@]} )

    g_cred[0]='user_no_password'
    verify_argv 2>&1 > /dev/null
    assertNull 'empty username' "${g_cred[0]}"
    assertNull 'empty password' "${g_cred[1]}"
    
    g_min_size='abc'
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking g_min_size resetted to zero' 0 $g_min_size

    g_min_size=666
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking g_min_size value' 666 $g_min_size

    g_charset='bogus'
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking default encoding' 'default' $g_charset

    g_charset='utf8'
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking encoding value' 'utf8' $g_charset
    g_charset=$cp_g_charset

    g_system[2]='bogus_id'
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking incorrect id' 'pynapi' ${g_system[2]}

    g_system[2]='other'
    verify_argv 2>&1 > /dev/null
    status=$?
    assertEquals 'checking failure due to lack of 7z' $RET_BREAK $status
    g_system[2]='pynapi'

    local logfile=$(mktemp -t logfile.XXXX)
    g_logfile="$logfile"
    local output=$(verify_argv | grep "istnieje" | wc -l)
    assertEquals 'warning on existing logfile' 1 $output
    unlink "$logfile"

    g_lang='XXX'
    verify_argv 2>&1 > /dev/null
    status=$?
    assertEquals 'checking status - unknown language' $RET_OK $status
    assertEquals 'checking language - unknown language' 'PL' $g_lang

    g_lang='list'
    output=$(verify_argv)
    status=$?
    output=$(echo $output | grep "PL" | wc -l)
    assertEquals 'checking status - list languages' $RET_BREAK $status
    assertEquals 'checking for list' 1 $output
    g_lang='PL'

    g_sub_format='bogus'
    verify_argv 2> /dev/null
    status=$?
    assertEquals 'checking status - bogus subs format' $RET_PARAM $status
    g_sub_format=$cp_g_sub_format

    g_fps_tool='bogus'
    verify_argv 2> /dev/null
    status=$?
    assertEquals 'checking status - bogus fps tool' $RET_PARAM $status
    g_fps_tool=$cp_g_fps_tool

    g_hook='not_existing_script.sh'
    verify_argv 2>/dev/null
    status=$?
    assertEquals 'non-existing external script' $RET_PARAM $status
    g_hook='none'

    local hook=$(mktemp -t hook.XXXX)
    chmod +x "$hook"
    g_hook="$hook"
    verify_argv 2> /dev/null
    status=$?
    assertEquals 'existing external script' $RET_OK $status
    g_hook='none'
    unlink "$hook"
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
# test download function
#
test_download_url() {
    local status=0
	declare -a cp_g_cmd_wget=( "${g_cmd_wget[@]}" )

    g_cmd_wget[0]="mocks/wget_log 127 none"
    download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" > /dev/null
    status=$?
    assertEquals 'check failure status' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 none"
    local output=$(download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" )
    status=$?
    assertEquals 'check success status' $RET_OK $status
    assertEquals 'check unknown http code' "unknown" $output

    g_cmd_wget[0]="mocks/wget_log 0 301_200"
    output=0
    output=$(download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" )
    status=$?
    assertEquals 'check success status' $RET_OK $status
    assertEquals 'check 200 http code' "301 200" "$output"

    g_cmd_wget[0]="mocks/wget_log 0 404"
    output=0
    output=$(download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" )
    status=$?
    assertEquals 'check success status' $RET_FAIL $status
    assertEquals 'check 404 http code' "404" "$output"

	# test post request
    g_cmd_wget[0]="mocks/wget_log 0 301_200"
	g_cmd_wget[1]=0
    output=0
    output=$(download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" "some post data")
    status=$?
    assertEquals 'check post failure status' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 301_200"
	g_cmd_wget[1]=1
    output=0
    output=$(download_url "test_url.com" "$g_assets_path/$g_ut_root/output file with spaces.dat" "some post data")
    status=$?
    assertEquals 'check post success status' $RET_OK $status
    assertEquals 'check 200 http code' "301 200" "$output"

	g_cmd_wget=( "${cp_g_cmd_wget[@]}" )
}

# TODO VERIFIED UP TO HERE =================================================

#
# test download subs routine
#
test_download_subs() {
    local status=0
    local cp_g_cmd_wget="$g_cmd_wget"
	local output_file="$g_assets_path/$g_ut_root/output file" 

    g_cmd_wget="mocks/wget_log 127 none"
    download_subs 123 123 "$output_file" PL other "" "" 2> /dev/null
    status=$?
    assertEquals 'verifying wget error' $RET_FAIL $status

    g_cmd_wget="mocks/wget_log 0 404"
    download_subs 123 123 "$output_file" PL other "" "" 2> /dev/null
    status=$?
    assertEquals 'verifying error when 404' $RET_FAIL $status

    g_cmd_wget="mocks/wget_log 0 200"
    download_subs 123 123 "$output_file" PL other "" "" 2> /dev/null
    status=$?
    assertEquals 'verifying failure when file down. successfully but file doesnt exist' $RET_FAIL $status

    g_cmd_wget="mocks/wget_log 0 200"
    echo test > "$output_file"
    download_subs 123 123 "$output_file" PL pynapi "" ""
    status=$?
    assertEquals 'verifying small file' $RET_FAIL $status
    assertFalse 'check if file has been removed' "[ -s \"$output_file\" ]"

    g_cmd_wget="mocks/wget_log 0 200"
    echo line1 > "$output_file"
    echo line2 >> "$output_file"
    echo line3 >> "$output_file"
    echo line4 >> "$output_file"
    echo line5 >> "$output_file"
    download_subs 123 123 "$output_file" PL pynapi "" ""
    status=$?
    assertEquals 'verifying big enough file' $RET_OK $status
    assertTrue 'check if file still exists' "[ -s \"$output_file\" ]"
    unlink "$output_file"

    g_cmd_wget="$g_cmd_wget"
}


#
# test download cover routine
#
test_download_cover() {
    local status=0  
    local cp_g_cmd_wget="$g_cmd_wget"
	local output_file="$g_assets_path/$g_ut_root/output file" 

    g_cmd_wget="mocks/wget_log 255 none"
    download_cover 123 "$output_file"
    status=$?
    assertEquals 'wget failure' $RET_FAIL $status

    g_cmd_wget="mocks/wget_log 0 404"
    download_cover 123 "$output_file"
    status=$?
    assertEquals 'wget 404' $RET_FAIL $status

    g_cmd_wget="mocks/wget_log 0 200"
    download_cover 123 "$output_file"
    status=$?
    assertEquals 'file doesnt exist' $RET_UNAV $status

    g_cmd_wget="mocks/wget_log 0 200"
    echo test > "$output_file"
    download_cover 123 "$output_file"
    status=$?
    assertEquals 'file exists' $RET_OK $status
    unlink "$output_file"

    g_cmd_wget="$g_cmd_wget"
}


#
# test get subtitles wrapper routine
#
test_get_subtitles() {
    local status=0  
    local cp_g_cmd_wget="$g_cmd_wget"
	local media=''
	local output_file="$g_assets_path/$g_ut_root/subs.txt" 

    g_cmd_wget="mocks/wget_log 0 200"
    echo line1 > "$output_file"
    echo line2 >> "$output_file"
    echo line3 >> "$output_file"
    echo line4 >> "$output_file"
    echo line5 >> "$output_file"
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download subs success' $RET_OK $status

	unlink "$output_file"
	g_cmd_wget="$g_cmd_wget"
}


#
# test get cover wrapper routine
#
test_get_cover() {
    local status=0  
    local cp_g_cmd_wget="$g_cmd_wget"

    g_cmd_wget="mocks/wget_log 0 200"
	echo cover_data > "$g_assets_path/$g_ut_root/av1 file.jpg"
	get_cover "$g_assets_path/$g_ut_root/av1 file.avi" 
	status=$?
	assertEquals 'checking the cover' $RET_OK $status

	unlink "$g_assets_path/$g_ut_root/av1 file.jpg"
	g_cmd_wget="$g_cmd_wget"
}


#
# test get charset routine
#
test_get_charset() {
    local output=''
    declare -a tmp=( ${g_tools[@]} )
	local output_file="$g_assets_path/$g_ut_root/test_file" 

	LANG=C echo test_file > "$output_file"
	output=$(get_charset "$output_file")
	assertEquals 'checking default charset when file=0' 'WINDOWS-1250' "$output"
	
	g_tools=( file=1 )
	output=$(get_charset "$output_file")
	assertEquals 'checking default charset when file=0' 'US-ASCII' "$output"

	unlink "$output_file"
    g_tools=( ${tmp[@]} )
}


#
# test convert charset routine
#
test_convert_charset() {
    local status=0
    declare -a tmp=( ${g_tools[@]} )
	local output_file="$g_assets_path/$g_ut_root/test_file" 

	LANG=C echo "znaki specjalne ęóąśżźćń" > "$output_file"
	g_tools=( file=1 )
	convert_charset "$output_file" 'utf8'
	status=$?
	assertEquals 'checking return value' $RET_OK $status

	output=$(get_charset "$output_file")
	assertEquals 'checking converted charset' 'UTF8' $output

	unlink "$output_file"
    g_tools=( ${tmp[@]} )
}


#
# test verify_extension routine
#
test_verify_extension() {
    local output=''
    output=$(verify_extension 'plik.txt')
    assertEquals 'verify txt ext' 0 $output
    
    output=$(verify_extension 'plik ze spacja.dat')
    assertEquals 'verify dat ext' 0 $output

    output=$(verify_extension 'plik ze spacja.avi')
    assertEquals 'verify dat ext' 1 $output
}


#
# test prepare_file_list
#
test_prepare_file_list() {
    declare -a cp_g_files=( ${g_files[@]} )

    prepare_file_list 0 "$g_assets_path/$g_ut_root"
    assertEquals 'number of elements' 3 ${#g_files[@]}

    g_files=()
    prepare_file_list 20 "$g_assets_path/$g_ut_root"
    assertEquals 'number of elements (min_size: 20)' 0 ${#g_files[@]}

    g_files=( ${cp_g_files[@]} )
}


#
# test prepare_filenames
#
test_prepare_filenames() {
    declare -a cp_g_abbrev=( ${g_abbrev[@]} )

    prepare_filenames 'file.avi'

    assertEquals 'checking 0' 'file.txt' ${g_pf[0]}
    assertEquals 'checking 1' 'file.txt' ${g_pf[1]}
    assertEquals 'checking 2' 'ORIG_file.txt' ${g_pf[2]}
    assertEquals 'checking 3' 'ORIG_file.txt' ${g_pf[3]}
    assertEquals 'checking 4' 'file.txt' ${g_pf[4]}
    assertEquals 'checking 5' 'file.txt' ${g_pf[5]}
    assertEquals 'checking 6' 'file.txt' ${g_pf[6]}
    assertEquals 'checking 7' 'file.txt' ${g_pf[7]}

    g_abbrev=( 'AB' 'CAB' )
    prepare_filenames 'file.avi'

    assertEquals 'checking 0' 'file.txt' ${g_pf[0]}
    assertEquals 'checking 1' 'file.AB.txt' ${g_pf[1]}
    assertEquals 'checking 2' 'ORIG_file.txt' ${g_pf[2]}
    assertEquals 'checking 3' 'ORIG_file.AB.txt' ${g_pf[3]}
    assertEquals 'checking 4' 'file.txt' ${g_pf[4]}
    assertEquals 'checking 5' 'file.AB.txt' ${g_pf[5]}
    assertEquals 'checking 6' 'file.CAB.txt' ${g_pf[6]}
    assertEquals 'checking 7' 'file.AB.CAB.txt' ${g_pf[7]}

    g_abbrev=( ${cp_g_abbrev[@]} )
}


#
# test the conversion routine
#
test_convert_format() {
    local cp_g_delete_orig=$g_delete_orig
	local cp_g_sub_format=$g_sub_format
	local status=0

	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "not_existing_file.txt" "ORIG_subs.txt" "converted.txt" 2>&1 > /dev/null
	status=$?
	assertEquals 'failure on non existing subs' $RET_FAIL $status

	echo "[529][586]line1" > "$g_assets_path/$g_ut_root/subs.txt"
	echo "[610][639]line2" >> "$g_assets_path/$g_ut_root/subs.txt"
	echo "[1059][1084]line3" >> "$g_assets_path/$g_ut_root/subs.txt"
	
	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" 2>&1 > /dev/null
	status=$?
	assertEquals 'failure on default subs format' $RET_FAIL $status

	g_delete_orig=1
	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" 2>&1 > /dev/null
	status=$?
	assertFalse 'checking if orig is deleted if failure' "[ -e \"$g_assets_path/$g_ut_root/ORIG_subs.txt\" ]"

	g_sub_format='subrip'
	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" 2>&1 > /dev/null
	status=$?
	assertEquals 'success on subrip subs format' $RET_OK $status
	assertFalse 'checking if orig is deleted if success' "[ -e \"$g_assets_path/$g_ut_root/ORIG_subs.txt\" ]"
	assertTrue 'checking for subs file' "[ -e \"$g_assets_path/$g_ut_root/converted.txt\" ]"
    
    g_delete_orig=$cp_g_delete_orig
	g_sub_format=$cp_g_sub_format
    return 0
}


#
# test subs file detection routine
#
test_check_subs_presence() {

	local rv=0
    
	g_abbrev=( 'AB' 'CAB' )
	prepare_filenames "video.avi"
	g_sub_format='default'

	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root"
	rv=$?
	assertEquals 'nothing available' 0 $rv

	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[0]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root"
	rv=$?
	assertEquals '0 available, checking rv' 2 $rv
	assertTrue '0 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[1]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[0]}"
	unlink "$g_assets_path/$g_ut_root/${g_pf[1]}"

	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[3]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root"
	rv=$?
	assertEquals '3 available, checking rv' 2 $rv
	assertTrue '3 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[1]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[0]}"
	unlink "$g_assets_path/$g_ut_root/${g_pf[3]}"

	g_sub_format='subrip'
	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[6]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root"
	rv=$?
	assertEquals '6 available, checking rv' 1 $rv
	assertTrue '6 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[7]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[6]}"
	unlink "$g_assets_path/$g_ut_root/${g_pf[7]}"

	g_abbrev=()
	g_sub_format='default'
	g_pf=()
    return 0    
}


#
# test the statistics printing routine
#
test_print_stats() {
    local output=''
	declare -a cp_g_stats=( ${g_stats[@]} )
    
	g_stats=( 1 2 3 4 5 6 7 )
	output=$(print_stats | grep -w OK | rev | cut -d ' ' -f 1)
	assertEquals 'OK stats' 1 ${output:-0}

	output=$(print_stats | grep -w UNAV | rev | cut -d ' ' -f 1)
	assertEquals 'UNAV stats' 2 ${output:-0}

	output=$(print_stats | grep -w SKIP | rev | cut -d ' ' -f 1)
	assertEquals 'SKIP stats' 3 ${output:-0}

	output=$(print_stats | grep -w CONV | rev | cut -d ' ' -f 1)
	assertEquals 'CONV stats' 4 ${output:-0}

	output=$(print_stats | grep -w COVER_OK | rev | cut -d ' ' -f 1)
	assertEquals 'COVER_OK stats' 5 ${output:-0}

	output=$(print_stats | grep -w COVER_UNAV | rev | cut -d ' ' -f 1)
	assertEquals 'COVER_UNAV stats' 6 ${output:-0}

	output=$(print_stats | grep -w TOTAL | rev | cut -d ' ' -f 1)
	assertEquals 'TOTAL stats' 7 ${output:-0}

	g_stats=( ${cp_g_stats[@]} )
}


#
# test usage routine
#
test_usage() {
    local output=''
	declare -a cp_g_tools=( ${g_tools[@]} )

	output=$(usage | grep "\-\-charset" | wc -l)
	assertEquals 'no charset option, when iconv missing' 0 $output

	output=$(usage | grep "\-\-format" | wc -l)
	assertEquals 'no subotage options, when subotage missing' 0 $output

	g_tools=( subotage.sh=1 iconv=1 )
	output=$(usage | grep "\-\-charset" | wc -l)
	assertEquals 'charset option, when iconv available' 1 $output

	output=$(usage | grep "\-\-format" | wc -l)
	assertEquals 'subotage options, when subotage available' 1 $output

	g_tools=( ${cp_g_tools[@]} )
}


#
# test statistics summing routine
#
test_sum_stats() {
	declare -a cp_g_stats=( ${g_stats[@]} )
	declare -a cp_g_tools=( ${g_tools[@]} )

	echo "1 2 3 4 5 6 7" > "$g_assets_path/$g_ut_root/stats.txt"	
	echo "8 9 10 11 12 13 14" >> "$g_assets_path/$g_ut_root/stats.txt"

	g_tools=( awk=1 )
	sum_stats "$g_assets_path/$g_ut_root/stats.txt"

	assertEquals 'checking column 0' 9 ${g_stats[0]}
	assertEquals 'checking column 1' 11 ${g_stats[1]}
	assertEquals 'checking column 2' 13 ${g_stats[2]}
	assertEquals 'checking column 3' 15 ${g_stats[3]}
	assertEquals 'checking column 4' 17 ${g_stats[4]}
	assertEquals 'checking column 5' 19 ${g_stats[5]}
	assertEquals 'checking column 6' 21 ${g_stats[6]}

	g_stats=( ${cp_g_stats[@]} )
	g_tools=( ${cp_g_tools[@]} )

	unlink "$g_assets_path/$g_ut_root/stats.txt"
}


#
# check the fork spawning function
#
test_spawn_forks() {
	declare -a cp_g_system=( ${g_system[@]} )

	local forks_info="$g_assets_path/$g_ut_root/forks.info"

	g_files=( file1 file2 file3 file4 )
	g_system[1]=2

	# setup some mocks first
	(
	process_files() {
		echo "mock params $@" >> "$forks_info"
		sleep 1
	}

	export -f process_files
	spawn_forks

	local no_forks="$(cat $forks_info | wc -l)"

	assertTrue 'checking forks info file' "[ -e \"$forks_info\" ]"
	assertEquals 'checking number of forks' 2 $no_forks

	assertEquals 'checking fork params #1' 1 "$(grep '0 2' $forks_info | wc -l)"
	assertEquals 'checking fork params #2' 1 "$(grep '1 2' $forks_info | wc -l)"

	unlink "$forks_info"

	g_files=( file1 file3 file4 )
	g_system[1]=4

	spawn_forks
	local no_forks="$(cat $forks_info | wc -l)"

	assertTrue 'checking forks info file' "[ -e \"$forks_info\" ]"
	assertEquals 'checking number of forks (less files than forks)' 3 $no_forks
	unlink "$forks_info"
	)

	g_files=()
	g_system=( ${cp_g_system[@]} )
    return 0    
}


#
# test files processing routine
#
test_process_files() {

	g_files=( file1 file2 file3 )

	(
	file_cnt=0
	process_file() {
		file_cnt=$(( $file_cnt + 1 ))
	}
	export -f process_file

	process_files 0 1
	assertEquals 'checking total no. of process files' ${#g_files[@]} $file_cnt

	file_cnt=0
	process_files 0 2
	assertEquals 'checking total no. of process files (incr = 2)' 2 $file_cnt
	)

    return 0    
}


#
# test obtain file routine
#
test_obtain_file() {
	# empty for now, will be verified with system tests
    return 0    
}


#
# test process file routine
#
test_process_file() {
	# empty for now, will be verified with system tests
    return 0    
}



# shunit call
. shunit2
