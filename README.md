# Bashnapi - napiprojekt.pl client

This script is a [NapiProjekt](napiprojekt.pl) client written in bash. It
automatically downloads subtitles from napiprojekt.pl database basing on the
video file.

This script works on Linux & OS X systems. It has very limited requirements and
is mostly depending on bash (it is proven to run from bash 2.04 - which makes
it ideal for embedded devices) and `coreutils` (which should be available on most
modern systems, no perl or python is required).

## Installation

**Bashnapi** uses [cmake](https://cmake.org) to build itself and install.
Typical install procedure is very simple:

    $ cd bashnapi
    $ mkdir build
    $ cmake ..
    # make && install

### Installation on embedded devices

In case you want to install **bashnapi** on a host which doesn't have
cmake, the procedure is very similar. Just install to a local
directory and deploy that to your device. Below is an example:

    $ cd bashnapi
    $ mkdir build
    $ cmake -DCMAKE_INSTALL_PREFIX=napi_install ..
    $ make && install

**bashnapi** is now installed in the `napi_install` directory. Just deploy
that to your device (with `scp`, `ftp`, or whatever you prefer) and add
the path to a directory under `napi_install/bin` to your `PATH`.

You can use any directory name, `napi_install` has been picked
arbitrarilly without any strict reason.

### Installation on macOS using Homebrew

```bash
$ brew install mstrzele/napi/napi
```

## Actions

Script funcionality has been divided into actions. Each action implements a
specific request type. Available actions:

- scan - scan a directory (or a single file) and download subtitles for all
found video files,
- download - download subtitles using a "dc link"
- search - search for a movie
- subtitles - list subtitles for given movie

Below are some usage examples

### scan action

### download action

### search action

### subtitles action


# Colaboration

**bashnapi** is an open project. Feel free to send patches and pull requests.
Check the [COLABORATION](COLABORATION.md) for more details.







# # Usage example:
#
# 1. Download subtitiles for "video_file.avi":
#
# `$ napi.sh video_file.avi`
#
# 2. Iterate through all elements in current directory and try to download subtitles for them. If directory contains subdirectories - than the script will also iterate through all the files in subdirectories:
#
# `$ napi.sh *`
#
# 3. Try to find and download subtitles for all files in movie_dir/ directory:
#
# `$ napi.sh movie_dir/`
#
# 4. Try to download subtitles for all files inside directories which match to pattern dir*.
#
# `$ napi.sh dir*`
#
# This will recursively search for video file in directories like:
# > dir1/ dir2/ dir3/ dir_other/
#
# 5. It has file size limitation too ! Download subtitles for all supported video files which are bigger than 100 MB:
#
# `$ napi.sh -b 100 *`
#
# 6. Not to mention that it integrates a separate subtitles converter written completely in **bash** & **awk**. To download subtitles for all supported video files and convert them to subrip format on the fly ( requires subotage.sh to be installed as well ) just use the **-f** option:
#
# `$ napi.sh -f subrip *`
#
#
# # subotage.sh - universal subtitle format converter
#
# **subotage.sh** is a dedicated subtitles format converter written in **bash** & **awk**. It integrates with napi.sh to provide a single command convenient toolset for automatic subtitle collection.
#
# ## Usage
#
# The script is meant for embedded devices mostly which dont have any other interpreters installed besides bash, or the installation/compilation of perl/python is simply to much of an effort. Currently supported formats:
#
# - mpl2
# - tmplayer (most of the versions)
# - subrip
# - subviewer (1.0)
# - fab
# - microdvd
#
# The properly convert from/to microdvd format (or any other format based on frames) a valid information about input/output file frame rate is needed! The default value (if not specified in the command line) is 23.98 fps for input/output.
#
# ### Examples
#
# 1. Convert from microdvd 23.98 fps to subrip. Subrip is default output format so it doesnt have to be specified. The input frame rate is also equal to the default one, so no addition specification in the command line has been made.
#
# `$ subotage.sh -i input_file.txt -o output_file.srt`
#
# 2. Convert from microdvd 25 fps to subviewer
#
# `$ subotage.sh -i input_file.txt -fi 25 -of subviewer -o output_file.sub`
#
# 3. Convert from subrip to fab
#
# `$ subotage.sh -i input_file.srt -of fab -o output_file.fab`
#
# 4. Convert from microdvd 25 fps to microdvd 29.98 fps:
#
# `$ subotage.sh -i input_file.txt -fi 25 -fo 29.98 -of microdvd -o output_file.txt`
#
# ## Required External Tools
#
# - sed
# - cut
# - head
# - grep
# - awk
# - iconv (optional)
# - any of: ffmpeg/mediainfo/mplayer/mplayer2 (for fps detection - optional)
# - mktemp
#
# To check if the listed tools are available in your system and their functionality meets the subotage.sh script requirements please use the attached **test_tools.sh** script.
