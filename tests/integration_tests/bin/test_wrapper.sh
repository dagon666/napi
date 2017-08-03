#!/bin/bash

declare -r LOGFILE="$1"
declare -r SHELL="$2"

exec 4<> "$LOGFILE"
shift 2

date >&4
echo "cmdline: $*" >&4

export BASH_XTRACEFD=4
exec "${SHELL}" -x "$@"
