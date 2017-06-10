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

# This module should be used for sharing values between modules. If a variable
# has a default value which will be accessed from multiple places it should be
# placed here. For module specific purposes module global variables should be
# used instead.

########################################################################

# globals

#
# The keys should be of format:
# module.category.value
#

declare -a ___g_sysconf_configuration=( \
    "napiprojekt.subtitles.orig.prefix=ORIG_" \
    "napiprojekt.subtitles.orig.delete=0" \
    "napiprojekt.subtitles.extension=txt" \
    "napiprojekt.subtitles.format=default" \
    "napiprojekt.subtitles.encoding=default" \
    "napiprojekt.cover.extension=jpg" \
    "napiprojekt.cover.download=0" \
    "napiprojekt.nfo.extension=nfo" \
    "napiprojekt.nfo.download=0" \
    "system.hook.executable=none" \
    "system.forks=1" \
)

########################################################################

sysconf_setKey_GV() {
    logging_debug $LINENO $"ustawiam wartosc klucza:" "[$1] -> [$2]"
    assoc_modifyValue_GV "$1" "$2" "___g_sysconf_configuration"
    # ___g_sysconf_configuration="$(assoc_modifyValue_SO \
    #     "$1" "$2" "${___g_sysconf_configuration[@]}")"
}

sysconf_getKey_SO() {
    assoc_lookupValue_SO "${1}" "${___g_sysconf_configuration[@]}"
}

################################################################################

# EOF
