#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

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
    echo
	echo "napi.sh i subotage.sh nie zostaly poprawnie zainstalowane"
	echo "uzyj skryptu install.sh (install.sh --help - pomoc)"
	echo "aby zainstalowac napi.sh w wybranym katalogu"
    echo
	exit -1
fi

# source the common routines
. "${NAPI_COMMON_PATH}/"napi_common.sh

################################################################################

#
# some constants
#
declare -r ___PATH=0
declare -r ___FORMAT=1
declare -r ___FPS=2

################################################################################

#
# input details
# 0 - file path
# 1 - format
# 2 - fps
#
declare -a g_inf=( 'none' 'none' '23.98' )

#
# input details
# 0 - file path
# 1 - format
# 2 - fps
#
declare -a g_outf=( 'none' 'subrip' '23.98' )

#
# @brief if set then getinfo only and exit
#
g_getinfo=0

#
# @brief defines how long the subtitles should last
#
g_lastingtime=3000

#
# supported subtitle file formats
#
declare -ar g_formats=( "microdvd" "mpl2" "subrip" "subviewer" "tmplayer" "fab" )

################################################################################

guess_format() {
    # TODO implement me
    return $RET_OK
}


#
# @brief list supported formats
#
list_formats() {
    local long="${1:-0}"

    local counter=0
    local fmt=''

    # description for every supported file format
    declare -ar desc=( "Format based on frames. Uses given framerate\n\t\t(default is [$g_inf[$___FPS]] fps)" \
                      "[start][stop] format. The unit is time based == 0.1 sec" \
                      "hh.mm.ss,mmm -> hh.mm.ss,mmm format" \
                      "hh:mm:ss timestamp format without the\n\t\tstop time information. Mostly deprecated" \
                      "hh:mm:ss:dd,hh:mm:ss:dd format with header.\n\t\tResolution = 10ms. Header is ignored" \
                      "similar to subviewer, subrip.\n\t\t0022 : 00:05:22:01  00:05:23:50. No header" \
                    ) 

    if [ "$long" -eq 1 ]; then

        # display them
        for fmt in "${g_formats[@]}"; do
            echo -e "\t$fmt - ${desc[$counter]}"
            counter=$(( counter + 1 ))
        done
    else
        echo "${g_formats[@]}"

    fi

    return $RET_OK
}


#
# @brief prints the help & options overview
#
usage() {
    echo    "subotage.sh -i <input_file> -o <output_file> [opcje]"
    echo    "napi bundle version [$g_revision]" 
    echo    "   "
    echo    "Opcje:"
    echo    "============="
    echo    "   -i  | --input <input_file>  - plik wejsciowy (wymagany)"
    echo    " "
    echo    "   -o  | --output <output_file> - plik wyjsciowy (wymagany)"
    echo    " "
    echo    "   -if | --input-format <format> - wymus podany format pliku wejsciowego,"
    echo    "                                   domyslnie, zostanie wykryty autom."
    echo    " "
    echo    "   -of | --output-format <format> - format wyjsciowy (domyslnie subrip)"
    echo    " "
    echo    "   -fi | --fps-input <fps> - fps dla pliku wejsciowego (wazne tylko dla formatu microdvd)"
    echo    "                               (domyslnie: ${g_inf[$___FPS]} fps)"
    echo    " "
    echo    "   -fo | --fps-output <fps> - fps dla pliku wyjsciowego (wazne tylko dla formatu microdvd)"
    echo    "                               (domyslnie: ${g_outf[$___FPS]} fps)"
    echo    " "
    echo    "   -l  | --lasting-time <time in ms> - czas wyswietlania linii napisow w milisekundach"
    echo    "                               (domyslnie: $g_lastingtime ms)"
    echo    " "
    echo    "   -gi | --get-info <input_file> - wyswietl informacje o pliku wejsciowym i zakoncz"
    echo    " "
    echo	"   -gf | --get-formats - wyswietl obslugiwane formaty i wyjdz"
    echo    " "
    echo	"   -gl | --get-formats-long - wyswietl obslugiwane formaty (wraz z opisem) i wyjdz"
    echo    " "
    echo    "   -v  | --verbosity <0..3> - poziom gadatliwosci 0 - cichy, 3 - najgadatliwszy"
    echo    " "
    echo    "Supported formats:"
    
    # list formats
    list_formats 1

    return $RET_OK
}


#
# @brief parse the cli arguments
#
parse_argv() {

    _debug $LINENO "parsowanie argumentow"

    # command line arguments parsing
    while [ $# -gt 0 ]; do
        unset varname
        # when adding a new option, please remember to maintain the same order as generated by usage()
        case "$1" in

            "-i" | "--input") varname="g_inf[$___PATH]"
                msg="nie określono pliku wejsciowego"
                ;;

            "-o" | "--output") varname="g_outf[$___PATH]"
                msg="nie określono pliku wyjsciowego"
                ;;

            # input format
            "-if" | "--input-format") varname="g_inf[$___FORMAT]"
                msg="nie określono formatu wejsciowego"
                ;;

            # output format
            "-of" | "--output-format") varname="g_outf[$___FORMAT]"
                msg="nie określono formatu wyjsciowego"
                ;;

            # fps for input file
            "-fi" | "--fps-input") varname="g_inf[$___FPS]"
                msg="nie określono fps pliku wejsciowego"
                ;;

            # fps for output file
            "-fo" | "--fps-output") varname="g_outf[$___FPS]"
                msg="nie określono fps pliku wyjsciowego"
                ;;

            # lasting time
            "-l" | "--lasting-time") varname="g_lastingtime"
                msg="nie okreslono czasu trwania napisow"
                ;;

            # get formats
            "-gl" | "--get-formats-long")        
                list_formats 1
                return $RET_BREAK
                ;;

            # get formats
            "-gf" | "--get-formats") 
                list_formats
                return $RET_BREAK
                ;;

            # get input info
            "-gi" | "--get-info") g_getinfo=1 ;;

            # verbosity
            "-v" | "--verbosity") varname="g_output[$___VERBOSITY]"
                msg="okresl poziom gadatliwosci (0 - najcichszy, 3 - najbardziej gadatliwy)"
                ;;

            # sanity check for unknown parameters
            *)
                _error "nieznany parametr: [$1]"
                return $RET_BREAK
                ;;
        esac

        # set the global var for simple switches
        # not requiring any further verification
        if [ -n "$varname" ]; then
            shift
            [ -z "$1" ] && _error "$msg" && return $RET_FAIL
            eval "${varname}=\$1"
        fi
        shift
    done
    return $RET_OK
}

#
# @brief verify format
#
verify_format() {
    local format="$1"
    local rv=$RET_PARAM
    local i=''

    [ -z "$format" ] && return $rv

    for i in "${g_formats[@]}"; do
        [ "$format" = "$i" ] && return $RET_OK
    done

    return $rv
}


#
# verify fps
#
verify_fps() {
    local fps="$1"
    local rv=$RET_OK

    local stripped=$(echo "$fps" | tr -d '[\n\.0-9]')
    [ -n "$stripped" ] && rv=$RET_PARAM

    return $rv
}


#
# @brief verify correctness of the argv settings provided
#
verify_argv() {

    _debug "sprawdzam plik wejsciowy"
    [ -z "${g_inf[$___PATH]}" ] || [ "${g_inf[$___PATH]}" = "none" ] || [ ! -s "${g_inf[$___PATH]}" ] &&
        _error "plik wejsciowy niepoprawny" &&
        return $RET_PARAM

    # verifying input format
    if [ "${g_inf[$___FORMAT]}" != "none" ]; then
        _debug $LINENO "weryfikuje format wejsciowy"
        ! verify_format "${g_inf[$___FORMAT]}" && return $RET_PARAM
    fi

    # verifying output format
    _debug $LINENO "weryfikuje format wyjsciowy"
    ! verify_format "${g_outf[$___FORMAT]}" && return $RET_PARAM


    # verify input fps
    _debug $LINENO "weryfikuje fps wejsciowy"
    ! verify_fps "${g_inf[$___FPS]}" && return $RET_PARAM
    
    # verify output fps
    _debug $LINENO "weryfikuje fps wyjsciowy"
    ! verify_fps "${g_outf[$___FPS]}" && return $RET_PARAM

    return 0
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

    # get argv
    if ! parse_argv "$@"; then
        _error "niepoprawne argumenty..."
        return $RET_FAIL
    fi

    # verify argv
    if ! verify_argv; then 
        _error "niepoprawne argumenty..."
        return $RET_FAIL
    fi

    return $RET_OK
}


# call the main
[ "${SHUNIT_TESTS:-0}" -eq 0 ] && main "$@"

# EOF
