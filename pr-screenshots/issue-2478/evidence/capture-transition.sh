#!/usr/bin/env bash
set -euo pipefail

device=${1:?Pass the UUID of a booted iOS simulator}
task_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
gallery_dir=$(mktemp -d /tmp/loop-live-transition.XXXXXX)
recording_pid=
appearance=$(xcrun simctl ui "$device" appearance)
cleanup() {
  local status=$?
  if [[ -n "$recording_pid" ]]; then kill -INT "$recording_pid" 2>/dev/null || true; fi
  xcrun simctl ui "$device" appearance "$appearance"
  xcrun simctl status_bar "$device" clear
  return "$status"
}
trap cleanup EXIT
xcrun simctl status_bar "$device" override --time '9:41' --dataNetwork wifi \
  --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
simulator_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)

capture_version() {
  local version=$1
  local derived_data=$2
  local products="$derived_data/Build/Products/Debug-iphonesimulator"
  local flags=(-D AFTER)
  if [[ "$version" == before ]]; then flags=(-D BEFORE); fi
  local app="$gallery_dir/$version/TransitionGallery.app"
  local output="$task_dir/$version"
  mkdir -p "$app/Frameworks" "$output"
  cp -R "$products/LoopKit.framework" "$products/LoopKitUI.framework" \
    "$products/PackageFrameworks/SwiftCharts.framework" "$app/Frameworks/"
  cat >"$app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.loopkit.LiveTransitionGallery</string>
<key>CFBundleExecutable</key><string>TransitionGallery</string>
<key>CFBundleName</key><string>Live Transition</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>17.6</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
  xcrun swiftc -parse-as-library -target arm64-apple-ios17.6-simulator \
    -sdk "$simulator_sdk" "${flags[@]}" \
    -F "$products" -F "$products/PackageFrameworks" -I "$products" \
    -framework LoopKitUI -framework LoopKit -framework SwiftCharts \
    -Xlinker -rpath -Xlinker @executable_path/Frameworks \
    "$task_dir/TransitionGallery.swift" -o "$app/TransitionGallery"
  for framework in "$app"/Frameworks/*.framework; do codesign --force --sign - "$framework"; done
  codesign --force --sign - "$app"
  xcrun simctl install "$device" "$app"
  local bundle=org.loopkit.LiveTransitionGallery
  xcrun simctl terminate "$device" "$bundle" >/dev/null 2>&1 || true
  xcrun simctl ui "$device" appearance light
  # Exactly one launch per version. All three phases keep that process and view alive.
  xcrun simctl launch "$device" "$bundle" | tee "$output/open-view-process.txt"
  sleep 3
  xcrun simctl io "$device" screenshot "$output/open-view-initial-light.png"
  xcrun simctl io "$device" recordVideo --codec=h264 --force "$output/open-view-transition.mp4" >"$output/open-view-recording.log" 2>&1 &
  recording_pid=$!
  sleep 3
  xcrun simctl ui "$device" appearance dark
  sleep 4
  xcrun simctl io "$device" screenshot "$output/open-view-dark.png"
  sleep 2
  xcrun simctl ui "$device" appearance light
  sleep 4
  xcrun simctl io "$device" screenshot "$output/open-view-returned-light.png"
  sleep 2
  kill -INT "$recording_pid"
  wait "$recording_pid"
  recording_pid=
}

capture_version before /tmp/loop-2478-before-build
capture_version after /tmp/loop-2478-build
