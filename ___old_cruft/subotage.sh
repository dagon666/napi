declare -r g_default_fps='23.98'

#
# @brief if set then getinfo only and exit
#
g_getinfo=0

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
