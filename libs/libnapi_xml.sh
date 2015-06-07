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

#
# @brief extracts xml tag contents
# @param tag name
# @param file name (optional)
#
xml_extractXmlTag() {
    local tag="$1"
    local filePath="${2:-/dev/stdin}"
    local awkScript=

# embed small awk program to extract the tag contents
read -d "" awkScript << EOF
BEGIN {
    RS=">"
    ORS=">"
}
/<$tag/,/<\\\/$tag/ { print }
EOF
    awk "$awkScript" "$filePath"
}

#
# @brief extracts cdata contents
# @param file name or none (if used as a stream filter)
#
xml_extractCdataTag() {
    local filePath="${1:-/dev/stdin}"
    local awkScript=

# embed small awk program to extract the tag contents
read -d "" awkScript << EOF
BEGIN {
    # this can't be a string - single character delimiter (to be portable)
    # RS="CDATA";
    FS="[\\]\\[]";
}
{
    print \$3;
}
EOF
    awk "$awkScript" "$filePath" | tr -d '\n'
}

#
# @brief strip xml tag
# @param tag name (if used with file given)
# @param file name or a tag name (if used as a stream filter)
#
xml_stripXmlTag() {
    local tag="$1"
    local filePath="${2:-/dev/stdin}"
    local awkScript=

# embed small awk program to extract the tag contents
read -d "" awkScript << EOF
BEGIN {
    FS="[><]"
}
/$tag/ { print \$3 }
EOF

    awk "$awkScript" "$filePath"
}

