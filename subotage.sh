#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

declare -r g_revision="v1.1.0"

################################################################################
################################################################################
#    subotage - universal subtitle converter
#    Copyright (C) 2010  Tomasz Wisniewski <tomasz@wisni3wski@gmail.com>

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
################################################################################

# verify presence of the napi_common library
declare -r NAPI_COMMON_PATH=
if [ -z "$NAPI_COMMON_PATH" ] || [ ! -e "${NAPI_COMMON_PATH}/napi_common.sh" ]; then
	echo "napi.sh i subotage.sh nie zostaly poprawnie zainstalowane"
	echo "uzyj skryptu install.sh (install.sh --help - pomoc)"
	echo "aby zainstalowac napi.sh w wybranym katalogu"
	exit -1
fi

# source the common routines
. "${NAPI_COMMON_PATH}/"napi_common.sh

################################################################################

#
# @brief prints the help & options overview
#
usage() {
	return $RET_OK
}

################################################################################

#
# @brief main function 
# 
main() {
    # first positional
    local arg1="${1:-}"

    # if no arguments are given, then print help and exit
    [ $# -lt 1 ] || [ "$arg1" = "--help" ] || [ "$arg1" = "-h" ] && 
        usage &&
        return $RET_BREAK
}


# call the main
[ "${SHUNIT_TESTS:-0}" -eq 0 ] && main "$@"

# EOF
