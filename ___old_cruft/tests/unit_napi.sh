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

    parse_argv -a >/dev/null 2>&1
    status=$?
    assertEquals "checking for failure without parameter value" $RET_FAIL $status

    parse_argv -a ABBREV >/dev/null 2>&1
    status=$?
    assertEquals "checking for success (-a)" $RET_OK $status
    assertEquals "checking for abbreviation" "ABBREV" "${g_abbrev[0]}"

    parse_argv -b 123 >/dev/null 2>&1
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
        file1.avi file2.avi >/dev/null 2>&1

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
    verify_format >/dev/null 2>&1
    status=$?
    assertEquals 'failure due to lack of subotage.sh' $RET_PARAM $status

    g_tools=( subotage.sh=1 )
    g_sub_format='subrip'
    verify_format >/dev/null 2>&1
    status=$?
    assertEquals 'format ok, subotage present' $RET_OK $status

    g_sub_format='bogus_format'
    verify_format >/dev/null 2>&1
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
    verify_fps_tool >/dev/null 2>&1
    status=$?
    assertEquals 'checking unsupported tool' $RET_PARAM $status

    g_fps_tool='mediainfo'
    verify_fps_tool >/dev/null 2>&1
    status=$?
    assertEquals 'checking supported, absent tool' $RET_PARAM $status

    g_tools=( mediainfo=1 )
    verify_fps_tool >/dev/null 2>&1
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
    verify_argv >/dev/null 2>&1
    assertNull 'empty username' "${g_cred[0]}"
    assertNull 'empty password' "${g_cred[1]}"

    g_min_size='abc'
    verify_argv >/dev/null 2>&1
    assertEquals 'checking g_min_size resetted to zero' 0 $g_min_size

    g_min_size=666
    verify_argv >/dev/null 2>&1
    assertEquals 'checking g_min_size value' 666 $g_min_size

    g_charset='bogus'
    verify_argv >/dev/null 2>&1
    assertEquals 'checking default encoding' 'default' $g_charset

    g_charset='utf8'
    verify_argv >/dev/null 2>&1
    assertEquals 'checking encoding value' 'utf8' $g_charset

    g_system[2]='bogus_id'
    verify_argv >/dev/null 2>&1
    assertEquals 'checking incorrect id' 'pynapi' ${g_system[2]}

    local logfile=$(mktemp -t logfile.XXXX)
    g_output[$___LOG]="$logfile"
    local output=$(verify_argv 2>&1 | grep "istnieje" | wc -l)
    assertEquals 'failure on existing logfile' 1 $output

	g_output[$___LOG_OWR]=1
    local output=$(verify_argv 2>/dev/null | grep "nadpisany" | wc -l)
    assertEquals 'warning on existing logfile' 1 $output
    unlink "$logfile"

    g_lang='XXX'
    verify_argv >/dev/null 2>&1
    status=$?
    assertEquals 'checking status - unknown language' $RET_OK $status
    assertEquals 'checking language - unknown language' 'PL' $g_lang

    g_lang='list'
    output=$(verify_argv 2>/dev/null)
    status=$?
    output=$(echo $output | grep "PL" | wc -l)
    assertEquals 'checking status - list languages' $RET_BREAK $status
    assertEquals 'checking for list' 1 $output
    g_lang='PL'

    g_sub_format='bogus'
    verify_argv >/dev/null 2>&1
    status=$?
    assertEquals 'checking status - bogus subs format' $RET_PARAM $status
    g_sub_format='default'

    g_fps_tool='bogus'
    verify_argv >/dev/null 2>&1
    status=$?
    assertEquals 'checking status - bogus fps tool' $RET_PARAM $status
    g_fps_tool=$_cp_g_fps_tool

    g_hook='not_existing_script.sh'
    verify_argv >/dev/null 2>&1
    status=$?
    assertEquals 'non-existing external script' $RET_PARAM $status
    g_hook='none'

    local hook=$(mktemp -t hook.XXXX)
    chmod +x "$hook"
    g_hook="$hook"
    verify_argv >/dev/null 2>&1
    status=$?
    assertEquals 'existing external script' $RET_OK $status
    g_hook='none'
    unlink "$hook"

	_restore_globs
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

		download_data_xml 0 "movie file.avi" 666 "/path/to/xml file.xml" 'ENG' 'tw' 'pass' >/dev/null 2>&1
		status=$?
		assertEquals 'checking success download status' $RET_OK $status

		retval=$RET_FAIL
		download_data_xml 0 "movie file.avi" 666 "/path/to/xml file.xml" 'ENG' 'tw' 'pass' >/dev/null 2>&1
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

	extract_subs_xml "$bogus_file" "$subs" >/dev/null 2>&1
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_cmd_7z="false"
	g_tools=( 'awk=1' )
	extract_subs_xml "$g_assets_path/$g_ut_root/example.xml" "$subs" >/dev/null 2>&1
	status=$?
	assertEquals "checking for 7z failure" $RET_FAIL "$status"

	g_cmd_7z="7za"
	extract_subs_xml "$g_assets_path/$g_ut_root/example.xml" "$subs" >/dev/null 2>&1
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

	extract_nfo_xml "$bogus_file" "$nfo" >/dev/null 2>&1
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_tools=( 'awk=1' )
	extract_nfo_xml "$g_assets_path/$g_ut_root/example.xml" "$nfo" >/dev/null 2>&1
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

	extract_nfo_xml "$bogus_file" "$cover" >/dev/null 2>&1
	status=$?
	assertEquals "checking for success status - failure" $RET_UNAV "$status"

	g_tools=( 'awk=1' )
	extract_nfo_xml "$g_assets_path/$g_ut_root/example.xml" "$cover" >/dev/null 2>&1
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

	download_item_xml "unsupported" >/dev/null 2>&1
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

	download_item_xml "subs" >/dev/null 2>&1
	status=$?
	assertEquals "failure for supported item but get_xml failure" $RET_FAIL "$status"

	retval1=$RET_OK
	download_item_xml "subs" 0 "$moviepath" >/dev/null 2>&1
	status=$?
	assertEquals "failure for supported item but extract_item failure" $RET_FAIL "$status"

	retval2=$RET_OK
	download_item_xml "subs" 0 "$moviepath" >/dev/null 2>&1
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
    download_subs_classic 123 123 "$output_file" PL other "" "" >/dev/null 2>&1
    status=$?
    assertEquals 'verifying wget error' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 404"
    download_subs_classic 123 123 "$output_file" PL other "" "" >/dev/null 2>&1
    status=$?
    assertEquals 'verifying error when 404' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    download_subs_classic 123 123 "$output_file" PL other "" "" >/dev/null 2>&1
    status=$?
    assertEquals 'verifying failure when file down. successfully but file doesnt exist' $RET_FAIL $status

    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo test > "$output_file"
    download_subs_classic 123 123 "$output_file" PL pynapi "" "" >/dev/null 2>&1
    status=$?
    assertEquals 'verifying small file' $RET_FAIL $status
    assertFalse 'check if file has been removed' "[ -s \"$output_file\" ]"

    g_cmd_wget[0]="mocks/wget_log 0 200"
    echo line1 > "$output_file"
    echo line2 >> "$output_file"
    echo line3 >> "$output_file"
    echo line4 >> "$output_file"
    echo line5 >> "$output_file"
    download_subs_classic 123 123 "$output_file" PL pynapi "" "" >/dev/null 2>&1
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
	get_nfo >/dev/null 2>&1
	status=$?
	assertEquals "failure for non API3 id" $RET_FAIL "$status"

	g_system[2]='NapiProjekt'
	get_nfo >/dev/null 2>&1
	status=$?
	assertEquals "failure for due to download_item_xml fail" $RET_FAIL "$status"

	retval=$RET_OK
	get_nfo >/dev/null 2>&1
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

	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root" >/dev/null 2>&1
	rv=$?
	assertEquals 'nothing available' 0 $rv

	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[0]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root" >/dev/null 2>&1
	rv=$?
	assertEquals '0 available, checking rv' 2 $rv
	assertTrue '0 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[1]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[0]}" 2> /dev/null
	unlink "$g_assets_path/$g_ut_root/${g_pf[1]}" 2> /dev/null

	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[3]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root" >/dev/null 2>&1
	rv=$?
	assertEquals '3 available, checking rv' 2 $rv
	assertTrue '3 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[1]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[0]}" 2> /dev/null
	unlink "$g_assets_path/$g_ut_root/${g_pf[3]}" 2> /dev/null

	g_sub_format='subrip'
	echo "fake_subs" > "$g_assets_path/$g_ut_root/${g_pf[6]}"
	check_subs_presence "video.avi" "$g_assets_path/$g_ut_root" >/dev/null 2>&1
	rv=$?
	assertEquals '6 available, checking rv' 1 $rv
	assertTrue '6 available, checking file' "[ -e \"$g_assets_path/$g_ut_root/${g_pf[7]}\" ]"
	unlink "$g_assets_path/$g_ut_root/${g_pf[6]}" 2> /dev/null
	unlink "$g_assets_path/$g_ut_root/${g_pf[7]}" 2> /dev/null

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

	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "not_existing_file.txt" "ORIG_subs.txt" "converted.txt" >/dev/null 2>&1
	status=$?
	assertEquals 'failure on non existing subs' $RET_FAIL $status

	echo "[529][586]line1" > "$g_assets_path/$g_ut_root/subs.txt"
	echo "[610][639]line2" >> "$g_assets_path/$g_ut_root/subs.txt"
	echo "[1059][1084]line3" >> "$g_assets_path/$g_ut_root/subs.txt"

	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" >/dev/null 2>&1
	status=$?
	assertEquals 'failure on default subs format' $RET_FAIL $status

	g_delete_orig=1
	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" >/dev/null 2>&1
	status=$?
	assertFalse 'checking if orig is deleted if failure' "[ -e \"$g_assets_path/$g_ut_root/ORIG_subs.txt\" ]"

	g_sub_format='subrip'
	convert_format "$g_assets_path/$g_ut_root/av1 file.avi" "subs.txt" "ORIG_subs.txt" "converted.txt" >/dev/null 2>&1
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

	g_stats=( 1 2 3 4 5 6 7 8 9 12 15 )
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

	output=$(print_stats | grep -w COVER_SKIP | rev | cut -d ' ' -f 1)
	assertEquals 'COVER_SKIP stats' 7 ${output:-0}

	output=$(print_stats | grep -w NFO_OK | rev | cut -d ' ' -f 1)
	assertEquals 'NFO_OK stats' 8 ${output:-0}

	output=$(print_stats | grep -w NFO_UNAV | rev | cut -d ' ' -f 1)
	assertEquals 'NFO_UNAV stats' 9 ${output:-0}

	output=$(print_stats | grep -w NFO_SKIP | rev | cut -d ' ' -f 1 | rev)
	assertEquals 'NFO_SKIP stats' 12 ${output:-0}

	output=$(print_stats | grep -w TOTAL | rev | cut -d ' ' -f 1 | rev)
	assertEquals 'TOTAL stats' 15 ${output:-0}

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


test_obtain_others() {
    _save_globs

    obtain_others "bogus" >/dev/null 2>&1
    status=$?
    assertEquals 'failure on bogus obtain_others request' $RET_FAIL "$status"

    g_nfo=0
    g_cover=0
    obtain_others "cover" >/dev/null 2>&1
    status=$?
    assertEquals 'no_act for cover and g_cover = 0 request' $RET_NOACT "$status"

    obtain_others "nfo" >/dev/null 2>&1
    status=$?
    assertEquals 'no_act for nfo and g_nfo = 0 request' $RET_NOACT "$status"

    (

    g_nfo=1
    g_cover=1

    nfo_retval=$RET_OK
    get_nfo() {
        return $nfo_retval
    }
    export -f get_nfo

    cover_retval=$RET_OK
    get_cover() {
        return $cover_retval
    }
    export -f get_cover

    obtain_others "cover" >/dev/null 2>&1
    status=$?
    assertEquals 'OK for cover and g_cover = 1 request' $RET_OK "$status"

    obtain_others "nfo" >/dev/null 2>&1
    status=$?
    assertEquals 'OK for nfo and g_nfo = 1 request' $RET_OK "$status"

    assertEquals 'check nfo stats' 1 "${g_stats[7]}"
    assertEquals 'check cover stats' 1 "${g_stats[4]}"

    )

    _restore_globs
}
