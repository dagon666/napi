#!/bin/bash

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


################################# napiprojekt ##################################
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
# @brief main function 
# 
main() {
  
	# check for mandatory toolset
 	verify_mandatory_tools 
	[ $? -ne 0 ] && exit -1


	# detect optional tools
	g_tools_opt="$(verify_optional_tools 'iconv' 'subotage.sh' '7z' )"
 	_debug $LINENO "wykryte narzedzia opcjonalne $g_tools_opt" 

	# check for fps detectors
	g_tools_fps="$(verify_optional_tools 'mediainfo' 'mplayer' 'mplayer2' 'ffmpeg' )"
 	_debug $LINENO "wykryte narzedzia fps $g_tools_fps" 

	# parse the positional parameters
	parse_argv "$@"


	declare -P $g_FileList
}
