#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
. /lib/config/uci.sh

init_proto "$@"

proto_dslite_terastream_init_config() {
	no_device=1
	available=0
	proto_config_add_string "interface"
	proto_config_add_string "opt_aftr_local"
	proto_config_add_string "opt_aftr_remote"
	proto_config_add_string "opt_aftr_v4_local"
	proto_config_add_string "opt_aftr_v4_remote"
	proto_config_add_boolean "nodefaultroute"
	proto_config_add_int "mtu"
}

config_error() {
	local config=$1

	proto_notify_error "$config" INVALID_OPTIONS
	proto_block_restart "$config"
        
	exit 1
}

get_real_interface_name() {                                         
	local interface="$1"                                        
	local type="$(uci -q get network.$interface.type)"          
	if [ -n "$type" -a "$type" = "bridge" ]; then               
		echo "br-$interface"                                
	else                                                        
		echo "$(uci -q get network.$interface.ifname)"      
	fi                                                          
}                                                                   

refresh_firewall() {
	local b4=$1
	local aftr=$2

	ip6tables -w -F deny_b4
	ip6tables -w -A deny_b4 ! -d $b4 -j RETURN
	ip6tables -w -A deny_b4 -p ipv6-icmp -j RETURN
	ip6tables -w -A deny_b4 -p udp --dport 67 -j RETURN
	ip6tables -w -A deny_b4 -s $aftr -j RETURN
	ip6tables -w -A deny_b4 -j REJECT
}

get_slaac() {
	local device="$1"
	ip a l $device | grep -m1 -E "scope global .*dynamic" | cut -d' ' -f6 | cut -d/ -f1
}

proto_dslite_terastream_setup() {
	local config="$1"			# logical interface name
	local link="$config-tun"	# physical tunnel interface

	# only start if default route is available
#	proto_add_host_dependency $config "::"

	local nodefaultroute=0
	local interface
	local mtu=0
	json_get_vars interface nodefaultroute mtu

	# $interface is logical interface we'll pull dynamic endpoint configuration
	# from, e.g., the wan IPv6 interface with DHCPv6-supplied values.
	# Defaults to our own logical interface name
	[ -z "$interface" ] && interface=$config

	local opt_aftr_local opt_aftr_remote opt_aftr_v4_local opt_aftr_v4_remote
	json_get_vars opt_aftr_local opt_aftr_remote opt_aftr_v4_local opt_aftr_v4_remote

	[ -z "$opt_aftr_local" -o -z "$opt_aftr_remote" -o -z "$opt_aftr_v4_local" -o -z "$opt_aftr_v4_remote" ] && {
		logger -t dslite "$config Error: some AFTR related pointer is not set."
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}

	# config_if holds the device that we pull our
	# local endpoint address from, if not specified
	local config_if="$(get_real_interface_name $interface)"
	[ -z "$config_if" ] && config_if=$interface

	local aftr_local="$(uci_get_state network $interface $opt_aftr_local)"
	[ -z "$aftr_local" ] && {
		logger -t dslite "$config: Error: no aftr local tunnel endpoint address configured."
		logger -t dslite "$config: Trying SLAAC address of ${config_if}..."

		aftr_local="$(get_slaac $config_if)"

		[ -z "$aftr_local" ] && {
			logger -t dslite "$config: Error: No SLAAC address configured."
			sleep 5
			proto_setup_failed "$config"
			exit 1
		}
	}

	# remote v6 endpoint comes as FQDN, try to resolve
	local aftr_remote_name="$(uci_get_state network $interface $opt_aftr_remote)"

	[ -z "$aftr_remote_name" ] && {
		logger -t dslite "$config: Error: no aftr remote given."
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}

	local aftr_remote="$(resolveip -6 $aftr_remote_name)"
	[ -z "$aftr_remote" ] && {
		logger -t dslite "$config: Error: cannot resolve AFTR ($aftr_remote_name)."
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}

	# setup IP4 endpoint addresses. default to dslite specs.
	local local_v4="$(uci_get_state network $interface $opt_aftr_v4_local)"
	local remote_v4="$(uci_get_state network $interface $opt_aftr_v4_remote)"

	logger -t dslite -- "$config: Setting up 4in6 tunnel. local=$aftr_local remote=$aftr_remote"
	logger -t dslite -- "$config: local_v4=$local_v4 remote_v4=$remote_v4 nodefaultroute=$nodefaultroute"

	refresh_firewall $aftr_local $aftr_remote

	proto_init_update "$link" 1
	proto_add_tunnel
	json_add_string mode ipip6
	json_add_string local "$aftr_local"
	json_add_string remote "$aftr_remote"
	proto_close_tunnel

	proto_add_ipv4_address ${local_v4} 32 255.255.255.255 ${remote_v4}

	# Set up default route over tunnel (if not disabled)
	[ "${nodefaultroute}" = "1" ] || proto_add_ipv4_route 0.0.0.0 0 "${remote_v4}"

	proto_send_update $config

	# set MTU. Should do this through netifd.
	[ -n "$mtu" ] && ifconfig $link mtu $mtu
}

proto_dslite_terastream_teardown() {
	local interface="$1"
	logger -t dslite $interface down

	ip6tables -w -F deny_b4

	local config_if=$(uci -q get network.$interface.interface)
	local wan_dev=$(uci -q get network.$config_if.ifname)
}

add_protocol dslite_terastream
