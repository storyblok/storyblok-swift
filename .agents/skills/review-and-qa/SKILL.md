---
name: review-and-qa
description: Use when asked to review a commit, branch, or PR, or to produce a QA plan for changes
model: opus
context: fork
agent: reviewer
effort: high
---

# Review Changes

Review the changes for: $ARGUMENTS.

Perform a two-phase review: a **code review** of quality, correctness and fit, then a **QA review**
with manual test cases. `AGENTS.md` has the package layout and conventions. Don't rediscover them.

## Step 0: Collect the context

Run this first, with the arguments unchanged and quoted, so a `#42` isn't read as a shell comment
(empty means the current branch and working tree):

```bash
bash .agents/skills/review-and-qa/scripts/review-context.sh "$ARGUMENTS"
```

It prints the PR description and CI status, commits with author emails, changed files, affected
targets, repo-specific flags (`public` lines changed, concurrency escape hatches, a missing
changelog) and the host test commands. It also writes the full diff to
`claude-output/review-<id>.diff`. Read that diff once, in full. Then open surrounding code only
where a finding depends on it. For a PR or commit that isn't checked out, read files at the head
with `git show "<sha>:<path>"` (quoted). If the script says the PR is already merged, review it as
merged code and frame findings as follow-ups.

Keep it fast:

- Trust CI for iOS, tvOS and watchOS. Don't run `xcodebuild` or simulators, and don't build the
  sample.
- If the checked-out code contains the change (the script says so) and package code changed,
  start the suggested
  `swift build --build-tests` and per-target `swift test --filter` commands **in the background**
  right away (one target per process). Collect the results before writing the report.
- Search with Grep across targets instead of reading whole files.

## Phase 1: Code review

### Required for all PRs

- [ ] **Small diff**: one logical change. If the PR does several, say how to split it.
- [ ] **Tests included**: new behaviour has tests, and a bug fix has a regression test that fails
      without the fix.
- [ ] **No secrets**: no tokens beyond the public demo tokens already used in `Examples/` and the
      sample.
- [ ] **Commits**: conventional format with a target scope. Org members' commits use
      `@storyblok.com` emails (CI rejects others).
      Judge commit rules against the base's `.github/` (an older PR may predate a check).

### Public API and semver

There's no ABI checker, so the `public`/`open` lines the script lists are the API diff. Check
each one.

- [ ] Every new `public` declaration is intended, and `internal` wouldn't do.
- [ ] Source-breaking changes are called out: removed or renamed declarations or argument labels,
      changed types, new protocol requirements without a default implementation, and **new cases
      on a public enum** (the package isn't built for library evolution, so clients' exhaustive
      `switch`es break).
- [ ] A breaking change needs a major version. `.upToNextMajor` would otherwise deliver it
      silently. Prefer `@available(*, deprecated, renamed: ...)` plus a typealias or forwarding
      shim where possible.
- [ ] New API carries the package's `@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)`
      where the surrounding API does, and gates newer OS APIs with `#available`.

### Concurrency (Swift 6 mode)

- [ ] Public types are `Sendable`. Each new `@unchecked Sendable`, `nonisolated(unsafe)` or
      `@preconcurrency` has a stated reason, and its mutable state is actually protected.
- [ ] `URLSessionDelegate` callbacks are thread-safe, and wrapping delegates still forward the
      callbacks a caller-supplied delegate handles.
- [ ] Combine pipelines don't leak (`AnyCancellable` ownership, `[weak self]` where a cycle is
      possible). Errors map to the documented types.
- [ ] SwiftUI code touches UI state on the main actor.

### Storyblok API behaviour

- [ ] `URLSessionExtension`: rate limits per API (CDN vs MAPI). Backoff on 429, 5xx and transport
      failures (no response at all), never on cache-only probes. `cv` comes from 301 redirects.
      Cache policy: published content cached, draft not.
- [ ] Cache keys are stable: query parameters sorted, and `+`/space encoding normalised.
- [ ] `StoryblokClient` decoding tolerates what the API and Visual Editor send (unknown keys,
      missing optional fields, `null`), and relation resolution handles cycles and `resolveLevel`.
- [ ] Errors: failed requests are `.api(message:underlyingError:)`, content mismatches are
      `.decoding(_:)`. Nothing is swallowed.

### `@BlockLibrary` macro

- [ ] New syntax handling has `assertMacroExpansion` tests covering the expansion **and** the
      diagnostics.
- [ ] Expansions respect user `CodingKeys`, nested types and technical names with dashes or
      backticks.
- [ ] Diagnostics say what's wrong and how to fix it. Expansions compile without warnings in Swift 6
      mode.

### `RichTextView` (SwiftUI)

- [ ] Rendering covers the node and mark types the change touches, and unknown nodes degrade
      gracefully.
- [ ] Accessibility: images have descriptions (`alt`, then `title`) or are hidden as decorative,
      traits are correct, and Dynamic Type and dark mode work.
- [ ] Code that's only available on some platforms (UIKit/AppKit, watchOS limits) is behind
      `#if canImport` / `#if os`.
- [ ] `body` stays cheap. Expensive attributed-string work isn't redone on every update.

### Quality, reuse and design

- [ ] Changes fit existing patterns. No unnecessary coupling between targets.
- [ ] Existing helpers are reused. No duplicated logic or magic numbers.
- [ ] No `try!`, `as!` or `fatalError` in library code without a comment explaining why it can't
      fail. No `print`: use the target's swift-log `Logger`.
- [ ] Error and log messages say what went wrong and what to do.

### If user-facing

- [ ] DocC `///` comments on new or changed public API, with symbol links.
- [ ] The target's `UserGuide.md` is updated where it covers the change.
- [ ] `CHANGELOG.md` has an entry under `**main**`. Breaking changes go first, prefixed
      `BREAKING CHANGE:`, with before/after.
- [ ] Docs and messages use Storyblok terms ("block", not "blok").

### If changing dependencies

- [ ] Version ranges in `Package.swift` are deliberate (swift-syntax versions each `6xx` as a
      major). `Package.resolved` changes match.
- [ ] A new dependency is justified, maintained, MIT-compatible and supports every platform.

### Verify before reporting

For each candidate issue, re-read the code that proves it. Drop anything you can't point to.
Prefer five real issues over fifteen maybes. Mark anything you inferred but couldn't confirm as
**Unverified**.

### Severity

- **Critical**: wrong behaviour in a common path, a crash, a data race, a security problem, or an
  unintended source break.
- **Major**: wrong in an edge case or on one platform, a missing regression test, or an
  undocumented user-facing change.
- **Minor**: clarity, naming, duplication, or docs polish.

## Phase 2: QA review

Use the [Test Plan Template](./templates/test-plan.md). See the
[Test Plan Example](./examples/rich-text-images-test-plan.md) for the level of detail.

Write manual test cases a person can run, covering:

1. **Happy path**: the change working as intended.
2. **Negative cases**: an invalid token, a missing story, network failure, 4xx/5xx.
3. **Edge cases**: empty content, unknown blocks or fields, circular relations, special characters
   in slugs and queries.
4. **Error recovery**: backoff and retry, cache fallback, and offline then online.
5. **Platforms**: which platforms to spot-check by hand and why. Use the JetNews sample on iOS (the
   `run-sample` skill), and macOS, tvOS or watchOS where the change is platform-specific.

Skip cases automated tests already cover. Mention them in a line instead.

## Output

Write the report to `claude-output/review-<id>.md` (the `<id>` from step 0):

```markdown
# Review: <title>

## Code review summary

[LGTM / Needs changes / Blocking issues]: one or two sentences.

Verification: <commands run and results, or "CI: N passed, M failing">

## Issues found

### [Critical/Major/Minor]: Issue title

**File:** `Sources/Target/File.swift:123`
**Problem:** What is wrong and when it happens.
**Suggestion:** How to fix it.

## QA test plan

<test plan>
```

Then reply with the verdict, the Critical and Major issues (one line each) and the report path.
