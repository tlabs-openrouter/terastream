# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dot1ag-utils
PKG_VERSION:=1.0.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_REV:=01a24e5de960318c4cc8a97212cc33b38d19e3e2
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE:=dot1ag-utils-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/vnrick/dot1ag-utils.git
PKG_SOURCE_SUBDIR:=dot1ag-utils-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/dot1ag-utils
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libpcap
  TITLE:=803.1ag utility programs
endef

define Build/Ciompile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -Wall" \
		all
endef

define Package/dot1ag-utils/install	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dot1ag_ccd $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ethping $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ethtrace $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/dot1agd $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,dot1ag-utils))
