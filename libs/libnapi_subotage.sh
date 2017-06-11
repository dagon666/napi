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

declare -r ___g_subotageNotDetectedMarker="not_detected"

declare -r ___g_subotageIOFPath=0
declare -r ___g_subotageIOFFormat=1
declare -r ___g_subotageIOFFps=2
declare -r ___g_subotageIOFDetails=3

#
# input details specific information
# 0 - file path
# 1 - format
# 2 - fps
# 3 - format specific details
#
declare -a ___g_subotageIF=( 'none' 'none' '0' '' )

#
# input details
# 0 - file path
# 1 - format
# 2 - fps
# 3 - format specific details
#
declare -a ___g_subotageOF=( 'none' 'subrip' '0' '1 0' )



#
# @brief defines how long the subtitles should last (in ms)
#
___g_subotageLastingTimeMs=3000

################################################################################

_subotage_init() {
    [ -z "$LANG" ] &&
        export LANG=C

    [ -z "$LC_ALL" ] &&
        export LC_ALL=C
}

#
# @brief tries to parse out fps data from microdvd format line
#
subotage_detectMicrodvdFps_SO() {
    local awkCode=

    read -r -d "" awkCode << 'EOF'
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
    awk "$awkCode"
}

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
subotage_checkFormatMicrodvd_SO() {
    local filePath="$1"
    local maxAttempts=3
    local attempts="$maxAttempts"
    local firstLine=1
    local match="$___g_subotageNotDetectedMarker"
    local matchTmp=
    local fpsDetected=
    local awkCode=

    read -r -d "" awkCode << 'EOF'
{
    gsub("^\\{[0-9]+\\}\\{[0-9]*\\}.*$", "success")
    print
}
EOF

    while read -r fileLine; do
        [ "$attempts" -eq 0 ] && break
        firstLine=$(( maxAttempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))

        # match the format
        matchTmp=$(echo "$fileLine" | awk "$awkCode")

        # skip empty lines
        [ -z "$matchTmp" ] && continue

        # we've got a match
        if [ "$matchTmp" = "success" ]; then
            fpsDetected=$(echo "$fileLine" | \
                wrappers_lcase_SO | \
                subotage_detectMicrodvdFps_SO | \
                wrappers_stripNewLine_SO)

            if [ -z "$fpsDetected" ]; then
                match="microdvd $firstLine"
            else
                match="microdvd $firstLine $fpsDetected"
            fi
            break
        fi
    done < "$filePath"

    echo "$match"
    return $G_RETOK
}

# mpl2 format detection routine
subotage_checkFormatMpl2_SO() {
    local filePath="$1"

    local maxAttempts=3
    local attempts="$maxAttempts"
    local firstLine=1
    local match="$___g_subotageNotDetectedMarker"
    local matchTmp=
    local awkCode=

    read -r -d "" awkCode << 'EOF'
{
    gsub("^\\[[0-9]+\\]\\[[0-9]*\\].*$", "success")
    print
}
EOF

    while read -r fileLine; do
        [ "$attempts" -eq 0 ] && break
        firstLine=$(( maxAttempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))

        matchTmp=$(echo "$fileLine" | awk "$awkCode")

        # skip empty lines
        [ -z "$matchTmp" ] && continue

        # we've got a match
        if [ "$matchTmp" = "success" ]; then
            match="mpl2 $firstLine"
            break
        fi
    done < "$filePath"

    echo "$match"
    return $G_RETOK
}

# subrip format detection routine
subotage_checkFormatSubrip() {
    local filePath="$1"
    local maxAttempts=8
    local firstLine=1
    local attempts="$maxAttempts"

    local counterType="not_found"
    local match="$___g_subotageNotDetectedMarker"
    local match_tmp=
    local match_ts=

    read -r -d "" match_ts << 'EOF'
{
    ts="[0-9]+:[0-9]+:[0-9]+,[0-9]+ --> [0-9]+:[0-9]+:[0-9]+,[0-9]+[ \r\n]*"
    fullReg =  "^" prefix ts "$"
    print match($0, fullReg)
}
EOF

    while read -r file_line; do
        [ "$attempts" -eq 0 ] && break

        if [ "$counterType" = "not_found" ]; then
                firstLine=$(( maxAttempts - attempts + 1 ))
                matchTmp=$(echo "$fileLine" | awk '/^[0-9]+[\r\n]*$/')

                if [ -n "$matchTmp" ]; then
                    counter_type="newline"
                    continue
                fi

                # check for inline counter
                matchTmp=$(echo "$fileLine" | \
                    awk -v prefix="[0-9]+ " "$matchTs")

                if [ "$matchTmp" -ne 0 ]; then
                    counterType="inline"
                    match="subrip $firstLine inline"
                    break
                fi

        elif [ "$counterType" = "newline" ]; then
                # check for the time signature
                matchTmp=$(echo "$fileLine" | awk -v prefix="" "$matchTs")

                if [ "$matchTmp" -ne 0 ]; then
                    counterType="newline"
                    match="subrip $firstLine newline"
                    break
                fi
        fi

        attempts=$(( attempts - 1 ))
    done < "$filePath"

    echo "$match"
    return $G_RETOK
}

# subviewer2 format check
subotage_checkFormatSubviewer2() {
    local filePath="$1"
    local match="$___g_subotageNotDetectedMarker"
    local matchTmp=''
    local maxAttempts=16
    local attempts="$maxAttempts"

    local firstLine=0
    local headerLine=0
    local matchTs=

    read -r -d "" matchTs << 'EOF'
{
    matchGroup="[0-9]+:[0-9]+:[0-9]+\\.[0-9]+"
    reg = "^" matchGroup "," matchGroup "[ \r\n]*$"
    where = match($0, reg)
    print where
}
EOF

    while read -r fileLine; do
        [ "$attempts" -eq 0 ] && break
        firstLine=$(( maxAttempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))

        if [ "$headerLine" -eq 0 ]; then
            # try to detect header
            matchTmp=$(echo "$fileLine" | grep "\[INFORMATION\]")

            # set the header line
            [ -n "$matchTmp" ] && headerLine="$firstLine"
        fi

        matchTmp=$(echo "$fileLine" | awk "$match_ts")

        # we've got a match
        if [ "$matchTmp" -ne 0 ]; then
            match="subviewer2 $firstLine $headerLine"
            break
        fi
    done < "$filePath"

    echo "$match"
    return $G_RETOK
}

# tmplayer format detection routine
subotage_checkFormatTmplayer() {
    local filePath="$1"

    local maxAttempts=3
    local attempts="$maxAttempts"
    local firstLine=1
    local match="$___g_subotageNotDetectedMarker"
    local matchTmp=

    declare -a tmpData=()
    local hourDigits=2
    local multiline=0
    local delim=':'

    local genericCheck=''
    local extractDelim=''

    read -r -d "" genericCheck << 'EOF'
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

    read -r -d "" extractDelim << 'EOF'
{
    print substr($0, match_len, 1)
}
EOF

    while read -r fileLine; do
        [ "$attempts" -eq 0 ] && break
        firstLine=$(( maxAttempts - attempts + 1 ))
        attempts=$(( attempts - 1 ))

        matchTmp=$(echo "$fileLine" | awk "$genericCheck")

        # skip empty lines
        [ -z "$matchTmp" ] && continue

        # we've got a match, get more data
        if [ "$matchTmp" != "-1" ]; then

            tmpData=( $matchTmp )


            # determine the hour digits
            [ "${tmpData[1]}" -eq 10 ] ||
            [ "${tmpData[1]}" -eq 8 ] && hourDigits=1

            # extract delimiter
            delim=$(echo "$fileLine" | \
                awk -v matchLen="${tmpData[1]}" "$extractDelim")

            # is it a multiline format (hh:mm:ss,LINENO=)?
            [ "${tmpData[0]}" -eq 1 ] && multiline=1

            # form the format identification string
            match="tmplayer $firstLine $hourDigits $multiline $delim"
            break
        fi

    done < "$filePath"

    echo "$match"
    return $G_RETOK
}

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
# - $G_RETOK - when file is processed and all the data is converted to
#             universal format present in /tmp file
###############################################################################

subotage_readFormatSubviewer2() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=
    local details=( ${___g_subotageIF[$___g_subotageIOFDetails]} )

read -r -d "" awkCode << 'EOF'
BEGIN {
    FS="\n"
    RS="" # blank line as record separator
    linesProcessed=1
}

{
    if (linesProcessed == 1) {
        rec = __start_line
    }
    else {
        rec = 1
    }

    lineData = rec + 1
    split($rec, start, ",")
    split(start[1], tmStart, ":")
    split(start[2], tmStop, ":")

    timeStart = (tmStart[1]*3600 + tmStart[2]*60 + tmStart[3] + tmStart[4]/100)
    timeStop = (tmStop[1]*3600 + tmStop[2]*60 + tmStop[3] + tmStop[4]/100)

    printf("%d %s %s ", linesProcessed, timeStart, timeStop)

    for (i=lineData; i<=NF; i++) {
        if (i>lineData) printf("|")
        printf("%s", $i);
    }

    linesProcessed++
    printf("\n")
}
EOF

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageIF[$___g_subotageIOFDetails]}"

    echo "secs" > "$outFilePath"
    awk -v __start_line="${details[1]}" \
        "$awkCode" "$inFilePath" >> "$outFilePath"
}

subotage_readFormatTmplayer() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

    local details=( ${___g_subotageIF[$___g_subotageIOFDetails]} )
    local delimiter=":"


    # match="tmplayer $first_line $hour_digits $multiline $delim"
    read -r -d "" awkCode << 'EOF'
BEGIN {
    linesProcessed = 1
    prevTimeStart = 0
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

        lineStart = 4
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
        lineStart = 2
    }

    timeStart = hours*3600 + minutes*60 + seconds
    timeEnd = (timeStart + __last_time)

    if (__multiline) {
        if (timeStart == prevTimeStart && NR > 1) {
            printf("|")
        }
        else {
            if (NR > 1) {
                printf("\n");
                linesProcessed++
            }

            printf("%d %02d:%02d:%02d %02d:%02d:%02d ", \
                linesProcessed, \
                hours, \
                minutes, \
                seconds, \
                (timeEnd/3600), \
                ((timeEnd/60)%60), \
                (timeEnd%60))
            }

    } # __multiline
    else {
        printf("%d %02d:%02d:%02d %02d:%02d:%02d ", \
            linesProcessed++, \
            hours, \
            minutes, \
            seconds, \
            (timeEnd/3600), \
            ((timeEnd/60)%60), \
            (timeEnd%60))
    }

    # display the line data
    for (i=lineStart; i<=NF; i++) printf("%s", $i)

    if (__multiline) {
        prevTimeStart = timeStart
    }
    else {
        printf "\n"
    }
}
EOF

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageIF[$___g_subotageIOFDetails]}"

    # adjust the delimiter
    [ -n "${details[4]}" ] && delimiter="${details[4]}"
    logging_info $LINENO $"przystanek" "[$delimiter]"

    echo "hms" > "$outFilePath"
    awk -F "$delimiter" -v __start_line="${details[1]}" \
        -v __last_time="$___g_subotageLastingTimeMs" \
        -v __multiline="${details[3]}" \
        "$awkCode" "$inFilePath" >> "$outFilePath"
}

subotage_readFormatMicrodvd() {
    local inFilePath="$1"
    local outFilePath="$2"
    local details=( ${___g_subotageIF[$___g_subotageIOFDetails]} )
    local awkCode=

read -r -d "" awkCode << 'EOF'
BEGIN {
    FS="[\\}\\{]"
    linesProcessed = 1
    __last_time = __last_time / 1000
}

NR >= __start_line {
    frameStart=$2
    frameEnd=$4
    lineData=5

    if (!($4 + 0)) {
        frameEnd=$2 + __last_time*__fps
    }

    printf("%d %s %s ", linesProcessed, (frameStart/__fps), (frameEnd/__fps))
    linesProcessed++

    for (i=lineData; i<=NF; i++) {
        # strip control codes - comment this out if you want to keep'em
        gsub(/[yYfFsScCP]+:.*/, "", $i)
        printf("%s", $i)
    }
    printf("\n")
}
EOF

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageIF[$___g_subotageIOFDetails]}"

    echo "secs" > "$outFilePath"
    awk -v __start_line="${details[1]}" \
        -v __last_time="$___g_subotageLastingTimeMs" \
        -v __fps="${___g_subotageIF[$___g_subotageIOFFps]}" \
        "$awkCode" "$inFilePath" >> "$outFilePath"
}

subotage_readFormatMpl2() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=''
    local details=( ${___g_subotageIF[$___g_subotageIOFDetails]} )

read -r -d "" awkCode << 'EOF'
BEGIN {
    FS="[][]"
    linesProcessed = 1;
    __last_time = __last_time / 100
}

length($0) && NR >= __start_line {

    frameStart=$2
    frameEnd=$4

    if (!($4 + 0)) {
        frameEnd=$2 + __last_time
    }

    printf("%s %s %s ", \
        linesProcessed++, \
        (frameStart/10), \
        (frameEnd/10))

    for (i=5; i<=NF; i++) printf("%s", $i)
    printf("\n")
}
EOF

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageIF[$___g_subotageIOFDetails]}"

    echo "secs" > "$outFilePath"
    awk -v __start_line="${details[1]}" \
        -v __last_time="$___g_subotageLastingTimeMs" \
        "$awkCode" "$inFilePath" >> "$outFilePath"
}

subotage_readFormatSubrip() {
    local inFilePath="$1"
    local outFilePath="$2"
    local details=( ${___g_subotageIF[$___g_subotageIOFDetails]} )
    local awkCode=

read -r -d "" awkCode << 'EOF'
BEGIN {
    FS="\n"
    RS=""
    linesProcessed = 1
}

length($0) {

    # this is to skip initial non subs lines
    if (linesProcessed == 1) {
        rec = __start_line
    }
    else {
        rec = 1
    }

    lineData = rec + 1

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
        lineData++
    }

    for (i = lineData; i<=NF; i++) {
        if (i > lineData) printf("|")
        printf("%s", $i)
    }
    printf("\n")
    linesProcessed++
}
EOF

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageIF[$___g_subotageIOFDetails]}"

    logging_debug $LINENO $"licznik:" "${details[2]}"

    echo "hmsms" > "$outFilePath"
    awk -v __start_line="${details[1]}" \
        -v __counter_type="${details[2]}" \
        "$awkCode" "$inFilePath" >> "$outFilePath"
}

###############################################################################
############################ format write routines ############################
###############################################################################

subotage_writeFormatMicrodvd() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

read -r -d "" awkCode << 'EOF'
NR == 1 {
    timeType=$0
    ORS=" "
}

NR > 1 {
    if (timeType == "secs") {
        printf("{%d}{%d}", $2*__fps, $3*__fps)
    }
    else if (timeType == "hmsms" || timeType == "hms") {
        split($2, timeStart, ":")
        split($3, timeStop, ":")

        start = (timeStart[1]*3600 + timeStart[2]*60 + timeStart[3])*__fps
        stop = (timeStop[1]*3600 + timeStop[2]*60 + timeStop[3])*__fps

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
    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageOF[$___g_subotageIOFDetails]}"

    logging_info $LINENO "fps:" \
        "${___g_subotageOF[$___g_subotageIOFFps]}"

    awk -v __fps="${___g_subotageOF[$___g_subotageIOFFps]}" \
        "$awkCode" "$inFilePath" > "$outFilePath"
}

subotage_writeFormatMpl2() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

read -r -d "" awkCode << 'EOF'
NR == 1 {
    timeType=$0
    ORS=" "
}

NR > 1 {
    if (timeType == "secs") {
        printf("[%d][%d]", $2*10, $3*10)
    }
    else if (timeType == "hmsms" || timeType == "hms") {
        split($2, timeStart, ":")
        split($3, timeStop, ":")

        start = (timeStart[1]*3600 + timeStart[2]*60 + timeStart[3])*10
        stop = (timeStop[1]*3600 + timeStop[2]*60 + timeStop[3])*10

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
    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageOF[$___g_subotageIOFDetails]}"

    awk "$awkCode" "$inFilePath" > "$outFilePath"
}

subotage_writeFormatSubrip() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

read -r -d "" awkCode << 'EOF'
NR == 1 {
    timeType=$0
    ORS=" "
}

function printTs(cnt, sh, sm, ss, sc, eh, em, es, ec) {
    printf("%d\n%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d\n", \
        cnt, \
        sh,sm,ss,sc, \
        eh,em,es,ec)
}

function printContent() {
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

    if (timeType == "secs") {
        sh = $2/3600
        sm = ($2/60) % 60
        ss = $2%60
        sc = int(($2 - int($2))*1000)

        eh = $3/3600
        em = ($3/60) % 60
        es = $3%60
        ec = int(($3 - int($3))*1000)
    }
    else if (timeType == "hmsms" || timeType == "hms") {
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

        if (timeType == "hmsms") {
            sc = int((start[3] - int(start[3]))*1000)
            ec = int((stop[3] - int(stop[3]))*1000)
        }
    }
    else {
        exit 1
    }

    printTs(cnt, sh, sm, ss, sc, eh, em, es, ec)
    printContent()
}
EOF

    awk "$awkCode" "$inFilePath" > "$outFilePath"
}

subotage_writeFormatSubviewer2() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

read -r -d "" awkCode << 'EOF'
NR == 1 {
    timeType=$0
    ORS=" "
}

NR > 1 {

    if (timeType == "secs") {
        sh = $2/3600
        sm = ($2/60)%60
        ss = $2%60
        sc = int( ($2 - int($2))*100 )

        eh = $3/3600
        em = ($3/60)%60
        es = $3%60
        ec = int( ($3 - int($3))*100 )
    }
    else if (timeType == "hmsms" || timeType == "hms") {
        split($2, timeStart, ":")
        split($3, timeStop, ":")

        sh = timeStart[1]
        sm = timeStart[2]
        ss = timeStart[3]
        sc = 0

        eh = timeStop[1]
        em = timeStop[2]
        es = timeStop[3]
        ec = 0

        if (timeType == "hmsms") {
            sc = int( (timeStart[3] - int(timeStart[3]))*100 )
            ec = int( (timeStop[3] - int(timeStop[3]))*100 )
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

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageOF[$___g_subotageIOFDetails]}"

    logging_info $LINENO "fps:" \
        "${___g_subotageOF[$___g_subotageIOFFps]}"

    echo    "[INFORMATION]" > "$outFilePath"
    echo    "[TITLE] none" >> "$outFilePath"
    echo    "[AUTHOR] none" >> "$outFilePath"
    echo    "[SOURCE]" >> "$outFilePath"
    echo    "[FILEPATH]Media" >> "$outFilePath"
    echo    "[DELAY]0" >> "$outFilePath"
    echo    "[COMMENT] Created using subotage - universal subtitle converter for bash" >> "$outFilePath"
    echo    "[END INFORMATION]" >> "$outFilePath"
    echo    "[SUBTITLE]" >> "$outFilePath"
    echo    "[COLF]&HFFFFFF,[STYLE]bd,[SIZE]18,[FONT]Arial" >> "$outFilePath"

    awk "$awkCode" "$inFilePath" >> "$outFilePath"
}

subotage_writeFormatTmplayer() {
    local inFilePath="$1"
    local outFilePath="$2"
    local awkCode=

read -r -d "" awkCode << 'EOF'
NR == 1 {
    timeType=$0
    ORS=" "
}

NR > 1 {

    if (timeType == "secs") {
        sh = $2/3600
        sm = ($2/60)%60
        ss = $2%60
        printf("%02d:%02d:%02d:", sh, sm, ss)
    }
    else if (timeType == "hms") {
        printf("%s:", $2)
    }
    else if (timeType == "hmsms") {
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

    logging_info $LINENO $"szczegoly formatu:" \
        "${___g_subotageOF[$___g_subotageIOFDetails]}"

    awk "$awkCode" "$inFilePath" > "$outFilePath"
}

# EOF
