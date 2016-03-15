#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "hostless " "$@"
}

CURRMODEM=$1
PROTO=$2
CONN="Modem #"$CURRMODEM

MANUF=$(uci get modem.modem$CURRMODEM.manuf)
MODEL=$(uci get modem.modem$CURRMODEM.model)
MODEM=$MANUF" "$MODEL
IP=$(uci get modem.modem$CURRMODEM.ip)

STARTIMEX=$(date +%s)
MONSTAT="Unknown"
rm -f /tmp/monstat$CURRMODEM

while [ 1 = 1 ]; do
	echo "$IP" > /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "$MODEM" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo " " >> /tmp/status$CURRMODEM.file
	echo " " >> /tmp/status$CURRMODEM.file
	echo "$MONSTAT" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	echo "$CONN" >> /tmp/status$CURRMODEM.file
	echo "-" >> /tmp/status$CURRMODEM.file
	if [ -e /tmp/monstat$CURRMODEM ]; then
		source /tmp/monstat$CURRMODEM
	fi
	if [ -z $MONSTAT ]; then
		MONSTAT="Unknown"
	fi
		CURRTIME=$(date +%s)
	let ELAPSE=CURRTIME-STARTIMEX
	while [ $ELAPSE -lt 10 ]; do
		sleep 2
		CURRTIME=$(date +%s)
		let ELAPSE=CURRTIME-STARTIMEX
	done
	STARTIMEX=$CURRTIME
done