#!/bin/bash

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

_prepare_env() {
    # create env
    mkdir -p "$g_assets_path/$g_ut_root"
    mkdir -p "$g_assets_path/$g_ut_root/bin"
    mkdir -p "$g_assets_path/$g_ut_root/sub dir"

	export PATH="$g_assets_path/$g_ut_root/bin:$PATH"
}

_purge_env() {
    # clear the env
    rm -rfv "$g_assets_path/$g_ut_root"
}

################################################################################
