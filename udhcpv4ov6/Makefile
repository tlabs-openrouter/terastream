#
# Copyright (C) 2006-2014 OpenWrt.org
#               2015 T-Labs
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=udhcpv4ov6
PKG_VERSION:=2014-11-18
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_REV:=1a1143907c84308781e23f07d0c6c597bfd13abb
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE:=busybox-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=git://busybox.net/busybox.git
PKG_SOURCE_SUBDIR:=busybox-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/udhcpv4ov6-$(PKG_VERSION)/busybox-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_CHECK_FORMAT_SECURITY:=0

PKG_LICENSE:=GPLv2 BSD-4c
PKG_LICENSE_FILES:=LICENSE archival/libarchive/bz/LICENSE

include $(INCLUDE_DIR)/package.mk

ifneq ($(findstring c,$(OPENWRT_VERBOSE)),)
  BB_MAKE_VERBOSE := V=1
else
  BB_MAKE_VERBOSE :=
endif

define Package/udhcpv4ov6
  SECTION:=telekom
  CATEGORY:=Telekom
  MAINTAINER:=Kaspar Schleiser <kaspar@schleiser.de>
  TITLE:=udhcp with Uni Zagreb's DHCPv4oDHCPv6 implementation
endef

define Package/busybox/description
	udhcp with Uni Zagreb's DHCPv4oDHCPv6 implementation
endef

define Build/Configure
	rm -f $(PKG_BUILD_DIR)/.configured*
	cp ./config $(PKG_BUILD_DIR)/.config
	yes 'n' | $(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		KBUILD_HAVE_NLS=no \
		ARCH="$(ARCH)" \
		$(BB_MAKE_VERBOSE) \
		oldconfig
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		KBUILD_HAVE_NLS=no \
		EXTRA_CFLAGS="$(TARGET_CFLAGS)" \
		ARCH="$(ARCH)" \
		SKIP_STRIP=y \
		LDLIBS="$(LDLIBS)" \
		$(BB_MAKE_VERBOSE) \
		all
	rm -rf $(PKG_INSTALL_DIR)
	$(FIND) $(PKG_BUILD_DIR) -lname "*busybox" -exec rm \{\} \;
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		EXTRA_CFLAGS="$(TARGET_CFLAGS)" \
		ARCH="$(ARCH)" \
		CONFIG_PREFIX="$(PKG_INSTALL_DIR)" \
		LDLIBS="$(LDLIBS)" \
		$(BB_MAKE_VERBOSE) \
		install
endef

define Package/udhcpv4ov6/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) $(PKG_INSTALL_DIR)/bin/busybox $(1)/sbin/udhcpv4ov6
endef

$(eval $(call BuildPackage,udhcpv4ov6))
