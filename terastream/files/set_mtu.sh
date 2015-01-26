#!/bin/sh
[ -z "$1" ] && {
	echo "Usage: $0 <mtu> [<wan|lan>]"
	exit 1
}

get_ifname() {
    local logical=$1

    echo $(uci -q get network.${logical}.ifname | cut "-d " -f1 | cut -d. -f1)
}

mtu=$1
zone=$2
set_wan_mtu=0
set_lan_mtu=0

lan_if="$(uci -q get openrouter.network.lan_if)"
lan_if=${lan_if:-$(get_ifname lan)}
[ -z "${lan_if}" ] && {
	echo "Error: LAN interface not configured. (openrouter.network.lan_if)."
	exit 1
}

wan_if="$(uci -q get openrouter.network.wan_if)"
wan_if=${wan_if:-$(get_ifname wan)}
[ -z "${wan_if}" ] && {
	echo "Error: WAN interface not configured. (openrouter.network.wan_if)."
	exit 1
}

max_mtu="$(uci -q get openrouter.network.max_mtu)"
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
	uci -q del network.lan_mtu
	uci set network.lan_mtu="interface"
	uci set network.lan_mtu.proto="none"
	uci set network.lan_mtu.ifname="$lan_if"
	uci set network.lan_mtu.mtu="$mtu"

	uci -q del network.wifi0_mtu
	uci set network.wifi0_mtu="interface"
	uci set network.wifi0_mtu.proto="none"
	uci set network.wifi0_mtu.ifname="wlan0"

	# should be harmless regardless of wifi1 presence

	uci -q del network.wifi1_mtu
	uci set network.wifi1_mtu="interface"
	uci set network.wifi1_mtu.proto="none"
	uci set network.wifi1_mtu.ifname="wlan1"

	if [ "$mtu" -ge "2304" ]; then
		echo "Limiting wifi MTU to 2304"
		uci set network.wifi0_mtu.mtu="2304"
		uci set network.wifi1_mtu.mtu="2304"
	else
		uci set network.wifi0_mtu.mtu="$mtu"
		uci set network.wifi1_mtu.mtu="$mtu"
	fi
fi

if [ "$set_wan_mtu" -eq 1 ]; then
	uci -q del network.wan_mtu
	uci set network.wan_mtu="interface"
	uci set network.wan_mtu.proto="none"
	uci set network.wan_mtu.ifname="$wan_if"
	uci set network.wan_mtu.mtu="$mtu"

	if [ "$mtu" -ge "1548" ]; then
		echo "Limiting Lw4o6 MTU to 1500"
		uci set network.wan_ds.mtu='1500'
	else
		uci -q del network.wan_ds.mtu
	fi
fi

uci commit network

echo "Updated MTU to $mtu. issue '/etc/init.d/network restart' or reboot to take effect."
