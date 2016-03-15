#!/bin/sh
 
GUEST=$(uci get guestwifi.guestwifi.ssid)

IP=$(uci get guestwifi.guestwifi.ip)
RADIO=$(uci get guestwifi.guestwifi.radio)
LIMIT=$(uci get guestwifi.guestwifi.limit)
DL=$(uci get guestwifi.guestwifi.dl)
UL=$(uci get guestwifi.guestwifi.ul)
 
# Configure guest network
uci delete network.$GUEST
uci set network.$GUEST=interface
uci set network.$GUEST.proto=static
uci set network.$GUEST.ipaddr=$IP
uci set network.$GUEST.netmask=255.255.255.0

# Configure guest Wi-Fi
uci delete wireless.$GUEST
uci set wireless.$GUEST=wifi-iface
uci set wireless.$GUEST.device=$RADIO
uci set wireless.$GUEST.mode=ap
uci set wireless.$GUEST.network=$GUEST
uci set wireless.$GUEST.ssid=$GUEST
uci set wireless.$GUEST.encryption=none

# Configure DHCP for guest network
uci delete dhcp.$GUEST
uci set dhcp.$GUEST=dhcp
uci set dhcp.$GUEST.interface=$GUEST
uci set dhcp.$GUEST.start=50
uci set dhcp.$GUEST.limit=200
uci set dhcp.$GUEST.leasetime=1h
 
# Configure firewall for guest network
## Configure guest zone
uci delete firewall.$GUEST"_zone"
uci set firewall.$GUEST"_zone"=zone
uci set firewall.$GUEST"_zone".name=$GUEST
uci set firewall.$GUEST"_zone".network=$GUEST
uci set firewall.$GUEST"_zone".input=REJECT
uci set firewall.$GUEST"_zone".forward=REJECT
uci set firewall.$GUEST"_zone".output=ACCEPT
## Allow Guest -> Internet
uci delete firewall.$GUEST"_forwarding"
uci set firewall.$GUEST"_forwarding"=forwarding
uci set firewall.$GUEST"_forwarding".src=$GUEST
uci set firewall.$GUEST"_forwarding".dest=wan
## Allow DNS Guest -> Router
uci delete firewall.$GUEST"_rule_dns"
uci set firewall.$GUEST"_rule_dns"=rule
uci set firewall.$GUEST"_rule_dns".name="Allow "$GUEST" DNS Queries"
uci set firewall.$GUEST"_rule_dns".src=$GUEST
uci set firewall.$GUEST"_rule_dns".dest_port=53
uci set firewall.$GUEST"_rule_dns".proto=tcpudp
uci set firewall.$GUEST"_rule_dns".target=ACCEPT
## Allow DHCP Guest -> Router
uci delete firewall.$GUEST"_rule_dhcp"
uci set firewall.$GUEST"_rule_dhcp"=rule
uci set firewall.$GUEST"_rule_dhcp".name="Allow "$GUEST" DHCP request"
uci set firewall.$GUEST"_rule_dhcp".src=$GUEST
uci set firewall.$GUEST"_rule_dhcp".src_port=68
uci set firewall.$GUEST"_rule_dhcp".dest_port=67
uci set firewall.$GUEST"_rule_dhcp".proto=udp
uci set firewall.$GUEST"_rule_dhcp".target=ACCEPT

uci commit
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart

if [ -e /etc/config/qos ]; then
	uci delete qos.$GUEST
	if [ $LIMIT = "1" ]; then
		uci set qos.$GUEST=interface
		uci set qos.$GUEST.classgroup=Default
		uci set qos.$GUEST.enabled=1
		uci set qos.$GUEST.upload=$DL
		uci set qos.$GUEST.download=$UL
		uci commit qos
		/etc/init.d/qos start
		/etc/init.d/qos enable
	fi
fi
 
