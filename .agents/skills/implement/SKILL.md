---
name: implement
description: Use when asked to implement, build, or code a change that has an approved plan
model: opus
effort: high
---

# Implement

Implement the approved plan: $ARGUMENTS

## Current state

- Branch: !`git branch --show-current`
- Working tree: !`git status --short 2>/dev/null | head -20`

## Instructions

1. **Follow the plan**: carry out the steps from the approved plan (e.g.
   `claude-output/plan-<id>.md`).
2. **Small diffs**: make one logical change at a time.
3. **No scope creep**: only implement what was planned.
4. **Verify as you go**: build and run the affected target's tests after each meaningful change.

## Rules

- Don't add package dependencies unless the plan says to.
- Don't refactor unrelated code.
- Keep declarations `internal` unless the plan makes them `public`. New public API gets DocC
  comments, the package's `@available` annotation where its neighbours have one, and a
  `CHANGELOG.md` entry under `**main**`.
- Compile cleanly in Swift 6 mode. Don't silence concurrency diagnostics with `@unchecked Sendable`
  or `nonisolated(unsafe)` without a comment explaining why it's safe.
- Preserve the existing code style and patterns.

## Output format

```markdown
## Changes made

| File                      | Change       |
| ------------------------- | ------------ |
| Sources/Target/File.swift | What changed |

## Verification

\`\`\`bash
# Commands run and their results
\`\`\`

## Notes

- Any deviations from the plan (with justification)
- Any follow-up items discovered
```

## Post-implementation checklist

- [ ] All planned changes completed
- [ ] Builds without new warnings: `swift build --build-tests`
- [ ] Tests pass, one target per process: `swift test --skip-build --filter <Target>Tests`
- [ ] DocC and `UserGuide.md` updated for public API changes
- [ ] `CHANGELOG.md` updated for user-facing changes
