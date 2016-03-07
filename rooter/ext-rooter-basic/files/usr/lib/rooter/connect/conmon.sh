#!/bin/sh
. /lib/functions.sh

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
	logger -t "Connection Monitor" "$@"
}

CURRMODEM=$1

power_toggle() {
	if [ -f "/tmp/gpiopin" ]; then
		$ROOTER/pwrtoggle.sh 3
	else
		if [ -f $ROOTER_LINK/reconnect$CURRMODEM ]; then
			$ROOTER_LINK/reconnect$CURRMODEM $CURRMODEM &
		fi
	fi
}

do_down() {
	echo 'MONSTAT="'"DOWN$1"'"' > /tmp/monstat$CURRMODEM
	case $ACTIVE in
	"1" )
		log "Modem $CURRMODEM Connection is Down$1"
		;;
	"2" )
		log "Modem $CURRMODEM Connection is Down$1"
		reboot -f
		;;
	"3" )
		log "Modem $CURRMODEM Connection is Down$1"
		if [ -f $ROOTER_LINK/reconnect$CURRMODEM ]; then
			$ROOTER_LINK/reconnect$CURRMODEM $CURRMODEM &
		fi
		;;
	"4" )
		log "Modem $CURRMODEM Connection is Down$1"
		power_toggle
		;;
	esac
}


CURSOR="-"

log "Start Connection Monitor for Modem $CURRMODEM"

while [ 1 = 1 ]; do
	ACTIVE=$(uci get modem.pinginfo$CURRMODEM.alive)
	if [ $ACTIVE = "0" ]; then
		echo 'MONSTAT="'"Disabled"'"' > /tmp/monstat$CURRMODEM
		sleep 60
	else
		track_ips=
		local INTER=$(uci get modem.modem$CURRMODEM.interface)
		local TIMEOUT=$(uci get modem.pinginfo$CURRMODEM.pingwait)
		local INTERVAL=$(uci get modem.pinginfo$CURRMODEM.pingtime)
		local RELIAB=$(uci get modem.pinginfo$CURRMODEM.reliability)
		local DOWN=$(uci get modem.pinginfo$CURRMODEM.down)
		local UP=$(uci get modem.pinginfo$CURRMODEM.up)
		local COUNT=$(uci get modem.pinginfo$CURRMODEM.count)

		list_track_ips() {
			track_ips="$1 $track_ips"
		}

		config_load modem
		config_list_foreach "pinginfo$CURRMODEM" "trackip" list_track_ips

		if [ -f "/tmp/connstat$CURRMODEM" ]; then
			do_down " from Modem"
			rm -f /tmp/connstat$CURRMODEM
			sleep 20
		else
			ENB="0"
			if [ -e /etc/config/failover ]; then
				ENB=$(uci get failover.enabled.enabled)
			fi
			if [ $ENB = "1" ]; then
				if [ -e /tmp/mdown$CURRMODEM ]; then
					do_down " (using Failover)"
				else
					echo 'MONSTAT="'"Up ($CURSOR) (using Failover)"'"' > /tmp/monstat$CURRMODEM
					log "Modem $CURRMODEM Connection is Alive Using Failover"
				fi
				sleep 20

			else
				MENABLE=$(uci get mwan3.wan$CURRMODEM.enabled)
				MSCR=$(uci get mwan3.wan$CURRMODEM.dwnscript)
				if [ $MENABLE = "1" -a $MSCR != nil -a -e $MSCR ]; then
					if [ -e /tmp/mdown$CURRMODEM ]; then
						do_down " (using Load Balance)"
					else
						echo 'MONSTAT="'"Up ($CURSOR) (using Load Balance)"'"' > /tmp/monstat$CURRMODEM
						log "Modem $CURRMODEM Connection is Alive Using Load Balance"
					fi
					sleep 20
				else
					UPDWN="0"
					host_up_count=0
					score_up=$UP
					score_dwn=$DOWN
					lost=0
					while true; do
						if [ ! -z "$track_ips" ]; then
							for track_ip in $track_ips; do
								ping -I $INTER -c $COUNT -W $TIMEOUT -s 4 -q $track_ip &> /dev/null
								if [ $? -eq 0 ]; then
									let host_up_count++
								else
									let lost++
								fi
							done
							if [ $host_up_count -lt $RELIAB ]; then
								let score_dwn--
								score_up=$UP
								if [ $score_dwn -eq 0 ]; then
									UPDWN="1"
									break
								fi
							else
								let score_up--
								score_dwn=$DOWN
								if [ $score_up -eq 0 ]; then
									UPDWN="0"
									break
								fi
							fi
						else
							UPDWN="0"
							exit
						fi
						host_up_count=0
						sleep $INTERVAL
					done
					if [ $UPDWN = "1" ]; then
						do_down " (using Ping Test)"
					else
						echo 'MONSTAT="'"UP ($CURSOR) (using Ping Test)"'"' > /tmp/monstat$CURRMODEM
						log "Modem $CURRMODEM Connection is Alive"
					fi
				fi
			fi
		fi
		if [ $CURSOR = "-" ]; then
			CURSOR="+"
		else
			CURSOR="-"
		fi
	fi
done
