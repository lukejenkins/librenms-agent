#!/bin/sh
#
# https://github.com/librenms/librenms-agent/
# https://github.com/lukejenkins/librenms-agent/
#
# Please make sure the paths below are correct.
# Alternatively you can put them in $0.conf, meaning if you've named
# this script ntpsec-client.sh then it must go in ntpsec-client.sh.conf .
#
# Cloned from ntp-server.sh from the librenms-agent project.
# At the time I cloned it, contributors for that script included:
# @crcro, @VVelox, @SourceDoctor, @Jellyfrog with comments from @laf. 
# Outputs from ntpsec version of the commands are different in a number of ways.

CONFIGFILE=/etc/snmp/ntpsec-server.conf

BIN_ENV='/usr/bin/env'

# --- options & debug helpers ---
DEBUG=0

usage() {
	echo "Usage: $0 [-d]" 1>&2
	echo "  -d    Enable debug logging to stderr (prints variable values as set)" 1>&2
}

# POSIX getopts for -d (debug) and -h (help)
while getopts ":dh" opt; do
	case "$opt" in
		d)
			DEBUG=1
			;;
		h)
			usage
			exit 0
			;;
		\?)
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))

# debug print helpers (to stderr so stdout JSON is unaffected)
debug() {
	[ "$DEBUG" -eq 1 ] && printf 'DEBUG: %s\n' "$*" >&2
}

debug_var() {
	# usage: debug_var NAME VALUE
	if [ "$DEBUG" -eq 1 ]; then
		# Print NAME='VALUE' including empty or spaced values safely
		printf "DEBUG: %s='%s'\n" "$1" "${2-}" >&2
	fi
}

if [ -f $CONFIGFILE ] ; then
	# shellcheck disable=SC1090
	. $CONFIGFILE
fi

debug "Loaded config file (if present)"
debug_var CONFIGFILE "$CONFIGFILE"

BIN_NTPD="$BIN_ENV ntpd"
BIN_NTPQ="$BIN_ENV ntpq"
BIN_GREP="$BIN_ENV grep"
BIN_TR="$BIN_ENV tr"
BIN_CUT="$BIN_ENV cut"
BIN_SED="$BIN_ENV sed"
BIN_AWK="$BIN_ENV awk"

debug_var BIN_ENV "$BIN_ENV"
debug_var BIN_NTPD "$BIN_NTPD"
debug_var BIN_NTPQ "$BIN_NTPQ"
debug_var BIN_GREP "$BIN_GREP"
debug_var BIN_TR "$BIN_TR"
debug_var BIN_CUT "$BIN_CUT"
debug_var BIN_SED "$BIN_SED"
debug_var BIN_AWK "$BIN_AWK"

################################################################
# Don't change anything unless you know what are you doing     #
################################################################
CONFIG=$0".conf"
if [ -f "$CONFIG" ]; then
	# shellcheck disable=SC1090
	. "$CONFIG"
fi

VERSION=1

debug_var CONFIG "$CONFIG"
debug_var VERSION "$VERSION"

# Old command:
# STRATUM=$($BIN_NTPQ -c rv | $BIN_GREP -Eow "stratum=[0-9]+" | $BIN_CUT -d "=" -f 2)


# parse the ntpq info that requires version specific info
# Old command:
# NTPQ_RAW=$($BIN_NTPQ -c rv | $BIN_GREP jitter | $BIN_SED 's/[[:alpha:]=,_]/ /g')
NTPQ_RAW=$($BIN_NTPQ -c rv | tr -d '\012\015')
debug_var NTPQ_RAW "$NTPQ_RAW"
# shellcheck disable=SC2086
STRATUM=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/stratum/{print $2}')
debug_var STRATUM "$STRATUM"
# shellcheck disable=SC2086
OFFSET=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/offset/{print $2}')
debug_var OFFSET "$OFFSET"
# shellcheck disable=SC2086
FREQUENCY=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/frequency/{print $2}')
debug_var FREQUENCY "$FREQUENCY"
# shellcheck disable=SC2086
SYS_JITTER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/sys_jitter/{print $2}')
debug_var SYS_JITTER "$SYS_JITTER"
# shellcheck disable=SC2086
CLK_JITTER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/clk_jitter/{print $2}')
debug_var CLK_JITTER "$CLK_JITTER"
# shellcheck disable=SC2086
CLK_WANDER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/clk_wander/{print $2}')
debug_var CLK_WANDER "$CLK_WANDER"

USECMD=$(echo "$BIN_NTPQ" -c iostats 127.0.0.1)
debug_var USECMD "$USECMD"

CMD2=$($USECMD | $BIN_TR -d ' ' | $BIN_CUT -d : -f 2 | $BIN_TR '\n' ' ')
debug_var CMD2 "$CMD2"

# shellcheck disable=SC2086
TIMESINCERESET=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $1}')
debug_var TIMESINCERESET "$TIMESINCERESET"
# shellcheck disable=SC2086
RECEIVEDBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $2}')
debug_var RECEIVEDBUFFERS "$RECEIVEDBUFFERS"
# shellcheck disable=SC2086
FREERECEIVEBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $3}')
debug_var FREERECEIVEBUFFERS "$FREERECEIVEBUFFERS"
# shellcheck disable=SC2086
USEDRECEIVEBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $4}')
debug_var USEDRECEIVEBUFFERS "$USEDRECEIVEBUFFERS"
# shellcheck disable=SC2086
LOWWATERREFILLS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $5}')
debug_var LOWWATERREFILLS "$LOWWATERREFILLS"
# shellcheck disable=SC2086
DROPPEDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $6}')
debug_var DROPPEDPACKETS "$DROPPEDPACKETS"
# shellcheck disable=SC2086
IGNOREDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $7}')
debug_var IGNOREDPACKETS "$IGNOREDPACKETS"
# shellcheck disable=SC2086
RECEIVEDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $8}')
debug_var RECEIVEDPACKETS "$RECEIVEDPACKETS"
# shellcheck disable=SC2086
PACKETSSENT=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $9}')
debug_var PACKETSSENT "$PACKETSSENT"
# shellcheck disable=SC2086
PACKETSENDFAILURES=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $10}')
debug_var PACKETSENDFAILURES "$PACKETSENDFAILURES"
# shellcheck disable=SC2086
INPUTWAKEUPS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $11}')
debug_var INPUTWAKEUPS "$INPUTWAKEUPS"
# shellcheck disable=SC2086
USEFULINPUTWAKEUPS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $12}')
debug_var USEFULINPUTWAKEUPS "$USEFULINPUTWAKEUPS"

echo '{"data":{"offset":"'"$OFFSET"\
'","frequency":"'"$FREQUENCY"\
'","sys_jitter":"'"$SYS_JITTER"\
'","clk_jitter":"'"$CLK_JITTER"\
'","clk_wander":"'"$CLK_WANDER"\
'","stratum":"'"$STRATUM"\
'","time_since_reset":"'"$TIMESINCERESET"\
'","receive_buffers":"'"$RECEIVEDBUFFERS"\
'","free_receive_buffers":"'"$FREERECEIVEBUFFERS"\
'","used_receive_buffers":"'"$USEDRECEIVEBUFFERS"\
'","low_water_refills":"'"$LOWWATERREFILLS"\
'","dropped_packets":"'"$DROPPEDPACKETS"\
'","ignored_packets":"'"$IGNOREDPACKETS"\
'","received_packets":"'"$RECEIVEDPACKETS"\
'","packets_sent":"'"$PACKETSSENT"\
'","packet_send_failures":"'"$PACKETSENDFAILURES"\
'","input_wakeups":"'"$INPUTWAKEUPS"\
'","useful_input_wakeups":"'"$USEFULINPUTWAKEUPS"\
'"},"error":"0","errorString":"","version":"'$VERSION'"}'
