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


# common library shared between napi and subotage
declare -r LIBNAPI_COMMON="libnapi_common.sh"


# verify presence of the napi_common library
declare -r NAPI_COMMON_PATH=
if [ -z "$NAPI_COMMON_PATH" ] || [ ! -e "${NAPI_COMMON_PATH}/${LIBNAPI_COMMON}" ]; then
    echo
	echo "napi.sh i subotage.sh nie zostaly poprawnie zainstalowane"
	echo "uzyj skryptu install.sh (install.sh --help - pomoc)"
	echo "aby zainstalowac napi.sh w wybranym katalogu"
    echo
	exit -1
fi

# source the common routines
. "${NAPI_COMMON_PATH}/${LIBNAPI_COMMON}"

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
# @brief defines how long the subtitles should last (in ms)
#
g_lastingtime=3000

#
# @brief ipc file for multiprocess data exchange
#
g_ipc_file='none'

#
# supported subtitle file formats
#
declare -ar g_formats=( "microdvd" "mpl2" "subrip" "subviewer2" "tmplayer" )

#
# tools
#
g_cmd_cp='cp'
g_cmd_unlink='rm -rf'
g_cmd_awk='awk'

# override awk when unit tests want it
[ -n "${SHUNIT_TESTS_AWK:-}" ] && g_cmd_awk="${SHUNIT_TESTS_AWK}"

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
    local awk_code=''

read -r -d "" awk_code << 'EOF'
{
    gsub("^\\{[0-9]+\\}\\{[0-9]*\\}.*$", "success")
    print
}
EOF
    
    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        # match the format
        match_tmp=$(echo "$file_line" | LC_ALL=C LANG=C $g_cmd_awk "$awk_code")

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
    local awk_code=''

read -r -d "" awk_code << 'EOF'
{
    gsub("^\\[[0-9]+\\]\\[[0-9]*\\].*$", "success")
    print 
}
EOF

    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        match_tmp=$(echo "$file_line" | LC_ALL=C LANG=C $g_cmd_awk "$awk_code")

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

read -r -d "" match_ts << 'EOF'
{
    ts="[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[ \r\n]*"
    full_reg =  "^" prefix ts "$"
    print match($0, full_reg)
}
EOF

    while read file_line; do
        [ "$attempts" -eq 0 ] && break

        if [ "$counter_type" = "not_found" ]; then
                first_line=$(( max_attempts - attempts + 1 ))
                match_tmp=$(echo "$file_line" | \
                    LC_ALL=C LANG=C $g_cmd_awk '/^[0-9]+[\r\n]*$/')

                if [ -n "$match_tmp" ]; then
                    counter_type="newline"
                    continue
                fi

                # check for inline counter
                match_tmp=$(echo "$file_line" | \
                    LC_ALL=C LANG=C $g_cmd_awk -v prefix="[0-9]+ " "$match_ts")

                if [ "$match_tmp" -ne 0 ]; then
                    counter_type="inline"
                    match="subrip $first_line inline"
                    break
                fi

        elif [ "$counter_type" = "newline" ]; then
                # check for the time signature
                match_tmp=$(echo "$file_line" | \
                    LC_ALL=C LANG=C $g_cmd_awk -v prefix="" "$match_ts")

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

read -r -d "" match_ts << 'EOF'
{
    match_group="[0-9]+:[0-9]+:[0-9]+\\.[0-9]+"
    reg = "^" match_group "," match_group "[ \r\n]*$"
    where = match($0, reg)
    print where
}
EOF

    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))

        if [ "$header_line" -eq 0 ]; then
            # try to detect header
            match_tmp=$(echo "$file_line" | grep "\[INFORMATION\]")

            # set the header line
            [ -n "$match_tmp" ] && header_line="$first_line"
        fi

        match_tmp=$(echo "$file_line" | \
            LC_ALL=C LANG=C $g_cmd_awk "$match_ts")

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

read -r -d "" generic_check << 'EOF'
{
    # 1 - multiline check regexp (length: 10/11)
    # 2 - non-multiline regexp (length: 8/9)
    reg[1] = "^[0-9]+:[0-9]+:[0-9]+,[0-9]+[:;=,]+"
    reg[2] = "^[0-9]+:[0-9]+:[0-9]+[:;=,]+"
    result=-1

    for (i = 1; i<=2; i++) {
        where = match($0, reg[i])
        if (where) {
            result = i " " RLENGTH
            break
        }
    }

    print result
}
EOF


read -r -d "" extract_delim << 'EOF'
{
    print substr($0, match_len, 1)
}
EOF


    while read file_line; do
        [ "$attempts" -eq 0 ] && break
        first_line=$(( max_attempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))       

        match_tmp=$(echo "$file_line" | LC_ALL=C LANG=C $g_cmd_awk "$generic_check")

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
                LC_ALL=C LANG=C $g_cmd_awk -v match_len="${tmp_data[1]}" "$extract_delim")

            # is it a multiline format (hh:mm:ss,LINENO=)?
            [ "${tmp_data[0]}" -eq 1 ] && multiline=1

            # form the format identification string
            match="tmplayer $first_line $hour_digits $multiline $delim"
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
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    declare -a details=( ${g_inf[$___DETAILS]} )

read -r -d "" awk_code << 'EOF'
BEGIN {
    FS="\n"
    RS="" # blank line as record separator
    lines_processed=1
}

{
    if (lines_processed == 1) {
        rec = __start_line
    }
    else {
        rec = 1
    }

    line_data = rec + 1
    split($rec, start, ",")
    split(start[1], tm_start, ":")
    split(start[2], tm_stop, ":")

    time_start = ( tm_start[1]*3600 + tm_start[2]*60 + tm_start[3] + tm_start[4]/100 )
    time_stop = ( tm_stop[1]*3600 + tm_stop[2]*60 + tm_stop[3] + tm_stop[4]/100 )

    printf("%d %s %s ", lines_processed, time_start, time_stop )

    for (i=line_data; i<=NF; i++) {
        if (i>line_data) printf("|")
        printf("%s", $i);                       
    }

    lines_processed++
    printf("\n")
}
EOF

    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"

    echo "secs" > "$out_file_path"
    $g_cmd_awk -v __start_line="${details[1]}" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}


read_format_tmplayer() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    
    declare -a details=( ${g_inf[$___DETAILS]} )
    local delimiter=":"


# match="tmplayer $first_line $hour_digits $multiline $delim"
read -r -d "" awk_code << 'EOF'
BEGIN {
    lines_processed = 1
    prev_time_start = 0
    __last_time = __last_time / 1000
}

length($0) && NR >= __start_line {
    
    if (FS == ":") {
        if (__multiline) {
            split($3, ts, ",")
            hours=$1
            minutes=$2
            seconds=ts[1]
        }
        else {
            hours=$1
            minutes=$2
            seconds=$3
        }

        line_start = 4
    }
    else {
        if (__multiline) {
            split($1, ts, "[:,]")
        }
        else {
            split($1, ts, ":")
        }

        hours = ts[1]
        minutes = ts[2]
        seconds = ts[3]
        line_start = 2
    }
    
    time_start = hours*3600 + minutes*60 + seconds
    time_end = (time_start + __last_time)

    if (__multiline) {
        if (time_start == prev_time_start && NR > 1) {
            printf("|")
        }
        else {
            if (NR > 1) {
                printf("\n");   
                lines_processed++
            }

            printf("%d %02d:%02d:%02d %02d:%02d:%02d ", \
                lines_processed, \
                hours, \
                minutes, \
                seconds, \
                (time_end/3600), \
                ((time_end/60)%60), \
                (time_end%60))
            }

    } # __multiline
    else {
        printf("%d %02d:%02d:%02d %02d:%02d:%02d ", \
            lines_processed++, \
            hours, \
            minutes, \
            seconds, \
            (time_end/3600), \
            ((time_end/60)%60), \
            (time_end%60))
    }

    # display the line data
    for (i=line_start; i<=NF; i++) printf("%s", $i)

    if (__multiline) {
        prev_time_start = time_start
    }
    else {
        printf "\n"
    }
}
EOF

    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"

    # adjust the delimiter
    [ -n "${details[4]}" ] && delimiter="${details[4]}"
    _info $LINENO "delimiter [$delimiter]"

    echo "hms" > "$out_file_path"
    $g_cmd_awk -F "$delimiter" -v __start_line="${details[1]}" \
        -v __last_time="$g_lastingtime" \
        -v __multiline="${details[3]}" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}


read_format_microdvd() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    declare -a details=( ${g_inf[$___DETAILS]} )

read -r -d "" awk_code << 'EOF'
BEGIN {
    FS="[\\}\\{]"
    lines_processed = 1
    __last_time = __last_time / 1000
}

NR >= __start_line {
    frame_start=$2
    frame_end=$4
    line_data=5

    if (!($4 + 0)) {
        frame_end=$2 + __last_time*__fps
    }

    printf("%d %s %s ", lines_processed, (frame_start/__fps), (frame_end/__fps))
    lines_processed++

    for (i=line_data; i<=NF; i++) {
        # strip control codes - comment this out if you want to keep'em
        gsub( /[yYfFsScCP]+:.*/, "", $i )
        printf("%s", $i)
    }
    printf("\n")
}
EOF
    
    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"

    echo "secs" > "$out_file_path"
    $g_cmd_awk -v __start_line="${details[1]}" \
        -v __last_time="$g_lastingtime" \
        -v __fps="${g_inf[$___FPS]}" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}


read_format_mpl2() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    declare -a details=( "${g_inf[$___DETAILS]}" )

read -r -d "" awk_code << 'EOF'
BEGIN {
    FS="[][]"
    lines_processed = 1;   
    __last_time = __last_time / 100
}

length($0) && NR >= __start_line {

    frame_start=$2
    frame_end=$4

    if (!($4 + 0)) {
        frame_end=$2 + __last_time
    }

    printf("%s %s %s ", \
        lines_processed++, \
        (frame_start/10), \
        (frame_end/10))

    for (i=5; i<=NF; i++) printf("%s", $i)
    printf("\n")
}
EOF
    
    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"

    echo "secs" > "$out_file_path"
    $g_cmd_awk -v __start_line="${details[1]}" \
        -v __last_time="$g_lastingtime" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}


read_format_subrip() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''
    declare -a details=( ${g_inf[$___DETAILS]} )

read -r -d "" awk_code << 'EOF'
BEGIN {
    FS="\n"
    RS=""
    lines_processed = 1
}

length($0) {

    # this is to skip initial non subs lines
    if (lines_processed == 1) {
        rec = __start_line
    }
    else {
        rec = 1
    }

    line_data = rec + 1

    if (__counter_type == "inline") {
        gsub(",", ".", $rec)
        gsub("--> ", "", $rec)
        printf("%s ", $rec)
    }
    else {
        ts = rec + 1
        gsub(",", ".", $ts)
        gsub("--> ", "", $ts)
        gsub(" ", "", $rec)
        printf("%s %s ", $rec, $ts)
        line_data++
    }

    for (i = line_data; i<=NF; i++) {
        if (i > line_data) printf("|")
        printf("%s", $i)
    }
    printf("\n")

    lines_processed++
}
EOF
    
    _info $LINENO "szczegoly formatu: ${g_inf[$___DETAILS]}"
    _debug $LINENO "licznik: ${details[2]}"

    echo "hmsms" > "$out_file_path"
    $g_cmd_awk -v __start_line="${details[1]}" \
        -v __counter_type="${details[2]}" \
        "$awk_code" "$in_file_path" >> "$out_file_path"

    return $RET_OK
}

###############################################################################
############################ format read routines #############################
###############################################################################

###############################################################################
############################ format write routines ############################
###############################################################################

write_format_microdvd() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -r -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0
    ORS=" "
}

NR > 1 {
    if (time_type == "secs") {
        printf("{%d}{%d}", $2*__fps, $3*__fps)
    }
    else if (time_type == "hmsms" || time_type == "hms") {
        split($2, time_start, ":")
        split($3, time_stop, ":")

        start = (time_start[1]*3600 + time_start[2]*60 + time_start[3])*__fps
        stop = (time_stop[1]*3600 + time_stop[2]*60 + time_stop[3])*__fps

        printf("{%d}{%d}", start, stop)
    }
    else {
        exit 1
    }

    for (i=4; i<=NF; i++) {
        ORS=" "; if (i == NF) ORS="\n"
        print $i
    }
}
EOF

    _info $LINENO "szczegoly formatu: ${g_outf[$___DETAILS]}"
    _info $LINENO "fps: ${g_outf[$___FPS]}"

    if ! $g_cmd_awk -v __fps="${g_outf[$___FPS]}" \
        "$awk_code" "$in_file_path" > "$out_file_path"; then
        _error "nie mozna przekonwertowac formatu uniw. do microdvd"
        return $RET_FAIL;
    fi

    return $RET_OK
}


write_format_mpl2() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -r -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0
    ORS=" "
}

NR > 1 {
    if (time_type == "secs") {
        printf("[%d][%d]", $2*10, $3*10)
    }
    else if (time_type == "hmsms" || time_type == "hms") {
        split($2, time_start, ":")
        split($3, time_stop, ":")

        start = (time_start[1]*3600 + time_start[2]*60 + time_start[3])*10
        stop = (time_stop[1]*3600 + time_stop[2]*60 + time_stop[3])*10

        printf("[%d][%d]", start, stop)
    }
    else {
        exit 1
    }
    
    for (i=4; i<=NF; i++) {
        ORS=" "; if (i == NF) ORS="\n"
        print $i
    }
}
EOF

    _info $LINENO "szczegoly formatu: ${g_outf[$___DETAILS]}"

    if ! $g_cmd_awk "$awk_code" "$in_file_path" > "$out_file_path"; then
        _error "nie mozna przekonwertowac formatu uniw. do mpl2"
        return $RET_FAIL;
    fi
    return $RET_OK
}


write_format_subrip() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -r -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0
    ORS=" "
}

function print_ts(cnt, sh, sm, ss, sc, eh, em, es, ec) {

    printf("%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n", \
        cnt, \
        sh,sm,ss,sc, \
        eh,em,es,ec)
}

function print_content() {
    for (i=4; i<=NF; i++) {
        tmp = sprintf("%s", $i)
        gsub(/\|/, "\n", tmp)
        ORS=" "; if (i == NF) ORS="\n"
        print tmp
    }

    printf("\n")
}

NR > 1 {
    cnt = $1

    if (time_type == "secs") {
        sh = $2/3600
        sm = ($2/60) % 60
        ss = $2%60
        sc = int(($2 - int($2))*1000)

        eh = $3/3600
        em = ($3/60) % 60
        es = $3%60
        ec = int(($3 - int($3))*1000)
    }
    else if (time_type == "hmsms" || time_type == "hms") {
        split($2, start, ":")
        split($3, stop, ":")

        sh = start[1]
        sm = start[2]
        ss = start[3]
        sc = 0

        eh = stop[1]
        em = stop[2]
        es = stop[3]
        ec = 0

        if (time_type == "hmsms") {
            sc = int((start[3] - int(start[3]))*1000)
            ec = int((stop[3] - int(stop[3]))*1000)
        }
    }
    else {
        exit 1
    }

    print_ts(cnt, sh, sm, ss, sc, eh, em, es, ec)
    print_content()
}
EOF

    # use the AWK force :)
    if ! LC_ALL=C LANG=C $g_cmd_awk "$awk_code" "$in_file_path" > "$out_file_path"; then
        return $RET_FAIL;
    fi
    return $RET_OK
}


write_format_subviewer2() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -r -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0
    ORS=" "
}

NR > 1 {

    if (time_type == "secs") {
        sh = $2/3600
        sm = ($2/60)%60
        ss = $2%60
        sc = int( ($2 - int($2))*100 )

        eh = $3/3600
        em = ($3/60)%60
        es = $3%60
        ec = int( ($3 - int($3))*100 )
    }
    else if (time_type == "hmsms" || time_type == "hms") {
        split($2, time_start, ":")
        split($3, time_stop, ":")

        sh = time_start[1]
        sm = time_start[2]
        ss = time_start[3]
        sc = 0

        eh = time_stop[1]
        em = time_stop[2]
        es = time_stop[3]
        ec = 0

        if (time_type == "hmsms") {
            sc = int( (time_start[3] - int(time_start[3]))*100 )
            ec = int( (time_stop[3] - int(time_stop[3]))*100 )
        }
    }
    else {
        exit 1
    }
    
    printf("%02d:%02d:%02d.%02d,%02d:%02d:%02d.%02d\n", \
        sh, sm, ss, sc, \
        eh, em, es, ec)

    for (i=4; i<=NF; i++) {
        tmp = sprintf("%s", $i)
        gsub(/\|/, "\n", tmp)
        ORS=" "; if (i == NF) ORS="\n"
        print tmp
    }

    printf("\n")
}
EOF

    _info $LINENO "szczegoly formatu: ${g_outf[$___DETAILS]}"
    _info $LINENO "fps: ${g_outf[$___FPS]}"

    echo    "[INFORMATION]" > "$out_file_path"  
    echo    "[TITLE] none" >> "$out_file_path"  
    echo    "[AUTHOR] none" >> "$out_file_path" 
    echo    "[SOURCE]" >> "$out_file_path"  
    echo    "[FILEPATH]Media" >> "$out_file_path"
    echo    "[DELAY]0" >> "$out_file_path"
    echo    "[COMMENT] Created using subotage - universal subtitle converter for bash" >> "$out_file_path"
    echo    "[END INFORMATION]" >> "$out_file_path" 
    echo    "[SUBTITLE]" >> "$out_file_path"
    echo    "[COLF]&HFFFFFF,[STYLE]bd,[SIZE]18,[FONT]Arial" >> "$out_file_path"

    if ! $g_cmd_awk "$awk_code" "$in_file_path" >> "$out_file_path"; then
        _error "nie mozna przekonwertowac formatu uniw. do subviewer2"
        return $RET_FAIL;
    fi

    return $RET_OK
}


write_format_tmplayer() {
    local in_file_path="$1"
    local out_file_path="$2"
    local awk_code=''

read -r -d "" awk_code << 'EOF'
NR == 1 {
    time_type=$0
    ORS=" "
}

NR > 1 {

    if (time_type == "secs") {
        sh = $2/3600
        sm = ($2/60)%60
        ss = $2%60
        printf("%02d:%02d:%02d:", sh, sm, ss)
    }
    else if (time_type == "hms") {
        printf("%s:", $2)
    }
    else if (time_type == "hmsms") {
        # just strip the fractional part
        idx = index($2, ".") - 1
        if (idx) {
            printf("%s:", substr($2, 1, idx))
        }
        else {
            # universal format is invalid - failure
            exit 1
        }
    }
    else {
        exit 1
    }
    
    for (i=4; i<=NF; i++) {
        ORS=" "; if (i == NF) ORS="\n"
        print $i
    }
}
EOF

    _info $LINENO "szczegoly formatu: ${g_outf[$___DETAILS]}"

    if ! $g_cmd_awk "$awk_code" "$in_file_path" > "$out_file_path"; then
        _error "nie mozna przekonwertowac formatu uniw. do tmplayer"
        return $RET_FAIL
    fi

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


convert_dos2unix() {
    $g_cmd_awk '{ sub("\r$",""); print }'
}


correct_overlaps() {
    local file_path="$1"
    local awk_code=''

    local tmp_file=$(mktemp overlaps.XXXXXXXX)
    local file_name=$(basename "$file_path")
    local num_lines=0
    local status=0

    local rv=$RET_OK

read -r -d "" awk_code << 'EOF'
BEGIN {
    counter = 0
    line_counter = 0
    previous_end = 0
    time_type = "unknown"
}

NR == 1 {
    time_type=$0
    print $0
}

#
# convert the timestamp to milliseconds timestamp
# This function unifies the hms/hmsms/secs format to
# a milliseconds timestamp
#
function conv_to_ms(time, format) {
    rv = 0

    if ("secs" == format) {
        rv = (time + 0) * 1000
    }
    else if ("hms" == format || "hmsms" == format) {
        split(time, ts, "[:.]")

        rv = ts[1] * 3600 + ts[2] * 60 + ts[3]
        rv = rv*1000

        if ("hmsms" == format) rv += ts[4]
    }

    return rv
}


NR > 1 {
    if (( time_type != "secs" ) &&
        ( time_type != "hms" ) &&
        ( time_type != "hmsms" )) {
        # format unsupported
        exit 2
    }

    # memorize the number of fields in the line
    # in this two-line queue
    lines[counter,0] = NF

    # buffer the line
    for (i=1; i<=NF; i++) lines[counter,i] = $i

    # correct the overlapping subtitles
    # current line index
    cli = counter == 0 ? 1 : 0

    # previous line index
    pli = cli == 1 ? 0 : 1

    # current ending time-stamp
    cets = conv_to_ms(lines[cli, 3], time_type)

    # previous starting time-stamp
    psts = conv_to_ms(lines[pli, 2], time_type)

    if (cets > psts) lines[cli, 3] = lines[pli, 2]

    # print every second line or if line counter == __num_lines
    # flush'em both at once
    do {
       line_counter++
       counter = (counter + 1) % 2

       if ((line_counter >=2 || line_counter == __num_lines) && lines[counter,0]>0) {

           # print the line counter, start & stop timestamps
           printf("%s %s %s ",
                lines[counter,1], lines[counter,2], lines[counter,3])

           # print the remaining part of the line
           for (i = 4; i<=lines[counter,0]; i++)
               printf("%s ", lines[counter,i])

           printf("\n")
       }
    } while (line_counter == __num_lines)
}
EOF
    _info $LINENO "sprawdzam plik uniwersalny i usuwam overlaps"

    num_lines=$(cat "$file_path" | count_lines)
    num_lines=$(( num_lines - 1 ))

    $g_cmd_awk -v __num_lines="$num_lines" \
        "$awk_code" "$file_path" > "$tmp_file"
    status=$?

    case "$status" in
        1)
            _error "blad przy poprawianiu overlaps. przywracam oryg. pliki"
            $g_cmd_cp "$file_path" "$tmp_file"
            rv=$RET_FAIL
            ;;

        2)
            _warning "brak korekcji nakladajacych sie napisow, dla formatu we."
            $g_cmd_cp "$file_path" "$tmp_file"
            rv=$RET_NOACT
            ;;

        *)
            _debug $LINENO "skorygowano nakladajace sie napisy"
            ;;
    esac

    _info $LINENO "kopiuje poprawiony plik na oryginalny [$tmp_file] -> [$file_name]"
    $g_cmd_cp "$tmp_file" "$file_path"

    # get rid of the temporary file
    [ -e "$tmp_file" ] &&
        _debug $LINENO "usuwam plik tymczasowy" &&
        $g_cmd_unlink "$tmp_file"

    return $rv
}


#
# @brief list supported formats
#
list_formats() {
    local long="${1:-0}"

    local counter=0
    local fmt=''

    # description for every supported file format
    desc=( "{start}{stop} - Format based on frames. Uses given framerate\n\t\t(default is [${g_inf[$___FPS]}] fps)" \
           "[start][stop] format. The unit is time based == 0.1 sec" \
           "hh.mm.ss,mmm -> hh.mm.ss,mmm format" \
           "hh:mm:ss:dd,hh:mm:ss:dd format with header.\n\t\tResolution = 10ms. Header is ignored" \
           "hh:mm:ss timestamp format without the\n\t\tstop time information. Mostly deprecated" ) 

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

            # thread id - this one's hidden not listed in the usage()
            "-t" | "--thread-id") varname="g_output[$___FORK]"
                msg="nie okreslono id watku"
                ;;

            # message-cnt - this one's hidden not listed in the usage()
            "-m" | "--message-cnt") varname="g_output[$___CNT]"
                msg="nie okreslono licznika logow"
                ;;

            # message-cnt - this one's hidden not listed in the usage()
            "--ipc-file") varname="g_ipc_file"
                msg="nie okreslono pliku ipc"
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
                msg="okresl poziom gadatliwosci (0 - najcichszy, 3 - najbardziej gadatliwy, 4 - insane)"
                ;;

            # sanity check for unknown parameters
            *)
                _error "nieznany parametr: [$1]"
                return $RET_PARAM
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

    # make sure first that the printing functions will work
    case "${g_output[$___VERBOSITY]}" in
        0 | 1 | 2 | 3 ) 
            ;;

        4 )
            _debug_insane
            ;;

        *)
            _error "poziom gadatliwosci moze miec jedynie wartosci z zakresu (0-3)"
            return $RET_BREAK
            ;;
    esac

    _debug "sprawdzam plik wejsciowy"
    [ -z "${g_inf[$___PATH]}" ] || [ "${g_inf[$___PATH]}" = "none" ] || [ ! -s "${g_inf[$___PATH]}" ] &&
        _error "plik wejsciowy niepoprawny" &&
        return $RET_PARAM

    # check presence of output file
    [ -z "${g_outf[$___PATH]}" ] || 
    [ "${g_outf[$___PATH]}" = "none" ] &&
    [ "$g_getinfo" -eq 0 ] &&
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

    return $RET_OK
}


#
# @brief tries to parse out fps data from microdvd format line
#
detect_microdvd_fps() {
    local awk_code=''


read -r -d "" awk_code << 'EOF'
BEGIN {
    FS="}"
}

{
    # regular expressions to match the fps data
    regs[1]="[0-9]+\\.[0-9]+ *(fps)*"
    regs[2]="[0-9]+ *(fps)+"
    regs[3]="[0-9]+ *$"

    # execute regexp each by each and seek for a match
    for (r = 1; r<=3; r++) {

        where = match($3, regs[r])
        if (where) {
            m = substr($3, where, RLENGTH)

            # extract only numbers
            where = match(m, "[\\.0-9]+")

            if (where) {
                print substr(m, 1, RLENGTH);
                # we've got a match quit other attempts
                exit 0
            }
        }
    }

    exit 1
}
EOF

    if ! LC_ALL=C LANG=C $g_cmd_awk "$awk_code"; then
        return $RET_FAIL
    fi

    return $RET_OK
}


correct_fps() {
    local tmp=0
    local i=0
    declare -a det=()
 
    if float_eq "${g_inf[$___FPS]}" 0; then

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

                [ "$i" -ge 2 ] &&
                [ -n "${det[$i]}" ] && 
                [ "${det[$i]}" != "0" ] && 
                    _info $LINENO "ustawiam wykryty fps jako: ${det[$i]}" &&
                    g_inf[$___FPS]="${det[$i]}"
                ;;
            *) 
                # do nothin'
                ;;
        esac
    fi

    if float_eq "${g_outf[$___FPS]}" 0; then
        _info $LINENO "nie podano fps pliku wyjsciowego, zakladam taki sam jak wejscie"
        g_outf[$___FPS]="${g_inf[$___FPS]}"
    fi

    return $RET_OK
}


check_if_conv_needed() {
    local inf=$(echo "${g_inf[$___FORMAT]}" | lcase)
    local outf=$(echo "${g_outf[$___FORMAT]}" | lcase)
    local rv=$RET_OK

    _debug $LINENO "sprawdzam formaty plikow [$inf]/[$outf]"
    [ "$inf" != "$outf" ] &&
        _debug $LINENO "formaty rozne, konwersja wymagana" &&
        return $RET_OK

    case "$inf" in
        'microdvd')
            _debug $LINENO "porownuje fps dla formatu microdvd"
            if float_eq "${g_inf[$___FPS]}" "${g_outf[$___FPS]}"; then
                _warning "konwersja nie jest wymagana, fps pliku wejsciowego jest rowny zadanemu"
                rv=$RET_NOACT
            fi
            ;;
        *)
            _debug $LINENO "formaty zgodne - konwersja nie wymagana"
            rv=$RET_NOACT
            ;;
    esac

    return $rv
}


print_format_summary() {
    local prefix="$1"
    local file_name=$(basename "$2")

    if [ "$g_getinfo" -eq 1 ] || [ "${g_output[$___VERBOSITY]}" -ge 2 ]; then
        _status "${prefix}FILE" "$file_name"
        _status "${prefix}FORMAT" "$3"
        _status "${prefix}FPS" "$4"
        _status "${prefix}DETAILS" "$5"
    fi
    return $RET_OK
}


convert_formats() {
    local freader="$1"
    local fwriter="$2"
    local tmp_output=$(mktemp conversion.XXXXXXXX)
    local unix_ln=$(mktemp conversion_unix.XXXXXXXX)

    local rv=$RET_OK
    local status=$RET_OK

    if [ "${g_inf[$___PATH]}" = "none" ] || [ ! -e "${g_inf[$___PATH]}" ]; then
        _error "plik wejsciowy [${g_inf[$___PATH]}] nie istnieje"
        return $RET_PARAM
    fi

    cat "${g_inf[$___PATH]}" | convert_dos2unix > "$unix_ln"
    
    if ! $freader "$unix_ln" "$tmp_output"; then
        _error "blad podczas konwersji pliku wejsciowego na format uniwersalny"
        rv=$RET_FAIL
    else
        correct_overlaps "$tmp_output"
        if ! $fwriter "$tmp_output" "${g_outf[$___PATH]}"; then
            _error "blad podczas konwersji do formatu docelowego"
            rv=$RET_FAIL
        fi
    fi

    # get rid of the temporary file
    [ -e "$unix_ln" ] && $g_cmd_unlink "$unix_ln"
    [ -e "$tmp_output" ] && $g_cmd_unlink "$tmp_output"
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
    local file_name=''

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

    file_name=$(basename "${g_outf[$___PATH]}")

    # check if the conversion is needed
    check_if_conv_needed
    status=$?
    [ "$status" -eq $RET_NOACT ] && 
        _status "SKIP" "$file_name" &&
        return "$status"

    # create read/write routine names & verify them
    freader="read_format_${g_inf[$___FORMAT]}"
    if ! verify_function_presence "$freader"; then
        _error "funkcja czytajaca [$freader] nie istnieje"
        return $RET_BREAK
    fi
    
    fwriter="write_format_${g_outf[$___FORMAT]}"
    if ! verify_function_presence "$freader"; then
        _error "funkcja piszaca do formatu [$freader] nie istnieje"
        return $RET_BREAK 
    fi
    
    convert_formats "$freader" "$fwriter"
    status=$?

    [ "$status" -eq $RET_OK ] && _status "OK" "$file_name"

    return $status
}


#
# @brief this is to inform any calling party about some internal data
#
create_output_summary() {
    if [ -e "$g_ipc_file" ] && 
        [ "$g_ipc_file" != "none" ]; then
        # message counter
        echo "${g_output[$___CNT]}" > "$g_ipc_file"
    fi
    return $RET_OK
}

################################################################################

#
# @brief main function 
# 
main() {
    # first positional
    local arg1="${1:-}"
    local status=$RET_OK
    local rv=0;

    # if no arguments are given, then print help and exit
    [ $# -lt 1 ] || [ "$arg1" = "--help" ] || [ "$arg1" = "-h" ] && 
        usage &&
        return $RET_OK

    # get argv
    parse_argv "$@"
    rv=$?

    # check the parse_argv return value
    case "$rv" in
        "$RET_OK" )
            status=$RET_OK
            ;;

        "$RET_BREAK" )
            return $RET_OK
            ;;

        *)
        _error "niepoprawne argumenty..."
        status=$RET_FAIL
    esac

    # verify collected arguments
    if [ "$status" -eq $RET_OK ]; then
        # verify argv
        if ! verify_argv; then 
            _error "niepoprawne argumenty..."
            status=$RET_FAIL
        fi
    fi

    # process the file
    if [ "$status" -eq $RET_OK ]; then
        _debug $LINENO "argumenty poprawne, przetwarzam plik"
        process_file
        status=$?
    fi

    # inform ipc
    create_output_summary
    return $status
}


# call the main
[ "${SHUNIT_TESTS:-0}" -eq 0 ] && main "$@"

# EOF
