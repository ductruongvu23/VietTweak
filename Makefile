# VietTweak — Makefile
# Rootless (iOS 15+ / Sileo / Dopamine / palera1n)

TARGET := iphone:clang:16.5:15.0
ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VietTweak

VietTweak_FILES = Tweak.x
VietTweak_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
VietTweak_FRAMEWORKS = UIKit Foundation
VietTweak_PRIVATE_FRAMEWORKS = Preferences
VietTweak_LIBRARIES = colorpicker prefs

include $(THEOS_MAKE_PATH)/tweak.mk

# Preference bundle ---------------------------------------------------------
BUNDLE_NAME = VietTweakPrefs
VietTweakPrefs_FILES = VRTRootListController.x
VietTweakPrefs_CFLAGS = -fobjc-arc
VietTweakPrefs_FRAMEWORKS = UIKit Foundation
VietTweakPrefs_PRIVATE_FRAMEWORKS = Preferences
VietTweakPrefs_LIBRARIES = colorpicker prefs
VietTweakPrefs_INSTALL_PATH = /Library/PreferenceBundles
VietTweakPrefs_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk

# Install the entry plist into PreferenceLoader's lookup path so the tweak
# shows up as a row in the root Settings list.
internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle
	$(ECHO_NOTHING)cp translations.json $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceBundles/VietTweakPrefs.bundle/translations.json
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceLoader/Preferences
	$(ECHO_NOTHING)cp Preferences/VietTweakPrefs.plist $(THEOS_STAGING_DIR)/var/jb/Library/PreferenceLoader/Preferences/VietTweakPrefs.plist
