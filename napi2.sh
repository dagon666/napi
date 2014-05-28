#!/bin/bash
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

process_file() {
	

	# generate all the possible filenames
	prepare_filenames "$file"



	
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
