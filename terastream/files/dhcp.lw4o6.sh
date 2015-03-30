#!/bin/sh
. /lib/functions.sh
. /lib/functions/network.sh

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
		[ -n "$tunnel_if" ] && network_get_device tunnel_if $tunnel_if

		# use same interface if no tunnel interface supplied
		[ -z "$tunnel_if" ] && tunnel_if="$interface"

		# bail out if something's missing
		[ -n "$tunnel_if" -a -n "$to_source" ] || exit 0

		[ "$without_portrange" -eq 0 ] && to_source="${to_source}:${port_range}"
		
		if [ "$without_portrange" -eq 0 ]; then 
			logger -t $config "Restricting ports on iface $INTERFACE to ${port_range}."
		else
			logger -t $config "Not restricting ports on iface ${INTERFACE}."
		fi
		
		local mychain="${config}_lw4o6"
		local rulefile="$(_rulefilename $INTERFACE)"
		mkdir -p "$(dirname $rulefile)"
		cat << EOF > "$rulefile"
#!/bin/sh

target_chain="postrouting_rule"

[ "\$ACTION" = "add" ] && {
	iptables -w -t nat -N $mychain
	if [ "$without_portrange" -eq 0 ]; then
		iptables -w -t nat -I $mychain -o "$tunnel_if" -p tcp -j SNAT --to-source $to_source
		iptables -w -t nat -I $mychain -o "$tunnel_if" -p udp -j SNAT --to-source $to_source
		iptables -w -t nat -I $mychain -o "$tunnel_if" -p icmp -j SNAT --to-source $to_source
	else
		iptables -w -t nat -I $mychain -o "$tunnel_if" -j SNAT --to-source $to_source
	fi

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

portparams_to_ranges() {
	[ -z "${port_params}" ] && return
	
	local offset="$(echo -n ${port_params} | cut -d ',' -f 1)"
	local psid_len="$(echo -n ${port_params} | cut -d ',' -f 2)"
	local psid="$(echo -n ${port_params} | cut -d ',' -f 3)"
	
	[ "${offset}" -ne "0" ] && {
		logger -t $config "PSID offset needs to be 0 in Lightweight 4over6"
		return
	}
	
	local psid_bin=$(echo "obase=2;${psid}" | bc)
	psid_bin=$(echo -n "0000000000000000${psid_bin}")
	local padded_len=$(echo -n "${psid_bin}" | wc -c)
	psid_bin=$(echo -n "${psid_bin}" | cut -b "$((padded_len - ${psid_len} + 1))-${padded_len}")
	
	local psid_bin_low="${psid_bin}0000000000000000"
	local portset_start=$(echo -n "${psid_bin_low}" | cut -b 1-16)
	
	local psid_bin_high="${psid_bin}1111111111111111"
	local portset_end=$(echo -n "${psid_bin_high}" | cut -b 1-16)
	
	port_range_min=$(echo "ibase=2;${portset_start}" | bc)
	port_range_max=$(echo "ibase=2;${portset_end}" | bc)
}

[ -n "${port_params}" ] && {
	logger -t $config "using port params ${port_params}"
	portparams_to_ranges
}

without_portrange=0

[ -z "${port_range_min}" -o "${port_range_min}" = "0" ] && without_portrange="1"
[ -z "${port_range_max}" -o "${port_range_max}" = "0" ] && without_portrange="1"

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
