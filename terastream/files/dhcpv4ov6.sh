#!/bin/sh

. /lib/functions.sh
. /lib/functions/network.sh

. ../netifd-proto.sh
init_proto "$@"

proto_dhcpv4ov6_init_config() {
	available=1

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

	proto_config_add_string "aftr_local"
	proto_config_add_string "aftr_remote"
	proto_config_add_string "dhcp_mode"
	proto_config_add_string "dhcp_servers"
}

proto_dhcpv4ov6_setup() {
	local config="$1"
	local iface="$2"
	local ia_b4

	proto_add_host_dependency "$config" ::

	local ipaddr hostname clientid vendorid broadcast reqopts nodefaultopts mode ignoredns iface6rd aftr_local aftr_remote dhcp_mode dhcp_servers tunlink
	json_get_vars ipaddr hostname clientid vendorid broadcast reqopts nodefaultopts mode ignoredns iface6rd aftr_local aftr_remote dhcp_mode dhcp_servers tunlink

	local opt dhcpopts
	for opt in $reqopts; do
		append dhcpopts "-O $opt"
	done

	if [ -n "$dhcp_servers" ]; then
		ia_b4="$aftr_local"
	fi

	[ "$broadcast" = 1 ] && broadcast="-B" || broadcast=
	
	# RFC 4361 defines client IDs as a concatenation of Type (255), IAID (32-bit) and DUID
	#   As long as we're requesting a single IPv4 address per HGW only, assume a static IAID == 0
	#   Furthermore, we assume that the DHCPv6 DUID is static across OS reboots

	if [ -n "$clientid" ]; then
		clientid="-x 0x3d:${clientid//:/}"
	fi
	
	logger -t $config "Using Client-ID $clientid for DHCPv4o6 request."
	
	[ "$nodefaultopts" = 1 ] && nodefaultopts="-o" || nodefaultopts=

	local mode_opts
	local aftr_dhcp4o6_servers server

	for server in $dhcp_servers; do
		append mode_opts "-6 $server"
	done

	append mode_opts "-I $ia_b4"

	[ -n "$iface6rd" ] && proto_export "IFACE6RD=$iface6rd"

	local DHCP_CLIENT
	if [ "$dhcp_mode" = "rfc7341" ]; then
		DHCP_CLIENT="udhcpv4ov6"
	elif [ "$dhcp_mode" = "terastream" ]; then
		DHCP_CLIENT="udhcpc"
	else
		logger -t $config "ERROR: unknown DHCP mode '$dhcp4o6_mode'"
		exit 1
	fi

	proto_export "INTERFACE=$config"
	proto_export "ignoredns=$ignoredns"
	proto_export "MODE=$mode"
	proto_export "TUNLINK=$tunlink"

	if [ -n "$dhcp_servers" ]; then
		proto_export "AFTR_LOCAL=$aftr_local"
		proto_export "AFTR_REMOTE=$aftr_remote"
	fi

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
	proto_kill_command "$interface"
}

add_protocol dhcpv4ov6

