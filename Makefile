ARCHS := arm64e arm64
THEOS_DEVICE_IP = 127.0.0.1 
THEOS_DEVICE_PORT = 2222

GO_EASY_ON_ME = 1
FINALPACKAGE = 1
DEBUG = 0

INSTALL_TARGET_PROCESSES = MobileTimer

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Clock
Clock_FILES = Tweak.x
Clock_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
