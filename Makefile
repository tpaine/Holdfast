APP_NAME = Holdfast
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources
INSTALL_DIR = /Applications

.PHONY: build run install clean

build:
	swift build -c release
	mkdir -p $(MACOS) $(RESOURCES)
	cp .build/release/$(APP_NAME) $(MACOS)/$(APP_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp Resources/$(APP_NAME).entitlements $(RESOURCES)/$(APP_NAME).entitlements
	cp Resources/$(APP_NAME).icns $(RESOURCES)/$(APP_NAME).icns
	xattr -cr $(APP_BUNDLE)
	codesign -s - --force --entitlements Resources/$(APP_NAME).entitlements $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

run: build
	@-pkill -x $(APP_NAME) 2>/dev/null && sleep 0.5 || true
	tccutil reset Accessibility com.holdfast.app
	open $(APP_BUNDLE)

install: build
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	swift package clean
	rm -rf $(BUILD_DIR)
