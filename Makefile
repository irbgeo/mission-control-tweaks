APP_NAME := MCTweaks
LABEL := dev.geo.mctweaks
BUILD_APP := build/$(APP_NAME).app
INSTALL_APP := $(HOME)/Applications/$(APP_NAME).app
OLD_AGENT := $(HOME)/Library/LaunchAgents/$(LABEL).plist
DOMAIN := gui/$(shell id -u)
VENV := build/venv
VERSION ?= 0.1.0
DMG := build/$(APP_NAME)-$(VERSION).dmg
PKG := build/Install $(APP_NAME).pkg
# "-" = ad-hoc. Use "MCTweaks Self-Signed" to keep the Accessibility permission across updates.
SIGN_ID ?= -
# Shown as "Check for Updates…" in the menu bar; empty hides the item.
REPO_URL ?=

.PHONY: build icon dmg-background pkg dmg dmg-image install uninstall

build:
	swift build -c release
	rm -rf $(BUILD_APP)
	mkdir -p $(BUILD_APP)/Contents/MacOS $(BUILD_APP)/Contents/Resources
	cp .build/release/$(APP_NAME) $(BUILD_APP)/Contents/MacOS/
	cp Resources/AppIcon.icns $(BUILD_APP)/Contents/Resources/
	cp Resources/Info.plist $(BUILD_APP)/Contents/
	plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(BUILD_APP)/Contents/Info.plist
	plutil -replace MCTReleasesURL -string "$(REPO_URL)" $(BUILD_APP)/Contents/Info.plist
	codesign --force --sign "$(SIGN_ID)" --identifier $(LABEL) $(BUILD_APP)

icon:
	rm -rf build/AppIcon.iconset
	mkdir -p build/AppIcon.iconset
	swift scripts/make-icon.swift Resources/AppIcon.svg build/icon-1024.png
	for size in 16 32 128 256 512; do \
		sips -z $$size $$size build/icon-1024.png --out build/AppIcon.iconset/icon_$${size}x$${size}.png >/dev/null; \
		double=$$((size * 2)); \
		sips -z $$double $$double build/icon-1024.png --out build/AppIcon.iconset/icon_$${size}x$${size}@2x.png >/dev/null; \
	done
	iconutil -c icns -o Resources/AppIcon.icns build/AppIcon.iconset

dmg-background:
	swift scripts/make-dmg-background.swift Resources/dmg

$(VENV)/.installed: Resources/dmg/requirements.txt
	python3 -m venv $(VENV)
	$(VENV)/bin/python -m pip install --quiet --require-hashes --only-binary :all: -r Resources/dmg/requirements.txt
	touch $@

# Installs into /Applications and starts the app (postinstall). Not relocatable: always /Applications.
pkg: build
	rm -rf build/pkgroot "$(PKG)"
	mkdir -p build/pkgroot
	cp -R $(BUILD_APP) build/pkgroot/
	pkgbuild --analyze --root build/pkgroot build/component.plist
	plutil -replace 0.BundleIsRelocatable -bool NO build/component.plist
	pkgbuild --root build/pkgroot --component-plist build/component.plist \
		--install-location /Applications --scripts Resources/pkg/scripts \
		--identifier $(LABEL).pkg --version "$(VERSION)" build/MCTweaks-component.pkg
	productbuild --distribution Resources/pkg/distribution.xml --resources Resources/pkg/resources \
		--package-path build "$(PKG)"

dmg: pkg dmg-image

# Only the disk image from an existing pkg: CI runs it after the signing keychain is gone.
dmg-image: $(VENV)/.installed
	rm -f $(DMG)
	$(VENV)/bin/python -m dmgbuild -s Resources/dmg/settings.py -D "pkg=$(PKG)" $(APP_NAME) $(DMG)

install: build
	-launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null
	rm -f $(OLD_AGENT)
	-pkill -x $(APP_NAME)
	mkdir -p $(HOME)/Applications
	rm -rf $(INSTALL_APP)
	cp -R $(BUILD_APP) $(INSTALL_APP)
	open $(INSTALL_APP)

uninstall:
	-launchctl bootout $(DOMAIN)/$(LABEL) 2>/dev/null
	rm -f $(OLD_AGENT)
	-pkill -x $(APP_NAME)
	rm -rf $(INSTALL_APP)
	@echo "Removed. If you turned on Open at Login, remove MCTweaks in System Settings > General > Login Items."
