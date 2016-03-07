#!/bin/sh

local CURRMODEM

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"
local TIMEOUT=10

log() {
	logger -t "Disconnect Modem" "$@"
}

handle_timeout(){
	local wget_pid="$1"
	local count=0
	res=1
	if [ -d /proc/${wget_pid} ]; then
		res=0
	fi
	while [ "$res" = 0 -a $count -lt "$((TIMEOUT))" ]; do
		sleep 1
		count=$((count+1))
		res=1
		if [ -d /proc/${wget_pid} ]; then
			res=0
		fi
	done

	if [ "$res" = 0 ]; then
		log "Killing process on timeout"
		kill "$wget_pid" 2> /dev/null
		res=1
		if [ -d /proc/${wget_pid} ]; then
			res=0
		fi
		if [ "$res" = 0 ]; then
			log "Killing process on timeout"
			kill -9 $wget_pid 2> /dev/null	
		fi
	fi
}

CURRMODEM=$(uci get modem.general.miscnum)
uci set modem.modem$CURRMODEM.connected=0
uci commit modem

killall -9 getsignal$CURRMODEM
rm -f $ROOTER_LINK/getsignal$CURRMODEM
killall -9 con_monitor$CURRMODEM
rm -f $ROOTER_LINK/con_monitor$CURRMODEM
ifdown wan$CURRMODEM

MAN=$(uci get modem.modem$CURRMODEM.manuf)
MOD=$(uci get modem.modem$CURRMODEM.model)
$ROOTER/signal/status.sh $CURRMODEM "$MAN $MOD" "Disconnected"

PROT=$(uci get modem.modem$CURRMODEM.proto)
CPORT=$(uci get modem.modem$CURRMODEM.commport)

case $PROT in
"3" )
	WDMNX=$(uci get modem.modem$CURRMODEM.wdm)
	WWANX=$(uci get modem.modem$CURRMODEM.wwan)
	TIMEOUT=10
	$ROOTER/mbim/mbim_connect.lua stop wwan$WWANX cdc-wdm$WDMNX $CURRMODEM &
	handle_timeout "$!"
	;;
* )
	$ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "reset.gcom" "$CURRMODEM"
	;;
esac

$ROOTER/log/logger "Modem #$CURRMODEM was Manually Disconnected"
