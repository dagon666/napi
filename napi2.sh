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

