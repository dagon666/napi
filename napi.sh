#!/bin/bash

#
# script version
#
declare -r g_revision="v1.2.1"

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2010 Tomasz Wisniewski aka DAGON <tomasz.wisni3wski@gmail.com>
#  http://www.dagon.bblog.pl
#  http://hekate.homeip.net
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
declare g_system='linux'

#
# id
# - pynapi - identifies itself as pynapi
# - other - identifies itself as other
#
declare g_id='pynapi'

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
# @brief number of parallel forks
#
declare g_forks=1

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


declare -a g_tools=()

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
	local key=$1 && shift

	for i in $*; do
		if [ $(get_key $i) = $key ]; then
			get_value $i
			break
		fi
	done
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
    local lang="$1"

    declare -a l_arr=( )
    local l_arr_name=""
    local i=0
    
    if [[ ${#lang} -ne 2 ]] && [[ ${#lang} -ne 3 ]]; then
        return $RET_PARAM
    fi

    l_arr_name="g_LanguageCodes${#lang}L";
    eval l_arr=\( \${${l_arr_name}[@]} \)

    while [[ $i -lt ${#l_arr[@]} ]]; do
        if [[ "${l_arr[$i]}" = "$lang" ]]; then
            echo "$i"
            return $RET_OK
        fi
        i=$(( $i + 1 ))
    done

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

################################################################################

#
# @brief parse the cli arguments
#
parse_argv() {
	# command line arguments parsing
	while [ $# -gt 0 ]; do
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
			"-I" | "--id") varname="g_id"
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

			# parameter is not a known argument, probably a filename
			*) g_paths+=( "$1" ) ;;
		esac

		# set the global var for simple switches
		# not requiring any further verification
		if [ -n $varname ]; then
			shift
			[ -z "$1" ] && _error $msg && exit -1
			eval "${varname}=\$1"
			unset varname
		fi
		shift
	done
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

	case $g_id in
		'pynapi' | 'other' ) ;;
		*) 
		rv=$RET_PARAM
		g_id='pynapi'
		;;
	esac
	return $rv
}


#
# @brief verify correctness of the argv settings provided
#
verify_argv() {
	# verify credentials correctness
	if ! verify_credentials "${g_cred[0]}" "${g_cred[1]}"; then
		g_cred[0]='' && g_cred[1]=''
	fi

	# make sure we have a number here
	g_min_size=$(( $g_min_size + 0 ))
	g_verbosity=$(( $g_verbosity + 0 ))

	# verify encoding request
	if ! verify_encoding $g_charset; then
		_warning "charset [$g_charset] niewspierany, ignoruje zadanie"
		g_charset='default'
	fi

	# verify the id setting
	if ! verify_id; then
		_warning "nieznany id [$g_id], przywracam domyslny"
	fi
	
	# logfile verification	
	[ -e "$g_logfile" ] && 
		_warning "plik loga istnieje - bedzie nadpisany"
	
	# language verification
	local lidx=$(verify_language $g_lang)
	if [ $? -ne $RET_OK ]; then
		if [ $g_lang = "list" ]; then 
			list_languages
			return $RET_BREAK
		else
			_warning "nieznany jezyk [$g_lang]. przywracam PL"
			g_lang='PL'
		fi
	else
		g_lang=$(normalize_language $lidx)
	fi

}


#
# @brief main function 
# 
main() {
  	# debug
  	_debug $LINENO "$0: ($g_revision) uruchamianie ..." 

 	# print bash version
 	if [ -z $BASH_VERSION ]; then
 		_debug $LINENO "interpreter inny niz bash ($SHELL)"
 	else
 		_debug $LINENO "interpreter to bash $BASH_VERSION"
 	fi
 
	_info $LINENO "parsowanie argumentow"
	parse_argv "$@"

	_info $LINENO "weryfikacja argumentow"
	verify_argv


	return 0
}

# call the main
main "$@"

# EOF
######################################################################## ######################################################################## ######################################################################## ########################################################################


################################## DB ##########################################

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
