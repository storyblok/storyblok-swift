---
name: release
description:
  Use when asked to prepare or cut a release, choose the next version, or write release notes for
  storyblok-swift
disable-model-invocation: true
---

# Release

Prepare the release: $ARGUMENTS

Swift Package Manager resolves versions from git tags, so there's no version string in the code.
Publishing a GitHub release creates the tag, and `.github/workflows/publish.yml` then builds the
combined DocC site and deploys it to `gh-pages`.

## Current state

- Latest release: !`gh release list -L 1 2>/dev/null`
- Top of changelog: !`sed -n 3p CHANGELOG.md`
- Branch: !`git branch --show-current`

## Step 1: Choose the version

Read the `**main**` section of `CHANGELOG.md` and `git log <last tag>..origin/main --oneline`.

- **Any breaking change means a major version.** Users install with
  `.upToNextMajor(from:)`, so a breaking minor would reach them automatically. (That's why
  0.3.0 was followed by 1.0.0.)
- New API means a minor version. Fixes only mean a patch.

Confirm the version with the user if they didn't give one.

## Step 2: Prepare (one PR, `chore: prep X.Y.Z release`)

Branch from `origin/main` (`chore/release-X.Y.Z`), then:

1. `CHANGELOG.md`: rename `**main**` to `**X.Y.Z**`. Order the entries breaking changes first
   (`BREAKING CHANGE:`), then additions, then fixes. Leave out internal-only changes (CI, tests,
   repo docs).
2. Point the installation snippets at the new version:

   ```bash
   git grep -n 'upToNextMajor(from:' -- 'Sources/*.docc/*' README.md
   ```

   That's the `UserGuide.md` of each of `URLSessionExtension`, `StoryblokClient` and
   `RichTextView`.
3. Verify, one test target per process. The subshell stops at the first failure and reports it,
   without closing the terminal it's pasted into. (It uses explicit `|| exit 1` because bash ignores
   `set -e` inside a subshell whose status is tested.)

   ```bash
   (
     swift build --build-tests || exit 1
     for t in URLSessionExtensionTests StoryblokClientTests StoryblokClientMacroTests RichTextViewTests; do
       swift test --skip-build --filter "$t" || exit 1
     done
     swift package generate-documentation --target StoryblokClient --target RichTextView \
       --target URLSessionExtension --enable-experimental-combined-documentation || exit 1
   ) && echo "release checks passed" || echo "release checks FAILED"
   ```

   Don't continue to the PR unless it prints `release checks passed`.

Commit, push and open the PR against `main`. Stop there. The release waits for the PR to merge.

## Step 3: Publish (only after the PR is merged, and only with the user's explicit go-ahead)

A published tag is public, and SwiftPM users resolve it straight away. Show the user the tag,
title and notes first, and wait for a clear yes.

```bash
gh release create vX.Y.Z --target main --title "X.Y.Z" --generate-notes
```

- The tag is lowercase `v` + version (`v1.0.0`), and the title is the bare version.
- Never move or delete a published tag. Fix forward with a new patch release.
- Afterwards, check the docs deploy: `gh run list --workflow publish.yml -L 1`.
