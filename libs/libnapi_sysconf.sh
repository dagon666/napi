#!/bin/bash

# force indendation settings
# vim: ts=4 shiftwidth=4 expandtab

########################################################################
########################################################################
########################################################################

#  Copyright (C) 2017 Tomasz Wisniewski aka
#       DAGON <tomasz.wisni3wski@gmail.com>
#
#  http://github.com/dagon666
#  http://pcarduino.blogspot.co.uk
#
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

########################################################################
########################################################################
########################################################################

# globals

#
# The keys should be of format:
# module.category.value
#

declare -a ___g_sysconf_configuration=( \
    "napiprojekt.subtitles.extension=txt" \
    "napiprojekt.cover.extension=jpg" \
    "napiprojekt.cover.download=0" \
    "napiprojekt.nfo.extension=nfo" \
    "napiprojekt.nfo.download=0" \
)

########################################################################

sysconf_setKey_GV() {
    logging_debug $LINENO $"ustawiam wartosc klucza:" "[$1] -> [$2]"
    ___g_sysconf_configuration="$(assoc_modifyValue_SO \
        "$1" "$2" "${___g_sysconf_configuration[@]}")"
}

sysconf_getKey_SO() {
    assoc_lookupValue_SO "${1}" "${___g_sysconf_configuration[@]}"
}

# declare -r ___g_sysconfSystem=0
# declare -r ___g_sysconfNForks=1
# declare -r ___g_sysconfEncoding=3
# declare -r ___g_sysconfHook=4
#
# 0 - system - detected system type
# - linux
# - darwin - mac osx
#
# 1 - number of forks
#
# 3 - text encoding
# defines the char-set of the resulting file
#
# 4 - external script
#
# declare -a ___g_sysConfig=( 'none' '0' 'default' 'none' )
#

################################################################################

# EOF
