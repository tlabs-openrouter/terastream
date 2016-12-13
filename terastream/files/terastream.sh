#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_terastream_init_config() {
	renew_handler=1

	proto_config_add_string 'reqaddress:or("try","force","none")'
	proto_config_add_string 'reqprefix:or("auto","no",range(0, 64))'
	proto_config_add_string clientid
	proto_config_add_string 'reqopts:list(uinteger)'
	proto_config_add_string 'noslaaconly:bool'
	proto_config_add_string 'forceprefix:bool'
	proto_config_add_string 'norelease:bool'
	proto_config_add_string 'ip6prefix:ip6addr'
	proto_config_add_string iface_dslite
	proto_config_add_string zone_dslite
	proto_config_add_string iface_map
	proto_config_add_string zone_map
	proto_config_add_string iface_464xlat
	proto_config_add_string zone_464xlat
	proto_config_add_string zone
	proto_config_add_string 'ifaceid:ip6addr'
	proto_config_add_string "userclass"
	proto_config_add_string "vendorclass"
	proto_config_add_boolean delegate
	proto_config_add_int "soltimeout"
	proto_config_add_boolean fakeroutes

	proto_config_add_int "request_na"
	proto_config_add_int "request_pd"
	proto_config_add_boolean "no_accept_reconfigure"
	proto_config_add_boolean "no_client_fqdn"

	proto_config_add_boolean "use_softwire"
}

proto_terastream_setup() {
	local config="$1"
	local iface="$2"

	local reqaddress reqprefix clientid reqopts noslaaconly forceprefix norelease ip6prefix iface_dslite iface_map iface_464xlat ifaceid userclass vendorclass delegate zone_dslite zone_map zone_464xlat zone soltimeout fakeroutes
	local request_na request_pd no_accept_reconfigure no_client_fqdn use_softwire
	json_get_vars reqaddress reqprefix clientid reqopts noslaaconly forceprefix norelease ip6prefix iface_dslite iface_map iface_464xlat ifaceid userclass vendorclass delegate zone_dslite zone_map zone_464xlat zone soltimeout fakeroutes request_na request_pd no_accept_reconfigure no_client_fqdn use_softwire


	# Configure
	local opts=""
	[ "$request_na" = 0 ] && reqaddress="none"

	[ -n "$reqaddress" ] && append opts "-N$reqaddress"

	if [ "$request_pd" -gt 0 ]; then
		[ "$request_pd" -gt 0 ] && append opts "-P 0,_ANY"
		[ "$request_pd" -gt 1 ] && append opts "-P 0,IPTV"
		[ "$request_pd" -gt 2 ] && append opts "-P 0,VOIP"
	else
		[ -z "$reqprefix" -o "$reqprefix" = "auto" ] && reqprefix=0
		[ "$reqprefix" != "no" ] && append opts "-P$reqprefix"
	fi

	[ -n "$clientid" ] && append opts "-c$clientid"

	[ "$noslaaconly" = "1" ] && append opts "-S"

	[ "$forceprefix" = "1" ] && append opts "-F"

	[ "$norelease" = "1" ] && append opts "-k"

	[ -n "$ifaceid" ] && append opts "-i$ifaceid"

	[ -z "$vendorclass" ] && vendorclass="00000B790006542D4C414253"

	[ -n "$vendorclass" ] && append opts "-V$vendorclass"

	[ -n "$userclass" ] && append opts "-u$userclass"

	for opt in $reqopts; do
		append opts "-r$opt"
	done

	append opts "-t${soltimeout:-120}"
	append opts "-m 10"
	append opts "-R"

	[ -n "$ip6prefix" ] && proto_export "USERPREFIX=$ip6prefix"
	[ -n "$iface_dslite" ] && proto_export "IFACE_DSLITE=$iface_dslite"
	[ -n "$iface_map" ] && proto_export "IFACE_MAP=$iface_map"
	[ -n "$iface_464xlat" ] && proto_export "IFACE_464XLAT=$iface_464xlat"
	[ "$delegate" = "0" ] && proto_export "IFACE_DSLITE_DELEGATE=0"
	[ "$delegate" = "0" ] && proto_export "IFACE_MAP_DELEGATE=0"
	[ -n "$zone_dslite" ] && proto_export "ZONE_DSLITE=$zone_dslite"
	[ -n "$zone_map" ] && proto_export "ZONE_MAP=$zone_map"
	[ -n "$zone_464xlat" ] && proto_export "ZONE_464XLAT=$zone_464xlat"
	[ -n "$zone" ] && proto_export "ZONE=$zone"
	[ "$fakeroutes" != "0" ] && proto_export "FAKE_ROUTES=1"
	[ -n "$use_softwire" ] && proto_export "USE_SOFTWIRE=1"

	proto_export "INTERFACE=$config"
	proto_run_command "$config" odhcp6c-terastream \
		-s /lib/netifd/terastream.script \
		$opts $iface
}

proto_terastream_renew() {
	local interface="$1"
	# SIGUSR1 forces odhcp6c to renew its lease
	local sigusr1="$(kill -l SIGUSR1)"
	[ -n "$sigusr1" ] && proto_kill_command "$interface" $sigusr1
}

proto_terastream_teardown() {
	local interface="$1"
	proto_kill_command "$interface"
	ifdown "${interface}_b4"
}

add_protocol terastream

