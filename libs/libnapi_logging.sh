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
#  http://pcarduino.blogspot.co.ul
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

################################## GLOBALS #####################################

declare -r ___g_output_verbosity=0
declare -r ___g_output_logfile=1
declare -r ___g_output_forkid=2
declare -r ___g_output_msgcnt=3
declare -r ___g_output_owrt=4

#
# 0 - verbosity
# - 0 - be quiet (prints only errors)
# - 1 - standard level (prints errors, warnings, statuses & msg)
# - 2 - info level (prints errors, warnings, statuses, msg & info's)
# - 3 - debug level (prints errors, warnings, statuses, msg, info's and debugs)
#
# 1 - the name of the file containing the output
#
# 2 - fork id
# 3 - msg counter
# 4 - flag defining whether to overwrite the log or not
#
declare -a ___g_output=( 1 'none' 0 1 0 )

################################################################################

#
# @brief produce output
#
_logging_blit() {
    printf "%02d:%04d %s\n" \
        "${___g_output[$___g_output_forkid]}" \
        "${___g_output[$___g_output_msgcnt]}" "$*"
    ___g_output[$___g_output_msgcnt]=$(( ___g_output[___g_output_msgcnt] + 1 ))
}

#
# @brief redirect errors to standard error output
#
_logging_toStderr() {
    if [ -n "${___g_output[$___g_output_logfile]}" ] &&
        [ "${___g_output[$___g_output_logfile]}" != "none" ]; then
        cat
    else
        cat > /dev/stderr
    fi
}

#
# @brief set insane verbosity
#
_logging_debugInsane() {
    # PS4='+ [${LINENO}] ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    # set -x
    :
}

#
# @brief verify if given verbosity level is in supported range
#
_logging_verifyVerbosity() {
    # make sure first that the printing functions will work
    logging_debug $LINENO $'sprawdzam poziom gadatliwosci'
    case "${___g_output[$___g_output_verbosity]}" in
        "0"|"1"|"2"|"3"|"4")
            ;;

        *)
            logging_error \
                $"poziom gadatliwosci moze miec jedynie wartosci z zakresu (0-4)"
            # shellcheck disable=SC2086
            return $G_RETPARAM
            ;;
    esac
}

#
# @brief verify if given logging file can be used
#
_logging_verifyLogFile() {
    logging_debug $LINENO $'sprawdzam logfile'
    if [ -e "${___g_output[$___g_output_logfile]}" ] &&
       [ "${___g_output[$___g_output_logfile]}" != "none" ]; then

        # whether to fail or not ?
        if [ "${___g_output[$___g_output_owrt]}" -eq 0 ]; then
            logging_error \
                $"plik loga istnieje, podaj inna nazwe pliku aby nie stracic danych"
            # shellcheck disable=SC2086
            return $G_RETPARAM
        else
            logging_warning $"plik loga istnieje, zostanie nadpisany"
        fi
    fi

    # shellcheck disable=SC2086
    return $G_RETOK
}

#
# @brief set log overwrite to given value
#
_logging_setLogOverwrite() {
    ___g_output[$___g_output_owrt]=$(wrappers_ensureNumeric_SO "$1")
}

#
# @brief redirect stdout to logfile
#
_logging_redirectToLogFile() {
    if [ -n "${___g_output[$___g_output_logfile]}" ] &&
        [ "${___g_output[$___g_output_logfile]}" != "none" ]; then

        # truncate
        cat /dev/null > "${___g_output[$___g_output_logfile]}"

        # append instead of ">" to assure that children won't mangle the output
        exec 3>&1 4>&2 1>> "${___g_output[$___g_output_logfile]}" 2>&1
    fi
}

#
# @brief redirect output to stdout
#
_logging_redirectToStdout() {
    # restore everything
    [ -n "${___g_output[$___g_output_logfile]}" ] &&
        [ "${___g_output[$___g_output_logfile]}" != "none" ] && {
        exec 1>&3 2>&4 4>&- 3>&-
    }
}

################################################################################

#
# @brief print a debug verbose information
#
logging_debug() {
    local line="${1:-0}" && shift
    [ "${___g_output[$___g_output_verbosity]}" -ge 3 ] &&
        _logging_blit "--- $line: $*"
    return $G_RETOK
}

#
# @brief print information
#
logging_info() {
    local line=${1:-0} && shift
    [ "${___g_output[$___g_output_verbosity]}" -ge 2 ] &&
        _logging_blit "-- $line: $*"
    return $G_RETOK
}

#
# @brief print warning
#
logging_warning() {
    logging_status "WARNING" "$*"
}

#
# @brief print error message
#
logging_error() {
    local tmp="${___g_output[$___g_output_verbosity]}"
    ___g_output[$___g_output_verbosity]=1
    logging_status "ERROR" "$*" | _logging_toStderr
    ___g_output[$___g_output_verbosity]="$tmp"
}

#
# @brief print standard message
#
logging_msg() {
    [ "${___g_output[$___g_output_verbosity]}" -ge 1 ] && _logging_blit "- $*"
}

#
# @brief print status type message
#
logging_status() {
    [ "${___g_output[$___g_output_verbosity]}" -ge 1 ] &&
        _logging_blit "$1 -> $2"
}

################################################################################

#
# @brief set the output verbosity level
#
# Automatically fall back to standard level if given level is out of range.
#
logging_setVerbosity() {
    ___g_output[$___g_output_verbosity]=$(wrappers_ensureNumeric_SO "$1")
    _logging_verifyVerbosity || ___g_output[$___g_output_verbosity]=1
    [ ${___g_output[$___g_output_verbosity]} -eq 4 ] && _logging_debugInsane
}

#
# @brief get the output verbosity level
#
logging_getVerbosity_SO() {
    echo "${___g_output[$___g_output_verbosity]}"
}

#
# @brief set message counter
#
logging_setMsgCounter() {
    ___g_output[$___g_output_msgcnt]=$(wrappers_ensureNumeric_SO "$1")
}

#
# @brief get message counter
#
logging_getMsgCounter_SO() {
    echo "${___g_output[$___g_output_msgcnt]}"
}

#
# @brief set log overwrite to true
#
logging_raiseLogOverwrite() {
    _logging_setLogOverwrite 1
}

#
# @brief set log overwrite to false
#
logging_clearLogOverwrite() {
    _logging_setLogOverwrite 0
}

#
# @brief set fork id
#
logging_setForkId() {
    ___g_output[$___g_output_forkid]=$(wrappers_ensureNumeric_SO "$1")
}

#
# @brief get fork id of the current process
#
logging_getForkId_SO() {
    echo "${___g_output[$___g_output_forkid]}"
}

#
# @brief set logging to a file or stdout
#
logging_setLogFile() {
    if [ "${___g_output[$___g_output_logfile]}" != "$1" ]; then
        logging_info $LINENO $"ustawiam STDOUT"
        _logging_redirectToStdout

        ___g_output[$___g_output_logfile]="$1"
        _logging_verifyLogFile || ___g_output[$___GOUTPUT_LOGFILE]="none"
        _logging_redirectToLogFile
    fi
}

################################################################################
