# Bashnapi - napiprojekt.pl client

This script is a [NapiProjekt](napiprojekt.pl) client written in bash. It automatically downloads subtitles from napiprojekt.pl database basing on the video file.

This script works on Linux & OS X systems. It has very limited requirements and is mostly depending on bash (it is proven to run from bash 2.04 - which makes it ideal for embedded devices) and coreutils (which should be available on most modern systems, no perl or python is required).

## Usage example:

1. Download subtitiles for "video_file.avi":

`$ napi.sh video_file.avi`

2. Iterate through all elements in current directory and try to download subtitles for them. If directory contains subdirectories - than the script will also iterate through all the files in subdirectories:

`$ napi.sh *`

3. Try to find and download subtitles for all files in movie_dir/ directory:

`$ napi.sh movie_dir/`

4. Try to download subtitles for all files inside directories which match to pattern dir*.

`$ napi.sh dir*`

This will recursively search for video file in directories like:
> dir1/ dir2/ dir3/ dir_other/

5. It has file size limitation too ! Download subtitles for all supported video files which are bigger than 100 MB:

`$ napi.sh -b 100 *`

6. Not to mention that it integrates a separate subtitles converter written completely in **bash** & **awk**. To download subtitles for all supported video files and convert them to subrip format on the fly ( requires subotage.sh to be installed as well ) just use the **-f** option:

`$ napi.sh -f subrip *`


# subotage.sh - universal subtitle format converter

**subotage.sh** is a dedicated subtitles format converter written in **bash** & **awk**. It integrates with napi.sh to provide a single command convenient toolset for automatic subtitle collection.

## Usage

The script is meant for embedded devices mostly which dont have any other interpreters installed besides bash, or the installation/compilation of perl/python is simply to much of an effort. Currently supported formats:

- mpl2
- tmplayer (most of the versions)
- subrip
- subviewer (1.0)
- fab
- microdvd

The properly convert from/to microdvd format (or any other format based on frames) a valid information about input/output file frame rate is needed! The default value (if not specified in the command line) is 23.98 fps for input/output.

### Examples

1. Convert from microdvd 23.98 fps to subrip. Subrip is default output format so it doesnt have to be specified. The input frame rate is also equal to the default one, so no addition specification in the command line has been made.

`$ subotage.sh -i input_file.txt -o output_file.srt`

2. Convert from microdvd 25 fps to subviewer

`$ subotage.sh -i input_file.txt -fi 25 -of subviewer -o output_file.sub`

3. Convert from subrip to fab

`$ subotage.sh -i input_file.srt -of fab -o output_file.fab`

4. Convert from microdvd 25 fps to microdvd 29.98 fps:

`$ subotage.sh -i input_file.txt -fi 25 -fo 29.98 -of microdvd -o output_file.txt`

## Required External Tools

- sed
- cut
- head
- grep
- awk
- iconv (optional)
- any of: ffmpeg/mediainfo/mplayer/mplayer2 (for fps detection - optional)
- mktemp

To check if the listed tools are available in your system and their functionality meets the subotage.sh script requirements please use the attached **test_tools.sh** script.

## Availability

napi.sh & subotage.sh are available in bundle in AUR - Arch Linux User Repository. The package is named bashnapi and can be installed through yaourt:

`$ yaourt -S bashnapi`


# Instalation

## AUTOMATIC (recommended)

Use the **install.sh** script to copy napi.sh & subotage.sh to the bin directory (/usr/bin - by default) and libnapi_common.sh library to a shared directory (/usr/share/napi - by default).
If you want to install into directories different than defaults specify them in install.sh invocation (USE ABSOLUTE PATHS ONLY).

To install napi.sh & subotage.sh under /bin and libnapi_common.sh under /shared/napi:

`$ ./install.sh --bindir /bin --shareddir /shared`

To install napi.sh & subotage.sh under /usr/bin (default path) and libnapi_common.sh under /my/custom/directory/napi

`$ ./install.sh --shareddir /my/custom/directory`

---


## MANUAL (only for experts)

napi.sh & subotage.sh share some common code from libnapi_common.sh. Both of them are sourcing this file. Bellow is an example installation procedure given (executables under /usr/bin, libraries under /usr/shared/napi)

1. Edit path to libnapi_common.sh in napi.sh & subotage.sh (the line numbers may slightly differ):

Search for a variable NAPI_COMMON_PATH

    38
    39	# verify presence of the napi_common library
    40	declare -r NAPI_COMMON_PATH=

and set it to /usr/shared/napi

    38
    39	# verify presence of the napi_common library
    40	declare -r NAPI_COMMON_PATH="/usr/shared/napi"

2. Place the napi.sh & subotage.sh under /usr/bin:

	$ cp -v napi.sh subotage.sh /usr/bin

3. Create the /usr/shared/napi directory and place the library inside of it:

	$ mkdir -p /usr/shared/napi
	$ cp -v libnapi_common.sh /usr/shared/napi


**bashnapi** bundle is now installed and ready to use.


# Colaboration

**napi.sh** is an open project. Feel free to send patches and pull requests. Check the [COLABORATION](COLABORATION.md) for more details.
