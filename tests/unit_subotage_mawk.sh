#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

declare -r SHUNIT_TESTS_AWK="/usr/bin/mawk"

echo "====================================="
echo "subotage unit tests with mawk"
echo "====================================="

. ./unit_subotage_common.sh

suite() {
	suite_addTest test_check_format_microdvd
	suite_addTest test_check_format_mpl2
	suite_addTest test_check_format_subrip
	suite_addTest test_check_format_subviewer2
	suite_addTest test_check_format_tmplayer
	suite_addTest test_read_format_subviewer2
	suite_addTest test_read_format_tmplayer
	suite_addTest test_read_format_microdvd
	suite_addTest test_read_format_mpl2
	suite_addTest test_read_format_subrip
	suite_addTest test_write_format_microdvd
	suite_addTest test_write_format_mpl2
	suite_addTest test_write_format_tmplayer
	suite_addTest test_write_format_subviewer2
	suite_addTest test_write_format_subrip
	suite_addTest test_guess_format
	suite_addTest test_correct_overlaps
	suite_addTest test_list_formats
	suite_addTest test_usage
	suite_addTest test_parse_argv
	suite_addTest test_verify_format
	suite_addTest test_verify_fps
	suite_addTest test_verify_argv
	suite_addTest test_detect_microdvd_fps
	suite_addTest test_correct_fps
	suite_addTest test_check_if_conv_needed
	suite_addTest test_print_format_summary
	suite_addTest test_convert_formats
	suite_addTest test_process_file
	suite_addTest test_create_output_summary
}

# shunit call
. shunit2

