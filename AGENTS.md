# Storyblok Swift

Swift packages for Storyblok on Apple platforms, distributed with Swift Package Manager from this
repository (`https://github.com/storyblok/storyblok-swift.git`). Versions are git tags. There is no
version string in the code.

## Layout

One package (`Package.swift`, swift-tools-version 6.2) with three library products:

| Target                  | Depends on                                       | What it is                                                                                                          |
| ----------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| `URLSessionExtension`   | swift-log                                        | `URLSession(storyblok:)` and `URLRequest(storyblok:path:)`: auth, regions, rate limiting, backoff, `cv`, caching, Combine helpers. |
| `StoryblokClient`       | `URLSessionExtension`, `StoryblokClientMacros`   | Typed Content Delivery API client (`StoryblokClient<Library>`), `Story`, `Field`, `RichText`, relation resolution. |
| `StoryblokClientMacros` | swift-syntax (`"602.0.0" ..< "605.0.0"`)         | The `@BlockLibrary` macro, which synthesises decoding and relation keys for a block enum. Not a product.            |
| `RichTextView`          | `StoryblokClient`                                | SwiftUI rendering of rich text (`RichTextView`, `RichTextViewDelegate`).                                             |

- `Tests/<Target>Tests/`: unit tests per target (`StoryblokClientMacroTests` for the macro).
- `Examples/URLSessionExtension/`: docs-site snippets as a test target (`Examples`). **They call
  the live Storyblok APIs.** Files are named `CDN <Area>.swift` / `MAPI <Area>.swift`.
- `Samples/JetNews/`: a SwiftUI iOS app. Its Xcode project references this package by local path
  (`../..`), so it always builds against your working copy.
- `Sources/<Target>/<Target>.docc/`: DocC catalogs (`<Target>.md` landing page, `UserGuide.md`).
- `.swiftpm/xcode/xcshareddata/xcschemes/`: the shared `<Target>Tests` and `Examples` schemes CI
  uses with `xcodebuild`.

Platforms: macOS 13, iOS 16, tvOS 16, watchOS 9. Public types that need newer APIs are annotated
`@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)`.

## Commands

```bash
swift build                                   # whole package (first build compiles swift-syntax, ~1 min)
swift test --filter URLSessionExtensionTests  # ~20s, mostly real backoff waits
swift test --filter StoryblokClientTests
swift test --filter StoryblokClientMacroTests
swift test --filter RichTextViewTests
```

- **Run test targets one at a time.** `StoryblokClientTests` and `URLSessionExtensionTests` both
  call `LoggingSystem.bootstrap`, so a plain `swift test` crashes with "logging system can only be
  initialized once per process". CI runs each target separately.
- Other platforms, as CI runs them (shared schemes, Xcode simulators):

  ```bash
  xcodebuild test -scheme StoryblokClientTests -destination 'platform=iOS Simulator,name=iPhone 17'
  xcodebuild test -scheme StoryblokClientTests -destination 'platform=tvOS Simulator,name=Apple TV'
  xcodebuild test -scheme StoryblokClientTests -destination 'platform=watchOS Simulator,name=Apple Watch SE 3 (40mm)'
  ```

  If `xcodebuild` fails to link the macro, disable the swift-syntax prebuilts as CI does:
  `defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts -bool NO`.
- `swift test --filter Examples` hits the real API with demo tokens. Run it on purpose, not as a
  regression suite.
- Docs: `swift package generate-documentation --target StoryblokClient` (see
  `.github/workflows/publish.yml` for the combined build that is published).
- There is no SwiftLint or swift-format config. Match the surrounding style.
- Toolchain: Xcode 26+ (Swift 6.2). CI uses `latest-stable` Xcode on `macOS-latest`.

## Conventions

- **Swift 6 language mode**, so strict concurrency checking applies. Public types are `Sendable`.
  A new `@unchecked Sendable` or `nonisolated(unsafe)` needs a comment saying what makes it safe.
- **Access control:** default to `internal`. Everything `public` is API you'll have to keep
  semver-stable. SwiftPM's `.upToNextMajor` means any breaking change needs a major release.
  There's no ABI checker, so review `public` changes by hand.
- **Docs:** `///` DocC comments on every public declaration, with symbol links (``` ``Type`` ```).
  User-facing changes update the target's `UserGuide.md` where it covers them.
- **Errors:** `StoryblokClient.Error` is an enum: `.api(message:underlyingError:)` for failed
  requests (retryable) and `.decoding(_:)` for content mismatches. In `URLSessionExtension`, the
  opt-in `failOnErrorResponse(_:)` operator publishes `Api.ResponseError` for 4xx/5xx.
- **Logging:** swift-log with `Logger(label: "com.storyblok.<Target>")`. Never `print` in library
  code.
- **Async style:** the client API is Combine publishers. Callers use `.values` for async/await.
  Keep new API consistent with the target it lives in.
- **Tests:** Swift Testing (`@Suite`, `@Test`, `#expect`) with sentence names as raw identifiers
  (`` @Test func `story without rels decodes normally`() ``), and Mocker for
  `URLProtocol`-level HTTP mocking. Macro tests use XCTest with `assertMacroExpansion`. A bug fix
  needs a regression test.
- **Changelog:** `CHANGELOG.md`. Add entries to a `**main**` section at the top (create it if the top
  section is a released version). It's renamed to the version at release. Breaking changes go
  first, prefixed `BREAKING CHANGE:`.
- **Storyblok terms:** Use "block", not "blok" (renamed in 0.3.0, with deprecated aliases). Use
  "story", "space", "Content Delivery API", "Management API" and "Visual Editor".

## Git and PRs

- Conventional commits, imperative: `type(scope): description`. Aim for a subject under 50 chars
  (`.github/git-commit-instructions.md`). Long target scopes make that impossible, so keep the
  description short instead. The scope
  is the target (`fix(URLSessionExtension): ...`, `docs(UserGuide): ...`). See
  `.github/git-commit-instructions.md`.
- Use `feat` and `fix` only for changes consumers can observe. Tests, CI, the sample and repo docs
  are `chore`, `ci`, `docs` or `test`.
- Org members must commit with their `@storyblok.com` email. CI (`commit-email-check.yml`) fails
  otherwise. External contributors are exempt.
- On `main`, only commit when explicitly asked. Never `git push --force`. Use
  `--force-with-lease`.
- PRs target `main`. Keep them to one logical change, and call out any change to `public` API.

## Skills

Skills live in `.agents/skills/` (symlinked into `.claude/skills/`). Generated reports go to
`claude-output/` (gitignored).

| Skill              | Use it to                                                      |
| ------------------ | -------------------------------------------------------------- |
| `review-and-qa`    | Review a PR, branch or commit and write a QA plan              |
| `investigate`      | Root-cause a GitHub issue or bug report                        |
| `triage`           | Classify and prioritise GitHub issues or Linear tickets        |
| `plan`             | Write an implementation plan before coding                     |
| `implement`        | Carry out an approved plan                                     |
| `qa-engineer-unit` | Write or change unit tests                                     |
| `run-sample`       | Build and run the JetNews sample in the iOS Simulator          |
| `release`          | Close the changelog, bump the docs and cut a release           |
