---
name: run-sample
description:
  Use when asked to run, build, or try the JetNews sample app, or to check a package change in a
  real app in the iOS Simulator
---

# Run the JetNews Sample

Run the sample for: $ARGUMENTS

`Samples/JetNews` is a SwiftUI iOS app (deployment target iOS 26.2, bundle ID
`com.example.JetNews`). Its Xcode project references this package by local path (`../..`), so it
always builds against the current working copy. No publishing or version changes are needed.

## Build, install and launch

```bash
cd Samples/JetNews
xcodebuild -project JetNews.xcodeproj -scheme JetNews \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build -quiet
xcrun simctl boot "iPhone 17" 2>/dev/null || true     # already booted is fine
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/JetNews.app
xcrun simctl launch booted com.example.JetNews
```

- A warm build takes about 30s. `build/` is gitignored.
- Pick another simulator with `xcrun simctl list devices available`. It needs an iOS 26.2+ runtime.
- If the build fails to link the `@BlockLibrary` macro, disable the swift-syntax prebuilts:
  `defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts -bool NO`.
- To let the user watch, open the Simulator app (`open -a Simulator`), or use an iOS Simulator
  tool if your agent has one.

## Check it

```bash
xcrun simctl io booted screenshot /tmp/jetnews.png                     # what's on screen
xcrun simctl launch --console-pty --terminate-running-process booted com.example.JetNews  # relaunch with stdout
```

The package logs through swift-log. The sample doesn't bootstrap a logging backend, so swift-log's
default handler writes `info` and above to stdout, and `--console-pty` shows those lines. Debug and
trace messages (e.g. rate-limit suspensions) only appear if you temporarily add
`LoggingSystem.bootstrap` with `logLevel = .trace` in `JetNewsApp.init`. Don't commit that. Run the
command in the background and stop it when done.

- Debug builds read **draft** content, release builds published content (`JetNewsApp.swift`).
- The app uses a demo space token. To use another space, change `accessToken` in
  `JetNews/JetNewsApp.swift`. Don't commit someone else's token.
- The block library (`JetNews/BlockLibrary.swift`) exercises `@BlockLibrary`, relation resolution
  and `RichTextView`, so it's the quickest end-to-end check for those targets.

## Report

Say which simulator and build configuration ran, what you checked, and anything that looked wrong,
with a screenshot or log excerpt where useful.
