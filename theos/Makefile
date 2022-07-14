TARGET := iphone:clang:latest:13.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = atlantis

atlantis_FILES = Tweak.xm \
	../Sources/Atlantis+Manual.swift \
	../Sources/Atlantis.swift \
	../Sources/AtlantisHelper.swift \
	../Sources/Configuration.swift \
	../Sources/DataCompression.swift \
	../Sources/DispatchQueue+Once.swift \
	../Sources/Message.swift \
	../Sources/NetworkInjector+URLSession.swift \
	../Sources/NetworkInjector.swift \
	../Sources/PackageIdentifier.swift \
	../Sources/Packages.swift \
	../Sources/Runtime.swift \
	../Sources/Transporter.swift
atlantis_CFLAGS = -fobjc-arc
atlantis_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	# Respring the device
	install.exec "killall -9 SpringBoard"
