ARCHS = armv7 arm64
TARGET = iphone:latest:8.0

SRC = $(wildcard src/*.m)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ioswechat
ioswechat_FILES =  $(wildcard src/*.m) src/Tweak.xm
ioswechat_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 WeChat"
