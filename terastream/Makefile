#
# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=terastream
PKG_VERSION:=$(PKG_FILE_NAME)
PKG_RELEASE:=27

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)

include $(INCLUDE_DIR)/package.mk

define Package/terastream
  SECTION:=telekom
  CATEGORY:=Telekom
  TITLE:=Terastream

  DEPENDS+= +dnsmasq-full
  DEPENDS+= +kmod-ipv6
  DEPENDS+= +kmod-ip6-tunnel
  DEPENDS+= +ip
  DEPENDS+= +ipv6calc-mini
  DEPENDS+= +odhcp6c-terastream
  DEPENDS+= +resolveip            # needed for resolving AFTR FQDN -> IP
  DEPENDS+= +lua                  # needed for decode_hostname
  DEPENDS+= +udhcpv4ov6
  DEPENDS+= +ds-lite +map
  DEPENDS+= +logremote-terastream
  DEPENDS+= +odhcpd
endef

define Package/terastream/description
 This package installs all components that are needed for terastream IPv6/IPv4 WAN/LAN connectivity
endef

define Build/Compile
endef

define Package/terastream/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/set_mtu.sh $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/dhcpv4ov6.script $(1)/lib/netifd/
	$(INSTALL_BIN) ./files/dhcpv4ov6.sh $(1)/lib/netifd/proto

	$(INSTALL_BIN) ./files/lw4o6l.sh $(1)/lib/netifd/proto/
	$(INSTALL_BIN) ./files/terastream.sh $(1)/lib/netifd/proto/
	$(INSTALL_BIN) ./files/terastream.script $(1)/lib/netifd/

	$(INSTALL_DIR) $(1)/etc/hotplug.d/firewall
	$(INSTALL_BIN) ./files/firewall-hotplug-ifrules.sh $(1)/etc/hotplug.d/firewall/20-ifrules

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/ntpd.hotplug $(1)/etc/hotplug.d/iface/50-ntpd

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/decode_hostname.lua $(1)/usr/bin/decode_hostname

	$(INSTALL_DIR) $(1)/etc/profiles/network
	$(INSTALL_DATA) ./files/terastream.network $(1)/etc/profiles/network/terastream
	$(INSTALL_DATA) ./files/terastream_legacy.network $(1)/etc/profiles/network/terastream_legacy

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/firewall.terastream $(1)/etc/firewall.terastream

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init/* $(1)/etc/init.d
endef

$(eval $(call BuildPackage,terastream))
