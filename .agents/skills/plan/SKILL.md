---
name: plan
description:
  Use when asked to plan, design, or architect a solution, before writing implementation code
model: sonnet
effort: high
---

# Plan

Create an implementation plan for: $ARGUMENTS

## Current state

- Branch: !`git branch --show-current`
- Working tree: !`git status --short 2>/dev/null | head -20`

## Instructions

1. **Understand the request**: read the relevant files and the target's DocC `UserGuide.md`.
2. **Identify scope**: which targets and platforms change? Does any `public` API change, and is it
   source-breaking (which means a major version)?
3. **Design the approach**: prefer extending existing patterns. Keep to the target's async style
   (Combine publishers in `StoryblokClient`) and Swift 6 concurrency rules.
4. **Plan the tests**: what fails before the change and passes after it? Use payloads shaped like
   real API responses, and `assertMacroExpansion` for macro changes.

## Output format

```markdown
## Summary

[1-2 sentences describing what this plan achieves]

## Files to modify

| File                            | Change            |
| ------------------------------- | ----------------- |
| Sources/Target/File.swift       | Brief description |

## Public API impact

[None / additive / breaking: list new or changed declarations, and the CHANGELOG entry needed]

## Implementation steps

1. Step one
2. Step two

## Test plan

- [ ] Test case 1
- [ ] Test case 2

## Verification commands

\`\`\`bash
swift build --build-tests
swift test --skip-build --filter <Target>Tests
\`\`\`

## Risks / open questions

- Assumptions, unknowns, platform-specific concerns
```

## Output

Write the plan to `claude-output/plan-<identifier>.md`.

## Rules

- Keep the plan focused and actionable.
- Only include files that actually need changes.
- Verification commands must be real and runnable (see `AGENTS.md`). Run test targets one per
  process.
- If the requirements are unclear, ask before planning.
