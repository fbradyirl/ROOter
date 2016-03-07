#!/bin/sh

local CURRMODEM

ROOTER=/usr/lib/rooter
ROOTER_LINK=$ROOTER"/links"

log() {
	logger -t "Reconnect Modem" "$@"
}

CURRMODEM=$1
$ROOTER_LINK/create_proto$CURRMODEM $CURRMODEM 1
