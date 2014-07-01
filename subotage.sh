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
declare -r NAPI_COMMON_PATH=.
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
declare -r ___DETAILS=3

################################################################################

declare -r g_default_fps='23.98'

#
# input details
# 0 - file path
# 1 - format
# 2 - fps
# 3 - format specific details
#
declare -a g_inf=( 'none' 'none' '0' '' )

#
# input details
# 0 - file path
# 1 - format
# 2 - fps
# 3 - format specific details
#
declare -a g_outf=( 'none' 'subrip' '0' '1 0' )

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
declare -ar g_formats=( "microdvd" "mpl2" "subrip" "subviewer2" "tmplayer" )

################################################################################


################################################################################
########################## format detection routines ###########################
################################################################################
# each detection function should return a string delimited by spaces containing:
# - format name (as in g_formats table) or "not_detedted" string
#       if file has not been identified
# - line in file on which a valid format line has been found (starting from 1)
# - format specific data
################################################################################

# microdvd format detection routine
check_format_microdvd() {
    local file_path="$1"

    local max_attempts=3
    local attempts=$max_attempts
    local first_line=1
    local match="not_detected"
    local match_tmp=""
    local fps_detected=''
    
    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        match_tmp=$(echo "$file_line" | \
            LANG=C awk '{ gsub("^{[0-9]+}{[0-9]*}.*$", "success"); print }')

        # skip empty lines
        [ -z "$match_tmp" ] && continue

        # we've got a match
        if [ "$match_tmp" = "success" ]; then
            fps_detected=$(echo "$file_line" | \
                lcase | \
                detect_microdvd_fps | \
                strip_newline)

            if [ -z "$fps_detected" ]; then
                match="microdvd $first_line"
            else
                match="microdvd $first_line $fps_detected"
            fi

            break
        fi

    done < "$file_path"

    echo "$match"
    return $RET_OK
}


# mpl2 format detection routine
check_format_mpl2() {
    local file_path="$1"

    local max_attempts=3
    local attempts=$max_attempts
    local first_line=1
    local match="not_detected"
    local match_tmp=""

    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        match_tmp=$(echo "$file_line" | \
            LANG=C awk '{ gsub("^\\[[0-9]+\\]\\[[0-9]*\\].*$", "success"); print }')

        # skip empty lines
        [ -z "$match_tmp" ] && continue

        # we've got a match
        if [ "$match_tmp" = "success" ]; then
            match="mpl2 $first_line"
            break
        fi
    done < "$file_path"

    echo "$match"
    return $RET_OK
}


# subrip format detection routine
check_format_subrip() {
    local file_path="$1"
    local max_attempts=8
    local first_line=1
    local attempts=$max_attempts

    local counter_type="not_found"
    local match="not_detected"
    local match_tmp=''
    local match_ts=''

read -d "" match_ts << 'EOF'
{
    ts="[0-9]+:[0-9]+:[0-9]+,[0-9]+\ -->\ [0-9]+:[0-9]+:[0-9]+,[0-9]+[\\r\\n]*"
    full_reg =  "^" prefix ts "$";
    print match($0, full_reg);
}
EOF

    while read file_line; do
        [ "$attempts" -eq 0 ] && break

        if [ "$counter_type" = "not_found" ]; then
                first_line=$(( max_attempts - attempts + 1 ))
                match_tmp=$(echo "$file_line" | \
                    LANG=C awk '/^[0-9]+[\r\n]*$/')

                if [ -n "$match_tmp" ]; then
                    counter_type="newline"
                    continue
                fi

                # check for inline counter
                match_tmp=$(echo "$file_line" | \
                    LANG=C awk -v prefix="[0-9]+ " "$match_ts")

                if [ "$match_tmp" -ne 0 ]; then
                    counter_type="inline"
                    match="subrip $first_line inline"
                    break
                fi

        elif [ "$counter_type" = "newline" ]; then
                # check for the time signature
                match_tmp=$(echo "$file_line" | \
                    LANG=C awk -v prefix="" "$match_ts")

                if [ "$match_tmp" -ne 0 ]; then
                    counter_type="newline"
                    match="subrip $first_line newline"
                    break
                fi
        fi

        attempts=$(( attempts - 1 ))
    done < "$file_path"

    echo "$match"
    return $RET_OK
}


check_format_subviewer2() {
    local file_path="$1"
    local match="not_detected"
    local match_tmp=''
    local max_attempts=16
    local attempts=$max_attempts

    local first_line=0
    local header_line=0
    local match_ts=''

read -d "" match_ts << 'EOF'
{
    match_group="[0-9]+:[0-9]+:[0-9]+\.[0-9]+"
    reg = "^" match_group "," match_group "[:space:]*[\\r\\n]*$"
    where = match($0, reg);
    print where;
}
EOF

    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))

        if [ "$header_line" -eq 0 ]; then
            # try to detect header
            match_tmp=$(echo "$file_line" | grep "\[INFORMATION\]")

            # set the header line
            [ -n "$match_tmp" ] && header_line="$first_line"
        fi

        match_tmp=$(echo "$file_line" | \
            LANG=C awk "$match_ts")

        # we've got a match
        if [ "$match_tmp" -ne 0 ]; then
            match="subviewer2 $first_line $header_line"
            break
        fi
    done < "$file_path"

    echo "$match"
    return $RET_OK
}


# tmplayer format detection routine
check_format_tmplayer() {
    local file_path="$1"

    local max_attempts=3
    local attempts=$max_attempts
    local first_line=1
    local match="not_detected"
    local match_tmp=""

    declare -a tmp_data=()
    local hour_digits=2
    local multiline=0
    local delim=':'

    local generic_check=''
    local extract_delim=''

read -d "" generic_check << 'EOF'
{
    # 1 - multiline check regexp (length: 10/11)
    # 2 - non-multiline regexp (length: 8/9)
    reg[1] = "^[0-9]{1,2}:[0-9]{2}:[0-9]{2},[0-9]{1}[:;=,]{1}";
    reg[2] = "^[0-9]{1,2}:[0-9]{2}:[0-9]{2}[:;=,]{1}";
    result=-1

    for (i in reg) {
        where = match($0, reg[i]);
        if (where) {
            result = i " " RLENGTH;
            break;
        }
    }

    print result;
}
EOF


read -d "" extract_delim << 'EOF'
{
    print substr($0, match_len, 1);
}
EOF


    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        match_tmp=$(echo "$file_line" | LANG=C awk "$generic_check")

        # skip empty lines
        [ -z "$match_tmp" ] && continue

        # we've got a match, get more data
        if [ "$match_tmp" != "-1" ]; then

            tmp_data=( $match_tmp )


            # determine the hour digits
            [ "${tmp_data[1]}" -eq 10 ] || 
            [ "${tmp_data[1]}" -eq 8 ] && hour_digits=1

            # extract delimiter
            delim=$(echo "$file_line" | \
                LANG=C awk -v match_len="${tmp_data[1]}" "$extract_delim")

            # is it a multiline format (hh:mm:ss,LINENO=)?
            [ "${tmp_data[0]}" -eq 1 ] && multiline=1

            # form the format identification string
            match="tmplayer $first_line $hour_digits $multiline [$delim]"
            break
        fi

    done < "$file_path"
    
    echo "$match"
    return $RET_OK
}


###############################################################################
########################## format detection routines ##########################
###############################################################################


###############################################################################
############################ format read routines #############################
###############################################################################
# Input parameters
# - filename to process
# - output filename
#
# Output: 
# - should be written in universal format. Line format
# - subtitle line number
# - time type: ( "hms", "hmsms", "secs" )
# - start time
# - stop time
# - line itself
#
# Return Value
# - $RET_OK - when file is processed and all the data is converted to 
#             universal format present in /tmp file
###############################################################################

read_format_subviewer2() {
    return $RET_OK
}

read_format_tmplayer() {
    
    return $RET_OK
}


read_format_microdvd() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    declare -a details=( "${g_inf[$___DETAILS]}" )

read -d "" awk_code << 'EOF'
BEGIN {
    FS="[{}]+"
    lines_processed=0;
}
/^[:space:]*$/ {
    next;
}
NR >= __start_line {
    frame_start=$2;
    frame_end=$3;
    line_data=4;

    if (!($3 + 0)) {
        line_data=3;
        frame_end=$2 + __last_time*__fps;        
    }

    printf("%s %s %s ", line_processed++, 
        (frame_start/__fps),
        (frame_end/__fps));

    for (i=line_data; i<=NF; i++) printf("%s", $i);
    printf("\\n");
}
EOF
    
    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"

    echo "secs" > "$out_file_path"
    awk -v __start_line="${details[1]}" \
        -v __last_time="$g_lastingtime" \
        -v __fps="${g_inf[$___FPS]}" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}


read_format_mpl2() {
    
    return $RET_OK
}

read_format_subrip() {
    
    return $RET_OK
}

###############################################################################
############################ format read routines #############################
###############################################################################

###############################################################################
############################ format write routines ############################
###############################################################################

write_format_subrip() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0;
}

NR > 1 {
}

END {
    printf("\\n\\n");
}
EOF

    awk "$awk_code" "$in_file_path" > "$out_file_path"

    
    return $RET_OK
}

###############################################################################
############################ format write routines ############################
###############################################################################

guess_format() {
    local file_path="$1"
    local lc=$(cat "$file_path" 2> /dev/null | count_lines)

    local fmt='not_detected'
    local detector='none'
    local f=''
    local rv=$RET_OK

    [ -z "$lc" ] || [ "$lc" -eq 0 ] &&
        return $RET_FAIL

    for f in "${g_formats[@]}"; do
        detector="check_format_${f}"

        # check if detector exists
        if ! verify_function_presence "$detector"; then
            return $RET_FAIL
        fi

        fmt=$($detector "$file_path")
        [ "$fmt" != "not_detected" ] && break
    done

    [ "$fmt" = "not_detected" ] && rv=$RET_FAIL

    echo "$fmt"
    return $rv
}


correct_overlaps() {
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

    # check presence of output file
    [ -z "${g_outf[$___PATH]}" ] || [ "${g_outf[$___PATH]}" = "none" ] || [ ! -s "${g_inf[$___PATH]}" ] &&
        _error "nie okreslono pliku wyjsciowego" &&
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


#
# @brief tries to parse out fps data from microdvd format line
#
detect_microdvd_fps() {
    local awk_code=''


read -d "" awk_code << 'EOF'
BEGIN {
    FS="}"
}

{
    # regular expressions to match the fps data
    regs[1]="[0-9]{2}[\.0-9]{2,}[:space:]*(fps)*";
    regs[2]="[0-9]{2}+[:space:]*(fps)*";

    # execute regexp each by each and seek for a match
    for (r in regs) {

        where = match($3, regs[r]);
        if (where) {
            m = substr($3, where, RLENGTH);

            # extract only numbers
            print substr(m, match(m, "[\.0-9]+"), RLENGTH);

            break;
        }
    }
}
EOF

    LANG=C awk "$awk_code"
    return $RET_OK
}


correct_fps() {
    local tmp=0
    local i=0
    declare -a det=()
 
    if [ "${g_inf[$___FPS]}" -eq 0 ]; then

        # set default setting
        g_inf[$___FPS]="$g_default_fps"
        _info $LINENO "przyjmuje wartosc domyslna fps dla plik we. ${g_inf[$___FPS]}"

        case "${g_inf[$___FORMAT]}" in
            'microdvd' )
                # in case of microdvd the format, the
                # detection routine, should place fps as the last
                # element
                det=( ${g_inf[$___DETAILS]} )
                i=${#det[@]}
                i=$(( i - 1 ))
                [ -n "${det[$i]}" ] && [ "${det[$i]}" != "0" ] && 
                    _info $LINENO "ustawiam wykryty fps jako: ${det[$i]}" &&
                    g_inf[$___FPS]="${det[$i]}"
                ;;
            *) 
                # do nothin'
                ;;
        esac
    fi

    [ "${g_outf[$___FPS]}" -eq 0 ] &&
        _info $LINENO "nie podano fps pliku wyjsciowego, zakladam taki sam jak wejscie" &&
        g_outf[$___FPS]="${g_inf[$___FPS]}"

    return $RET_OK
}


check_if_conv_needed() {
    local inf=$(echo "${g_inf[$___FORMAT]}" | lcase)
    local outf=$(echo "${g_outf[$___FORMAT]}" | lcase)
    local rv=$RET_OK

    [ "$inf" != "$outf" ] &&
        _debug $LINENO "formaty rozne, konwersja wymagana" &&
        return $RET_OK

    case "$inf" in
        'microdvd')
            _debug $LINENO "porownuje fps dla formatu microdvd"
            if float_eq "${g_inf[$___FPS]}" "${g_outf[$___FPS]}"; then
                _warning "konwersja nie jest wymagana, fps pliku wejsciowego jest rowny zadanemu"
                rc=$RET_NOACT
            fi
            ;;
        *)
            rv=$RET_NOACT
            ;;
    esac

    return $RET_OK
}


print_format_summary() {
    local prefix="$1"
    local file_name=$(basename "$2")
    _status "${prefix}FILE" "$file_name"
    _status "${prefix}FORMAT" "$3"
    _status "${prefix}FPS" "$4"
    _status "${prefix}DETAILS" "$5"
    return $RET_OK
}


convert_formats() {
    local freader="$1"
    local fwriter="$2"
    local tmp_output=$(mktemp conversion.XXXXXXXX)

    local rv=$RET_OK
    local status=$RET_OK
    
    if ! $freader "${g_inf[$___PATH]}" "$tmp_output"; then
        _error "blad podczas konwersji pliku wejsciowego na format uniwersalny"
        rv=$RET_FAIL
    else
        correct_overlaps "$tmp_output"
        if ! $fwriter "$tmp_output" "${g_outf[$___PATH]}"; then
            _error "blad podczas konwersji do formatu docelowego"
            rv=$RET_FAIL
        fi
    fi

    # TODO - REMOVE ME, DISABLED THAT TEMPORARILY
    # [ -e "$tmp_output" ] && rm -rf "$tmp_output"
    return $rv
}


#
# process the file
#
process_file() {
    local status=$RET_OK
    local freader=''
    local fwriter=''
    declare -a fmt=()

    g_inf[$___FORMAT]=$(echo "${g_inf[$___FORMAT]}" | lcase)
    g_outf[$___FORMAT]=$(echo "${g_outf[$___FORMAT]}" | lcase)

    # detect the format if requested
    if [ "$g_getinfo" -eq 1 ] || [ "${g_inf[$___FORMAT]}" = "none" ]; then
        _debug $LINENO "wykrywam format pliku wejsciowego"

        g_inf[$___DETAILS]=$(guess_format "${g_inf[$___PATH]}")
        status=$?

        fmt=( ${g_inf[$___DETAILS]} )
        g_inf[$___FORMAT]=${fmt[0]}
    fi

    # format detection failure
    [ "$status" -ne $RET_OK ] &&
        _error "nie mozna wykryc formatu pliku wejsciowego" &&
        return $RET_FAIL

    # detect fps if not given
    correct_fps

    # display input details
    print_format_summary "IN_" "${g_inf[@]}"

    # display output details
    print_format_summary "OUT_" "${g_outf[@]}"

    # we've got the data, quit
    [ "$g_getinfo" -eq 1 ] && return $RET_BREAK

    # check if the conversion is needed
    check_if_conv_needed
    status=$?
    [ "$status" -eq $RET_NOACT ] && return "$status"

    # create read/write routine names & verify them
    freader="read_format_${g_inf[$___FORMAT]}"
    if ! verify_function_presence "$freader"; then
        _error "funkcja czytajaca [$freader] nie istnieje"
        return $RET_BREAK
    fi
    
    fwriter="write_format_${g_outf[$___FORMAT]}"
    if ! verify_function_presence "$freader"; then
        _error "funkcja piszaca do formatu [$freader] nie istnieje"
        # return $RET_BREAK # TODO - REMOVE THIS - DISABLED THAT TEMPORARILY
    fi
    
    convert_formats "$freader" "$fwriter"
    status=$?

    return $status
}


################################################################################

#
# @brief main function 
# 
main() {
    # first positional
    local arg1="${1:-}"
    local status=$RET_OK

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

    # process the file
    _debug $LINENO "argumenty poprawne, przetwarzam plik"
    process_file
    status=$?

    return $status
}


# call the main
[ "${SHUNIT_TESTS:-0}" -eq 0 ] && main "$@"

# EOF
