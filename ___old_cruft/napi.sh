#
# @brief format verification
#
verify_format() {
    # format verification if conversion requested
    if [ "$g_sub_format" != 'default' ]; then

        if ! tools_is_detected "subotage.sh"; then
            _error "subotage.sh nie jest dostepny. konwersja nie jest mozliwa"

            # shellcheck disable=SC2086
            return $RET_PARAM
        fi

        declare -a formats=()
        formats=( $(subotage.sh -gf) )

        # this function can cope with that kind of input
        # shellcheck disable=SC2068
        if ! lookup_key $g_sub_format ${formats[@]} > /dev/null; then
            _error "podany format docelowy jest niepoprawny [$g_sub_format]"

            # shellcheck disable=SC2086
            return $RET_PARAM
        fi
    fi

    # shellcheck disable=SC2086
    return $RET_OK
}

#
# @brief verify correctness of the argv settings provided
#
verify_argv() {
    # format verification
    _debug $LINENO 'sprawdzam format'
    ! verify_format && return $RET_PARAM
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

    if [ $status -eq $RET_OK ] || [ $status -eq $RET_NOACT ]; then
        _status "OK" "$media_file"

        [ "$g_sub_format" != 'default' ] &&
            _debug $LINENO "zadanie konwersji - korekcja nazwy pliku"
            si=7

        # charset conversion (only if freshly downloaded)
        [ $status -eq $RET_OK ] && io_convert_encoding "$path/${g_pf[$si]}"

        # process nfo requests
        obtain_others "nfo" "$media_path"

        # process cover requests
        obtain_others "cover" "$media_path"

        # process hook - only if some processing has been done
        [ $status -eq $RET_OK ] && system_execute_hook "$path/${g_pf[$si]}"
    else
        _status "UNAV" "$media_file"
        g_stats[1]=$(( g_stats[1] + 1 ))
        rv=$RET_UNAV
    fi # if [ $status = $RET_OK ]

    return "$rv"
}

#
# @brief main function
#
main() {
    # cleanup & exit
    _info $LINENO "przywracam STDOUT"
    output_set_logfile "none"
}
