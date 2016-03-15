#!/bin/sh
. /usr/share/libubox/jshn.sh

# Restore wireless access to the local AP for STA (Client) failures
# (association or login) with a remote AP (revert to 'AP-only') configuration.

local _rc 
_sta_err=0
let _sta_err++
json_init
json_load $(ubus -S call network.interface."$2" status)
json_get_var _rc up
while  [ $_rc = 0 ] || [ $ACTION = ifdown -a $_rc = 0 ]
    do
        if [ $((_sta_err * 3)) -ge $1 ]; then
            cp /etc/config/wireless /etc/config/wireless_AP+STA
            cp /etc/config/wireless_AP /etc/config/wireless
            wifi down
            wifi up
            sleep 3
            mv -f /etc/config/wireless_AP+STA /etc/config/wireless
		wifi
            break
        fi
        sleep 3
        json_load $(ubus -S call network.interface."$2" status)
        json_get_var _rc up
        let ++_sta_err
    done
json_cleanup
