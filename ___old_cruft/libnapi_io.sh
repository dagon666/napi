#
# @brief detects the charset of the subtitles file
# @param full path to the subtitles file
#
io_get_encoding() {
    local file="$1"
    local charset='WINDOWS-1250'
    local et=''

    if tools_is_detected "file"; then

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
            case "$et" in
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

    # shellcheck disable=SC2086
    return $RET_OK
}

#
# @brief convert charset of the file
# @param input file path
# @param output charset
# @param input charset or null
#
io_convert_encoding_generic() {
    local file="$1"
    local d="${2:-utf8}"
    local s="${3}"
    local rv=$RET_FAIL

    # detect charset
    [ -z "$s" ] && s=$(io_get_encoding "$file")

    local tmp=$(mktemp napi.XXXXXXXX)
    iconv -f "$s" -t "$d" "$file" > "$tmp"

    if [ $? -eq $RET_OK ]; then
        _debug $LINENO "moving after charset conv. $tmp -> $file"
        mv "$tmp" "$file"
        rv=$RET_OK
    fi

    [ -e "$tmp" ] && io_unlink "$tmp"

    return "$rv"
}


#
# @brief convert charset of the file
# @param input file path
#
io_convert_encoding() {
    local filepath="$1"

    local encoding=$(system_get_encoding)
    local filename=$(basename "$filepath")

    [ "$encoding" = "default" ] && return $RET_OK

    _msg "[$filename]: konwertowanie kodowania do $encoding"
    io_convert_encoding_generic \
        "$filepath" "$encoding"
}

#
# @brief set fps tool
#
io_set_fps_tool() {
    ___g_io[$___GIO_FPS]="${1:-none}"

    if ! io_verify_fps_tool; then
        ___g_io[$___GIO_FPS]="unavailable"
        return $RET_PARAM
    fi

    return $RET_OK
}


io_verify_fps_tool() {
    # fps tool verification

    # don't do anything if the tool has been already marked as unavailable
    [ "${___g_io[$___GIO_FPS]}" = 'unavailable' ] &&
        return $RET_UNAV

    # verify selected fps tool
    if [ "${___g_io[$___GIO_FPS]}" != 'none' ]; then
        ! tools_is_in_group_and_detected &&
            return $RET_PARAM
    else
        # choose first available as the default tool
        local firstav=''
        firstav=$(tools_first_available_from_group "fps")
        [ -z "$firstav" ] &&
            return $RET_PARAM

         ___g_io[$___GIO_FPS]="$firstav"
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}


io_get_fps() {
    [ "${___g_io[$___GIO_WGET]}" = 'none' ] && io_verify_fps_tool
    io_get_fps_with_tool "${___g_io[$___GIO_FPS]}" "$@"
}


#
# @brief detect fps of the video file
# @param tool
# @param filename
#
io_get_fps_with_tool() {
    local fps=0
    local tbr=0
    local t="${1:-none}"
    local tmp=''
    declare -a atmp=()

    # don't bother if there's no tool available or not specified
    if [ -z "$t" ] ||
        [ "$t" = "none" ] ||
        [ "$t" = "unavailable" ]; then
        echo $fps

        # shellcheck disable=SC2086
        return $RET_PARAM
    fi

    if tools_is_detected "$1"; then
        case "$1" in
            'mplayer' | 'mplayer2' )
            fps=$($1 -identify -vo null -ao null -frames 0 "$2" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2)
            ;;

            'mediainfo' )
            fps=$($1 --Output='Video;%FrameRate%' "$2")
            ;;

            'ffmpeg' )
            tmp=$($1 -i "$2" 2>&1 | grep "Video:")
            tbr=$(echo "$tmp" | sed 's/, /\n/g' | tr -d ')(' | grep tbr | cut -d ' ' -f 1)
            fps=$(echo "$tmp" | sed 's/, /\n/g' | grep fps | cut -d ' ' -f 1)

            [ -z "$fps" ] && fps="$tbr"
            ;;

            'ffprobe' )
            tmp=$(ffprobe -v 0 -select_streams v -print_format csv -show_entries stream=avg_frame_rate,r_frame_rate -- "$2" | tr ',' ' ')
            atmp=( $tmp )

            local i=0
            for i in 1 2; do
                local a=$(echo "${atmp[$i]}" | cut -d '/' -f 1)
                local b=$(echo "${atmp[$i]}" | cut -d '/' -f 2)
                [ "${atmp[$i]}" != "0/0" ] && fps=$(float_div "$a" "$b")
            done
            ;;

            *)
            ;;
        esac
    fi

    # just a precaution
    echo "$fps" | cut -d ' ' -f 1

    # shellcheck disable=SC2086
    return $RET_OK

}

io_verify_sub_format() {
    local format="$1"

    _debug $LINENO "Weryfikuje format napisow: $format"

    if ! tools_is_detected "subotage.sh"; then
        _error "subotage.sh nie jest dostepny. konwersja nie jest mozliwa"

        # shellcheck disable=SC2086
        return $RET_PARAM
    fi

    declare -a formats=()
    formats=( $(subotage.sh -gf) )

    # this function can cope with that kind of input
    # shellcheck disable=SC2068
    if ! lookup_key "$format" ${formats[@]} > /dev/null; then
        _error "podany format docelowy jest niepoprawny [$format]"
        # shellcheck disable=SC2086
        return $RET_PARAM
    fi

    return $RET_OK
}
