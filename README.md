** napiprojekt.pl client
=====================

This script is a napiprojekt.pl client written in bash. It automatically downloads subtitles from napiprojekt.pl database basing on the video file.

This script works on OS X as well.

Usage example:
==============

napi.sh video_file.avi
- download subtitiles for video_file.avi

napi.sh *
- iterate through all elements in current directory and try to download subtitles for them. If directory contains subdirectories - than the script will also iterate through all the files in subdirectories.

napi.sh movie_dir/
- try to find and download subtitles for all files in movie_dir/ directory.

napi.sh dir*
- try to download subtitles for all files inside directories which match to pattern dir*. So i.e. if you have those dirs on disk

dir1/
dir2/
dir3/

... and you'll call napi.sh dir* - it will go through all of them and try to download subtitles for all files inside of them.


subotage.sh - universal subtitle format converter
=====

Usage
=====

The script is ment for embedded devices mostly which dont have any other interpreters installed besides bash, or the installation/compilation of perl/python is simply to much effort to spend. Currently supported convertion formats:

- mpl2
- tmplayer (most of the versions)
- subrip
- subviewer (1.0)
- fab
- microdvd

The properly convert from/to microdvd format (or any other format based on frames) a valid information about input/output file frame rate is needed !!! The default value (if not specified in the command line) is 23.98 fps for input/output.

Examples
========

1. Convert from microdvd 23.98 fps to subrip. Subrip is default output format so it doesnt have to be specified. The input frame rate is also equal to the default one, so no addition specification in the command line has been made.

-- subotage.sh -i input_file.txt -o output_file.srt

2. Convert from microdvd 25 fps to subviewer

-- subotage.sh -i input_file.txt -fi 25 -of subviewer -o output_file.sub

3. Convert from subrip to fab

-- subotage.sh -i input_file.srt -of fab -o output_file.fab

4. Convert from microdvd 25 fps to microdvd 29.98 fps:

-- subotage.sh -i input_file.txt -fi 25 -fo 29.98 -of microdvd -o output_file.txt

Required External Tools
=======================

- sed
- cut
- head
- grep
- awk

To check if the listed tools are available in your system and their functionality meets the subotage.sh script requirements please use the attached test_tools.sh script.

Availability
============

napi.sh & subotage.sh are available in bundle in AUR - Arch Linux User Repository. The package is named bashnapi and can be installed through yaourt:

yaourt -S bashnapi
