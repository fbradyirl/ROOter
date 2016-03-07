
#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Phone Change" "$@"
}

CURRMODEM=$1
PHONE=$2
CPORT=$(uci get modem.modem$CURRMODEM.commport)
PHONE=$(echo "$PHONE" | sed -e 's/ //g')
echo 'CNUM="'"$PHONE"'"' > /tmp/phonenumber$CURRMODEM
log "Change Modem $CURRMODEM SIM phone number to $PHONE"

INTER=${PHONE:0:1}
if [ $INTER = "+" ]; then
	TON="145"
else
	TON="129"
fi

ATCMDD="AT+CPBS=\"ON\";+CPBS?"
OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
OX=$($ROOTER/common/processat.sh "$OX")

ON=$(echo "$OX" | awk -F[,\ ] '/^\+CPBS:/ {print $2}')
if [ $ON = "\"ON\"" ]; then
	ATCMDD="AT+CPBW=1,\"$PHONE\",$TON,\"OwnNbr\""
	OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	ATCMDD="AT+CNUM"
	OX=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
	OX=$($ROOTER/common/processat.sh "$OX")
	M2=$(echo "$OX" | sed -e "s/+CNUM: /+CNUM:,/g")
	CNUM=$(echo "$M2" | awk -F[,] '/^\+CNUM:/ {print $3}')
	if [ "x$CNUM" != "x" ]; then
		CNUM=$(echo "$CNUM" | sed -e 's/"//g')
	else
		CNUM="*"
	fi
	echo 'CNUM="'"$CNUM"'"' > /tmp/phonenumber$CURRMODEM
fi

