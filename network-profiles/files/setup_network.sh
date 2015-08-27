#!/bin/sh
# misc utility functions

uci_add_to_list_if_absent() {
    local option="$1"
    local value="$2"
    local oldlist="$(uci -q get $option)"

    for entry in $oldlist; do
        [ "$entry" = "$value" ] && return
    done

    uci add_list $option="$value"
}

# get device's default wan interface name from uci.
# if unset, try previously set from /etc/config/network
get_wanif() {
    wan_eth=$(uci -q get profiles.network.wan_if)
    [ -z "$wan_eth" ] && wan_eth=$(uci -q get network.wan.ifname)
    echo $wan_eth
}

# get device's default iptv interface name from uci.
# if unset, try previously set from /etc/config/network
get_iptvif() {
    iptv_if=$(uci -q get profiles.network.iptv_if)
    [ -z "$iptv_if" ] && iptv_if=$(uci -q get network.lan_iptv.ifname)
    echo $iptv_if
}

uci_find_by_name() {
    uci show $1 | grep -m 1 "${1}\.@${2}\[.*\]\.name=${3}" | cut -d[ -f 2 | cut -d] -f 1
}

uci_delete_by_name() {
    n=$(uci_find_by_name $*)
    [ -n "$n" ] && {
        uci delete "${1}.@${2}[$n]"
    } || return 1
}

PROFILE_DIR=/etc/profiles/network
PROFILE=$1

[ -z "$PROFILE" ] && {
    echo "Usage: $0 <mode>"
    echo "Available modes: $(ls -- $PROFILE_DIR)"
    exit 1
}

[ ! -f "$PROFILE_DIR/$PROFILE" ] && {
    echo "Profile $PROFILE not found!"
    exit 1
}

old_mode=$(uci -q get profiles.network.mode)

[ -n "$old_mode" -a -f "$PROFILE_DIR/$old_mode" ] && {
    echo "Unconfiguring profile ${old_mode}..."
    . $PROFILE_DIR/$old_mode
    unsetup_$old_mode
    uci commit
}

echo "Configuring profile ${PROFILE}..."
. $PROFILE_DIR/$PROFILE
setup_$PROFILE && $(uci set profiles.network.mode=$PROFILE)

uci commit

