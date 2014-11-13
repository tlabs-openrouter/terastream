#!/bin/sh
. /lib/functions.sh

config=$2
iface=$3

_rulefilename() {
	echo "/tmp/firewall-hotplug/${INTERFACE}.sh"
}

setup_nat() {
		local tunnel_if="$(uci -q get network.${config}.dslite_tunnel)"
		local port_range="${port_range_min}-${port_range_max}"
		local to_source="$ip"

		# get device name from logical interface name
		[ -n "$tunnel_if" ] && tunnel_if="$(uci_get_state network $tunnel_if ifname)"

		# use same interface if no tunnel interface supplied
		[ -z "$tunnel_if" ] && tunnel_if="$interface"

		# bail out if something's missing
		[ -n "$tunnel_if" -a -n "$to_source" ] || exit 0

		[ -z "${port_range_min}" -o -z "${port_range_max}" ] || to_source="${to_source}:${port_range}"

                # set uci config values for port range
		uci -q set network.${config}.port_range_min="${port_range_min}"
		uci -q set network.${config}.port_range_max="${port_range_max}"
		
		logger -t $config "Restricting ports on iface $INTERFACE to ${port_range}."
		
		local mychain="${config}_lw4o6"
		local rulefile="$(_rulefilename $INTERFACE)"
		mkdir -p "$(dirname $rulefile)"
		cat << EOF > "$rulefile"
#!/bin/sh

target_chain="postrouting_rule"

[ "\$ACTION" = "add" ] && {
	iptables -w -t nat -N $mychain
	iptables -w -t nat -I $mychain -o "$tunnel_if" -p tcp -j SNAT --to-source $to_source
	iptables -w -t nat -I $mychain -o "$tunnel_if" -p udp -j SNAT --to-source $to_source
	iptables -w -t nat -I $mychain -o "$tunnel_if" -p icmp -j SNAT --to-source $to_source

	iptables -w -t nat -I \$target_chain -j $mychain
}

[ "\$ACTION" = "remove" ] && {
	iptables -w -t nat -D \$target_chain -j $mychain
	iptables -w -t nat -F $mychain
	iptables -w -t nat -X $mychain
}
	
EOF

chmod a+x "$rulefile"
}

[ -z "${port_range_min}" -o "${port_range_min}" = "0" ] && port_range_min="1"
[ -z "${port_range_max}" -o "${port_range_max}" = "0" ] && port_range_max="65535"

case "$1" in
	get_opts)
		# 
		local aftr_dhcp4o6_servers="$(uci_get_state network wan aftr_dhcp4o6_servers)"
		[ -z "$aftr_dhcp4o6_servers" ] && {
			logger -t $config "No DHCPv4o6 server address given. Won't start stateless dslite."
			exit 1
		}

		local server servers
		for server in $aftr_dhcp4o6_servers; do
			append servers "-6 $server"
		done

		local ia_b4="$(uci_get_state network wan aftr_local)"
		local I=""
		
		[ -n "$ia_b4" ] && I="-I $ia_b4"

		echo "$servers $I"
		;;
	renew|bound)
		setup_nat
		;;
	teardown)
		rm -f -- "$(_rulefilename $config)"
		;;
esac
