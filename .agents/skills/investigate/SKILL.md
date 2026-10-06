---
name: investigate
description: Use when asked to investigate, analyze, or dig into a GitHub issue or reported bug
model: opus
context: fork
agent: investigator
effort: high
---

# Investigate Issue

Investigate the following issue: $ARGUMENTS

## Instructions

### Phase 1: Fetch issue details

1. Parse the input:
   - `DX-123` or a `linear.app` URL → **Linear ticket**
   - `#123`, a bare number, or a `github.com` URL → **GitHub issue**
   - Anything else → a free-text bug description
2. Fetch the ticket:
   - **GitHub:** `gh issue view <number> --json title,body,labels,comments,author,createdAt,state`
   - **Linear:** `bash .agents/skills/triage/scripts/linear-fetch.sh issue DX-123`
3. Extract: error messages, crash logs, package version, Xcode/Swift version, OS and platform, and
   reproduction steps.

### Phase 2: Identify the affected target(s) and platform(s)

| Symptom                                                              | Likely target           |
| -------------------------------------------------------------------- | ----------------------- |
| Auth, region, rate limiting, backoff, `cv`, caching, raw `URLSession` | `URLSessionExtension`   |
| `StoryblokClient`, decoding, relations, `Story`/`Field` types        | `StoryblokClient`       |
| `@BlockLibrary` expansion errors, compiler diagnostics               | `StoryblokClientMacros` |
| Rich text rendering, images, links, accessibility                    | `RichTextView`          |

If it only happens on one platform, look for `#if os(...)`, `#if canImport(...)` and
`@available` branches first.

### Phase 3: Deep analysis

1. Search for the error message and the referenced symbols.
2. Trace the execution path from the public entry point to the reported behaviour.
3. Check recent changes: `git log --oneline -20 -- Sources/<Target>` and `CHANGELOG.md`. Was it a
   regression in a specific version?
4. Search for similar issues:
   `gh issue list --search "<keywords>" --state all --limit 10`.
5. Where it settles the question, reproduce with a temporary failing test (Swift Testing, Mocker
   for HTTP, or `assertMacroExpansion` for the macro) and run it with
   `swift test --filter <Target>Tests`.

### Phase 4: Root cause analysis

Categorise it: logic bug, API change, payload shape mismatch, concurrency or data race, platform
divergence, macro expansion bug, missing validation, configuration, or a documentation gap.

### Phase 5: Propose solutions

For each root cause, give the fix (file paths and line numbers), the regression test to add, any
`public` API impact (and whether it needs a major version), and the verification commands.

## Output

1. Extract an identifier from the arguments (issue `7` → `7`, ticket `DX-296` → `DX-296`, text →
   slugified).
2. `mkdir -p claude-output` and write `claude-output/investigate-<identifier>.md`.
3. Reply with a three-line summary and the report path.

### Output structure

```markdown
# Investigation: <title>

**URL:** | **Created:** | **State:** | **Author:** | **Package version:** | **Platforms:**

## Summary

## Affected target(s) (table: Target, Platform, Confidence, Evidence)

## Issue details (Reported behaviour, Expected behaviour, Environment, Reproduction steps)

## Code analysis (Relevant files table, Execution flow, Code snippets)

## Root cause (Category, Explanation, Evidence)

## Proposed solutions (Changes table, Code before/after, Tests to add, API impact, Verification)

## Similar issues

## Notes / Risks

## Next steps
```
