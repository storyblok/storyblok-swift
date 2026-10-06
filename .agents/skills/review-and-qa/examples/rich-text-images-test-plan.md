---
name: Test Plan Example
description: Example of a manual test plan for an SDK change, verified through the JetNews sample
---

# Rich Text Image Accessibility Manual Test Plan

## Environment setup

The JetNews sample builds against this working copy, so no publishing is needed. See the
`run-sample` skill for the full steps.

```bash
cd Samples/JetNews
xcodebuild -project JetNews.xcodeproj -scheme JetNews \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/JetNews.app
xcrun simctl launch booted com.example.JetNews
```

In the sample's Storyblok space, prepare a post whose rich text body has four images:

1. `alt` set
2. `alt` empty, `title` set
3. `alt` of only spaces, `title` set
4. Neither `alt` nor `title`

Open Accessibility Inspector (Xcode → Open Developer Tool) and point it at the simulator.

## Test cases

### 1. Image descriptions

#### 1.1 Alt text present

Open the post and inspect image 1.

**Verify:**

- [ ] The label is the `alt` text, and the traits include **Image**.

#### 1.2 Empty or whitespace-only alt falls back to title

Inspect images 2 and 3.

**Verify:**

- [ ] The label is the `title`, trimmed, for both.
- [ ] The traits include **Image**.

#### 1.3 Decorative image

Inspect image 4, then move through the post with VoiceOver (Inspector's audit, or VoiceOver on a
device).

**Verify:**

- [ ] The image isn't in the accessibility tree. VoiceOver skips it.

### 2. Loading states

#### 2.1 Slow network

Throttle the network with Network Link Conditioner (a "3G" profile) and reopen the post.

**Verify:**

- [ ] VoiceOver announces the in-progress indicator while the image loads.
- [ ] The label and traits are correct once loaded.

#### 2.2 Failed load

Turn networking off after the story loads, then scroll to an uncached image.

**Verify:**

- [ ] The failure placeholder is shown, and the app doesn't crash or hang.

### 3. Platforms

#### 3.1 Dynamic Type and dark mode

Switch to the largest accessibility text size and dark appearance (Settings → Accessibility, or
Environment Overrides in Xcode).

**Verify:**

- [ ] Captions and surrounding text scale, and images keep their aspect ratio.

## Checklist summary

### Descriptions

- [ ] `alt` is used when present.
- [ ] Falls back to a trimmed `title`.
- [ ] Hidden when neither is set.

### Loading

- [ ] The progress announcement is kept.
- [ ] Failure is handled.

### Presentation

- [ ] Dynamic Type and dark mode work.
