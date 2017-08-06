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
    $ mkdir build && cd build
    $ cmake ..
    # make && install

### Installation on embedded devices

In case you want to install **bashnapi** on a host which doesn't have
cmake, the procedure is very similar. Just install to a local
directory and deploy that to your device. Below is an example:

    $ cd bashnapi
    $ mkdir build
    $ cmake -DCMAKE_INSTALL_PREFIX=napi_install -DNAPI_INSTALL_PREFIX=/opt/napi ..
    $ make && install

**bashnapi** is now installed in the `napi_install` directory on your local
machine. Just deploy that to your device (with `scp`, `ftp`, or whatever you
prefer) and add the path to a directory under `/opt/napi/bin` to your
`PATH`. The variables:

    - `CMAKE_INSTALL_PREFIX` - defines the directory on the host to which napi
    will be installed

    - `NAPI_INSTALL_PREFIX` - defines the directory on the target to which napi
    should be deployed

You can use any directory names, `napi_install` and `/opt/napi` have been picked
arbitrarilly without any strict reason.

### Dockerized application

`napi.sh` is available as well as a Dockerized application. In order to use it
with docker, just build the container image:

    $ docker build -t napi .

Once it's built it can be used through docker:

    $ docker run -v /media:/mnt napi scan /mnt

The above command maps the directory `/media` to a directory `/mnt` in the
container and invokes `napi.sh` scan action in container's `/mnt`.

## Actions

Script funcionality has been divided into actions. Each action implements a
specific request type. Available actions:

- scan - scan a directory (or a single file) and download subtitles for all
found video files,
- download - download subtitles using a "dc link"
- search - search for a movie
- subtitles - list subtitles for given movie

Each action has its own command set and its own help system as well so,

     $ napi.sh scan --help

... and

    $ napi.sh download --help

... will produce different output. Try out help for different actions to learn
about how to use them and what do they do. Generic options, shared by all
actions are listed in the global help:

    $ napi.sh --help

Below are some usage examples

### scan action

This action is the equivalent of napi 1.X versions behaviour. It goes either
through given directories or media files and, creates a media file list and
tries to download subtitles for all found media files.

Examples:

- Download subtitles for `video_file.avi`:

    $ napi.sh scan video_file.avi

- Iterate through all elements in current directory and try to download
subtitles for them. If directory contains subdirectories - than the script will
also iterate through all the files in subdirectories:

    $ napi.sh scan *

- Try to find and download subtitles for all files in `movie_dir/` directory:

    $ napi.sh scan movie_dir/

- This will recursively search for video file in directories like:

    $ napi.sh scan dir1/ dir2/ dir3/ dir_other/

- It has file size limitation too ! Download subtitles for all supported video
files which are bigger than 100 MB:

    $ napi.sh scan -b 100 *

- Not to mention that it integrates a separate subtitles converter written
completely in **bash** & **awk**. To download subtitles for all supported video
files and convert them to subrip format on the fly, just use the **-f** option:

    $ napi.sh -f subrip *

### download action (experimental)

This action can be used to download a selected subtitles from napiprojekt.pl
using the subtitles id, which can be obtained from napiprojekt.pl site.

TODO: complete this

### search action (experimental)

This action can be used to search for a given movie in napiprojekt.pl database.

- Search for movie "terminator":

    $ napi.sh search -k movie terminator
    $ napi.sh search "the big bang theory"

### subtitles action (experimental)

This action can be used to list all the available subtitles for a given movie
title.

TODO: complete this

## subotage.sh

`subotage.sh` is a simple subtitles format converter bundled with `napi.sh`

Currently supported formats:
- mpl2
- tmplayer (most of the versions)
- subrip
- subviewer
- microdvd

### Usage

The properly convert from/to microdvd format (or any other format based on
frames) a valid information about input/output file frame rate is
needed! The default value (if not specified in the command line) is 23.98 fps
for input/output.

Examples:

- Convert from microdvd 23.98 fps to subrip. Subrip is default output format so
it doesnt have to be specified. The input frame rate is also equal to the
default one, so no addition specification in the command line has been made.
    $ subotage.sh -i input_file.txt -o output_file.srt

- Convert from microdvd 25 fps to subviewer:
    $ subotage.sh -i input_file.txt -fi 25 -of subviewer -o output_file.sub

- Convert from subrip to mpl2
    $ subotage.sh -i input_file.srt -of mpl2 -o output_file.fab

- Convert from microdvd 25 fps to microdvd 29.98 fps:
    $ subotage.sh -i input_file.txt -fi 25 -fo 29.98 -of microdvd -o output_file.txt

# Colaboration

**bashnapi** is an open project. Feel free to send patches and pull requests.
Check the [COLABORATION](COLABORATION.md) for more details.
