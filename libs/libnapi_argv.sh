#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2017 Tomasz Wisniewski aka
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.uk
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

########################################################################
########################################################################
########################################################################

# globals

___g_argvOutputHandlerType=
___g_argvOutputHandler=
___g_argvErrorMsg=

########################################################################

#
# @brief option dispatcher stub
#
argv_nullDispatcher() {
    return $G_RETOK
}

#
# @brief generic option parser
#
argv_argvParser_GV() {
    local argvDispatcher="${1:-argv_nullDispatcher}"
    shift

    # command line arguments parsing
    while [ $# -gt 0 ]; do
        ___g_argvOutputHandlerType=
        ___g_argvOutputHandler=
        ___g_argvErrorMsg=

        logging_debug $LINENO $"dispatcher opcji:" \
            "[$argvDispatcher]"

        "$argvDispatcher" "$@" || {
            local s=$?
            logging_debug $LINENO $"blad dispatchera opcji"
            return $s
        }

        logging_debug $LINENO $"wywoluje handler" \
            "[$___g_argvOutputHandler]" $"typu" \
            "[$___g_argvOutputHandlerType]"

        shift

        # check if there's anything to do
        [ -z "$___g_argvOutputHandlerType" ] ||
            [ -z "$___g_argvOutputHandler" ] && continue

        # check if there's any argument provided
        # shellcheck disable=SC2086
        [ -z "$1" ] && {
            logging_error "$msg"
            return $G_RETFAIL
        }

        case "$___g_argvOutputHandlerType" in
            "var"|"variable"|"v")
                # set the variable's value
                eval "${___g_argvOutputHandler}=\$1"
                ;;
            "func"|"function"|"f")
                logging_debug $LINENO $"wywoluje setter" "[$___g_argvOutputHandler]"
                # I want the splitting to occur to be able to hard-code
                # arguments to function
                $___g_argvOutputHandler "$1"
                ;;
            *)
                ;;
        esac
        shift
    done
}

# EOF
