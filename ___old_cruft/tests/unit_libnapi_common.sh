
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
