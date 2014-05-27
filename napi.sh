#!/bin/bash

#
# script version
#
declare -r g_revision="v1.2.1"

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2010 Tomasz Wisniewski aka 
#		DAGON <tomasz.wisni3wski@gmail.com>
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
# 	only for the converted subtitles
#
declare -a g_abbrev=( '' '' )

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
declare -a g_system=( 'linux' '1' 'pynapi' )

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


################################### TOOLS ######################################

#
# @brief global tools array 
# =1 - mandatory tool
# =0 - optional tool
#
declare -a g_tools=( 'tr=1' 'printf=1' 'mktemp=1' 'wget=1' 
				'dd=1' 'grep=1' 'sed=1' 'cut=1' 
				'stat=1' 'basename=1' 'dirname=1' 'cat=1'
				'subotage.sh=0' '7z=0' 'iconv=0' 
				'mediainfo=0' 'mplayer=0' 'mplayer2=0' 'ffmpeg=0' )

# fps detectors
declare -a g_tools_fps=( 'mediainfo' 'mplayer' 'mplayer2' 'ffmpeg' )

g_cmd_stat='stat -c%s'
g_cmd_wget='wget -q -O'
g_cmd_md5='md5sum'

################################## RETVAL ######################################

# success
RET_OK=0

# function failed
RET_FAIL=-1

# parameter error
RET_PARAM=-2

# parameter/result will cause the script to break
RET_BREAK=-3

################################## STDOUT ######################################

#
# @brief print a debug verbose information
#
_debug() {
	local line=${1:-0} && shift
	[ $g_verbosity -ge 3 ] && echo -e " --- $line: $*"
	return $RET_OK
}


#
# @brief print information 
#
_info() {
	local line=${1:-0} && shift
	[ $g_verbosity -ge 2 ] && echo -e " -- $line: $*"
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
	[ $g_verbosity -ge 1 ] && echo -e " - $*"
	return $RET_OK
}


#
# @brief print status type message
#
_status() {
	[ $g_verbosity -ge 1 ] && echo -e "$1 -> $2"
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
	local key=$1 && shift

	for i in $*; do
		if [ $(get_key $i) = $key ]; then
			get_value $i
			rv=$RET_OK
			break
		fi
	done
	return $rv
}


#
# @brief lookup key in the array for given value
# returns the key of the value and 0 on success
#
lookup_key() {
	local i=''
	local idx=0
	local rv=$RET_FAIL
	local key=$1 

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
		[ $(get_key $i) != $key ] && rv+=( "$i" )
	done

	rv+=($key=$value)
	echo ${rv[*]}
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
    
    [ ${#lang} -ne 2 ] && [ ${#lang} -ne 3 ] && 
		return $RET_PARAM

    local l_arr_name="g_LanguageCodes${#lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

	i=$(lookup_key $lang ${l_arr[@]})
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
    declare lang=${g_LanguageCodes2L[$1]}
    # don't ask me why
    [[ $lang = "EN" ]] && lang="ENG"
	echo $lang
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
	[ ${g_system[0]} = "darwin" ] && 
		g_cmd_md5="md5" &&
		g_cmd_stat="stat -f%z"

	g_tools+=( "$g_cmd_md5=1" )

	_debug $LINENO "sprawdzam czy wget wspiera opcje -S"
	local cmd_test=$(wget --help 2>&1 | grep "\-S")

	[ -n "$cmd_test" ] && 
		g_cmd_wget='wget -q -S -O' &&
		_info $LINENO "wget wspiera opcje -S"

	return 0
}


#
# @brief verify system settings and gather info about commands
#
verify_system() {
	_debug $LINENO "weryfikuje system"
	g_system[0]=$(get_system)
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
		tool=$(get_key $t)
		m=$(get_value $t)

 		[ -z $(verify_tool_presence $tool) ] && p=0
		ret+=( "$tool=$p" )
		
		# break if mandatory tool is missing
		[ $m -eq 1 ] && [ $p -eq 0 ] && rv=$RET_FAIL && break
 	done

	echo ${ret[*]}
	return $rv
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
			"-s" | "--skip") skip=1 ;;

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

			"-P" | "--pref_fps") varname="g_fps_tool"
			msg="nie określono narzedzia do detekcji fps"
			;;

       		# orig prefix 
       	 	"-o" | "--orig-prefix") varname="g_default_prefix"
			msg="nie określono domyslnego prefixu"
       	 	;;

        	# abbrev
        	"--conv-abbrev") varname="g_abbrev[1]"
			msg="nie określono wstawki dla konwersji"
        	;;

        	"--forks") varname="g_system[1]"
			msg="nie określono ilosci watkow"
        	;;

			# parameter is not a known argument, probably a filename
			*) g_paths+=( "$1" ) ;;
		esac

		# set the global var for simple switches
		# not requiring any further verification
		if [[ -n $varname ]]; then
			shift
			[ -z "$1" ] && _error $msg && exit -1
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

	local user="${1:-''}"
	local passwd="${2:-''}"
	local rv=$RET_OK
	
	if [ -z "$user" ] && [ -n "$passwd" ]; then
		_warning "podano haslo, brak loginu. tryb anonimowy."
		retval=$RET_PARAM
	fi

	if [ -n "$user" ] && [ -z "$passwd" ]; then
		_warning "podano login, brak hasla. tryb anonimowy."
		retval=$RET_PARAM
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
	return $rv
}


#
# @brief format verification
#
verify_format() {
	# format verification if conversion requested
	if [ $g_sub_format != 'default' ]; then
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
	# verify selected fps tool
	if [ $g_fps_tool != 'default' ]; then
		if ! lookup_key $g_fps_tool ${g_tools_fps[@]} > /dev/null; then
        	_error "podane narzedzie jest niewspierane [$g_fps_tool]"
			return $RET_PARAM
		fi
		
		local sp=$(lookup_value $g_fps_tool ${g_tools[@]})

		# make sure it's a number
		sp=$(( $sp + 0 ))

		if [ $sp -eq 0 ]; then
			_error "$g_fps_tool nie jest dostepny"
			return $RET_PARAM
		fi
	fi

	return $RET_OK
}


#
# @brief verify correctness of the argv settings provided
#
verify_argv() {

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
	if ! verify_encoding $g_charset; then
		_warning "charset [$g_charset] niewspierany, ignoruje zadanie"
		g_charset='default'
	fi

	# verify the id setting
	_debug $LINENO 'sprawdzam id'
	if ! verify_id; then
		_warning "nieznany id [${g_system[2]}], przywracam domyslny"
	fi
	
	# logfile verification	
	_debug $LINENO 'sprawdzam logfile'
	[ -e "$g_logfile" ] && 
		_warning "plik loga istnieje - bedzie nadpisany"
	
	# language verification
	_debug $LINENO 'sprawdzam wybrany jezyk'
	local idx=0
	idx=$(verify_language $g_lang)

	if [ $? -ne $RET_OK ]; then
		if [ $g_lang = "list" ]; then 
			list_languages
			return $RET_BREAK
		else
			_warning "nieznany jezyk [$g_lang]. przywracam PL"
			g_lang='PL'
		fi
	else
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
	if [ $g_hook != 'none' ]; then
	   [ ! -x "$g_hook" ] &&
		   _error "podany skrypt jest niedostepny (lub nie ma uprawnien do wykonywania)" &&
		   return $RET_PARAM
	fi

	return $RET_OK
}

################################################################################

#
# @brief prints the help & options overview
#
usage() {
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
 	if [ -z $BASH_VERSION ]; then
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

 	# if no arguments are given, then print help and exit
 	[ $# -lt 1 ] || [ $arg1 = "--help" ] || [ $arg1 = "-h" ] && 
		usage &&
		return $RET_BREAK

	_info $LINENO "parsowanie argumentow"
	parse_argv "$@"

	_info $LINENO "weryfikacja argumentow"
	if ! verify_argv; then 
		_error "niepoprawne argumenty..."
		return $RET_FAIL
	fi

	_info $LINENO "ustawiam STDOUT"
	redirect_to_logfile

	_msg "wywolano o $(date)"
	_msg "system: ${g_system[0]}, forkow: ${g_system[1]}"


	_info $LINENO "przywracam STDOUT"
	redirect_to_stdout

	return $RET_OK
}

# call the main
main "$@"

# EOF
######################################################################## 
######################################################################## 
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
## 	eval "echo \$${g_GlobalPrefix}_$1"	
## }
## 
## 
## #
## # @brief set variable in the db
## #
## _db_set() {
## 	eval "${g_GlobalPrefix}_${1/./_}=\$2"
## }

######################################################################## ######################################################################## ######################################################################## ########################################################################
