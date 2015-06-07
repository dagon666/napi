#!/bin/bash

#
# @brief default extension used for subtitle files
#
# Will be forced to lowercase when assigned
#
declare -l __g_settings_default_extension='txt'

#
# @brief prefix for the original file - before the conversion
#
declare __g_settings_orig_prefix='ORIG_'

#
# @brief get extension for given subtitle format
#
common_get_sub_ext() {
    local status=0
    declare -a fmte=( 'subrip=srt' 'subviewer2=sub' )

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    lookup_value "$1" ${fmte[@]}
    status=$?

    # shellcheck disable=SC2086
    [ "$status" -ne $RET_OK ] && settings_get default_extension

    # shellcheck disable=SC2086
    return $RET_OK
}
