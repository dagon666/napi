
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
