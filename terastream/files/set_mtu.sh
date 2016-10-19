#!/bin/sh
[ -z "$1" ] && {
	echo "Usage: $0 <mtu> [<wan|lan>]"
	exit 1
}

get_ifnames() {
    local logical=$1
    local ifnames=""

    for iface in $(uci -q get network.${logical}.ifname); do
        ifnames="$ifnames $(echo $iface | cut "-d " -f1 | cut -d. -f1)"
    done
    echo "$ifnames"
}

set_mtu() {
    local iface="$1"
    local mtu="$2"

    case "$iface" in
        wifi*)
            if [ "$mtu" -ge "2304" ]; then
                mtu=2304
            fi
            ;;
    esac

    uci -q del network.${iface}_mtu
    uci set network.${iface}_mtu="interface"
    uci set network.${iface}_mtu.proto="none"
    uci set network.${iface}_mtu.ifname="${iface}"
    uci set network.${iface}_mtu.mtu="$mtu"
}

mtu=$1
zone=$2
set_wan_mtu=0
set_lan_mtu=0

lan_if="$(uci -q get profiles.network.lan_if)"
lan_if="${lan_if:-$(get_ifnames lan)}"
[ -z "${lan_if}" ] && {
    echo "Error: LAN interface not configured. (profiles.network.lan_if)."
    exit 1
}

wan_if="$(uci -q get profiles.network.wan_if)"
wan_if="${wan_if:-$(get_ifnames wan)}"
[ -z "${wan_if}" ] && {
    echo "Error: WAN interface not configured. (profiles.network.wan_if)."
    exit 1
}

max_mtu="$(uci -q get profiles.network.max_mtu)"
[ -z "${max_mtu}" ] && max_mtu=1500

if [ "$mtu" -gt "$max_mtu" ]; then
	echo "Error: MTU out of range (maximum $max_mtu)"
	exit 1
fi

case "$zone" in
    wan)
        set_wan_mtu=1
        ;;
    lan)
        set_lan_mtu=1
        ;;
    "")
        set_wan_mtu=1
        set_lan_mtu=1
        ;;
    *)
        echo "Error: unknown zone '$zone'"
        exit 1
        ;;
esac

if [ "$set_lan_mtu" -eq 1 ]; then
    for i in $lan_if wifi0 wifi1; do
        set_mtu "$i" $mtu
    done
fi

if [ "$set_wan_mtu" -eq 1 ]; then
    for i in $wan_if; do
        set_mtu "$i" $mtu
    done
fi

uci commit network

echo "Updated MTU to $mtu. issue '/etc/init.d/network restart' or reboot to take effect."
