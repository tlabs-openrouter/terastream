#
# Copyright (C) 2012-2014 OpenWrt.org
#               2015 T-Labs
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=odhcp6c-terastream
PKG_VERSION:=2015-07-29.4
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=git@github.com:tlabs-openrouter/odhcp6c.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=9c91c3f56f37a654701a5e68a8e2168c0cbb1dfa
PKG_MAINTAINER:=Kaspar Schleiser <kaspar@schleiser.de>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

ifneq ($(CONFIG_PACKAGE_odhcp6c_ext_prefix_class),0)
  CMAKE_OPTIONS += -DEXT_PREFIX_CLASS=$(CONFIG_PACKAGE_odhcp6c_ext_prefix_class)
endif

ifneq ($(CONFIG_PACKAGE_odhcp6c-terastream_ext_cer_id),0)
  CMAKE_OPTIONS += -DEXT_CER_ID=$(CONFIG_PACKAGE_odhcp6c-terastream_ext_cer_id)
endif

ifneq ($(CONFIG_PACKAGE_odhcp6c-terastream_s46_priority),0)
  CMAKE_OPTIONS += -DEXT_S46_PRIORITY=$(CONFIG_PACKAGE_odhcp6c-terastream_ext_s46_priority)
endif

define Package/odhcp6c-terastream
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Embedded DHCPv6-client for OpenWrt, Terastream fork
  DEPENDS:=@IPV6
endef

define Package/odhcp6c-terastream/config
  config PACKAGE_odhcp6c-terastream_ext_prefix_class
    int "Prefix Class Extension ID (0 = disabled)"
    depends on PACKAGE_odhcp6c-terastream
    default 0

  config PACKAGE_odhcp6c-terastream_ext_cer_id
    int "CER-ID Extension ID (0 = disabled)"
    depends on PACKAGE_odhcp6c-terastream
    default 0

  config PACKAGE_odhcp6c-terastream_ext_s46_priority
    int "S46 Priority Extension ID (0 = disabled)"
    depends on PACKAGE_odhcp6c-terastream
    default 0
endef

define Package/odhcp6c-terastream/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/odhcp6c $(1)/usr/sbin/odhcp6c-terastream
endef

$(eval $(call BuildPackage,odhcp6c-terastream))
