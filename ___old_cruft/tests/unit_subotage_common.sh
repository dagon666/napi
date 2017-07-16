#!/bin/bash

################################################################################

#
# tests env setup
#
oneTimeSetUp() {
	_prepare_env
    cp -rv "$g_assets_path/napi_test_files/subtitles" "$g_assets_path/$g_ut_root/"
}


#
# tests env tear down
#
oneTimeTearDown() {
	_purge_env
}

################################################################################

test_guess_format() {
	_save_subotage_globs

	declare -a files=( \
		"1_inline_subrip.txt" \
		"1_microdvd.txt" \
		"1_mpl2.txt" \
		"1_subviewer2.sub" \
		"1_tmplayer.txt" \
		"2_microdvd.txt" \
		"2_mpl2.txt" \
		"2_newline_subrip.txt" \
		"2_tmplayer.txt" \
		"3_microdvd.txt" \
		"3_subrip.txt" \
		"3_tmplayer.txt" \
		"4_tmplayer.txt" \
	   	)
	
	declare -a formats=( \
		"subrip 1 inline" \
		"microdvd 1 23.976" \
		"mpl2 1" \
		"subviewer2 11 1" \
		"tmplayer 1 2 0 :" \
		"microdvd 1" \
		"mpl2 1" \
		"subrip 1 newline" \
		"tmplayer 1 1 0 :" \
		"microdvd 1 23.976" \
		"subrip 5 newline" \
		"tmplayer 1 2 1 :" \
		"tmplayer 1 2 1 =" \
		)

	local idx=0
	local path=''
	local format=''
	local status=0

	for i in "${files[@]}"; do
		path="$g_assets_path/$g_ut_root/subtitles/$i"
		format=$(guess_format "$path")
		status=$?

		assertEquals "checking exit code" $RET_OK "$status"
		assertEquals "checking details for $i" "${formats[$idx]}" "$format"

		idx=$(( idx + 1 ))
	done
	_restore_subotage_globs
	return 0
}


test_correct_overlaps() {
	local tmp=$(mktemp tmp.XXXXXXXX)
	local status=0
	local data=''
	declare -a adata=()
	_save_subotage_globs

    # should reject unsupported format
	echo "xxx" > "$tmp"
	echo "junk" >> "$tmp"
	correct_overlaps "$tmp" 2>&1 > /dev/null
	status=$?
	assertEquals "xxx not supported" $RET_NOACT "$status"

	echo "hms" > "$tmp"
    echo "1 00:05:56 00:05:59 Zmierzasz na" >> "$tmp"
    echo "2 00:05:58 00:06:01 Polnoc." >> "$tmp"
    echo "3 00:06:00 00:06:03 Wskakuj" >> "$tmp"
    echo "4 00:06:02 00:06:05 Upewnie sie, | ze znajdziesz droge" >> "$tmp"
    echo "5 00:06:17 00:06:20 - Dokad zmierzasz? | - Portland" >> "$tmp"
    echo "6 00:06:20 00:06:23 Portland jest na poludniu mowiles, | ze zmierzasz na polnoc" >> "$tmp"
	correct_overlaps "$tmp" 2>&1 > /dev/null
	status=$?
	assertEquals "hms status ok" $RET_OK "$status"

	data=$(head -n 1 "$tmp" | tail -n 1)
    assertEquals 'check for file type (hms)' "hms" "$data"

	data=$(head -n 2 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '1 (hms) check counter' 1 "${adata[0]}"
	assertEquals '1 (hms) check start_time' "00:05:56" "${adata[1]}"
	assertEquals '1 (hms) check end_time' "00:05:58" "${adata[2]}"
	assertEquals '1 (hms) check content' "Zmierzasz" "${adata[3]}"

	data=$(head -n 3 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '2 (hms) check counter' 2 "${adata[0]}"
	assertEquals '2 (hms) check start_time' "00:05:58" "${adata[1]}"
	assertEquals '2 (hms) check end_time' "00:06:00" "${adata[2]}"
	assertEquals '2 (hms) check content' "Polnoc." "${adata[3]}"

	data=$(head -n 4 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '3 (hms) check counter' 3 "${adata[0]}"
	assertEquals '3 (hms) check start_time' "00:06:00" "${adata[1]}"
	assertEquals '3 (hms) check end_time' "00:06:02" "${adata[2]}"
	assertEquals '3 (hms) check content' "Wskakuj" "${adata[3]}"

	data=$(head -n 5 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '4 (hms) check counter' 4 "${adata[0]}"
	assertEquals '4 (hms) check start_time' "00:06:02" "${adata[1]}"
	assertEquals '4 (hms) check end_time' "00:06:05" "${adata[2]}"
	assertEquals '4 (hms) check content' "Upewnie" "${adata[3]}"
	unlink "$tmp"

    # === hmsms

	echo "hmsms" > "$tmp"
    echo "1 00:05:56.000 00:05:59.000 Zmierzasz na polnoc" >> "$tmp"
    echo "2 00:05:58.000 00:06:01.000 Polnoc." >> "$tmp"
    echo "3 00:06:00.000 00:06:03.000 Wskakuj" >> "$tmp"
    echo "4 00:06:02.000 00:06:05.000 Upewnie sie, | ze znajdziesz droge." >> "$tmp"
	correct_overlaps "$tmp" 2>&1 > /dev/null
	status=$?
	assertEquals "hmsms status ok" $RET_OK "$status"

	data=$(head -n 1 "$tmp" | tail -n 1)
    assertEquals 'check for file type (hmsms)' "hmsms" "$data"

	data=$(head -n 2 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '1 (hmsms) check counter' 1 "${adata[0]}"
	assertEquals '1 (hmsms) check start_time' "00:05:56.000" "${adata[1]}"
	assertEquals '1 (hmsms) check end_time' "00:05:58.000" "${adata[2]}"
	assertEquals '1 (hmsms) check content' "Zmierzasz" "${adata[3]}"

	data=$(head -n 3 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '2 (hmsms) check counter' 2 "${adata[0]}"
	assertEquals '2 (hmsms) check start_time' "00:05:58.000" "${adata[1]}"
	assertEquals '2 (hmsms) check end_time' "00:06:00.000" "${adata[2]}"
	assertEquals '2 (hmsms) check content' "Polnoc." "${adata[3]}"

	data=$(head -n 4 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '3 (hmsms) check counter' 3 "${adata[0]}"
	assertEquals '3 (hmsms) check start_time' "00:06:00.000" "${adata[1]}"
	assertEquals '3 (hmsms) check end_time' "00:06:02.000" "${adata[2]}"
	assertEquals '3 (hmsms) check content' "Wskakuj" "${adata[3]}"

	data=$(head -n 5 "$tmp" | tail -n 1)
	adata=( $data )
    assertEquals '4 (hmsms) check counter' 4 "${adata[0]}"
	assertEquals '4 (hmsms) check start_time' "00:06:02.000" "${adata[1]}"
	assertEquals '4 (hmsms) check end_time' "00:06:05.000" "${adata[2]}"
	assertEquals '4 (hmsms) check content' "Upewnie" "${adata[3]}"
	unlink "$tmp"

    # === secs

	echo "secs" > "$tmp"
	echo "1 10 20 line1" >> "$tmp"
	echo "2 18 25 overlap1" >> "$tmp"
	echo "3 23 28 overlap2" >> "$tmp"

	correct_overlaps "$tmp" 2>&1 > /dev/null
	status=$?
	assertEquals "secs status ok" $RET_OK "$status"

	data=$(head -n 1 "$tmp" | tail -n 1)
	assertEquals 'check for file type' "secs" "$data"

	data=$(head -n 2 "$tmp" | tail -n 1)
	adata=( $data )
	assertEquals '1 check counter' 1 "${adata[0]}"
	assertEquals '1 check start_time' "10" "${adata[1]}"
	assertEquals '1 check end_time' "18" "${adata[2]}"
	assertEquals '1 check content' "line1" "${adata[3]}"

	data=$(head -n 3 "$tmp" | tail -n 1)
	adata=( $data )
	assertEquals '2 check counter' 2 "${adata[0]}"
	assertEquals '2 check start_time' "18" "${adata[1]}"
	assertEquals '2 check end_time' "23" "${adata[2]}"
	assertEquals '2 check content' "overlap1" "${adata[3]}"

	data=$(head -n 4 "$tmp" | tail -n 1)
	adata=( $data )
	assertEquals '3 check counter' 3 "${adata[0]}"
	assertEquals '3 check start_time' "23" "${adata[1]}"
	assertEquals '3 check end_time' "28" "${adata[2]}"
	assertEquals '3 check content' "overlap2" "${adata[3]}"

	_restore_subotage_globs
	unlink "$tmp"
	return 0
}

test_verify_format() {
	local status=0

	verify_format "bogus_format"
	status=$?
	assertEquals "failure for bogus format" $RET_PARAM "$status"

	declare -a formats=( "subrip" "microdvd" "subviewer2" "mpl2" "tmplayer" )
	for i in "${formats[@]}"; do
		verify_format "$i"
		status=$?
		assertEquals "$i format" $RET_OK "$status"
	done
	return 0
}

test_verify_fps() {
	local status=0

	verify_fps "23,456"
	status=$?
	assertEquals "fps format with comma" $RET_PARAM "$status"

	verify_fps "23.456"
	status=$?
	assertEquals "fps format with period" $RET_OK "$status"

	verify_fps "23"
	status=$?
	assertEquals "fps format without period" $RET_OK "$status"
	return 0
}

test_verify_argv() {
	local status=0
	_save_subotage_globs

	g_inf[$___PATH]="none"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect input" $RET_PARAM "$status"

	echo "test" > "input.txt"

	g_inf[$___PATH]="input.txt"
	g_outf[$___PATH]="none"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect output" $RET_PARAM "$status"

	g_inf[$___PATH]="input.txt"
	g_outf[$___PATH]="output.txt"
	g_inf[$___FORMAT]="bogus"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect input format" $RET_PARAM "$status"

	g_inf[$___FORMAT]="microdvd"
	g_outf[$___FORMAT]="bogus"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect output format" $RET_PARAM "$status"

	g_outf[$___FORMAT]="subrip"
	g_inf[$___FPS]="25fps"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect input fps" $RET_PARAM "$status"

	g_outf[$___FORMAT]="subrip"
	g_inf[$___FPS]="25"
	g_outf[$___FPS]="25fps"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "incorrect output fps" $RET_PARAM "$status"

	g_outf[$___FORMAT]="subrip"
	g_inf[$___FPS]="25"
	g_outf[$___FPS]="25"
	verify_argv >/dev/null 2>&1 
	status=$?
	assertEquals "correct settings" $RET_OK "$status"

	unlink "input.txt"
	_restore_subotage_globs
	return 0
}


test_detect_microdvd_fps() {
	local status=0

	declare -a data=( \
	   "{1}{1}23.976fps" \
	   "{1}{72}movie info: XVID  720x304 23.976fps 1.4 GB" \
	   "{1}{72}movie info: XVID  720x304 25.0 1.4 GB" \
	   "{1}{72}30fps" \
	   "{1}{72}30" \
   	   )

	declare -a res=( \
	   "23.976" \
	   "23.976" \
	   "25.0" \
	   "30" \
	   "30"
   	   )

	local idx=0
	local fps=0

	for i in "${data[@]}"; do
		fps=$(echo "$i" | detect_microdvd_fps)
		assertEquals "checking fps $idx" "${res[$idx]}" "$fps"
		idx=$(( idx + 1 ))
	done	
	return 0
}


test_correct_fps() {
	_save_subotage_globs

	g_inf[$___FPS]=25
	g_outf[$___FPS]=0
	correct_fps
	assertEquals "checking if fps has been synced" "${g_inf[$___FPS]}" "${g_outf[$___FPS]}"


	g_inf[$___FPS]=25
	g_outf[$___FPS]=23
	correct_fps
	assertEquals "checking if fps has not been synced" 23 "${g_outf[$___FPS]}"

	_restore_subotage_globs
	return 0
}


test_check_if_conv_needed() {
	local status=0

	_save_subotage_globs

	g_inf[$___FORMAT]="subrip"
	g_outf[$___FORMAT]="SUBRIP"
	check_if_conv_needed
	status=$?
	assertEquals "conversion not needed rv check" $RET_NOACT "$status"

	g_inf[$___FORMAT]="subrip"
	g_outf[$___FORMAT]="mpl2"
	check_if_conv_needed
	status=$?
	assertEquals "conversion needed rv check" $RET_OK "$status"

	g_inf[$___FORMAT]="microdvd"
	g_outf[$___FORMAT]="microdvd"

	g_inf[$___FPS]="23.456"
	g_outf[$___FPS]="23.456"
	check_if_conv_needed 2>&1 > /dev/null
	status=$?
	assertEquals "conversion not needed udvd same fps" $RET_NOACT "$status"
	
	g_inf[$___FPS]="23.456"
	g_outf[$___FPS]="29.756"
	check_if_conv_needed
	status=$?
	assertEquals "conversion needed udvd != fps" $RET_OK "$status"

	_restore_subotage_globs
	return 0
}


test_print_format_summary() {
	local presence=0
	_save_subotage_globs

	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertEquals "checking summary prefix" 0 "$presence"

	g_output[$___VERBOSIRTY]=2
	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertTrue "checking summary prefix" "[ $presence -gt 0 ]"

	g_output[$___VERBOSIRTY]=1
	g_getinfo=1
	presence=$(print_format_summary "PREFIX_" "some_file" | grep -c "PREFIX_")
	assertTrue "checking summary prefix" "[ $presence -gt 0 ]"

	_restore_subotage_globs
	return 0
}


test_convert_formats() {
	local status=0
	local input=$(mktemp input.XXXXXXXX)

	_save_subotage_globs

	(
	reader_rv=$RET_FAIL
	writer_rv=$RET_FAIL

	_test_reader() {
		return $reader_rv
	}
	export -f _test_reader

	_test_writer() {
		return $writer_rv
	}
	export -f _test_writer

	correct_overlaps() {
		return 0
	}
	export -f correct_overlaps

	g_inf[$___PATH]="$input"

	convert_formats "_test_reader" "_test_writer" >/dev/null 2>&1 
	status=$?
	assertEquals "reader failure" $RET_FAIL "$status"

	reader_rv=$RET_OK
	convert_formats "_test_reader" "_test_writer" >/dev/null 2>&1 
	status=$?
	assertEquals "writer failure" $RET_FAIL "$status"
		
	writer_rv=$RET_OK
	convert_formats "_test_reader" "_test_writer" >/dev/null 2>&1 
	status=$?
	assertEquals "all ok" $RET_OK "$status"
	)
	
	unlink "$input"
	_restore_subotage_globs
	return 0
}
