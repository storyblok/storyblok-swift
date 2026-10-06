# Contributing

Thanks for helping improve the Storyblok Swift packages! The general process (open an issue to
discuss your proposal first, then fork, branch and open a pull request) is in Storyblok's
[contributing guide](https://github.com/storyblok/.github/blob/main/contributing.md), and we expect
everyone to follow the [code of conduct](https://www.storyblok.com/trust-center#code-of-conduct).
This page covers what's specific to this repository.

## Development setup

- **Xcode 26 or later** (Swift 6.2). Open the package folder in Xcode, or use the `swift` command
  line.
- The first build compiles swift-syntax for the `@BlockLibrary` macro, which takes about a minute.

## Building and testing

```bash
swift build
swift test --filter StoryblokClientTests   # one test target at a time
```

Run test targets one at a time: two of them configure swift-log, which only works once per process.
CI also runs every target on the iOS, tvOS and watchOS simulators, so macOS is enough locally.
[AGENTS.md](AGENTS.md) lists every target and command, and how to run the JetNews sample app.

## Public API changes

There's no automated API check, so call out any change to `public` declarations in your pull
request. SwiftPM users depend on `.upToNextMajor`, so a source-breaking change needs a major
release. Prefer deprecating with `@available(*, deprecated, renamed: ...)` over removing. New public
API needs DocC comments, and user-facing changes need a `CHANGELOG.md` entry under `**main**`.

## Commits and pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) with the target as the scope,
  e.g. `fix(URLSessionExtension): skip cache-miss backoff`. Write the subject in the imperative
  and aim for under 50 characters. With a long scope, keep the description short.
- Keep each pull request to one logical change, with tests. A bug fix needs a regression test.
- Storyblok employees: commit with your `@storyblok.com` email address. CI checks it.

## Using AI coding tools

This repository is set up for AI coding agents. Use them if you like, but you're responsible for
everything you submit: review, run and understand the code as if you wrote it yourself.

- **[AGENTS.md](AGENTS.md)**: the project guide for agents. It covers layout, platforms, commands,
  conventions and commit rules. Claude Code (v2.1.277 or later), Codex, Cursor, GitHub Copilot,
  Gemini CLI and most other tools read it automatically.
- **Skills** in [`.agents/skills/`](.agents/skills) (symlinked into `.claude/skills/`) package
  common workflows. In Claude Code, run them as slash commands:

  | Command                       | What it does                                                 |
  | ----------------------------- | ------------------------------------------------------------ |
  | `/review-and-qa <PR\|branch>` | Reviews a change against this repo's checklist and writes a QA plan |
  | `/investigate <issue>`        | Root-causes a GitHub issue or bug report                     |
  | `/triage <issues>`            | Classifies and prioritises issues                            |
  | `/plan <task>`, `/implement`  | Plans a change, then carries out the approved plan           |
  | `/qa-engineer-unit`           | Writes unit tests the way this repo does                     |
  | `/run-sample`                 | Builds and launches JetNews in the iOS Simulator             |
  | `/release <version>`          | Maintainers: prepares a release                              |

  Other agents can follow the same `SKILL.md` files as instructions.
- Reports from these skills go to `claude-output/`, which is gitignored.
- Please run `/review-and-qa` on your branch before you open a pull request. It catches the
  things reviewers here look for first: `public` API changes, concurrency escape hatches and
  missing regression tests.
