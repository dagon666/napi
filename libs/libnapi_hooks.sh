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

########################################################################

hooks_callHook_GV() {
    local subtitlesFile="${1:-}"
    local hook="$(sysconf_getKey_SO system.hook.executable)"

    [ "${hook:-none}" = "none" ] &&
        logging_debug $LINENO $"brak skonfigurowanego hooka, ignoruje" &&
        return $G_RETNOACT

    [ ! -x "${hook}" ] && {
        logging_error $"podany skrypt jest niedostepny (lub nie ma uprawnien do wykonywania)" "[$hook]"
        return $G_RETPARAM
    }

    logging_msg $"wywoluje zewnetrzny skrypt: " "[$hook]"
    $hook "$subtitlesFile"
}

# EOF
