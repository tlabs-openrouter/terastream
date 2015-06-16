#!/bin/sh
# lw4o6l.sh - Lightweight 4 over 6 legacy protocol support
#
#
# Based on map.sh 
# Author: Steven Barth <cyrus@openwrt.org>
# Copyright (c) 2014 cisco Systems, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2
# as published by the Free Software Foundation
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_lw4o6l_setup() {
	local cfg="$1"
	local iface="$2"
	local link="lw4-$cfg"
	local remoteip6

	# uncomment for legacy MAP0 mode
	#export LEGACY=1

	local type mtu ttl tunlink zone
	local rule ipaddr ip6addr peeraddr psidlen psid port_range_min port_range_max portsets
	json_get_vars type mtu ttl tunlink zone
	json_get_vars rule ipaddr ip6addr peeraddr psidlen psid port_range_min port_range_max

	remoteip6=$(resolveip -6 $peeraddr)
	if [ -z "$remoteip6" ]; then
		sleep 3
		remoteip6=$(resolveip -6 $peeraddr)
		if [ -z "$remoteip6" ]; then
			proto_notify_error "$cfg" "AFTR_DNS_FAIL"
			return
		fi
	fi
	peeraddr="${remoteip6%% *}"

	[ -z "$zone" ] && zone="wan"

	if [ -n "$port_range_min" -a "$port_range_min" -gt 0 ]; then
		portsets="${port_range_min}-${port_range_max}"
	fi

	( proto_add_host_dependency "$cfg" "::" "$tunlink" )

	proto_init_update "$link" 1

	proto_add_ipv4_route "0.0.0.0" 0
	proto_add_ipv4_address "192.0.0.2" "" "" "192.0.0.1"
	
	# proto_send_update "$cfg"
	# return 0
	
	proto_add_tunnel
	json_add_string mode ipip6
	json_add_int mtu "${mtu:-1280}"
	json_add_int ttl "${ttl:-64}"
	json_add_string local "$ip6addr"
	json_add_string remote "$peeraddr"
	[ -n "$tunlink" ] && json_add_string link "$tunlink"
	proto_close_tunnel

	logger -t "$cfg" "tunnel: $ip6addr -> $peeraddr over $tunlink"

	proto_add_data
	[ "$zone" != "-" ] && json_add_string zone "$zone"

	json_add_array firewall
	  if [ -z "$portsets" ]; then
	    json_add_object ""
	      json_add_string type nat
	      json_add_string target SNAT
	      json_add_string family inet
	      json_add_string snat_ip "$ipaddr"
	    json_close_object
	  else
	    for portset in $portsets; do
              for proto in icmp tcp udp; do
	        json_add_object ""
	          json_add_string type nat
	          json_add_string target SNAT
	          json_add_string family inet
	          json_add_string proto "$proto"
                  json_add_boolean connlimit_ports 1
                  json_add_string snat_ip "$ipaddr"
                  # json_add_string snat_port "$portset"
		  json_add_string snat_port "4096-8191"
	        json_close_object
              done
	    done
	  fi
	json_close_array
	proto_close_data

	proto_send_update "$cfg"

	logger -t "$cfg" "updated proto"
}

proto_lw4o6l_teardown() {
	local cfg="$1"
	ifdown "${cfg}_"
}

proto_lw4o6l_init_config() {
	no_device=1
	available=1

	logger -t "lw4o6l" "init_config"

	proto_config_add_string "ipaddr"
	proto_config_add_string "ip6addr"
	proto_config_add_string "peeraddr"
	proto_config_add_int "psidlen"
	proto_config_add_int "psid"

	proto_config_add_int "port_range_min"
	proto_config_add_int "port_range_max"

	proto_config_add_string "tunlink"
	proto_config_add_int "mtu"
	proto_config_add_int "ttl"
	proto_config_add_string "zone"
}

[ -n "$INCLUDE_ONLY" ] || {
	logger -t "lw4o6l" "adding proto"
        add_protocol lw4o6l
}
