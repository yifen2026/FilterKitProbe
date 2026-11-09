TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

# FilterKitProbe App
APPLICATION_NAME := FilterKitProbe
FilterKitProbe_FILES := \
    main.m \
    AppDelegate.m \
    FKPProfileCollectorViewController.m \
    FKPEntitlementsViewController.m \
    FKPElleKitScannerViewController.m \
    FKPPListParserViewController.m \
    FKPAppListViewController.m \
    FKPDyldImagesViewController.m

FilterKitProbe_CFLAGS := -fobjc-arc -Wall -Wextra -Werror=return-type
FilterKitProbe_FRAMEWORKS := UIKit Foundation
FilterKitProbe_INSTALL_PATH := /Applications

FilterKitProbe_BUNDLE_IDENTIFIER := com.filterkit.probe
FilterKitProbe_DISPLAY_NAME := FilterKitProbe
FilterKitProbe_EXECUTABLE_NAME := FilterKitProbe
FilterKitProbe_PACKAGE_TYPE := APPL
FilterKitProbe_SHORT_VERSION_STRING := 1.0
FilterKitProbe_VERSION := 1
FilterKitProbe_REQUIRES_IPHONE_OS := YES
FilterKitProbe_MAIN_NIB_FILE :=
FilterKitProbe_PRERENDERED_ICONS := YES

# 打包配置
PACKAGE_NAME = com.filterkit.probe
PACKAGE_VERSION = 1.0
PACKAGE_DESCRIPTION = FilterKit 技术信息采集工具
PACKAGE_MAINTAINER = yifen <https://yfen.cn>
PACKAGE_AUTHOR = yifen
PACKAGE_SECTION = Utilities
PACKAGE_DEPENDS = firmware (>= 15.0)

include $(THEOS_MAKE_PATH)/application.mk

# 手动复制 Info.plist
internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Applications/FilterKitProbe.app"$(ECHO_END)
	$(ECHO_NOTHING)cp Info.plist "$(THEOS_STAGING_DIR)/Applications/FilterKitProbe.app/Info.plist"$(ECHO_END)
