#
# @brief get the number of configured forks
#
system_get_forks() {
    if [ "${___g_system[$___GSYSTEM_NFORKS]}" -eq 0 ]; then
        local cores=1

        # establish the number of cores
        cores=$(get_cores "$(system_get_system)")

        # sanity checks
        [ "${#cores}" -eq 0 ] && cores=1
        [ "$cores" -eq 0 ] && cores=1

        # two threads on one core should be safe enough
        system_set_forks $(( cores * 2 ))
    fi

    echo "${___g_system[$___GSYSTEM_NFORKS]}"
}


#
# @brief set the number of forks
#
system_set_forks() {
    ___g_system[$___GSYSTEM_NFORKS]=$(ensure_numeric "$1")
}


#
# @brief get system type
#
system_get_system() {
    if [ "${___g_system[$___GSYSTEM_SYSTEM]}" = 'none' ]; then
        ___g_system[$___GSYSTEM_SYSTEM]="$(get_system)"
    fi

    echo "${___g_system[$___GSYSTEM_SYSTEM]}"
}


#
# @brief set the desired output file encoding
#
system_set_encoding() {
    ___g_system[$___GSYSTEM_ENCODING]="${1:-default}"
    if ! system_verify_encoding; then
        _warning "charset [$1] niewspierany, ignoruje ..."
        ___g_system[$___GSYSTEM_ENCODING]="default"
    fi
    return $RET_OK
}


#
# @brief get the output file encoding
#
system_get_encoding() {
    echo "${___g_system[$___GSYSTEM_ENCODING]}"
}


#
# @brief checks if the given encoding is supported
#
system_verify_encoding() {
    [ "${___g_system[$___GSYSTEM_ENCODING]}" = 'default' ] &&
        return $RET_OK

    ! tools_is_detected "iconv" &&
        _warning "iconv jest niedostepny. Konwersja kodowania niewsperana" &&
        return $RET_UNAV

    echo test | iconv \
        -t "${___g_system[$___GSYSTEM_ENCODING]}" > /dev/null 2>&1
    return $?
}


system_set_hook() {
    ___g_system[$___GSYSTEM_HOOK]="$1"
    system_verify_hook
}


system_verify_hook() {
    ___g_system[$___GSYSTEM_HOOK]="$1"

    if [ "${___g_system[$___GSYSTEM_HOOK]}" != 'none' ] &&
        [ ! -x "${___g_system[$___GSYSTEM_HOOK]}" ]; then
           _error "podany skrypt jest niedostepny (lub nie ma uprawnien do wykonywania)" &&
           return $RET_PARAM
    fi
    return $RET_OK
}


system_execute_hook() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    [ "${___g_system[$___GSYSTEM_HOOK]}" = 'none' ] && return $RET_OK
    _msg "wywoluje zewnetrzny skrypt: $filename"
    "${___g_system[$___GSYSTEM_HOOK]}" "$filepath"
}
