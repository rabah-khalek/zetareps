# Convenience targets for ZetaReps.

.PHONY: build clean icons favicons

## Build the app for the iOS simulator and show only errors, warnings and the result
build:
	xcodebuild -project ZetaReps.xcodeproj -scheme ZetaReps -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | head -20

## Remove Xcode build products for the ZetaReps scheme
clean:
	xcodebuild -project ZetaReps.xcodeproj -scheme ZetaReps clean

## Regenerate the app icon set from web/logo.png
icons:
	python3 scripts/generate-app-icons.py

## Regenerate the website favicons from web/logo.png
favicons:
	python3 scripts/generate-favicons.py
