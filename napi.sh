#!/bin/bash

#
# script version
#
declare -r g_revision="v1.2.1"

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2014 Tomasz Wisniewski aka 
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

#
# @brief abbreviation 
# - string added between the filename and the extension
#
# @brief conversion abbreviation 
# - string added between the filename and the extension 
#   only for the converted subtitles
#
declare -a g_abbrev=( "" "" )

#
# @brief prefix for the original file - before the conversion
#
declare g_orig_prefix='ORIG_'

#
# system - detected system type
# - linux
# - darwin - mac osx
#
# numer of forks
#
# id
# - pynapi - identifies itself as pynapi
# - other - identifies itself as other
#
# fork id
#
declare -a g_system=( 'linux' '1' 'pynapi' 1 )

#
# @brief minimum size of files to be processed
#
declare g_min_size=0

#
# @brief whether to download cover or not
#
declare g_cover=0

#
# @brief whether to skip downloading if file is already present
#
declare g_skip=0

#
# @brief whether to delete the original file after conversion
#
declare g_delete_orig=0

#
# @brief defines the charset of the resulting file
#
declare g_charset='default'

#
# @brief default subtitles language
#
declare g_lang='PL'

#
# @brief default subtitles extension
#
declare g_default_ext='txt'

#
# @brief subtitles format
#
declare g_sub_format='default'

#
# @brief preferred fps detection tool
#
declare g_fps_tool='default'

#
# @brief external script
#
declare g_hook='none'

#
# @brief napiprojekt.pl user credentials
# 0 - user
# 1 - password
#
declare -a g_cred=( '' '' )

#
# verbosity (kept outside of g_settings to be more flexible)
# - 0 - be quiet (prints only errors)
# - 1 - standard level (prints errors, warnings, statuses & msg)
# - 2 - info level (prints errors, warnings, statuses, msg & info's)
# - 3 - debug level (prints errors, warnings, statuses, msg, info's and debugs)
#
declare g_verbosity=1 

#
# @brief the name of the file containing the output
#
declare g_logfile='none'

#
# global paths list
#
declare -a g_paths=()

#
# global files list
#
declare -a g_files=()

#
# @brief prepare all the possible filename combinations 
#
declare -a g_pf=()

#
# @brief processing stats
# 0 - downloaded
# 1 - unavailable
# 2 - skipped
# 3 - converted
# 4 - covers downloaded
# 5 - covers unavailable
# 6 - total processed
#
declare -a g_stats=( 0 0 0 0 0 0 0 )

#
# controls whether to print statistics on exit or not
#
g_stats_print=0

################################### TOOLS ######################################

#
# @brief global tools array 
# =1 - mandatory tool
# =0 - optional tool
#
declare -a g_tools=( 'tr=1' 'printf=1' 'mktemp=1' 'wget=1' 'dd=1' 'grep=1' 'sed=1' 'cut=1' 'stat=1' 'basename=1' 'dirname=1' 'cat=1' 'cp=1' 'mv=1' 'awk=0' 'file=0' 'subotage.sh=0' '7z=0' 'iconv=0' 'mediainfo=0' 'mplayer=0' 'mplayer2=0' 'ffmpeg=0' )

# fps detectors
declare -a g_tools_fps=( 'mediainfo' 'mplayer' 'mplayer2' 'ffmpeg' )

g_cmd_stat='stat -c%s'
g_cmd_wget='wget -q -O'
g_cmd_md5='md5sum'
g_cmd_cp='cp'

################################## RETVAL ######################################

# success
declare -r RET_OK=0

# function failed
declare -r RET_FAIL=255

# parameter error
declare -r RET_PARAM=254

# parameter/result will cause the script to break
declare -r RET_BREAK=253

# resource unavailable
declare -r RET_UNAV=252

################################## STDOUT ######################################

#
# @brief print a debug verbose information
#
_debug() {
    local line=${1:-0} && shift
    [ $g_verbosity -ge 3 ] && echo -e "#${g_system[3]} --- $line: $*"
    return $RET_OK
}


#
# @brief print information 
#
_info() {
    local line=${1:-0} && shift
    [ $g_verbosity -ge 2 ] && echo -e "#${g_system[3]} -- $line: $*"
    return $RET_OK
}


#
# @brief print warning 
#
_warning() {
    _status "WARNING" "$*"
    return $RET_OK
}


#
# @brief print error message
#
_error() {
    local tmp=$g_verbosity
    g_verbosity=1
    _status "ERROR" "$*" | to_stderr
    g_verbosity=$tmp
    return $RET_OK
}


#
# @brief print standard message
#
_msg() {
    [ $g_verbosity -ge 1 ] && echo -e "#${g_system[3]} - $*"
    return $RET_OK
}


#
# @brief print status type message
#
_status() {
    [ $g_verbosity -ge 1 ] && echo -e "#${g_system[3]} $1 -> $2"
    return $RET_OK
}


#
# @brief redirect errors to standard error output
#
to_stderr() {
    if [ -n "$g_logfile" ] && [ "$g_logfile" != "none" ]; then
        cat > /dev/stderr
    else
        cat
    fi
}


#
# @brief redirect stdout to logfile
#
redirect_to_logfile() {
    [ -n "$g_logfile" ] && [ "$g_logfile" != "none" ] && exec 3>&1 1> "$g_logfile"
}


#
# @brief redirect output to stdout
#
redirect_to_stdout() {
    [ -n "$g_logfile" ] && [ "$g_logfile" != "none" ] && exec 1>&3 3>&-
}

################################### misc #######################################

#
# @brief lowercase the input
#
lcase() {
    tr '[:upper:]' '[:lower:]'
}

#
# @brief get the extension of the input
#
get_ext() {
    echo "${1##*.}"
}

#
# @brief strip the extension of the input
#
strip_ext() {
    echo "${1%.*}"
}


#
# @brief get the value from strings like key=value
#
get_value() {
    echo "${1##*=}"
}


#
# @brief get the key from strings like key=value
#
get_key() {
    echo "${1%=*}"
}

#
# @brief search for specified key and return it's value
# @param key
# @param array
#
lookup_value() {
    local i=''
    local rv=$RET_FAIL
    local key="$1" && shift

    for i in $*; do
        if [ $(get_key "$i") = "$key" ]; then
            get_value $i
            rv=$RET_OK
            break
        fi
    done
    return $rv
}


#
# @brief lookup index in the array for given value
# returns the index of the value and 0 on success
#
lookup_key() {
    local i=''
    local idx=0
    local rv=$RET_FAIL
    local key="$1" 

    shift

    for i in "$@"; do
        [ "$i" = "$key" ] && rv=$RET_OK && break
        idx=$(( $idx + 1 ))
    done

    echo $idx
    return $rv
}


#
# @brief modify value in the array (it will be added if the key doesn't exist)
# @param key
# @param value
# @param array
#
modify_value() {
    local key=$1 && shift
    local value=$1 && shift

    local i=0
    declare -a rv=()

    for i in $*; do
        [ "$(get_key $i)" != "$key" ] && rv+=( "$i" )
    done

    rv+=($key=$value)
    echo ${rv[*]}

    return $RET_OK
}

################################ languages #####################################

# language code arrays
declare -ar g_Language=( 'Albański' 'Angielski' 'Arabski' 'Bułgarski' 
        'Chiński' 'Chorwacki' 'Czeski' 'Duński' 
        'Estoński' 'Fiński' 'Francuski' 'Galicyjski' 
        'Grecki' 'Hebrajski' 'Hiszpanski' 'Holenderski' 
        'Indonezyjski' 'Japoński' 'Koreański' 'Macedoński' 
        'Niemiecki' 'Norweski' 'Oksytański' 'Perski' 
        'Polski' 'Portugalski' 'Portugalski' 'Rosyjski' 
        'Rumuński' 'Serbski' 'Słoweński' 'Szwedzki' 
        'Słowacki' 'Turecki' 'Wietnamski' 'Węgierski' 'Włoski' )

declare -ar g_LanguageCodes2L=( 'SQ' 'EN' 'AR' 'BG' 'ZH' 'HR' 'CS' 'DA' 'ET' 'FI' 
                    'FR' 'GL' 'EL' 'HE' 'ES' 'NL' 'ID' 'JA' 'KO' 'MK' 
                    'DE' 'NO' 'OC' 'FA' 'PL' 'PT' 'PB' 'RU' 'RO' 'SR' 
                    'SL' 'SV' 'SK' 'TR' 'VI' 'HU' 'IT' )

declare -ar g_LanguageCodes3L=( 'ALB' 'ENG' 'ARA' 'BUL' 'CHI' 'HRV' 'CZE' 
                    'DAN' 'EST' 'FIN' 'FRE' 'GLG' 'ELL' 'HEB' 
                    'SPA' 'DUT' 'IND' 'JPN' 'KOR' 'MAC' 'GER' 
                    'NOR' 'OCI' 'PER' 'POL' 'POR' 'POB' 'RUS' 
                    'RUM' 'SCC' 'SLV' 'SWE' 'SLO' 'TUR' 'VIE' 'HUN' 'ITA' )


#
# @brief: list all the supported languages and their respective 2/3 letter codes
#
list_languages() {
    local i=0
    while [[ $i -lt ${#g_Language[@]} ]]; do
        echo "${g_LanguageCodes2L[$i]}/${g_LanguageCodes3L[$i]} - ${g_Language[$i]}"
        i=$(( $i + 1 ))
    done
}


#
# @brief verify that the given language code is supported
#
verify_language() {
    local lang="${1:-''}"
    local i=0
    declare -a l_arr=( )
    
    [ ${#lang} -ne 2 ] && [ ${#lang} -ne 3 ] && return $RET_PARAM

    local l_arr_name="g_LanguageCodes${#lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

    i=$(lookup_key "$lang" ${l_arr[@]})
    local found=$?

    echo $i 
    [ $found -eq $RET_OK ] && return $RET_OK
    return $RET_FAIL
}


#
# @brief set the language variable
# @param: language index
#
normalize_language() {
    local i=${1:-0}
    i=$(( $i + 0 ))

    local lang=${g_LanguageCodes2L[$1]}
    
    # don't ask me why
    [[ "$lang" = "EN" ]] && lang="ENG"
    echo $lang

    return $RET_OK
}

#################################### ENV #######################################

#
# @brief checks if the tool is available in the PATH
#
verify_tool_presence() {
    echo $(builtin type -P "$1")
}


#
# determines number of available cpu's in the system
#
get_cores() {
    grep -i processor /proc/cpuinfo | wc -l
}


#
# @brief detects running system type
#
get_system() {
    uname | lcase
}


#
# @brief configure external commands
#
configure_cmds() {
    _debug $LINENO "konfiguruje stat i md5"

    # verify stat & md5 tool
    if [ "${g_system[0]}" = "darwin" ]; then
        g_cmd_md5="md5" 
        g_cmd_stat="stat -f%z"
    else
        g_cmd_md5="md5sum" 
        g_cmd_stat="stat -c%s"
    fi

    g_tools+=( "$g_cmd_md5=1" )

    _debug $LINENO "sprawdzam czy wget wspiera opcje -S"
    local cmd_test=$(wget --help 2>&1 | grep "\-S")

    [ -n "$cmd_test" ] && 
        g_cmd_wget='wget -q -S -O' &&
        _info $LINENO "wget wspiera opcje -S"

    return $RET_OK
}


#
# @brief verify system settings and gather info about commands
#
verify_system() {
    _debug $LINENO "weryfikuje system"
    g_system[0]="$(get_system)"
    g_system[1]=$(( $(get_cores) * 2 ))
}


#
# @brief perform tools presence verification
#
verify_tools() {

    declare -a ret=()
    local rv=$RET_OK

    local tool=''
    local p=0
    local m=0
    local t=''

    for t in "$@"; do
        p=1
        tool="$(get_key $t)"
        m="$(get_value $t)"

        [ -z "$(verify_tool_presence $tool)" ] && p=0
        ret+=( "$tool=$p" )
        
        # break if mandatory tool is missing
        [[ $m -eq 1 ]] && [[ $p -eq 0 ]] && rv=$RET_FAIL && break
    done

    echo ${ret[*]}
    return $rv
}


#
# @brief get extension for given subtitle format
#
get_sub_ext() {
    declare -a fmte=( 'subrip=srt' 'subviewer=sub' )
    lookup_value "$1" ${fmte[@]}
    [ $? -ne $RET_OK ] && echo $g_default_ext
    return $RET_OK
}

##################################### fps ######################################

#
# @brief returns the number of available fps detection tools in the system
#
count_fps_detectors() {
    local c=0
    local t=""

    for t in ${g_tools_fps[@]}; do      
        [[ "$(lookup_value $t ${g_tools[@]})" = "1" ]] && c=$(( $c + 1 ))
    done

    echo $c
    return $RET_OK
}


#
# @brief detect fps of the video file
# @param tool
# @param filename
#
get_fps() {
    local fps=0
 
    # don't bother if there's no tool available or not specified
    if [[ -z "$1" ]] || [[ "$1" = "default" ]]; then
        echo $fps
        return $RET_PARAM
    fi
    
    local tool=$(lookup_value "$1" ${g_tools[@]})

    # prevent empty output
    tool=$(( $tool + 0 ))

    if [[ $tool -ne 0 ]]; then
        case "$1" in
            'mplayer' | 'mplayer2' )
            fps=$($1 -identify -vo null -ao null -frames 0 "$2" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2)
            ;;

            'mediainfo' )
            fps=$($1 "$2" | grep -i 'frame rate' | tr -d '[\r a-zA-Z:]')
            ;;

            'ffmpeg' )
            fps=$($1 -i "$2" 2>&1 | grep "Video:" | sed 's/, /\n/g' | grep tbr | cut -d ' ' -f 1)
            ;;

            *)
            ;;
        esac
    fi

    echo $fps
    return $RET_OK
}


#################################### ARGV ######################################

#
# @brief parse the cli arguments
#
parse_argv() {
    # command line arguments parsing
    while [ $# -gt 0 ]; do
        unset varname
        # when adding a new option, please remember to maintain the same order as generated by usage()
        case "$1" in
            # abbrev
            "-a" | "--abbrev") varname="g_abbrev[0]"
            msg="nie określono wstawki"
            ;;

            "-b" | "--bigger-than") varname="g_min_size"
            msg="nie okreslono minimalnego rozmiaru"
            ;;

            # cover download
            "-c" | "--cover" ) g_cover=1 ;;
            # orig prefix 
            "-d" | "--delete-orig") g_delete_orig=1 ;;
            # skip flag
            "-s" | "--skip") g_skip=1 ;;

            # stats flag
            "--stats") g_stats_print=1 ;;

            # move instead of copy
            "-M" | "--move") g_cmd_cp='mv' ;;

            # charset conversion
            "-C" | "--charset") varname="g_charset"
            msg="nie podano docelowego kodowania"
            ;;

            # extension
            "-e" | "--ext") varname="g_default_ext"
            msg="nie okreslono domyslnego rozszerzenia dla pobranych plikow"
            ;;

            # identification
            "-I" | "--id") varname="g_system[2]"
            msg="okresl typ narzedzia jako pynapi albo other"
            ;;

            # logfile
            "-l" | "--log") varname="g_logfile"
            msg="nie podano nazwy pliku loga"
            ;;

            # languages
            "-L" | "--language") varname="g_lang"
            msg="wybierz jeden z dostepnych 2/3 literowych kodow jezykowych (-L list - zeby wyswietlic)"
            ;;

            # password
            "-p" | "--pass") varname="g_cred[1]"
            msg="nie podano hasla"
            ;;

            # external script
            "-S" | "--script") varname="g_hook"
            msg="nie okreslono sciezki do skryptu"
            ;;

            # user login
            "-u" | "--user") varname="g_cred[0]"
            msg="nie podano nazwy uzytkownika"
            ;;

            # verbosity
            "-v" | "--verbosity") varname="g_verbosity"
            msg="okresl poziom gadatliwosci (0 - najcichszy, 3 - najbardziej gadatliwy)"
            ;;
            
            # destination format definition
            "-f" | "--format") varname="g_sub_format"
            msg="nie określono formatu docelowego"
            ;;

            "-P" | "--pref-fps") varname="g_fps_tool"
            msg="nie określono narzedzia do detekcji fps"
            ;;

            # orig prefix 
            "-o" | "--orig-prefix") varname="g_orig_prefix"
            msg="nie określono domyslnego prefixu"
            ;;

            # abbrev
            "--conv-abbrev") varname="g_abbrev[1]"
            msg="nie określono wstawki dla konwersji"
            ;;

            "-F" | "--forks") varname="g_system[1]"
            msg="nie określono ilosci watkow"
            ;;

            # parameter is not a known argument, probably a filename
            *) g_paths+=( "$1" ) ;;
        esac

        # set the global var for simple switches
        # not requiring any further verification
        if [[ -n "$varname" ]]; then
            shift
            [ -z "$1" ] && _error $msg && return $RET_FAIL
            eval "${varname}=\$1"
        fi
        shift
    done
    return $RET_OK
}


#
# @brief validate username and password
#
verify_credentials() {

    local user="${1:-}"
    local passwd="${2:-}"
    local rv=$RET_OK
    
    if [ -z "$user" ] && [ -n "$passwd" ]; then
        _warning "podano haslo, brak loginu. tryb anonimowy."
        rv=$RET_PARAM
    fi

    if [ -n "$user" ] && [ -z "$passwd" ]; then
        _warning "podano login, brak hasla. tryb anonimowy."
        rv=$RET_PARAM
    fi

    return $rv
}


#
# @brief checks if the given encoding is supported
#
verify_encoding() {
    [ "$1" = 'default' ] && return $RET_OK
    echo test | iconv -t $1 > /dev/null 2>&1
    return $?
}


#
# @brief checks id
#
verify_id() {
    local rv=$RET_OK

    case ${g_system[2]} in
        'pynapi' | 'other' ) ;;
        *) 
        rv=$RET_PARAM
        g_system[2]='pynapi'
        ;;
    esac

    if [[ "${g_system[2]}" = 'other' ]]; then
        local p=$(lookup_value '7z' ${g_tools[@]})
        if [ $(( $p + 0 )) -eq 0 ]; then
            _error "7z nie jest dostepny. zmien id na pynapi albo zainstaluj 7z"
            rv=$RET_FAIL
        fi
    fi
    return $rv
}


#
# @brief format verification
#
verify_format() {
    # format verification if conversion requested
    if [ "$g_sub_format" != 'default' ]; then
        local sp=$(lookup_value 'subotage.sh' ${g_tools[@]})

        # make sure it's a number
        sp=$(( $sp + 0 ))

        if [ $sp -eq 0 ]; then
            _error "subotage.sh nie jest dostepny. konwersja nie jest mozliwa"
            return $RET_PARAM
        fi

        declare -a formats=( $(subotage.sh -gf) )

        if ! lookup_key $g_sub_format ${formats[@]} > /dev/null; then
            _error "podany format docelowy jest niepoprawny [$g_sub_format]"
            return $RET_PARAM
        fi
    fi

    return $RET_OK
}


#
# @brief verify fps tool
#
verify_fps_tool() {
    local t=''
    local sp=0

    # verify selected fps tool
    if [ "$g_fps_tool" != 'default' ]; then
        if ! lookup_key "$g_fps_tool" ${g_tools_fps[@]} > /dev/null; then
            _error "podane narzedzie jest niewspierane [$g_fps_tool]"
            return $RET_PARAM
        fi
        
        sp=$(lookup_value "$g_fps_tool" ${g_tools[@]})

        # make sure it's a number
        sp=$(( $sp + 0 ))

        if [ $sp -eq 0 ]; then
            _error "$g_fps_tool nie jest dostepny"
            return $RET_PARAM
        fi
    else
        # choose first available as the default tool
        if [ $(count_fps_detectors) -gt 0 ]; then 
            for t in ${g_tools_fps[@]}; do
                [ $(lookup_value $t ${g_tools[@]}) -eq 1 ] && 
                    g_fps_tool=$t && 
                    break
            done
        fi
    fi

    return $RET_OK
}


#
# @brief verify correctness of the argv settings provided
#
verify_argv() {
    local status=0

    # verify credentials correctness
    _debug $LINENO 'sprawdzam dane uwierzytelniania'
    if ! verify_credentials "${g_cred[0]}" "${g_cred[1]}"; then
        g_cred[0]='' && g_cred[1]=''
    fi

    # make sure we have a number here
    _debug $LINENO 'normalizacja parametrow numerycznych'
    g_min_size=$(( $g_min_size + 0 ))
    g_verbosity=$(( $g_verbosity + 0 ))
    g_system[1]=$(( ${g_system[1]} + 0 ))

    # verify encoding request
    _debug $LINENO 'sprawdzam wybrane kodowanie'
    if ! verify_encoding "$g_charset"; then
        _warning "charset [$g_charset] niewspierany, ignoruje zadanie"
        g_charset='default'
    fi

    # verify the id setting
    _debug $LINENO 'sprawdzam id'
    verify_id
    status=$?

    if [ $status = $RET_PARAM ]; then
        _warning "nieznany id [${g_system[2]}], przywracam domyslny"

    elif [ $status = $RET_FAIL ]; then
        _error "brak wymaganych narzedzi"
        return $RET_PARAM
    fi
    
    # logfile verification  
    _debug $LINENO 'sprawdzam logfile'
    [ -e "$g_logfile" ] && 
        _warning "plik loga istnieje - bedzie nadpisany"
    
    # language verification
    _debug $LINENO 'sprawdzam wybrany jezyk'
    local idx=0
    idx=$(verify_language "$g_lang")

    if [ $? -ne $RET_OK ]; then
        if [ "$g_lang" = "list" ]; then 
            list_languages
            return $RET_BREAK
        else
            _warning "nieznany jezyk [$g_lang]. przywracam PL"
            g_lang='PL'
        fi
    else
        _debug $LINENO "jezyk znaleziony, index = $idx"
        g_lang=$(normalize_language $idx)
    fi
    unset idx

    # format verification
    _debug $LINENO 'sprawdzam format'
    ! verify_format && return $RET_PARAM

    # fps tool verification
    _debug $LINENO 'sprawdzam wybrane narzedzie fps'
    ! verify_fps_tool && return $RET_PARAM

    # verify external script
    _debug $LINENO 'sprawdzam zewnetrzny skrypt'
    if [ "$g_hook" != 'none' ]; then
       [ ! -x "$g_hook" ] &&
           _error "podany skrypt jest niedostepny (lub nie ma uprawnien do wykonywania)" &&
           return $RET_PARAM
    fi

    return $RET_OK
}

################################# napiprojekt ##################################

#
# @brief: mysterious f() function
# @param: md5sum
#
f() {
    declare -a t_idx=( 0xe 0x3 0x6 0x8 0x2 )
    declare -a t_mul=( 2 2 5 4 3 )
    declare -a t_add=( 0 0xd 0x10 0xb 0x5 )
    local sum="$1"
    local b=""    
    local i=0

    for i in {0..4}; do
    # for i in $(seq 0 4); do
        local a=${t_add[$i]}
        local m=${t_mul[$i]}
        local g=${t_idx[$i]}        
        
        local t=$(( a + 16#${sum:$g:1} ))
        local v=$(( 16#${sum:$t:2} ))
        
        local x=$(( (v*m) % 0x10 ))
        local z=$(printf "%X" $x)
        b="$b$(echo $z | lcase)"
    done

    echo "$b"
    return $RET_OK
}


#
# @brief extracts http status from the http headers
#
get_http_status() {
    grep -o "HTTP/[\.0-9]* [0-9]*"
}


#
# @brief wrapper for wget
# @param url
# @param output file
#
# returns the http code(s)
#
download_url() {
    local url="$1"
    local output="$2"
    local headers=""
    local rv=$RET_OK
    local code='unknown'

    headers=$($g_cmd_wget "$output" "$url" 2>&1)

    if [ $? -eq $RET_OK ]; then
        # check the headers
        if [ -n "$headers" ]; then
            rv=$RET_FAIL
            code=$(echo $headers | get_http_status | cut -d ' ' -f 2)
            [ -n "$(echo $code | grep 200)" ] && rv=$RET_OK
        fi
    else
        rv=$RET_FAIL
    fi
    
    echo $code
    return $rv
}


#
# @brief downloads subtitles
# @param md5 sum of the video file
# @param hash of the video file
# @param output filepath
# @param requested subtitles language
#
download_subs() {
    local md5sum=${1:-0}
    local h=${2:-0}
    local of="$3"
    local lang="${4:-'PL'}"
    local id="${5:-'pynapi'}"
    local user="${6:-''}"
    local passwd="${7:-''}"
    local status=$RET_FAIL

    local rv=$RET_OK
    local http_codes=''

    # downloaded filename
    local dof="$of"
    local url="http://napiprojekt.pl/unit_napisy/dl.php?l=$lang&f=$md5sum&t=$h&v=$id&kolejka=false&nick=$user&pass=$passwd&napios=posix"
    local napi_pass="iBlm8NTigvru0Jr0"

    # should be enough to avoid clashing
    [ "$id" = "other" ] && dof=$(mktemp -t napisy.7z.XXXXXXXX)

    http_codes=$(download_url "$url" "$dof")
    status=$?
    _info $LINENO "otrzymane odpowiedzi http: [$http_codes]"

    if [ $status -ne $RET_OK ]; then
        _error "blad wgeta. nie mozna pobrac pliku [$of], odpowiedzi http: [$http_codes]"

        # cleanup
        [ "$id" = "other" ] && [ -e "$dof" ] && unlink "$dof"

        # ... and exit
        return $RET_FAIL
    fi

    # it seems that we've got the file perform some verifications on it
    case $id in
        "pynapi" )
        # no need to do anything
        ;;

        "other")
        7z x -y -so -p"$napi_pass" "$dof" 2> /dev/null > "$of"
        [ -e "$dof" ] && unlink "$dof"

        if ! [ -s "$of" ]; then
            _info $LINENO "plik docelowy ma zerowy rozmiar"
            rv=$RET_FAIL
            [ -e "$of" ] && unlink "$of"
        fi
        ;;

        *)
        _error "not supported"
        ;;
    esac

    # verify the contents
    if [ $rv -eq $RET_OK ]; then

        # check if the file was downloaded successfully by checking
        # if it exists at all 
        if [ ! -e "$of" ]; then
            _error "sciagniety plik nie istnieje, nieznany blad"
            return $RET_FAIL
        fi

        # count lines in the file
        local lines=$(wc -l "$of" | cut -d ' ' -f 1)
        
        # adjust that if needed
        local min_lines=3

        if [ $lines -lt $min_lines ]; then
            _info $LINENO "plik zawiera mniej ($lines) niz $min_lines lin(ie). zostanie usuniety"

            local fdata=$(cat "$of")
            _debug $LINENO "$fdata"

            rv=$RET_FAIL
            unlink "$of"
        fi
    fi

    return $rv
}


#
# @brief: retrieve cover
# @param: md5sum
# @param: outputfile
#
download_cover() {
    local url="http://www.napiprojekt.pl/okladka_pobierz.php?id=$1&oceny=-1"
    local rv=$RET_FAIL
	local http_codes=""

	http_codes=$(download_url "$url" "$2")
    rv=$?
    _info $LINENO "otrzymane odpowiedzi http: [$http_codes]"

    if [ $rv -eq $RET_OK ]; then

        # if file doesn't exist or has zero size
        if ! [ -s "$2" ]; then
            rv=$RET_UNAV 
            [ -e "$2" ] && unlink "$2"
        fi
    fi

    return $rv
}


#
# @brief downloads subtitles for a given media file
# @param media file path
# @param subtitles file path
# @param requested subtitles language
#
get_subtitles() {
    local fn="$1"
    local of="$2"
    local lang="$3"

    # md5sum and hash calculation
    local sum=$(dd if="$fn" bs=1024k count=10 2> /dev/null | $g_cmd_md5 | cut -d ' ' -f 1)
    local hash=$(f $sum)

    _info $LINENO "pobieram napisy dla pliku [$fn]"
    download_subs $sum $hash "$of" $lang ${g_system[2]} ${g_cred[@]}
    return $?
}


#
# @param media file path
#
get_cover() {
    local sum=$(dd if="$1" bs=1024k count=10 2> /dev/null | $g_cmd_md5 | cut -d ' ' -f 1)
    local path=$(dirname "$1")
	local media_file=$(basename "$1")
    local cover_fn=$(strip_ext "$media_file")
    
    # TODO correct this - extension hardcoded
    cover_fn="${cover_fn}.jpg"
    
    download_cover $sum "$path/$cover_fn"
    return $?
}


#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
get_charset() {
    local file="$1"
    local ft_presence=$(lookup_value 'file' ${g_tools[@]})
    local charset='WINDOWS-1250'
    local et=''

    # sanitizing the value
    ft_presence=$(( $ft_presence + 0 ))

    if [ $ft_presence -eq 1 ]; then

        et=$(file \
            --brief \
            --mime-encoding \
            --exclude apptype \
            --exclude tokens \
            --exclude cdf \
            --exclude compress \
            --exclude elf \
            --exclude soft \
            --exclude tar \
            "$file" | lcase)

        if [ "$?" = "0" ] && [ -n "$et" ]; then
            case "${et,,}" in
                *utf*) charset="UTF8";;
                *iso*) charset="ISO-8859-2";;
				us-ascii) charset="US-ASCII";;
				csascii) charset="CSASCII";;
                *ascii*) charset="ASCII";;
                *) charset="WINDOWS-1250";;
            esac
        fi
    fi

    echo "$charset"
    return $RET_OK
}


#
# @brief convert charset of the file
# @param input file path
# @param output charset
# @param input charset or null
#
convert_charset() {
    local file="$1"
    local d="${2:-'utf8'}"
    local s="${3}"
    local rv=$RET_FAIL

    # detect charset
    [ -z "$s" ] && s=$(get_charset "$file")
	
    local tmp=$(mktemp -t napi.XXXXXXXX)
    iconv -f "$s" -t "$d" "$file" > "$tmp"

    if [ $? -eq $RET_OK ]; then
		_debug $LINENO "moving after charset conv. $tmp -> $file"
        mv "$tmp" "$file"
        rv=$RET_OK
    fi

    [ -e "$tmp" ] && unlink "$tmp"
    return $rv
}

################################# file handling ################################

#
# @brief: check if the given file is a video file
# @param: video filename
# @return: bool 1 - is video file, 0 - is not a video file
#
verify_extension() {
    local filename=$(basename "$1")
    local extension=$(get_ext "$filename" | lcase)
    local is_video=0  

    declare -a formats=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' 
        'mpeg' 'wmv' '3gp' 'asf' 'divx' 
        'm4v' 'mpe' 'ogg' 'ogv' 'qt' )

    lookup_key "$extension" ${formats[@]} > /dev/null && is_video=1

    echo $is_video
    return $RET_OK
}


#
# @brief prepare a list of file which require processing
# @param minimum filesize
# @param space delimited file list string
#
prepare_file_list() {
    local file=""
    local min_size=${1:-0}

    shift
    for file in "$@"; do

        # check if file exists, if not skip it
        if [[ ! -e "$file" ]]; then
            continue

        elif [[ ! -s "$file" ]]; then
            _warning "podany plik jest pusty [$file]"
            continue

        # check if is a directory
        # if so, then recursively search the dir
        elif [[ -d "$file" ]]; then
            local tmp="$file"
            prepare_file_list $min_size "$tmp"/*

        else
            # check if the respective file is a video file (by extention)       
            if [[ $(verify_extension "$file") -eq 1 ]] &&
               [[ $($g_cmd_stat "$file") -ge $(( $min_size*1024*1024 )) ]]; then
                g_files+=( "$file" )
            fi
        fi
    done

    return $RET_OK
}


#
# @brief prepare all the possible filenames for the output file (in order to check if it already exists)
#
# this function prepares global variables g_pf containing all the possible output filenames
# index description
#
# @param video filename (without path)
#
prepare_filenames() {
    
    # media filename (with path)
    local fn="${1:-''}"

    # media filename without extension
    local noext=$(strip_ext "$fn")

    # converted extension
    local cext=$(get_sub_ext $g_sub_format)

    local ab=${g_abbrev[0]}
    local cab=${g_abbrev[1]}

    # empty the array
    g_pf=()

    # array contents description
    #
    # original_file (o) - as download from napiprojekt.pl (with extension changed only)
    # abbreviation (a)
    # conversion abbreviation (A)
    # prefix (p) - g_orig_prefix for the original file
    # converted_file (c) - filename with converted subtitles format (may have differect extension)
    #
    # 0 - o - filename + g_default_ext
    # 1 - o + a - filename + abbreviation + g_default_ext
    # 2 - p + o - g_orig_prefix + filename + g_default_ext
    # 3 - p + o + a - g_orig_prefix + filename + abbreviation + g_default_ext
    # 4 - c - filename + get_sub_ext
    # 5 - c + a - filename + abbreviation + get_sub_ext
    # 6 - c + A - filename + conversion_abbreviation + get_sub_ext
    # 7 - c + a + A - filename + abbreviation + conversion_abbreviation + get_sub_ext

    # original
    g_pf+=( "${noext}.$g_default_ext" )
    g_pf+=( "${noext}.${ab:+$ab.}$g_default_ext" )
    g_pf+=( "${g_orig_prefix}${g_pf[0]}" )
    g_pf+=( "${g_orig_prefix}${g_pf[1]}" )

    # converted
    g_pf+=( "${noext}.$cext" )
    g_pf+=( "${noext}.${ab:+$ab.}$cext" )
    g_pf+=( "${noext}.${cab:+$cab.}$cext" )
    g_pf+=( "${noext}.${ab:+$ab.}${cab:+$cab.}$cext" )

    return $RET_OK
}


#
# @brief convert format
# @param full path to the media file
# @param original (as downloaded) subtitles filename
# @param filename to which unconverted subtitles should be renamed
# @param filename for converted subtitles
#
convert_format() {

    local media_path="$1"
    local input="$2"
    local orig="$3"
    local conv="$4"

    local path=$(dirname "$media_path")

    local fps=0
    local fps_opt=''
    local rv=$RET_OK
    local sb_data=''

    # for the backup
    local tmp="$(mktemp -t napi.XXXXXXXX)"

	# verify original file existence before proceeding further
	! [ -e "$path/$input" ] &&
		_error "oryginalny plik nie istnieje" &&
		return $RET_FAIL

    # create backup
    _debug $LINENO "backupuje oryginalny plik jako $tmp"
    cp "$path/$input" "$tmp"

    # if delete orig flag has been requested don't rename the original file
    if [ $g_delete_orig -eq 0 ]; then
        _info $LINENO "kopiuje oryginalny plik jako [$orig]" &&
        cp "$path/$input" "$path/$orig"
	else
		# get rid of it, if it already exists
		[ -e "$path/$orig" ] && unlink "$path/$orig"
	fi

    # detect video file framerate
    [ $g_fps_tool != 'default' ] && fps=$(get_fps $g_fps_tool "$media_path")

    if [[ "$fps" != 0 ]]; then
        _msg "wykryty fps: $fps"
        fps_opt="-fi $fps"
    else
        _msg "fps nieznany, okr. na podstawie napisow albo wart. domyslna"
    fi

    _msg "wolam subotage.sh"
    sb_data=$(subotage.sh -i "$path/$input" -of $g_sub_format -o "$path/$conv" $fps_opt)
    status=$?

    # subotage output only on demand
    _debug $LINENO "$sb_data"

    # remove the old format if conversion was successful
    if [[ $status -eq $RET_OK ]]; then
        _msg "pomyslnie przekonwertowano do $g_sub_format"
        [[ "$input" != "$conv" ]] &&
            _msg "usuwam oryginalny plik" &&
            unlink "$path/$input"
    else
        _msg "konwersja do $g_sub_format niepomyslna"

        # restore the backup (the original file may be corrupted due to failed conversion)
        cp "$tmp" "$path/$input"
        rv=$RET_FAIL
    fi

    # delete a backup
    [ -e "$tmp" ] && unlink "$tmp"
    return $rv
}


#
# @brief check file presence
#
check_subs_presence() {
    local media_file="$1"
    local path="$2"

    # bits
    # 1 - unconverted available/unavailable
    # 0 - converted available/unavailable
    #
    # default - converted unavailable, unconverted unavailable
    local rv=0

    _debug $LINENO "g_cmd_cp = $g_cmd_cp"

    if [ $g_sub_format != 'default' ]; then

        # unconverted unavailable, converted available
        rv=$(( $rv | 1 ))

        if [[ -e "$path/${g_pf[7]}" ]]; then
            _status "SKIP" "$media_file"
        
        elif [[ -e "$path/${g_pf[6]}" ]]; then
            _status "COPY" "${g_pf[6]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[6]}" "$path/${g_pf[7]}"

        elif [[ -e "$path/${g_pf[5]}" ]]; then
            _status "COPY" "${g_pf[5]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[5]}" "$path/${g_pf[7]}"

        elif [[ -e "$path/${g_pf[4]}" ]]; then
            _status "COPY" "${g_pf[4]} -> ${g_pf[7]}"
            $g_cmd_cp "$path/${g_pf[4]}" "$path/${g_pf[7]}"

        else
            _info $LINENO "skonwertowany plik niedostepny"
            rv=$(( $rv & ~1 ))
        fi

        # we already have what we need - bail out
        [ $(( $rv & 1 )) -eq 1 ] && return $rv
    fi

    # assume unconverted available & verify that
    rv=$(( $rv | 2 ))

    # when the conversion is not required
    if [[ -e "$path/${g_pf[1]}" ]]; then
        _status "SKIP" "$media_file"
    
    elif [[ -e "$path/${g_pf[0]}" ]]; then
        _status "COPY" "${g_pf[0]} -> ${g_pf[1]}"
        $g_cmd_cp "$path/${g_pf[0]}" "$path/${g_pf[1]}"

    elif [[ -e "$path/${g_pf[3]}" ]]; then
        _status "COPY" "${g_pf[3]} -> ${g_pf[1]}"
        $g_cmd_cp "$path/${g_pf[3]}" "$path/${g_pf[1]}"

    else
        _info $LINENO "oryginalny plik niedostepny"
        rv=$(( $rv & ~2 ))
    fi

    # exceptionally in this function return value caries the 
    # information - not the execution status
    return $rv
}


#
# @brief try to obtain media file from napiprojekt or skip
# @param media file full path
#
obtain_file() {
    local media_path="$1"
    local media_file=$(basename "$media_path")
    local path=$(dirname "$media_path")
    local rv=$RET_FAIL

    # file availability
    local av=0
    local should_convert=0

    # prepare all the possible filename combinations
    prepare_filenames "$media_file"
    _debug $LINE "potencjalne nazwy plikow: ${g_pf[*]}"
	_debug $LINE "katalog docelowy [$path]"

    if [ $g_skip -eq 1 ]; then
        _debug $LINENO "sprawdzam dostepnosc pliku"
        check_subs_presence "$media_file" "$path"
        av=$?
    fi

    _info $LINENO "dostepnosc pliku $av"
    _debug $LINENO "przekonwertowany dostepny = $(( $av & 1 ))"
    _debug $LINENO "oryginalny dostepny = $(( ($av & 2) >> 1 ))"

    # if conversion is requested
    if [ "$g_sub_format" != 'default' ]; then

        case $av in
            0) # download & convert
                if get_subtitles "$media_path" "$path/${g_pf[1]}" $g_lang; then
                    _debug $LINENO "napisy pobrano, nastapi konwersja"
                    should_convert=1
                    g_stats[0]=$(( ${g_stats[0]} + 1 ))
                else
                    # unable to get the file
                    _debug $LINENO "napisy niedostepne"
                    rv=$RET_UNAV
                fi
            ;;

            1) # unconverted unavailable, converted available
                _debug $LINENO "nie pobieram, nie konwertuje - dostepna skonwertowana wersja"

                # increment skipped counter
                g_stats[2]=$(( ${g_stats[2]} + 1 ))
                rv=$RET_OK
            ;;

            2|3) # convert 
                _debug $LINENO "nie pobieram - dostepna jest nieskonwertowana wersja"

                # increment skipped counter
                g_stats[2]=$(( ${g_stats[2]} + 1 ))
                should_convert=1
            ;;
        esac

        # original file available - convert it
        if [ $should_convert -eq 1 ]; then
            _msg "konwertowanie do formatu $g_sub_format"
            convert_format "$media_path" "${g_pf[1]}" "${g_pf[3]}" "${g_pf[7]}"
            rv=$?

            # increment converted counter
            g_stats[3]=$(( ${g_stats[3]} + 1 ))
        fi

    else
        _info $LINENO "konwersja nie wymagana"

        # file is not available - download
        if [ ${av[0]} -eq 0 ]; then
            get_subtitles "$media_path" "$path/${g_pf[1]}" $g_lang
            rv=$?
            [ $rv -eq $RET_OK ] && g_stats[0]=$(( ${g_stats[0]} + 1 ))
        else

            # increment skipped counter
            g_stats[2]=$(( ${g_stats[2]} + 1 ))
            rv=$RET_OK
        fi
    fi
    
    # return the subtitles index
    return $rv
}


#
# @brief process a single media file
#
process_file() {
    local media_path="$1"
    local media_file=$(basename "$media_path")
    local path=$(dirname "$media_path")

    local rv=$RET_OK
    local status=0
    local si=1

    obtain_file "$media_path"
    status=$?

    if [ $status -eq $RET_OK ]; then
        _status "OK" "$media_file"

        [ "$g_sub_format" != 'default' ] &&
            _debug $LINENO "zadanie konwersji - korekcja nazwy pliku"
            si=7

        # charset conversion
        [ "$g_charset" != 'default' ] && 
            _msg "konwertowanie kodowania do $g_charset" &&
            convert_charset "$path/${g_pf[$si]}" $g_charset

        # process hook
        [ "$g_hook" != 'none' ] &&
            _msg "wywoluje zewnetrzny skrypt" &&
            $g_hook "$path/${g_pf[$si]}"

        # download cover
        # assumed here that cover is only available
        # if subtitles are
        if [ $g_cover -eq 1 ]; then
            if get_cover "$media_path"; then
                _status "OK" "cover for $media_path"
                g_stats[4]=$(( ${g_stats[4]} + 1 ))
            else
                _status "UNAV" "cover for $media_file"
                g_stats[5]=$(( ${g_stats[5]} + 1 ))
            fi 
        fi # if [[ $g_cover -eq 1 ]]
    else
        _status "UNAV" "$media_file"
        g_stats[1]=$(( ${g_stats[1]} + 1 ))
        rv=$RET_UNAV
    fi # if [ $status = $RET_OK ]

    # increment total processed counter
    g_stats[6]=$(( ${g_stats[6]} + 1 ))
    return $rv
}


#
# @brief this is a worker function it will run over the files array with a given step starting from given index
# @param starting index
# @param increment
# 
process_files() {

    local s=${1:-0}
    local i=${2:-1}

    # current
    local c=$s

    while [ $c -lt ${#g_files[@]} ]; do
        _info $LINENO "#$s - index poczatkowy $c"
        process_file "${g_files[$c]}"
        c=$(( $c + $i ))
    done

	# dump statistics to fd #8 (if it has been opened before)
    [ -e "/proc/self/fd/8" ] && echo "${g_stats[*]}" >&8
    return $RET_OK
}


#
# @brief summarize statistics collected from forks
# @param statistics file
# 
sum_stats() {
    local file="$1"
    local awk_script=''
    local fc=${#g_stats[@]}
    local awk_presence=$(lookup_value 'awk' ${g_tools[@]})

    awk_presence=$(( $awk_presence + 0 ))

# embed small awk program to count the columns
read -d "" awk_script << EOF
BEGIN {
    fmax=$fc
    for (x=0; x<fmax; x++) cols[x] = 0
}

{
    max = fmax > NF ? NF : fmax
    for (x=0; x<max; x++) cols[x] += \$(x + 1)
}

END {
    for (x=0; x<fmax; x++) 
        printf "%d ", cols[x]
    print ""
}
EOF

    # update the contents
    [ $awk_presence -eq 1 ] && g_stats=( $(awk "$awk_script" "$file") )
    return $RET_OK
}


#
# @brief creates the actual worker forks
#
spawn_forks() {
    local c=0
    local stats_file="$(mktemp -t stats.XXXXXXXX)"

    # open fd #8 for statistics collection
    exec 8<> "$stats_file"

    # spawn parallel processing
    while [ $c -lt ${g_system[1]} ] && [ $c -lt ${#g_files[@]} ]; do
        g_system[3]=$(( $c + 1 ))
        _debug $LINENO "tworze fork #${g_system[3]}, przetwarzajacy od $c z incrementem ${g_system[1]}"
        process_files $c ${g_system[1]} &
        c=${g_system[3]}
    done
    
    # wait for all forks
    wait

    # sum stats data
    sum_stats "$stats_file"

    # close the fd
    exec 8>&-
    [ -e "$stats_file" ] && unlink "$stats_file"

    # restore main fork id
    g_system[3]=1
    return $RET_OK
}


#
# print stats summary
#
print_stats() {

    declare -a labels=( 'OK' 'UNAV' 'SKIP' 'CONV' 'COVER_OK' 'COVER_UNAV' 'TOTAL' )
    local i=0

    _msg "statystyki przetwarzania"

    while [ $i -lt ${#g_stats[@]} ]; do
        _status "${labels[$i]}" "${g_stats[$i]}"
        i=$(( $i + 1 ))
    done

    return $RET_OK
}

################################################################################

#
# @brief prints the help & options overview
#
usage() {
    local subotage_presence=$(lookup_value 'subotage.sh' ${g_tools[@]})
    local iconv_presence=$(lookup_value 'iconv' ${g_tools[@]})

    # precaution to prevent variables from being empty
    subotage_presence=$(( $subotage_presence + 0 ))
    iconv_presence=$(( $iconv_presence + 0 ))

    echo "=============================================================="
    echo "napi.sh version $g_revision (identifies as ${g_system[2]})"
    echo "napi.sh [OPCJE] <plik|katalog|*>"
    echo

    echo "   -a | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
    echo "   -b | --bigger-than <size MB> - szukaj napisow tylko dla plikow wiekszych niz <size>"
    echo "   -c | --cover - pobierz okladke"

    [ $iconv_presence -eq 1 ] && 
        echo "   -C | --charset - konwertuj kodowanie plikow (iconv -l - lista dostepnych kodowan)"

    echo "   -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
    echo "   -F | --forks - okresl recznie ile rownoleglych procesow utworzyc (dom. ${g_system[1]})"
    echo "   -I | --id <pynapi|other> - okresla jak napi.sh ma sie przedstawiac serwerom napiprojekt.pl (dom. ${g_system[2]})"
    echo "   -l | --log <logfile> - drukuj output to pliku zamiast na konsole"
    echo "   -L | --language <LANGUAGE_CODE> - pobierz napisy w wybranym jezyku"
    echo "   -M | --move - w przypadku opcji (-s) przenos pliki, nie kopiuj"
    echo "   -p | --pass <passwd> - haslo dla uzytkownika <login>"
    echo "   -S | --script <script_path> - wywolaj skrypt po pobraniu napisow (sciezka do pliku z napisami, relatywna do argumentu napi.sh, bedzie przekazana jako argument)"
    echo "   -s | --skip - nie sciagaj, jezeli napisy juz sciagniete"
    echo "   -u | --user <login> - uwierzytelnianie jako uzytkownik"
    echo "   -v | --verbosity <0..3> - zmien poziom gadatliwosci 0 - cichy, 3 - debug"
    echo "      | --stats - wydrukuj statystyki (domyslnie nie beda drukowane)"
    
    if [ $subotage_presence -eq 1 ]; then    
        echo "   -d | --delete-orig - Delete the original file"   
        echo "   -f | --format - konwertuj napisy do formatu (wym. subotage.sh)"
        echo "   -P | --pref-fps <fps_tool> - preferowany detektor fps (jezeli wykryto jakikolwiek)"
        echo "   -o | --orig-prefix - prefix dla oryginalnego pliku przed konwersja (domyslnie: $g_orig_prefix)"   
        echo "      | --conv-abbrev <string> - dodaj dowolny string przed rozszerzeniem podczas konwersji formatow"
        echo
        echo "Obslugiwane formaty konwersji napisow"
        subotage.sh -gl
    fi

    echo
    echo "Przyklady:"
    echo " napi.sh film.avi          - sciaga napisy dla film.avi."
    echo " napi.sh -c film.avi       - sciaga napisy i okladke dla film.avi."
    echo " napi.sh -u foo -p bar -c film.avi - sciaga napisy i okladke do"
    echo "                             film.avi jako uzytkownik foo"
    echo " napi.sh *                 - szuka plikow wideo w obecnym katalogu"
    echo "                             i podkatalogach, po czym stara sie dla"
    echo "                             nich znalezc i pobrac napisy."
    echo " napi.sh *.avi             - wyszukiwanie tylko plikow avi."
    echo " napi.sh katalog_z_filmami - wyszukiwanie we wskazanym katalogu"
    echo "                             i podkatalogach."
    
    if [ $subotage_presence -ne 1 ]; then
        echo " "
        echo "UWAGA !!!"
        echo "napi.sh moze automatycznie dokonywac konwersji napisow"
        echo "do wybranego przez Ciebie formatu. Zainstaluj uniwersalny"
        echo "konwerter formatow dla basha: subotage.sh"
        echo "http://sourceforge.net/projects/bashnapi/"
        echo
    else
        echo " napi.sh -f subrip *       - sciaga napisy dla kazdego znalezionego pliku"
        echo "                           po czym konwertuje je do formatu subrip"

        if [ $(count_fps_detectors) -gt 0 ]; then 
            echo
            echo "Wykryte narzedzia detekcji FPS"

            local t=0
            for t in ${g_tools_fps[@]}; do
                [ $(lookup_value $t ${g_tools[@]}) -eq 1 ] && echo $t
            done
            echo
        else
            echo
            echo "By moc okreslac FPS na podstawie pliku video a nie na"
            echo "podstawie pierwszej linii pliku (w przypadku konwersji z microdvd)"
            echo "zainstaluj dodatkowo jedno z tych narzedzi (dowolne)"
            ( IFS=$'\n'; echo "${g_tools_fps[*]}" )
            echo
        fi
    fi

    return $RET_OK
}

################################################################################

#
# @brief main function 
# 
main() {
    # first positional
    local arg1="${1:-''}"

    # debug
    _debug $LINENO "$0: ($g_revision) uruchamianie ..." 

    # print bash version
    if [ -z "$BASH_VERSION" ]; then
        _debug $LINENO "interpreter inny niz bash ($SHELL)"
    else
        _debug $LINENO "interpreter to bash $BASH_VERSION"
    fi

    # system verification
    verify_system

    # commands configuration
    configure_cmds

    # verify tools presence
    _debug $LINENO "sprawdzam narzedzia ..." 
    g_tools=( $(verify_tools ${g_tools[@]}) )
    if [ $? -ne $RET_OK ]; then
        _error "nie wszystkie wymagane narzedzia sa dostepne"
        return $RET_FAIL
    fi

    _debug $LINENO ${g_tools[*]}

    # if no arguments are given, then print help and exit
    [ $# -lt 1 ] || [ "$arg1" = "--help" ] || [ "$arg1" = "-h" ] && 
        usage &&
        return $RET_BREAK

    _info $LINENO "parsowanie argumentow"
    if ! parse_argv "$@"; then
        _error "niepoprawne argumenty..."
        return $RET_FAIL
    fi

    _info $LINENO "weryfikacja argumentow"
    if ! verify_argv; then 
        _error "niepoprawne argumenty..."
        return $RET_FAIL
    fi

    _info $LINENO "ustawiam STDOUT"
    redirect_to_logfile

    _msg "wywolano o $(date)"
    _msg "system: ${g_system[0]}, forkow: ${g_system[1]}"

    _info $LINENO "przygotowuje liste plikow..."
    prepare_file_list $g_min_size "${g_paths[@]}"
    _msg "znaleziono ${#g_files[@]} plikow..."

    # do the job
    spawn_forks

    [ $g_stats_print -eq 1 ] && print_stats

    # cleanup & exit
    _info $LINENO "przywracam STDOUT"
    redirect_to_stdout

    return $RET_OK
}

# call the main
[[ $SHUNIT_TESTS -eq 0 ]] && main "$@"

# EOF
######################################################################## 
######################################################################## 


############################## DB ######################################

# that was an experiment which I decided to drop after all. 
# those functions provide a mechanism to generate consistently names global vars
# i.e. _db_set "abc" 1 will create glob. var ___g_db___abc=1
# left as a reference - do not use it

## #
## # @global prefix for the global variables generation
## #
## g_GlobalPrefix="___g_db___"
## 
## 
## #
## # @brief get variable from the db
## #
## _db_get() {
##  eval "echo \$${g_GlobalPrefix}_$1"  
## }
## 
## 
## #
## # @brief set variable in the db
## #
## _db_set() {
##  eval "${g_GlobalPrefix}_${1/./_}=\$2"
## }

######################################################################## 
