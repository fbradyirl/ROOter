#!/bin/sh
. /lib/functions.sh

ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

CODENAME="ROOter "
if [ -f "/etc/codename" ]; then
	source /etc/codename
fi

#
# Set the maximum number of modems supported
#
MAX_MODEMS=2
local MODCNT=$MAX_MODEMS

log() {
	logger -t "ROOter Initialize" "$@"
}

do_zone() {
	local config=$1
	local name
	local network
	local newnet="wan wwan"

	config_get name $1 name
	config_get network $1 network
	if [ $name = wan ]; then
		COUNTER=1
		while [ $COUNTER -le $MODCNT ]; do
			newnet="$newnet wan$COUNTER"
			let COUNTER=COUNTER+1
		done
		uci_set firewall "$config" network "$newnet"
		uci_commit firewall
		/etc/init.d/firewall restart
	fi
}

firstboot() {
	HO=$(uci get system.@system[-1].hostname)
	if [ $HO = "OpenWrt" ]; then
		uci set system.@system[-1].hostname="ROOter"
	fi
	uci set system.@system[-1].cronloglevel="9"
	uci commit system
# wifi enable
# edit the file package/kernel/mac80211/files/lib/wifi/mac80211.sh
# and delete the lines
# option disabled 1
	log "ROOter First Boot finalized"

	config_load firewall
	config_foreach do_zone zone

	uci set luci.main.mediaurlbase="/luci-static/material"
	uci commit luci
}

if [ -e /tmp/installing ]; then
	exit 0
fi

log " Initializing Rooter"

sed -i -e 's|/etc/savevar|#removed line|g' /etc/rc.local

[ -f "/etc/firstboot" ] || {
	firstboot
}

mkdir -p $ROOTER_LINK

uci delete modem.Version
uci set modem.Version=version
uci set modem.Version.ver=$CODENAME
uci commit modem

source /etc/openwrt_release
rm -f /etc/openwrt_release
DISTRIB_DESCRIPTION=$(uci get modem.Version.ver)" ( OpenWRT "$DISTRIB_REVISION" )"
echo 'DISTRIB_ID="'"$DISTRIB_ID"'"' >> /etc/openwrt_release
echo 'DISTRIB_RELEASE="'"$DISTRIB_RELEASE"'"' >> /etc/openwrt_release
echo 'DISTRIB_REVISION="'"$DISTRIB_REVISION"'"' >> /etc/openwrt_release
echo 'DISTRIB_CODENAME="'"$DISTRIB_CODENAME"'"' >> /etc/openwrt_release
echo 'DISTRIB_TARGET="'"$DISTRIB_TARGET"'"' >> /etc/openwrt_release
echo 'DISTRIB_DESCRIPTION="'"$DISTRIB_DESCRIPTION"'"' >> /etc/openwrt_release

if `cat /proc/version | grep "3.10" 1>/dev/null 2>&1`
then
	echo "1" > /etc/kernel310
fi

if `cat /tmp/sysinfo/model | grep "A5-V11" 1>/dev/null 2>&1`
then
	swconfig dev switch0 port 1 set disable 1
	swconfig dev switch0 port 2 set disable 1
	swconfig dev switch0 port 3 set disable 1
	swconfig dev switch0 port 4 set disable 1
	swconfig dev switch0 set apply
	uci delete system.led_wifi       
	uci set system.led_wifi=led
	uci set system.led_wifi.default="0"  
	uci set system.led_wifi.name="WIFI"
	uci set system.led_wifi.sysfs="a5-v11:blue:system"
	uci set system.led_wifi.trigger="netdev"
	uci set system.led_wifi.dev="wlan0"
	uci set system.led_wifi.mode="link tx rx"
	uci commit system
fi

MODSTART=1
WWAN=0
USBN=0
ETHN=1
BASEPORT=0
WDMN=0
if 
	ifconfig eth1
then
	if [ -e "/sys/class/net/eth1/device/bInterfaceProtocol" ]; then
		ETHN=1
	else
		ETHN=2
	fi
fi

echo 'MODSTART="'"$MODSTART"'"' > /tmp/variable.file
echo 'WWAN="'"$WWAN"'"' >> /tmp/variable.file
echo 'USBN="'"$USBN"'"' >> /tmp/variable.file
echo 'ETHN="'"$ETHN"'"' >> /tmp/variable.file
echo 'WDMN="'"$WDMN"'"' >> /tmp/variable.file
echo 'BASEPORT="'"$BASEPORT"'"' >> /tmp/variable.file

echo 'MODCNTX="'"$MODCNT"'"' > /tmp/modcnt
uci set modem.general.max=$MODCNT
uci set modem.general.modemnum=1
uci set modem.general.smsnum=1
uci set modem.general.miscnum=1

OPING=$(uci get modem.ping.alive)
if [ ! -z $OPING ]; then
	uci delete modem.ping
fi

COUNTER=1
while [ $COUNTER -le $MODCNT ]; do
	uci delete modem.modem$COUNTER        
	uci set modem.modem$COUNTER=modem  
	uci set modem.modem$COUNTER.empty=1

	IPEX=$(uci get modem.pinginfo$COUNTER.alive)
	if [ -z $IPEX ]; then
		uci set modem.pinginfo$COUNTER=pinfo$COUNTER
		uci set modem.pinginfo$COUNTER.alive="0"
	fi

	INEX=$(uci get modem.modeminfo$COUNTER)
	if [ -z $INEX ]; then
		uci set modem.modeminfo$COUNTER=minfo$COUNTER
	fi

	rm -f $ROOTER_LINK/getsignal$COUNTER
	rm -f $ROOTER_LINK/reconnect$COUNTER
	rm -f $ROOTER_LINK/create_proto$COUNTER
	$ROOTER/signal/status.sh $COUNTER "No Modem Present"

	uci delete network.wan$COUNTER       
	uci set network.wan$COUNTER=interface
	uci set network.wan$COUNTER.proto=dhcp 
	uci set network.wan$COUNTER.ifname=" "  
	uci set network.wan$COUNTER.metric=$COUNTER"0"

	if [ -e /etc/config/mwan3 ]; then
		ENB=$(uci get mwan3.wan$COUNTER.enabled)
		if [ ! -z $ENB ]; then
			uci set mwan3.wan$COUNTER.enabled=0
		fi
	fi

	if [ -e /etc/config/failover ]; then
		uci delete failover.Modem$COUNTER       
		uci set failover.Modem$COUNTER=member
	fi

	let COUNTER=COUNTER+1 
done

if [ -e /etc/config/failover ]; then
	uci delete failover.Wan
	EXX=$(uci get network.wan)
	if [ ! -z $EXX ]; then
		uci set failover.Wan=member
	fi
	uci delete failover.Hotspot
	uci set failover.Hotspot=member
	uci commit failover
	ENB=$(uci get failover.enabled.enabled)
	if [ $ENB = "1" ]; then
		if [ -e $ROOTER/connect/failover.sh ]; then
			log "Starting Failover System"
			$ROOTER/connect/failover.sh &
		fi
	fi
fi

PRO=$(uci get network.wan.proto)
if [ ! -z $PRO ]; then
	uci set network.wan.metric="1"
fi

PRO=$(uci get network.wwan.proto)
if [ -z $PRO ]; then
	uci set network.wwan=interface
	uci set network.wwan.proto=dhcp  
	uci set network.wwan.ifname="wlan0"
	uci set network.wwan.metric="2"
fi

uci commit modem
uci commit network
if [ -e /etc/config/mwan3 ]; then
	uci commit mwan3
fi

WW=$(uci get wireless.wwan)
if [ -z $WW ]; then
	uci set wireless.wwan="wifi-iface"
	uci set wireless.wwan.device="radio0"
	uci set wireless.wwan.network="wwan"
	uci set wireless.wwan.mode="sta"
	uci set wireless.wwan.ssid="hotspotssid"
	uci set wireless.wwan.encryption="none"
	uci set wireless.wwan.disabled="1"
	uci commit wireless
	wifi
fi

cp /etc/config/wireless /etc/config/wireless_AP
uci delete wireless_AP.wwan
uci commit wireless_AP

if [ -e $ROOTER/removeipv6.sh ]; then
	$ROOTER/removeipv6.sh
fi

if [ -e /etc/hotplug.d/10-motion ]; then
	rm -f /etc/hotplug.d/10-motion
fi
if [ -e /etc/hotplug.d/20-mjpg-streamer ]; then
	rm -f /etc/hotplug.d/20-mjpg-streamer
fi
if [ -e /etc/hotplug.d/50-printer ]; then
	rm -f /etc/hotplug.d/50-printer
fi

lua $ROOTER/gpiomodel.lua

HO=$(uci get system.@system[-1].hostname)
if [ $HO = "OpenWrt" ]; then
	uci set system.@system[-1].hostname="ROOter"
	uci commit system
fi

echo "0" > /etc/firstboot
echo "0" > /tmp/bootend.file


