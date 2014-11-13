#!/bin/sh +x

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

leasefile=/tmp/lease4

proto_dhcp4_init_config() {
	proto_config_add_string "aftr_tunnel"
}

generate_dhcp4_config() {

cat << EOF > $1
#
option port-range-min code 240 = unsigned integer 16;
option port-range-max code 241 = unsigned integer 16;

request port-range-min, port-range-max;

script "/lib/netifd/dhcp4.script";

EOF

}

dnsmasq_ignore() {
	local if=$1
	local dnsmasq_config=/tmp/etc/dnsmasq.d/09-ignore-${if}.conf

	logger -t $config "Disabling dnsmasq on $if."

	cat << EOF > "$dnsmasq_config"
bind-interfaces
except-interface=${if}
EOF

    /etc/init.d/dnsmasq reload
}

dnsmasq_restore() {
	local if=$1
	local dnsmasq_config=/tmp/etc/dnsmasq.d/09-ignore-${if}.conf

	logger -t $config "Restoring dnsmasq on $if."
	rm -f -- $dnsmasq_config
	/etc/init.d/dnsmasq reload
}

proto_dhcp4_setup() {
	local config="$1"
	local iface="$2"

	local dhcp4conf=/tmp/dhclient.$iface.conf
	generate_dhcp4_config $dhcp4conf

	local wan_if="$(uci_get_state network wan ifname)"
	local aftr_dhcp4o6_servers="$(uci_get_state network wan aftr_dhcp4o6_servers)"
	local ia_b4="$(uci_get_state network wan aftr_local)"

	[ -z "$wan_if" ] && {
		logger -t $config "Couldn't determin wan interface name. Giving up."
		proto_block_restart "$config"
		proto_setup_failed "$config"
		exit 1
	}

	[ -z "$aftr_dhcp4o6_servers" ] && {
		logger -t $config "No DHCPv4o6 server address given. Won't start stateless dslite."
		proto_block_restart "$config"
		proto_setup_failed "$config"
		exit 1
	}

	[ -n "$ia_b4" ] && {
		DHCP_CLIENT_ID=0$(ipv6calc --in ipv6 --out ipv6 --printprefix --printfulluncompressed --uppercase $ia_b4/64)
		DHCP_CLIENT_ID="$(echo $DHCP_CLIENT_ID | sed s/://g)"

		logger -t $config "Using Client-ID $DHCP_CLIENT_ID for DHCPv4o6 request."
		echo "send dhcp-client-identifier \"$DHCP_CLIENT_ID\";" >> $dhcp4conf
	}

	[ ! -f $leasefile ] && touch $leasefile

	#
	json_get_vars aftr_tunnel
	aftr_tunnel=${aftr_tunnel}-tun
	local aftr_opt=""
	[ ! -z "$aftr_tunnel" ] && aftr_opt="-e AFTR_TUNNEL=${aftr_tunnel}"

	local l6=""
	[ -n "$ia_b4" ] && l6="-l6 $ia_b4"

	dnsmasq_ignore $wan_if
	sleep 2 # give dnsmasq some time to release the interfaces it isn't supposed to bind on
	dhccra -q -pf /tmp/dhccra.$wan_if.pid -S node $l6 -i $wan_if $aftr_dhcp4o6_servers || /bin/echo -e "$(netstat -aln)" | logger -t $config

	proto_run_command "$config" dhclient \
		-4 -q -d \
		-cf $dhcp4conf \
		-lf $leasefile \
		-e INTERFACE=$config \
		$aftr_opt \
		$iface
}

proto_dhcp4_teardown() {
	export reason=NETIFD_DOWN
	export interface=$1

	/lib/netifd/dhcp4.script

	proto_kill_command "$interface"

	[ -f $leasefile ] && rm -f $leasefile

	local wan_if="$(uci_get_state network wan ifname)"
	dnsmasq_restore $wan_if
	[ -e "/tmp/dhccra.$wan_if.pid" ] && kill "$(cat /tmp/dhccra.$wan_if.pid)"
}

add_protocol dhcp4

