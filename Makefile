APP_NAME := MCTweaks
LABEL := dev.geo.mctweaks
BUILD_APP := build/$(APP_NAME).app
INSTALL_APP := $(HOME)/Applications/$(APP_NAME).app
AGENT := $(HOME)/Library/LaunchAgents/$(LABEL).plist
DOMAIN := gui/$(shell id -u)
VERSION ?= 0.1.0
DMG := build/$(APP_NAME)-$(VERSION).dmg

.PHONY: build dmg install uninstall

build:
	swift build -c release
	rm -rf $(BUILD_APP)
	mkdir -p $(BUILD_APP)/Contents/MacOS
	cp .build/release/$(APP_NAME) $(BUILD_APP)/Contents/MacOS/
	cp Resources/Info.plist $(BUILD_APP)/Contents/
	plutil -replace CFBundleShortVersionString -string $(VERSION) $(BUILD_APP)/Contents/Info.plist
	codesign --force --sign - --identifier $(LABEL) $(BUILD_APP)

dmg: build
	rm -rf build/dmg $(DMG)
	mkdir -p build/dmg
	cp -R $(BUILD_APP) build/dmg/
	ln -s /Applications build/dmg/Applications
	hdiutil create -volname $(APP_NAME) -srcfolder build/dmg -format UDZO -ov $(DMG)

install: build
	-launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null
	mkdir -p $(HOME)/Applications $(HOME)/Library/LaunchAgents
	rm -rf $(INSTALL_APP)
	cp -R $(BUILD_APP) $(INSTALL_APP)
	sed "s#__APP__#$(INSTALL_APP)#" Resources/launchagent.plist > $(AGENT)
	launchctl bootstrap $(DOMAIN) $(AGENT)
	@echo "Installed. Allow $(APP_NAME) in System Settings > Privacy & Security > Accessibility."

uninstall:
	-launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null
	rm -f $(AGENT)
	rm -rf $(INSTALL_APP)
