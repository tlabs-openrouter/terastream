#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

leasefile=/tmp/lease6

proto_dhcp6_terastream_init_config() {
	proto_config_add_int "request_na"
	proto_config_add_int "request_pd"
	proto_config_add_boolean "no_accept_reconfigure"
	proto_config_add_boolean "no_client_fqdn"
	proto_config_add_string "reqopts"
}

# echo string if it's an integer, 0 otherwise
to_int() {
	case "$1" in
		''|*[!0-9]*)
			echo 0
			;;
		*)
			echo $1
			;;
	esac
}

proto_dhcp6_terastream_setup() {
	local config="$1"
	local iface="$2"

	local request_na request_pd no_accept_reconfigure no_client_fqdn reqopts
	json_get_vars request_na request_pd no_accept_reconfigure no_client_fqdn reqopts

	local opts

	[ "$request_na" = "1" ] && append opts "-N try" || append opts "-N none"
	[ "$(to_int $request_pd)" -gt 0 ] && append opts "-P 0,_ANY"
	[ "$(to_int $request_pd)" -gt 1 ] && append opts "-P 0,IPTV"
	[ "$(to_int $request_pd)" -gt 2 ] && append opts "-P 0,VOIP"

	[ "$no_accept_reconfigure" = "1" ] && append opts "-a"
	[ "$no_client_fqdn" = "1" ] && append opts "-f"

	[ "$reqopts" ] && append opts "-r $reqopts"

	proto_export "INTERFACE=$config"
	proto_run_command "$config" odhcp6c-terastream \
		$opts \
		-R \
		-t 120 \
		-m 10 \
		-V 00000B790006542D4C414253 \
		-s /lib/netifd/dhcp6_terastream.script \
		$iface
}

proto_dhcp6_terastream_teardown() {
	local interface="$1"

	/lib/netifd/dhcp6_terastream.script $1 "NETIFD_DOWN6"
	proto_kill_command "$interface"
}

add_protocol dhcp6_terastream

