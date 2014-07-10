#!/bin/bash

################################################################################

declare -r SHUNIT_TESTS=1

#
# path to the test env root
#
declare -r g_assets_path="${1:-/home/vagrant}"
shift

#
# installation directory of the napi bundle
#
declare -r g_install_path="$g_assets_path/napi_bin"

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

declare -a _cp_g_output=()
declare -a _cp_g_abbrev=()
declare -a _cp_g_system=()
declare -a _cp_g_cred=()
declare -a _cp_g_paths=()
declare -a _cp_g_files=()
declare -a _cp_g_pf=()
declare -a _cp_g_stats=()
declare -a _cp_g_tools=()
declare -a _cp_g_tools_fps=()
declare -a _cp_g_cmd_wget=()

declare -a _cp_g_inf=()
declare -a _cp_g_outf=()

_save_globs() {
	# save arrays
	_cp_g_output=( "${g_output[@]}" )
	_cp_g_abbrev=( "${g_abbrev[@]}" )
	_cp_g_system=( "${g_system[@]}" )
	_cp_g_cred=( "${g_cred[@]}" )
	_cp_g_paths=( "${g_paths[@]}" )
	_cp_g_files=( "${g_files[@]}" )
	_cp_g_pf=( "${g_pf[@]}" )
	_cp_g_stats=( "${g_stats[@]}" )
	_cp_g_tools=( "${g_tools[@]}" )
	_cp_g_tools_fps=( "${g_tools_fps[@]}" )
	_cp_g_cmd_wget=( "${g_cmd_wget[@]}" )

	# save variables
	_cp_g_orig_prefix="$g_orig_prefix"
	_cp_g_min_size="$g_min_size"
	_cp_g_cover="$g_cover"
	_cp_g_nfo="$g_nfo"
	_cp_g_skip="$g_skip"
	_cp_g_delete_orig="$g_delete_orig"
	_cp_g_charset="$g_charset"
	_cp_g_lang="$g_lang"
	_cp_g_default_ext="$g_default_ext"
	_cp_g_sub_format="$g_sub_format"
	_cp_g_fps_tool="$g_fps_tool"
	_cp_g_hook="$g_hook"
	_cp_g_stats_print="$g_stats_print"
	_cp_g_cmd_stat="$g_cmd_stat"
	_cp_g_cmd_md5="$g_cmd_md5"
	_cp_g_cmd_cp="$g_cmd_cp"
	_cp_g_cmd_unlink="$g_cmd_unlink"
	_cp_g_cmd_7z="$g_cmd_7z"
}

_restore_globs() {
	# save arrays
	g_output=( "${_cp_g_output[@]}" )
	g_abbrev=( "${_cp_g_abbrev[@]}" )
	g_system=( "${_cp_g_system[@]}" )
	g_cred=( "${_cp_g_cred[@]}" )
	g_paths=( "${_cp_g_paths[@]}" )
	g_files=( "${_cp_g_files[@]}" )
	g_pf=( "${_cp_g_pf[@]}" )
	g_stats=( "${_cp_g_stats[@]}" )
	g_tools=( "${_cp_g_tools[@]}" )
	g_tools_fps=( "${_cp_g_tools_fps[@]}" )
	g_cmd_wget=( "${_cp_g_cmd_wget[@]}" )

	# save variables
	g_orig_prefix="$_cp_g_orig_prefix"
	g_min_size="$_cp_g_min_size"
	g_cover="$_cp_g_cover"
	g_nfo="$_cp_g_nfo"
	g_skip="$_cp_g_skip"
	g_delete_orig="$_cp_g_delete_orig"
	g_charset="$_cp_g_charset"
	g_lang="$_cp_g_lang"
	g_default_ext="$_cp_g_default_ext"
	g_sub_format="$_cp_g_sub_format"
	g_fps_tool="$_cp_g_fps_tool"
	g_hook="$_cp_g_hook"
	g_stats_print="$_cp_g_stats_print"
	g_cmd_stat="$_cp_g_cmd_stat"
	g_cmd_md5="$_cp_g_cmd_md5"
	g_cmd_cp="$_cp_g_cmd_cp"
	g_cmd_unlink="$_cp_g_cmd_unlink"
	g_cmd_7z="$_cp_g_cmd_7z"
}

_save_subotage_globs() {
	# save arrays
	_cp_g_output=( "${g_output[@]}" )
	_cp_g_inf=( "${g_inf[@]}" )
	_cp_g_outf=( "${g_outf[@]}" )

	_cp_g_getinfo="$g_getinfo"
	_cp_g_lastingtime="$g_lastingtime"
	_cp_g_ipc_file="$g_ipc_file"
	_cp_g_cmd_cp="$g_cmd_cp"
	_cp_g_cmd_unlink="$g_cmd_unlink"
	_cp_g_cmd_awk="$g_cmd_awk"
}

_restore_subotage_globs() {
	# save arrays
	g_output=( "${_cp_g_output[@]}" )
	g_inf=( "${_cp_g_inf[@]}" )
	g_outf=( "${_cp_g_outf[@]}" )

	g_getinfo="$_cp_g_getinfo"
	g_lastingtime="$_cp_g_lastingtime"
	g_ipc_file="$_cp_g_ipc_file"
	g_cmd_cp="$_cp_g_cmd_cp"
	g_cmd_unlink="$_cp_g_cmd_unlink"
	g_cmd_awk="$_cp_g_cmd_awk"
}

################################################################################

