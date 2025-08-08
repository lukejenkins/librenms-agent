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
# Outputs from ntpsec version of the commands are different in a number of ways.
#

CONFIGFILE=/etc/snmp/ntpsec-server.conf

BIN_ENV='/usr/bin/env'

if [ -f $CONFIGFILE ] ; then
	# shellcheck disable=SC1090
	. $CONFIGFILE
fi

BIN_NTPD="$BIN_ENV ntpd"
BIN_NTPQ="$BIN_ENV ntpq"
BIN_GREP="$BIN_ENV grep"
BIN_TR="$BIN_ENV tr"
BIN_CUT="$BIN_ENV cut"
BIN_SED="$BIN_ENV sed"
BIN_AWK="$BIN_ENV awk"

################################################################
# Don't change anything unless you know what are you doing     #
################################################################
CONFIG=$0".conf"
if [ -f "$CONFIG" ]; then
	# shellcheck disable=SC1090
	. "$CONFIG"
fi
VERSION=1

# Old command:
# STRATUM=$($BIN_NTPQ -c rv | $BIN_GREP -Eow "stratum=[0-9]+" | $BIN_CUT -d "=" -f 2)


# parse the ntpq info that requires version specific info
# Old command:
# NTPQ_RAW=$($BIN_NTPQ -c rv | $BIN_GREP jitter | $BIN_SED 's/[[:alpha:]=,_]/ /g')
NTPQ_RAW=$($BIN_NTPQ -c rv | tr -d '\012\015')
# shellcheck disable=SC2086
STRATUM=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/stratum/{print $2}')
# shellcheck disable=SC2086
OFFSET=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/offset/{print $2}')
# shellcheck disable=SC2086
FREQUENCY=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/frequency/{print $2}')
# shellcheck disable=SC2086
SYS_JITTER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/sys_jitter/{print $2}')
# shellcheck disable=SC2086
CLK_JITTER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/clk_jitter/{print $2}')
# shellcheck disable=SC2086
CLK_WANDER=$(echo $NTPQ_RAW | $BIN_AWK -v RS="[ ,]+" -F "[=, ]+" '/clk_wander/{print $2}')

echo $NTPQ_RAW
echo $STRATUM
echo $OFFSET
echo $FREQUENCY
echo $SYS_JITTER
echo $CLK_JITTER
echo $CLK_WANDER

USECMD=$(echo "$BIN_NTPQ" -c iostats 127.0.0.1)
fi
CMD2=$($USECMD | $BIN_TR -d ' ' | $BIN_CUT -d : -f 2 | $BIN_TR '\n' ' ')

# shellcheck disable=SC2086
TIMESINCERESET=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $1}')
# shellcheck disable=SC2086
RECEIVEDBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $2}')
# shellcheck disable=SC2086
FREERECEIVEBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $3}')
# shellcheck disable=SC2086
USEDRECEIVEBUFFERS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $4}')
# shellcheck disable=SC2086
LOWWATERREFILLS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $5}')
# shellcheck disable=SC2086
DROPPEDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $6}')
# shellcheck disable=SC2086
IGNOREDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $7}')
# shellcheck disable=SC2086
RECEIVEDPACKETS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $8}')
# shellcheck disable=SC2086
PACKETSSENT=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $9}')
# shellcheck disable=SC2086
PACKETSENDFAILURES=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $10}')
#INPUTWAKEUPS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $11}')
# shellcheck disable=SC2086
USEFULINPUTWAKEUPS=$(echo $CMD2 | $BIN_AWK -F ' ' '{print $12}')

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
'","input_wakeups":"'"$PACKETSENDFAILURES"\
'","useful_input_wakeups":"'"$USEFULINPUTWAKEUPS"\
'"},"error":"0","errorString":"","version":"'$VERSION'"}'
