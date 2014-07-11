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
. "$g_install_path/napi.sh" 2>&1 > /dev/null

################################################################################

#
# tests env setup
#
oneTimeSetUp() {
	_prepare_env

    # the space in the file name is deliberate
    mkdir -p "$g_assets_path/$g_ut_root/sub dir"
    cp -v "$g_assets_path/napi_test_files/av1.dat" "$g_assets_path/$g_ut_root/av1 file.avi"
    cp -v "$g_assets_path/napi_test_files/av2.dat" "$g_assets_path/$g_ut_root/av2 file.avi"
    cp -v "$g_assets_path/napi_test_files/av1.dat" "$g_assets_path/$g_ut_root/sub dir/av3 file.avi"

	# copy the example xml
    cp -v "$g_assets_path/napi_test_files/example.xml" "$g_assets_path/$g_ut_root/example.xml"
}


#
# tests env tear down
#
oneTimeTearDown() {
	_purge_env
}

################################################################################


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
# verify the configure_cmds routine
#
test_configure_cmds() {

	_save_globs

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

	g_tools=( 'unlink=0' )
	assertEquals "checking if unlink is rm -rf" "rm -rf" "$g_cmd_unlink"

	_restore_globs
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
	_save_globs

    declare -a tmp=( ${g_tools[@]} )

    c=$(count_fps_detectors)
    assertEquals 'default no of fps detectors' 0 $c

    g_tools=( $(modify_value 'mediainfo' 1 ${g_tools[@]}) )
    c=$(count_fps_detectors)
    assertEquals 'no of fps detectors' 1 $c

	_restore_globs
}


#
# test get_fps routine with various fps detectors
#
test_get_fps() {
    local fps=0
    fps=$(get_fps 'doesnt_matter' 'doesnt_matter.avi')
    assertEquals 'get fps without tools' 0 $fps

	_save_globs

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

	_restore_globs
}


#
# test the argument parsing routine
# 
test_parse_argv() {
    local status=0
	_save_globs
    
    parse_argv -a 2>&1 > /dev/null
    status=$?
    assertEquals "checking for failure without parameter value" $RET_FAIL $status

    parse_argv -a ABBREV 2>&1 > /dev/null
    status=$?
    assertEquals "checking for success (-a)" $RET_OK $status
    assertEquals "checking for abbreviation" "ABBREV" "${g_abbrev[0]}"

    parse_argv -b 123 2>&1 > /dev/null
    status=$?
    assertEquals "checking for success (-b)" $RET_OK $status
    assertEquals "checking for size" 123 $g_min_size
    g_min_size=0

    # test complex command
    parse_argv -c \
        -n \
		-M \
        -d \
        -s \
		-lo \
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
    assertEquals 'checking logfile' 'log' ${g_output[$___LOG]}
    assertEquals 'checking lang' 'EN' $g_lang
    assertEquals 'checking user' 'john' ${g_cred[0]}
    assertEquals 'checking passwd' 'doe' ${g_cred[1]}
    assertEquals 'checking hook' 'my_hook.sh' $g_hook
    assertEquals 'checking verbosity' 3 ${g_output[$___VERBOSITY]}
    assertEquals 'checking verbosity' 3 ${g_output[$___VERBOSITY]}
    assertEquals 'checking format' 'subrip' $g_sub_format
    assertEquals 'checking fps tool' 'ffmpeg' $g_fps_tool
    assertEquals 'checking prefix' 'PREFIX_' $g_orig_prefix
    assertEquals 'checking forks' 32 ${g_system[1]}
    assertEquals 'checking conv abbreviation' "CONV" "${g_abbrev[1]}"
    assertEquals 'checking paths' 'file1.avi' ${g_paths[0]}
    assertEquals 'checking log overwrite' 1 ${g_output[$___LOG_OWR]}

	_restore_globs
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
	_save_globs

    g_system[2]='pynapi'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'success for pynapi' $RET_OK $status

    g_system[2]='NapiProjekt'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjekt - no 7z' $RET_UNAV $status
	assertEquals 'checking for id' 'pynapi' ${g_system[2]}

    g_system[2]='NapiProjektPython'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjektPython - no 7z' $RET_UNAV $status
	assertEquals 'checking for id' 'pynapi' ${g_system[2]}

    g_system[2]='other'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'other - failure 7z marked as absent' $RET_UNAV $status
	assertEquals 'checking for id' 'pynapi' ${g_system[2]}

    # faking 7z presence
    g_tools=( 7z=1 )
	g_cmd_7z='7z'
    g_system[2]='other'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'other - success 7z marked as present' $RET_OK $status
	assertEquals 'checking for id' 'other' ${g_system[2]}

    g_system[2]='NapiProjektPython'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'failure for NapiProjektPython - no base64 & awk' $RET_UNAV $status

    g_tools=( 7z=1 base64=1 awk=1 )
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'success for NapiProjektPython - 7z & base64 & awk' $RET_OK $status

    g_system[2]='unknown_system'
    verify_id 2>&1 > /dev/null
    status=$?
    assertEquals 'unknown_system - failure' $RET_PARAM $status

	_restore_globs
}


#
# test format verification routine
#
test_verify_format() {
    local status=0
	_save_globs

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

	_restore_globs
}


#
# fps tool verification
#
test_verify_fps_tool() {
    local status=0
	_save_globs

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
    
	_restore_globs
}


#
# test the 7z detection/verification routine
#
test_verify_7z() {
	local status=0
	_save_globs

	verify_7z
	status=$?
	assertEquals "checking for failure - no 7z" $RET_FAIL "$status"

	g_tools=( '7z=1' '7za=1' )
	verify_7z
	status=$?
	assertEquals "checking for success" $RET_OK "$status"
	assertEquals "7za has priority" "7za" "$g_cmd_7z"
	
	g_tools=( '7z=1' '7za=0' )
	verify_7z
	status=$?
	assertEquals "checking for success" $RET_OK "$status"
	assertEquals "7z presence" "7z" "$g_cmd_7z"

	_restore_globs
}


#
# test verify argv routine
#
test_verify_argv() {
    local status=0

	_save_globs

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

    g_system[2]='bogus_id'
    verify_argv 2>&1 > /dev/null
    assertEquals 'checking incorrect id' 'pynapi' ${g_system[2]}

    local logfile=$(mktemp -t logfile.XXXX)
    g_output[$___LOG]="$logfile"
    local output=$(verify_argv 2>&1 | grep "istnieje" | wc -l)
    assertEquals 'failure on existing logfile' 1 $output

	g_output[$___LOG_OWR]=1
    local output=$(verify_argv | grep "nadpisany" | wc -l)
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
    g_sub_format='default'

    g_fps_tool='bogus'
    verify_argv 2> /dev/null
    status=$?
    assertEquals 'checking status - bogus fps tool' $RET_PARAM $status
    g_fps_tool=$_cp_g_fps_tool

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

	_restore_globs
}


#
# @brief verify the f hashing function
#
test_f() {
	local sum="91a929824737bbdd98c41e17d7f9630c"
	local hash="ae34b"
	local output=''

	output=$(f "$sum")
	assertEquals "verifying hash" "$hash" "$output"
}


#
# test download function
#
test_download_url() {
    local status=0
	_save_globs

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

	_restore_globs
}


#
# test the awk code execution wrapper
#
test_run_awk_script() {
	local code='{ print $2 }'
	local status=0
	local output=''
	_save_globs

	echo "col1 col2 col3" | run_awk_script "$code"
	status=$?
	assertEquals "awk failure - awk marked as absent" $RET_FAIL $status
	
	g_tools=( awk=1 )
	output=$(echo "col1 col2 col3" | run_awk_script "$code")
	status=$?
	assertEquals "awk success - marked as present" $RET_OK $status
	assertEquals "checking result of the stream processing" "col2" "$output"
	
	local tmpf=$(mktemp -t tmp.awk.XXXXXXXX)

	echo "col1 col2 col3" > "$tmpf"
	output=$(run_awk_script "$code" "$tmpf")
	status=$?
	assertEquals "awk success - marked as present" $RET_OK $status
	assertEquals "checking result of the file processing" "col2" "$output"

	unlink "$tmpf"
	_restore_globs
}


#
# xml single tag extraction check
#
test_extract_xml_tag() {
	local tmpf=$(mktemp -t test.xml.XXXXXXXX)
	local data=''
	local output=''

	_save_globs

	g_tools=( awk=1 )
	data='<taga><nested><x>data</x></nested></taga>'
	output=$(echo "$data" | extract_xml_tag 'x')
	assertEquals "checking for extracted tag" "<x>data</x>" "$output"

	echo "$data" > "$tmpf"
	output=$(extract_xml_tag 'x' "$tmpf")
	assertEquals "checking for extracted tag from file" "<x>data</x>" "$output"

	unlink "$tmpf"
	_restore_globs
}


#
# xml cdata tag extraction check
#
test_extract_cdata_tag() {
	local tmpf=$(mktemp -t test.xml.XXXXXXXX)
	local data=''
	local output=''

	_save_globs

	g_tools=( awk=1 )
	data='<taga><![CDATA[some_data]]></taga>'
	output=$(echo "$data" | extract_cdata_tag)
	assertEquals "checking for extracted data" "some_data" "$output"

	echo "$data" > "$tmpf"
	output=$(extract_cdata_tag "$tmpf")
	assertEquals "checking for extracted data from file" "some_data" "$output"

	unlink "$tmpf"
	_restore_globs
}


#
# xml tag strip check
#
test_strip_xml_tag() {
	local tmpf=$(mktemp -t test.xml.XXXXXXXX)
	local data=''
	local output=''

	_save_globs

	g_tools=( awk=1 )
	data='<taga>data</taga>'
	output=$(echo "$data" | strip_xml_tag 'taga')
	assertEquals "checking for bare data" "data" "$output"

	echo "$data" > "$tmpf"
	output=$(strip_xml_tag 'taga' "$tmpf")
	assertEquals "checking for bare data from file" "data" "$output"

	unlink "$tmpf"
	_restore_globs
}


#
# test xml download data function
#
test_download_data_xml() {
	local status=0

	(
		retval=$RET_OK

		download_url() {
			return $retval
		}
		export -f download_url

		download_data_xml 0 "movie file.avi" 666 "/path/to/xml file.xml" 'ENG' 'tw' 'pass'
		status=$?
		assertEquals 'checking success download status' $RET_OK $status

		retval=$RET_FAIL
		download_data_xml 0 "movie file.avi" 666 "/path/to/xml file.xml" 'ENG' 'tw' 'pass' 2>&1 > /dev/null
		status=$?
		assertEquals 'checking failure download status' $RET_FAIL $status
	)

	return 0
}


#
# test get_xml wrapper
#
test_get_xml() {
	local xmltmp=$(mktemp tmp.xml.XXXXXXXX)
	local status=0
	local data="this is some bogus xml data which must be longer than 32 bytes"

	echo "$data" > "$xmltmp"

	(

	retval=$RET_FAIL
	download_data_xml() {
		[ "$retval" -eq $RET_OK ] && echo "$data" > "$4"
		return $retval
	}

	get_xml 0 'movie.avi' 123 PL 'not_existing.xml'
	status=$?
	assertEquals 'checking failure status' $RET_FAIL $status

	get_xml 0 'movie.avi' 123 PL "$xmltmp"
	status=$?
	assertEquals 'checking success status xml already exists' $RET_OK $status

	retval=$RET_OK
	get_xml 0 'movie.avi' 123 PL "will_be_created.xml"
	status=$?
	assertEquals 'checking success status download_data_xml is successful' $RET_OK $status
	[ -e "will_be_created.xml" ] && unlink "will_be_created.xml"

	)

	unlink "$xmltmp"
	return 0
}


#
# test subs xml extraction
#
test_extract_subs_xml() {
	local bogus_file=$(mktemp -t bogus.xml.XXXXXXXX)
	local subs="$g_assets_path/$g_ut_root/subs.txt"
	local status=0

	_save_globs

	extract_subs_xml "$bogus_file" "$subs" 2>&1 > /dev/null
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_cmd_7z="false"
	g_tools=( 'awk=1' )
	extract_subs_xml "$g_assets_path/$g_ut_root/example.xml" "$subs" 2>&1 > /dev/null
	status=$?
	assertEquals "checking for 7z failure" $RET_FAIL "$status"

	g_cmd_7z="7za"
	extract_subs_xml "$g_assets_path/$g_ut_root/example.xml" "$subs"
	status=$?
	assertEquals "checking for 7z success" $RET_OK "$status"
	assertTrue "checking the subs file" "[ -e \"$subs\" ]"

	unlink "$subs"
	unlink "$bogus_file"
	_restore_globs
}


#
# test nfo xml extraction
#
test_extract_nfo_xml() {
	local bogus_file=$(mktemp -t bogus.xml.XXXXXXXX)
	local nfo="$g_assets_path/$g_ut_root/info.nfo"
	local status=0

	_save_globs

	extract_nfo_xml "$bogus_file" "$nfo" 2>&1 > /dev/null
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_tools=( 'awk=1' )
	extract_nfo_xml "$g_assets_path/$g_ut_root/example.xml" "$nfo"
	status=$?
	assertEquals "checking for success" $RET_OK "$status"
	assertTrue "checking the nfo file" "[ -s \"$nfo\" ]"

	unlink "$nfo"
	unlink "$bogus_file"
	_restore_globs
	return 0
}


#
# test cover xml extraction
#
test_extract_cover_xml() {
	local bogus_file=$(mktemp -t bogus.xml.XXXXXXXX)
	local cover="$g_assets_path/$g_ut_root/cover.jpg"
	local status=0

	_save_globs

	extract_nfo_xml "$bogus_file" "$cover" 2>&1 > /dev/null
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_tools=( 'awk=1' )
	extract_nfo_xml "$g_assets_path/$g_ut_root/example.xml" "$cover"
	status=$?
	assertEquals "checking for success" $RET_OK "$status"
	assertTrue "checking the nfo file" "[ -s \"$cover\" ]"

	unlink "$cover"
	unlink "$bogus_file"
	_restore_globs
	return 0
}


#
# test xml cleanup routine
#
test_cleanup_xml() {
	local media_path="$g_assets_path/$g_ut_root/av1 file.avi"
	local xml_path="$g_assets_path/$g_ut_root/av1 file.xml"

	_save_globs

	touch "$xml_path"
	echo "bogus data" > "$xml_path"

	g_system[2]='pynapi'
	cleanup_xml "$media_path"
	assertTrue 'checking file existence' "[ -e \"$xml_path\" ]"

	g_system[2]='NapiProjektPython'
	cleanup_xml "$media_path"
	assertFalse 'checking file absence' "[ -e \"$xml_path\" ]"

	_restore_globs
	[ -e "$xml_path" ] && unlink "$xml_path"
	return 0
}


test_download_item_xml() {
	local status=0
	local moviepath="$g_assets_path/$g_ut_root/example.avi"

	download_item_xml "unsupported" 2>&1 > /dev/null
	status=$?
	assertEquals "failure for unsupported item" $RET_BREAK "$status"

	(
	retval1=$RET_FAIL
	retval2=$RET_FAIL

	get_xml() {
		return $retval1
	}
	export -f get_xml

	extract_subs_xml() {
		return $retval2
	}
	export -f extract_subs_xml

	download_item_xml "subs" 2>&1 > /dev/null
	status=$?
	assertEquals "failure for supported item but get_xml failure" $RET_FAIL "$status"

	retval1=$RET_OK	
	download_item_xml "subs" 0 "$moviepath" 2>&1 > /dev/null
	status=$?
	assertEquals "failure for supported item but extract_item failure" $RET_FAIL "$status"

	retval2=$RET_OK	
	download_item_xml "subs" 0 "$moviepath" 2>&1 > /dev/null
	status=$?
	assertEquals "success for supported item but extract_item failure" $RET_OK "$status"
	)

	return 0
}


#
# test download subs routine
#
test_download_subs_classic() {
    local status=0
	local output_file="$g_assets_path/$g_ut_root/output file" 

	_save_globs

    g_cmd_wget[0]="mocks/wget_log 127 none"
    download_subs_classic 123 123 "$output_file" PL other "" "" 2>&1 > /dev/null
    status=$?
    assertEquals 'verifying wget error' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 404"
    download_subs_classic 123 123 "$output_file" PL other "" "" 2>&1 > /dev/null
    status=$?
    assertEquals 'verifying error when 404' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    download_subs_classic 123 123 "$output_file" PL other "" "" 2>&1 > /dev/null
    status=$?
    assertEquals 'verifying failure when file down. successfully but file doesnt exist' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo test > "$output_file"
    download_subs_classic 123 123 "$output_file" PL pynapi "" "" 2>&1 > /dev/null
    status=$?
    assertEquals 'verifying small file' $RET_FAIL $status
    assertFalse 'check if file has been removed' "[ -s \"$output_file\" ]"

    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo line1 > "$output_file"
    echo line2 >> "$output_file"
    echo line3 >> "$output_file"
    echo line4 >> "$output_file"
    echo line5 >> "$output_file"
    download_subs_classic 123 123 "$output_file" PL pynapi "" "" 2>&1 > /dev/null
    status=$?
    assertEquals 'verifying big enough file' $RET_OK $status
    assertTrue 'check if file still exists' "[ -s \"$output_file\" ]"
    unlink "$output_file"

	_restore_globs
}


#
# test download cover routine
#
test_download_cover_classic() {
    local status=0  
	local output_file="$g_assets_path/$g_ut_root/output file" 

	_save_globs

    g_cmd_wget[0]="mocks/wget_log 255 none"
    download_cover_classic 123 "$output_file"
    status=$?
    assertEquals 'wget failure' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 404"
    download_cover_classic 123 "$output_file"
    status=$?
    assertEquals 'wget 404' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    download_cover_classic 123 "$output_file"
    status=$?
    assertEquals 'file doesnt exist' $RET_UNAV $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo test > "$output_file"
    download_cover_classic 123 "$output_file"
    status=$?
    assertEquals 'file exists' $RET_OK $status
    unlink "$output_file"

	_restore_globs
}


#
# test get subtitles wrapper routine
#
test_get_subtitles() {
    local status=0  
	local media=''
	local output_file="$g_assets_path/$g_ut_root/subs.txt" 

	_save_globs

	g_system[2]='pynapi'
    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo line1 > "$output_file"
    echo line2 >> "$output_file"
    echo line3 >> "$output_file"
    echo line4 >> "$output_file"
    echo line5 >> "$output_file"
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download subs success' $RET_OK $status

	(
	retval=$RET_FAIL
	download_item_xml() {
		return $retval
	}
	export -f download_item_xml

	g_system[2]='NapiProjekt'
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download subs failure' $RET_FAIL $status

	retval=$RET_OK
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download subs success' $RET_OK $status
	)

	unlink "$output_file"
	_restore_globs
}


#
# @brief test nfo retrieval wrapper
#
test_get_nfo() {
	local status=0
	_save_globs

	(
	retval=$RET_FAIL
	download_item_xml() {
		return $retval
	}
	export -f download_item_xml

	g_system[2]='pynapi'
	get_nfo 2>&1 > /dev/null
	status=$?
	assertEquals "failure for non API3 id" $RET_FAIL "$status"

	g_system[2]='NapiProjekt'
	get_nfo 2>&1 > /dev/null
	status=$?
	assertEquals "failure for due to download_item_xml fail" $RET_FAIL "$status"

	retval=$RET_OK
	get_nfo 2>&1 > /dev/null
	status=$?
	assertEquals "get_nfo success" $RET_OK "$status"
	)

	_restore_globs
}


#
# test get cover wrapper routine
#
test_get_cover() {
    local status=0  

	_save_globs

    g_cmd_wget[0]="mocks/wget_log 0 200"
	g_system[2]='pynapi'
	echo "cover_data" > "$g_assets_path/$g_ut_root/av1 file.jpg"
	get_cover "$g_assets_path/$g_ut_root/av1 file.avi" 
	status=$?
	assertEquals 'checking the cover' $RET_OK $status

	(
	retval=$RET_FAIL
	download_item_xml() {
		return $retval
	}
	export -f download_item_xml

	g_system[2]='NapiProjekt'
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download cover failure' $RET_FAIL $status

	retval=$RET_OK
	get_subtitles "$g_assets_path/$g_ut_root/av1 file.avi" "$output_file" "PL"
    status=$?
    assertEquals 'download cover success' $RET_OK $status
	)

	unlink "$g_assets_path/$g_ut_root/av1 file.jpg"
	_restore_globs
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
# test the conversion routine
#
test_convert_format() {
	local status=0

	_save_globs

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
    
	_restore_globs
    return 0
}


#
# test the statistics printing routine
#
test_print_stats() {
    local output=''
	_save_globs
    
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

	_restore_globs
}


#
# test usage routine
#
test_usage() {
    local output=''
	_save_globs

	output=$(usage | grep "\-\-charset" | wc -l)
	assertEquals 'no charset option, when iconv missing' 0 $output

	output=$(usage | grep "\-\-format" | wc -l)
	assertEquals 'no subotage options, when subotage missing' 0 $output

	g_tools=( subotage.sh=1 iconv=1 )
	output=$(usage | grep "\-\-charset" | wc -l)
	assertEquals 'charset option, when iconv available' 1 $output

	output=$(usage | grep "\-\-format" | wc -l)
	assertEquals 'subotage options, when subotage available' 1 $output

	_restore_globs
}


#
# test statistics summing routine
#
test_sum_stats() {
	_save_globs

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

	_restore_globs
	unlink "$g_assets_path/$g_ut_root/stats.txt"
}


#
# check the fork spawning function
#
test_spawn_forks() {
	local forks_info="$g_assets_path/$g_ut_root/forks.info"

	_save_globs

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

	_restore_globs
    return 0    
}


#
# test files processing routine
#
test_process_files() {

	_save_globs
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

	_restore_globs
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
