# Instalation

**bashnapi** provides a simple install.sh script. It should be used to install the bundle. There's a reason why it doesn't use autotools, cmake or any other build system. Most of the embedded devices (routers, NASes) etc. don't have any of these installed.


## Automatic (recommended)

Use the **install.sh** script to copy napi.sh & subotage.sh to the bin directory (/usr/bin - by default) and libnapi_common.sh library to a shared directory (/usr/share/napi - by default).
If you want to install into directories different than defaults specify them in install.sh invocation (USE ABSOLUTE PATHS ONLY).

To install napi.sh & subotage.sh under /bin and libnapi_common.sh under /shared/napi:

`$ ./install.sh --bindir /bin --shareddir /shared`

To install napi.sh & subotage.sh under /usr/bin (default path) and libnapi_common.sh under /my/custom/directory/napi

`$ ./install.sh --shareddir /my/custom/directory`
---

## Manual (only for experts)

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
---


## 3rd_party tools required:
- bash shell
- wget (can be installed via Homebrew/Macports)
- find tool
- dd (coreutils)
- md5sum (in OS X, it's md5)
- cut
- mktemp
- 7z (if napiprojekt3 is used) (p7zip)
- awk
- grep
