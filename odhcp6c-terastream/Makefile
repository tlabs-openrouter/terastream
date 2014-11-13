#
# Copyright (C) 2012-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=odhcp6c-terastream
PKG_VERSION:=2014-11-04
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=git@slowspeed.hopto.org:odhcp6c
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=373cfe63962b7be31a7ec820bbcfe0032e561a83
PKG_MAINTAINER:=Kaspar Schleiser <kaspar@schleiser.de>

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

ifneq ($(CONFIG_PACKAGE_odhcp6c_ext_prefix_class),0)
  CMAKE_OPTIONS += -DEXT_PREFIX_CLASS=$(CONFIG_PACKAGE_odhcp6c_ext_prefix_class)
endif

ifneq ($(CONFIG_PACKAGE_odhcp6c_ext_cer_id),0)
  CMAKE_OPTIONS += -DEXT_CER_ID=$(CONFIG_PACKAGE_odhcp6c_ext_cer_id)
endif

define Package/odhcp6c
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Embedded DHCPv6-client for OpenWrt, Terastream fork
  DEPENDS:=+kmod-ipv6 -odhcp6c
endef

define Package/odhcp6c/config
  config PACKAGE_odhcp6c_ext_prefix_class
    int "Prefix Class Extension ID (0 = disabled)"
    depends on PACKAGE_odhcp6c
    default 0

  config PACKAGE_odhcp6c_ext_cer_id
    int "CER-ID Extension ID (0 = disabled)"
    depends on PACKAGE_odhcp6c
    default 0
endef

define Package/odhcp6c/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/odhcp6c $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/dhcpv6.sh $(1)/lib/netifd/proto/dhcpv6.sh
	$(INSTALL_BIN) ./files/dhcpv6.script $(1)/lib/netifd/
endef

$(eval $(call BuildPackage,odhcp6c))
