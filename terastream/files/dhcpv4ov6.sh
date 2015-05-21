#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_dhcpv4ov6_init_config() {
	proto_config_add_string "ipaddr"
	proto_config_add_string "netmask"
	proto_config_add_string "hostname"
	proto_config_add_string "clientid"
	proto_config_add_string "vendorid"
	proto_config_add_boolean "broadcast"
	proto_config_add_string "reqopts"
	proto_config_add_boolean "nodefaultopts"
	proto_config_add_string "mode"
	proto_config_add_boolean "ignoredns"
	proto_config_add_string "iface6rd"
}

proto_dhcpv4ov6_mode_ops() {
	local aftr_dhcp4o6_servers="$(uci_get_state network wan aftr_dhcp4o6_servers)"
	[ -z "$aftr_dhcp4o6_servers" ] && {
		logger -t $config "No DHCPv4o6 server address given. Won't start stateless dslite."
		return 1
	}

	local server servers
	for server in $aftr_dhcp4o6_servers; do
		append servers "-6 $server"
	done

	local ia_b4="$(uci_get_state network wan aftr_local)"
	local I=""
	[ -n "$ia_b4" ] && I="-I $ia_b4"
	echo "$servers $I"
}

proto_dhcpv4ov6_setup() {
	local config="$1"
	local iface="$2"

	proto_add_host_dependency $config "0.0.0.0"

	local ipaddr hostname clientid vendorid broadcast reqopts nodefaultopts mode ignoredns iface6rd
	json_get_vars ipaddr hostname clientid vendorid broadcast reqopts nodefaultopts mode ignoredns iface6rd

	local opt dhcpopts
	for opt in $reqopts; do
		append dhcpopts "-O $opt"
	done

	[ "$broadcast" = 1 ] && broadcast="-B" || broadcast=
	
	# RFC 4361 defines client IDs as a concatenation of Type (255), IAID (32-bit) and DUID
	#   As long as we're requesting a single IPv4 address per HGW only, assume a static IAID == 0
	#   Furthermore, we assume that the DHCPv6 DUID is static across OS reboots

	if [ -n "$clientid" ]; then
		clientid="-x 0x3d:${clientid//:/}"
	else
		local dhcpv6_duid="$(uci_get_state network wan dhcpv6_duid)"
		local dhcpv6_duid_len=$(echo -n "$dhcpv6_duid" | wc -c)
		
		# a DHCPv6 DUID is at least 10 bytes (20 nibbles) long
		
		if [ $dhcpv6_duid_len -gt 19 ]; then
			clientid="-x 0x3d:ff00000000${dhcpv6_duid}"
		else
			local ia_b4="$(uci_get_state network wan aftr_local)"
			
			if [ -z "$ia_b4" ]; then
				clientid="-C"
			else
				local DHCP_CLIENT_ID
				
				DHCP_CLIENT_ID=0$(ipv6calc --in ipv6 --out ipv6 --printprefix --printfulluncompressed --uppercase $ia_b4/64)
				DHCP_CLIENT_ID="$(echo $DHCP_CLIENT_ID | sed s/://g)"

				clientid="-x 0x3d:$DHCP_CLIENT_ID"
			fi
		fi
	fi
	
	logger -t $config "Using Client-ID $clientid for DHCPv4o6 request."
	
	[ "$nodefaultopts" = 1 ] && nodefaultopts="-o" || nodefaultopts=

	local mode_opts
	[ -n "$mode" ] && {
		mode_opts="$(proto_dhcpv4ov6_mode_ops)"
		[ $? -ne 0 ] && { logger -t $config "ERROR: Unable to initialize DHCP mode $mode." ; exit 1 ; }
	}
	[ -n "$iface6rd" ] && proto_export "IFACE6RD=$iface6rd"

	local dhcp4o6_mode="$(uci_get_state network wan aftr_dhcp4o6_mode)"
	local DHCP_CLIENT
	if [ "$dhcp4o6_mode" = "rfc7341" ]; then
		DHCP_CLIENT="udhcpv4ov6"
	elif [ "$dhcp4o6_mode" = "terastream" ]; then
		DHCP_CLIENT="udhcpc"
	else
		logger -t $config "ERROR: unknown DHCP mode '$dhcp4o6_mode'"
		exit 1
	fi

	proto_export "INTERFACE=$config"
	proto_export "ignoredns=$ignoredns"
	proto_export "MODE=$mode"

	proto_run_command "$config" $DHCP_CLIENT \
		-p /var/run/$DHCP_CLIENT-$iface.pid \
		-s /lib/netifd/dhcpv4ov6.script \
		-f -i "$iface" \
		${ipaddr:+-r $ipaddr} \
		${hostname:+-H $hostname} \
		${vendorid:+-V $vendorid} \
		$clientid $broadcast $nodefaultopts $dhcpopts $mode_opts
}

proto_dhcpv4ov6_teardown() {
	local interface="$1"

	local mode
	json_get_vars mode

	if [ "$mode" = "lw4o6" ]; then
		rm -f -- "/tmp/firewall-hotplug/${interface}.sh"
	fi

	proto_kill_command "$interface"
}

add_protocol dhcpv4ov6

