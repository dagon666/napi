# [version 1.3.5 (2015-06-07)](https://github.com/dagon666/napi/releases/tag/v1.3.5)
- fix for MAC OS having both GNU & BSD stat installed
- install.sh fixes for MAC OS
- configure_cmds function refactoring
- overlap correction implemented for all supported format
- added debian packaging script

# [version 1.3.4 (2015-01-21)](https://github.com/dagon666/napi/releases/tag/v1.3.4)
- bugfix for system detection routine
- core detection routine bugfix
- test environment corrected test box name
- added -px debugging option to preserve the xml
- various fixes for mac osx

# [version 1.3.3 (2014-09-11)](https://github.com/dagon666/napi/releases/tag/v1.3.3)
- cleanup on SIGINT implemented
- removed attempts to access /proc on darwin
- corrections for the log being broken
- removed grep -o which is not portable (busybox)

# [version 1.3.2 (2014-08-08)](https://github.com/dagon666/napi/releases/tag/v1.3.2)
- corrections for ffmpeg framerate detection
- corrections for the logging mechanism
- bugfixes
- subotage correction for minutes increment

# [version v1.3.1 (2014-07-11)](https://github.com/dagon666/napi/releases/tag/v1.3.1)
- napiprojekt3 XML API support implemented
- napiprojekt3 API as default engine (legacy mode still supported using --id
		pynapi or --id other)
- implemented media nfo retrieval from napi xml (napiprojekt3 API)
- implemented cover support using napi xml (napiprojekt3 API)
- fps detection using ffprobe + ffmpeg fps detection fixes
- subotage.sh reimplemented and code cleaned up
- fab support removed from subotage
- napi and subotage code integration
- extraction of common code to the napi_common.sh library
- unit tests for napi and subotage
- system tests for napi and subotage
- a lot of bugfixes and corrections
- napi bundle installer introduced
- many fixes to subotage format processing
- added logoverwrite option to napi

# [version v1.2.1 (2014-06-11)](https://github.com/dagon666/napi/releases/tag/v1.2.1)
- Major code redesign which includes
-- decomposing code into small functional blocks
-- assuring more compatibility with old shells
-- implemented multithreading (spawning multiple processes at the same time to speed
		up the processing -F options)
-- "skip" option reimplemented and made more flexible
-- multiple verbosity levels
- implemented unit test suite for napi.sh
- prepared test environment for system & unit tests (based on Vagrant & Puppet)
- prepared system tests for napi & subotage

# [version v1.1.13 (2014-05-03)](https://github.com/dagon666/napi/releases/tag/v1.1.13)
- contributions from Maciej Lopacinski (iconv charset conversion) merged
- contributions from github user "emfor" merged (abbreviations support)
- created a test environment
- made napi.sh more compatible with old bash releases
- preparations to write unit tests

# [version 1.1.12 (2014-04-19)](https://github.com/dagon666/napi/releases/tag/v1.1.12)
- fps detection using ffmpeg added
- corrections to subotage
- Abbreviations support added - you can add any custom string between the filename and it's extension

# [version 1.1.11 (2014-02-05)](https://github.com/dagon666/napi/releases/tag/v1.1.11)
- napi.sh bugfixes
- added support to download subtitles in a selected language

# [version 1.1.10 (2014-02-03)](https://github.com/dagon666/napi/releases/tag/v1.1.10)
- napi.sh added a --bigger-than flag, which can be used to download subtitles only for files bigger than the given size (in MB) - that way video samples can be sift out
- various corrections to the file search function

# [version 1.1.9 (2014-02-03)](https://github.com/dagon666/napi/releases/tag/v1.1.9)
- napi works on Mac OS X, corrections for subotage script - overlap detection function
- napi.sh code cleanup (polish variable names renamed to english)
- merged changes from mcmajkel (Mac OS X compatibility)
- subotage.sh by default subtitles with no end marker will be displayed for 5 seconds
- subotage.sh overlap detection function

# [version 1.1.8 (2013-11-03)](https://github.com/dagon666/napi/releases/tag/v1.1.8)
- fix for a bug which deleted the resulting subtitles file when the converted file had the same name and extension as the source file

# [version 1.1.7 (2013-10-26)](https://github.com/dagon666/napi/releases/tag/v1.1.7)
- introduced -e argument to specify default extension for output files. This helps when used in conjunction with subotage the script will detect that the conversion is not needed and will leave the remaining unconverted files with the default extension.

# [version 1.1.6 (2013-10-25)]()
- subotage and napi will be maintained in a single repository
- github source repository for the project created: https://github.com/dagon666/napi
- contributions from Michal Gorny included

# [version 1.1.3 (2011-02-04)]()
- Necessary tools presence validation added
- some small bugfixes introduced

# [version 1.1.2 (2011-01-18)]()
- Logging option was added. Complete operational log can be chosed instead of standard output.
- Some improvements in case that the subtitles file already exists had been introduced - directory sweeping is now performed way faster

# [version v1.1.1 (2011-01-09)](https://github.com/dagon666/napi/releases/tag/v1.3.5)
- integration with subotage - universal subtitle converter. napi.sh is now able to convert subtitles to one of the supported destination formats on the fly - right after the original file has been downloaded
- a lot of changes in the processing functions
- some small bugfixes related with argument processing
- user authorisation data can now be passed as arguments

# [version v0.1.8 (2010-06-04)](https://github.com/dagon666/napi/releases/tag/v1.3.5)
- Added support to download covers
- 7zip is no longer obligatory !!!
- code cleanup

