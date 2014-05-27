#!/bin/bash

#
# @brief: check if the given file is a video file
# @param: video filename
# @return: bool 1 - is video file, 0 - is not a video file
#
verify_extension() {
    local filename=$(basename "$1")

    local is_video=0  
    local exsention=$(get_ext "$filename" | lcase)
    local ext=""

	declare -a formats=( 'avi' 'rmvb' 'mov' 'mp4' 'mpg' 'mkv' 
		'mpeg' 'wmv' '3gp' 'asf' 'divx' 
		'm4v' 'mpe' 'ogg' 'ogv' 'qt' )

    for ext in ${formats[@]}; do
        [ "$ext" = "$extension" ] && is_video=1 && break
    done
    
    echo $is_video
	return 0
}



#
# @brief extracts http status from the http headers
#
get_http_status() {
	grep -o "HTTP/[\.0-9*] [0-9]*"
}


#
# @brief wrapper for wget
# @param url
# @param output file
#
# returns the http code(s)
#
download_url() {
	local $url="${1:-''}"
	local $output="$2"
	local headers=""
	local rv=0
	local code='unknown'

	if [ -n $g_tool_opt_wget ]; then
		headers=$(wget -q $g_tool_opt_wget -O "$output" "$url" 2>&1)
	else
		wget -q -O "$output" "$url"
	fi

	if [ $? -eq 0 ]; then
		# check the headers
		if [ -n $headers ]; then
			rv=-1
			code=$(echo $headers | get_http_status | cut -d ' ' -f 2)
			[ -n $(echo $code | grep 200) ] && rv=0
		fi
	else
		rv=-1
	fi
	
	echo $code
	return $rv
}


#
# @brief detect fps of the video file
# @param tool
# @param filename
#
get_fps() {
	local cmd=""
	local fps=0
	local tool=$(lookup_value $1 $g_tools_fps)

	# prevent empty output
	tool=$(( $tool + 0 ))

	if [ -n $tool ] && [ $tool -ne 0 ]; then
		case "$1" in
			'mplayer' | 'mplayer2' )
			fps=$($1 -identify -vo null -ao null -frames 0 "$2" 2> /dev/null | grep ID_VIDEO_FPS | cut -d '=' -f 2)
			;;

			'mediainfo' )
			fps=$($1 "$2" | grep -i 'frame rate' | tr -d '[\r a-zA-Z:]')
			;;

			'ffmpeg' )
			fps=$($1 -i "$2" 2>&1 | grep "Video:" | sed 's/, /\n/g' | grep fps | cut -d ' ' -f 1)
			;;

			*)
			;;
		esac
	fi

	echo $fps
	return 0
}


#
# @brief returns the number of available fps detection tools in the system
#
count_fps_detectors() {
	local c=0
	local t=""

	for t in $g_tools_fps; do		
		[[ $(get_value $t) -eq 1 ]] && c=$(( $c + 1 ))
	done
	echo $c
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
	return 0
}


#
# @brief: retrieve cover
# @param: md5sum
# @param: outputfile
#
download_cover() {
    local url="http://www.napiprojekt.pl/okladka_pobierz.php?id=$1&oceny=-1"
	local rv=-1

	# not interested in the headers
	download_url "$url" "$2" > /dev/null
	rv=$?

	if [ $rv -eq 0 ]; then
		local size=$(stat_file "$2")
		[ $size -eq 0 ] && 
			rv=-1 && 
			unlink "$2"
	fi

	return $rv
}


#
# @brief downloads subtitles
# @param md5 sum of the video file
# @param hash of the video file
# @param output filename
# @param requested subtitles language
#
download_subs() {
	local md5sum={$1:-0}
	local h=${2:-0}
	local of="$3"
	local lang=${4:-'PL'}
	local id=${5:-'pynapi'}
	local user=${6:-''}
	local passwd=${7:-''}

	local rv=0

	# downloaded filename
	local dof="$of"
    local url="http://napiprojekt.pl/unit_napisy/dl.php?l=$lang&f=$md5sum&t=$h&v=$id&kolejka=false&nick=$user&pass=$passwd&napios=posix"
	local napi_pass="iBlm8NTigvru0Jr0"

	# should be enough to avoid clashing
	[ $id = "other" ] && dof=$(ktemp -t napisy.7z.XXXXXXXX)

	local http_codes=$(download_url "$url" "$dof")
	if [ $? -ne 0 ]; then
		_error "nie mozna pobrac pliku, odpowiedzi http: [$http_codes]"
		return -1
	fi

	# it seems that we've got the file perform some verifications on it
	case $id in
		"pynapi" )
		# no need to do anything
		;;

		"other")
        7z x -y -so -p"$napi_pass" "$dof" 2> /dev/null > "$of"
        unlink "$dof"
		! [ -s "$of" ] && rv=-1 && unlink "$of"
		;;

		*)
		_error "not supported"
		;;
	esac

	# verify the contents
	if [ $rv -eq 0 ]; then
		local lines=$(wc -l "$of" | cut -d ' ' -f 1)
		
		# adjust that if needed
		local $min_lines=3

		if [ $lines -lt $min_lines ]; then
			_info $LINENO "plik zawiera mniej niz $min_lines lin(ie). zostanie usuniety"
			rv=-1 && unlink "$of"
		fi
	fi

	return $rv
}


#
# @brief downloads subtitles for a given media file
# @param media filename
# @param subtitles filename
# @param requested subtitles language
#
get_subtitles() {
	local fn="$1"
	local of="$2"
	local lang="$3"
	local tool_md5=$(get_md5)

	# md5sum and hash calculation
	local sum=$(dd if="$fn" bs=1024k count=10 2> /dev/null | $tool_md5 | cut -d ' ' -f 1)
	local hash=$(f $sum)

	# TODO tego brakuje w wywolaniu nizej
	# local id=${5:-'pynapi'}
	# local user=${6:-''}
	# local passwd=${7:-''}

	download_subs $sum $hash "$of" $lang
	return $?
}


process_file() {
	
    local file="$1"
	_info $LINENO "pobieram napisy dla pliku [$file]"

	# generate all the possible filenames
	prepare_filenames "$file"



	
	return 0
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
			   [[ $(stat_file "$file") -ge $(( $min_size*1024*1024 )) ]]; then
                g_FileList+=( "$file" )
            fi
        fi
    done

	return 0
}


get_sub_ext() {
	local ext=$g_DefaultExt

	case $1 in
		'subrip') ext='srt' ;;
		'subviewer') ext='sub' ;;
		*) ;;
	esac
	echo $ext
}


#
# @brief prepare all the possible filenames for the output file (in order to check if it already exists)
#
# this function prepares global variables g_possible_filenames containing all the possible output filenames
# index description
#
# @brief video filename
#
prepare_filenames() {
	
	# media filename (with path)
	local fn="${1:-''}"

    # movie filename without path
    local base=$(basename "$fn")

    # movie filename without extension
	local noext=$(strip_ext $base)

	# converted extension
	local cext=$(get_sub_ext $g_sub_format)

	# empty the array
	g_possible_filenames=()

	# original
	g_possible_filenames+=( "${noext}.$g_default_ext" )
	g_possible_filenames+=( "${noext}${g_abbrev:+$g_abbrev.}$g_default_ext" )
	g_possible_filenames+=( "${g_default_prefix}${g_possible_filenames[1]}" )
	g_possible_filenames+=( "${g_default_prefix}${g_possible_filenames[2]}" )

	# converted
	g_possible_filenames+=( "${noext}.$cext" )
	g_possible_filenames+=( "${noext}${g_abbrev:+$g_abbrev.}$cext" )
	g_possible_filenames+=( "${noext}${g_conv_abbrev:+$g_conv_abbrev.}$cext" )
	g_possible_filenames+=( "${noext}${g_abbrev:+$g_abbrev.}${g_conv_abbrev:+$g_conv_abbrev.}$cext" )

	return 0
}


###########################################################################

#
# @brief prints the help & options overview
#
usage() {

	local subotage_presence=$(lookup_value 'subotage.sh' $g_tools_opt)
	local iconv_presence=$(lookup_value 'iconv' $g_tools_opt)

	# precaution to prevent variables from being empty
	subotage_presence=$(( $subotage_presence + 0 ))
	iconv_presence=$(( $iconv_presence + 0 ))

	echo "=============================================================="
	echo "napi.sh version $g_revison (identifies as $g_id)"
	echo "napi.sh [OPCJE] <plik|katalog|*>"
	echo

	echo "   -a | --abbrev <string> - dodaj dowolny string przed rozszerzeniem (np. nazwa.<string>.txt)"
	echo "   -b | --bigger-than <size MB> - szukaj napisow tylko dla plikow wiekszych niz <size>"
	echo "   -c | --cover - pobierz okladke"

	[ $iconv_presence -eq 1 ] && 
		echo "   -C | --charset - konwertuj kodowanie plikow (iconv -l - lista dostepnych kodowan)"

	echo "   -e | --ext - rozszerzenie dla pobranych napisow (domyslnie *.txt)"
	echo "   -I | --id <pynapi|other> - okresla jak napi.sh ma sie przedstawiac serwerom napiprojekt.pl (dom. $g_id)"
	echo "   -l | --log <logfile> - drukuj output to pliku zamiast na konsole"
	echo "   -L | --language <LANGUAGE_CODE> - pobierz napisy w wybranym jezyku"
	echo "   -p | --pass <passwd> - haslo dla uzytkownika <login>"
	echo "   -S | --script <script_path> - wywolaj skrypt po pobraniu napisow (sciezka do pliku z napisami, relatywna do argumentu napi.sh, bedzie przekazana jako argument)"
	echo "   -s | --skip - nie sciagaj, jezeli napisy juz sciagniete"
	echo "   -u | --user <login> - uwierzytelnianie jako uzytkownik"
	echo "   -v | --verbosity <0..3> - zmien poziom gadatliwosci 0 - cichy, 3 - debug"
    
	if [ $subotage_presence -eq 1 ]; then    
		echo "   -d | --delete-orig - Delete the original file"   
		echo "   -f | --format - konwertuj napisy do formatu (wym. subotage.sh)"
		echo "   -P | --pref-fps <fps_tool> - preferowany detektor fps (jezeli wykryto jakikolwiek)"
		echo "   -o | --orig-prefix - prefix dla oryginalnego pliku przed konwersja (domyslnie: $g_default_prefix)"   
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
			for t in $g_tools_fps; do
				[ $(get_value $t) -eq 1 ] && get_key $t
			done
			echo
		else
			echo
			echo "By moc okreslac FPS na podstawie pliku video a nie na"
			echo "podstawie pierwszej linii pliku (w przypadku konwersji z microdvd)"
			echo "zainstaluj dodatkowo jedno z tych narzedzi (dowolnie ktore)"
			echo -e "- mediainfo\n- mplayer\n- mplayer2\n- ffmpeg\n"
		fi
	fi

	exit -1;
}



#
# @brief main function 
# 
main() {
  
 	# system detection
 	g_system=$(get_system)

	# number of cores detected
	local cores=$(get_cores)

	# first positional
	local arg1="${1:-''}"
 
 	# print the system info
 	_debug $LINENO "$0: wykryty system to: $g_system (cpu: $cores)" 

	# check for mandatory toolset
 	verify_mandatory_tools 
	[ $? -ne 0 ] && exit -1


	# detect optional tools
	g_tools_opt="$(verify_optional_tools 'iconv' 'subotage.sh' '7z' )"
 	_debug $LINENO "wykryte narzedzia opcjonalne $g_tools_opt" 

	# check for fps detectors
	g_tools_fps="$(verify_optional_tools 'mediainfo' 'mplayer' 'mplayer2' 'ffmpeg' )"
 	_debug $LINENO "wykryte narzedzia fps $g_tools_fps" 

 	# if no arguments are given, then print help and exit
 	[ $# -lt 1 ] || [ $arg1 = "--help" ] || [ $arg1 = "-h" ] && usage 


	# parse the positional parameters
	parse_argv "$@"

	# wget
	get_wget_tool_options

	prepare_file_list $g_min_size "${g_paths[@]}"

	declare -P $g_FileList



}

# call the main
main "$@"

# EOF
######################################################################## ######################################################################## ######################################################################## ########################################################################
