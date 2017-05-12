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
#  http://pcarduino.blogspot.co.ul
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

#
# version for the whole bundle (napi.sh & subotage.sh)
#
declare -r g_revision="v1.4.0"

#
# client version which will be presented to remote services
#
declare -r g_napiprojektClientVersion="2.2.0.2399"

#
# base address of the napiprojekt service
#
declare -r g_napiprojektBaseUrl="${NAPIPROJEKT_BASEURL:-http://napiprojekt.pl}"

#
# XML API URI
#
declare -r g_napiprojektApi3Uri='/api/api-napiprojekt3.php'

#
# Legacy API URI
#
declare -r g_napiprojektApiLegacyUri='/unit/napisy/dl.php'

#
# password to napiprojekt archives
#
declare -r g_napiprojektPassword='iBlm8NTigvru0Jr0'

#
# Cover download service URI
#
declare -r g_napiprojektCoverUri='/okladka_pobierz.php'

#
# Movie catalogue search
#
declare -r g_napiprojektMovieCatalogueSearchUri='/ajax/search_catalog.php'

