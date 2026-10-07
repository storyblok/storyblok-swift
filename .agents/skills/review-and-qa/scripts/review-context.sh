#!/usr/bin/env bash
# Collect everything a review needs up front, so the reviewer starts from the facts rather than
# rediscovering them.
#
# Usage:
#   review-context.sh                  # current branch + uncommitted changes vs origin/main
#   review-context.sh 42               # pull request (also #42 or a github.com PR URL)
#   review-context.sh my-branch        # local or origin branch vs origin/main
#   review-context.sh abc1234          # a single commit
#   review-context.sh main~3..main     # a commit range
#
# Prints a summary to stdout and writes the full diff to claude-output/review-<id>.diff.

set -euo pipefail

# Under pipefail, a reader that exits early (grep -q, head) makes the writer die of SIGPIPE on large
# input, and the whole pipeline then reports failure: a match reads as no match, or set -e aborts.
# These helpers never close a pipe early.
changed_has() { grep -qE "$1" <<< "$changed"; }   # does any changed path match the regex?
first() { awk -v n="$1" 'NR <= n'; }              # like head -n, but reads all of its input

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
OUT_DIR="claude-output"
mkdir -p "$OUT_DIR"

target="${1:-}"
pr=""
head_ref=""
worktree_mode=false
untracked=""

git fetch -q origin main 2>/dev/null || echo "warning: could not fetch origin/main, using the local copy" >&2

if [[ "$target" =~ ^#?([0-9]+)$ ]] || [[ "$target" =~ /pull/([0-9]+) ]]; then
  pr="${BASH_REMATCH[1]}"
  id="pr-$pr"
  base_branch="$(gh pr view "$pr" --json baseRefName --jq .baseRefName)"
  git fetch -q origin "pull/$pr/head" "$base_branch"
  head_ref="$(git rev-parse FETCH_HEAD)"
  base="$(git merge-base "origin/$base_branch" "$head_ref")"
  if [[ "$base" == "$head_ref" ]]; then
    # Merged with a merge commit, so the head is already in the base branch and the range is empty.
    # Compare against the base branch as it was before the merge instead.
    merge_oid="$(gh pr view "$pr" --json mergeCommit --jq '.mergeCommit.oid // empty')"
    if [[ -n "$merge_oid" ]]; then
      base="$(git merge-base "$merge_oid^1" "$head_ref")"
    else
      echo "warning: the PR head is already in $base_branch, so the diff is empty" >&2
    fi
  fi
elif [[ -z "$target" ]]; then
  worktree_mode=true
  head_ref="HEAD"
  base="$(git merge-base origin/main HEAD)"
  id="$(git branch --show-current | tr '/' '-')"
  id="${id:-detached-$(git rev-parse --short HEAD)}"
elif [[ "$target" == *..* ]]; then
  base="$(git rev-parse "${target%%..*}")"
  head_ref="$(git rev-parse "${target##*..}")"
  id="range-$(git rev-parse --short "$base")-$(git rev-parse --short "$head_ref")"
elif git show-ref --verify -q "refs/heads/$target" || git show-ref --verify -q "refs/remotes/origin/$target"; then
  git show-ref --verify -q "refs/heads/$target" && head_ref="$target" || head_ref="origin/$target"
  base="$(git merge-base origin/main "$head_ref")"
  id="$(echo "$target" | tr '/' '-')"
elif git rev-parse --verify -q "$target^{commit}" >/dev/null; then
  head_ref="$(git rev-parse "$target")"
  base="$(git rev-parse "$target^")"
  id="commit-$(git rev-parse --short "$target")"
else
  echo "error: '$target' is not a PR number, branch, commit or range" >&2
  exit 1
fi

in_head=false
if ! $worktree_mode; then
  if git merge-base --is-ancestor "$head_ref" HEAD 2>/dev/null; then
    in_head=true
  elif [[ -n "$pr" ]]; then
    merge_oid="$(gh pr view "$pr" --json mergeCommit --jq '.mergeCommit.oid // empty' 2>/dev/null || true)"
    [[ -n "$merge_oid" ]] && git merge-base --is-ancestor "$merge_oid" HEAD 2>/dev/null && in_head=true
  fi
fi

if $worktree_mode; then
  diff_args=("$base")
else
  diff_args=("$base" "$head_ref")
fi

diff_file="$OUT_DIR/review-$id.diff"
git diff -U5 "${diff_args[@]}" > "$diff_file"
changed="$(git diff --name-only "${diff_args[@]}")"
if $worktree_mode; then
  # New files are part of the change too, but git diff only sees tracked ones.
  untracked="$(git ls-files --others --exclude-standard)"
  while IFS= read -r f; do
    if [[ -L "$f" ]]; then
      printf 'new symlink: %s -> %s\n' "$f" "$(readlink "$f")" >> "$diff_file"
    elif [[ -f "$f" ]]; then
      git diff --no-index -U5 /dev/null "$f" >> "$diff_file" || true
    fi
  done <<< "$untracked"
  [[ -n "$untracked" ]] && changed="$(printf '%s\n%s' "$changed" "$untracked" | sed '/^$/d')"
fi

echo "# Review context: $id"
echo
echo "- Base: $(git log -1 --format='%h %s' "$base")"
if $worktree_mode; then
  echo "- Head: working tree on $(git branch --show-current) ($(git status --short | wc -l | tr -d ' ') uncommitted paths)"
else
  echo "- Head: $(git log -1 --format='%h %s' "$head_ref")"
  echo "- Read files at head with: git show \"$(git rev-parse --short "$head_ref"):<path>\" (keep the quotes; zsh mangles an unquoted \$var:path)"
  $in_head && echo "- This change is already contained in the checked-out HEAD ($(git branch --show-current)). Review it as merged code; host tests can run as is."
fi
echo "- Full diff: $diff_file ($(wc -l < "$diff_file" | tr -d ' ') lines)"

if [[ -n "$pr" ]]; then
  echo
  echo "## Pull request"
  echo
  gh pr view "$pr" --json title,author,url,isCrossRepository,headRefName,state,mergedAt,mergeCommit \
    --template '- Title: {{.title}}
- Author: @{{.author.login}}
- URL: {{.url}}
- Branch: {{.headRefName}}{{if .isCrossRepository}} (from a fork){{end}}
- State: {{.state}}{{if .mergedAt}}, merged {{.mergedAt}} as {{.mergeCommit.oid}}{{end}}
'
  echo
  echo "### Description"
  echo
  gh pr view "$pr" --json body --jq .body
  echo
  echo "### CI checks"
  echo
  checks="$(gh pr checks "$pr" 2>/dev/null || true)"
  if [[ -z "$checks" ]]; then
    echo "- (no checks reported)"
  else
    echo "$checks" | awk -F'\t' '{n[$2]++} END {for (k in n) printf "- %s: %d\n", k, n[k]}' | sort
    echo "$checks" | awk -F'\t' '$2 != "pass" && $2 != "skipping" {print "  - " $2 ": " $1}'
  fi
fi

echo
echo "## Commits"
echo
git log --format='- %h %s (%an <%ae>)' "$base..$head_ref"
if $worktree_mode && [[ -n "$(git status --short)" ]]; then
  echo "- (plus uncommitted changes)"
fi

echo
echo "## Changed files"
echo
git diff --stat=200,160 "${diff_args[@]}" | sed 's/^/    /'
if $worktree_mode && [[ -n "$untracked" ]]; then
  echo "$untracked" | sed 's/^/    (new, untracked) /'
fi

# --- repo-specific: storyblok-swift ----------------------------------------------------------

targets="URLSessionExtension StoryblokClient StoryblokClientMacros RichTextView"
touched=""
for t in $targets; do
  if changed_has "^(Sources/$t/|Tests/${t}Tests/)" ||
     { [[ "$t" == StoryblokClientMacros ]] && changed_has '^Tests/StoryblokClientMacroTests/'; }; then
    touched="$touched $t"
  fi
done
package_changed=$(grep -E '^Package\.(swift|resolved)$' <<< "$changed" || true)

echo
echo "## Affected areas"
echo
for t in $touched; do echo "- $t"; done
changed_has '^Examples/' && echo "- Examples (live-API docs snippets)"
changed_has '^Samples/JetNews/' && echo "- Samples/JetNews (builds against this working copy)"
[[ -n "$package_changed" ]] && echo "- package manifest:" && echo "$package_changed" | sed 's/^/  - /'
changed_has '^(\.github/|\.swiftpm/)' && echo "- CI workflows / shared schemes"

echo
echo "## Flags"
echo
for t in $targets; do
  if changed_has "^Sources/$t/.*\.swift$"; then
    test_dir="Tests/${t}Tests/"; [[ "$t" == StoryblokClientMacros ]] && test_dir="Tests/StoryblokClientMacroTests/"
    changed_has "^$test_dir" || echo "- $t: sources changed without test changes."
  fi
done
public_lines=$(grep -cE '^[-+]([^-+].*)?\b(public|open)\b' "$diff_file" || true)
if [[ "$public_lines" -gt 0 ]]; then
  echo "- $public_lines added/removed lines mention \`public\`/\`open\`. There is no ABI checker, so review each one as an API change:"
  grep -nE '^[-+]([^-+].*)?\b(public|open)\b' "$diff_file" | first 12 | sed 's/^/  - /'
  changed_has '\.docc/' || echo "- Public API lines changed but no DocC catalog (.docc) changed."
fi
if [[ -n "$touched" ]] && ! changed_has '^CHANGELOG.md$'; then
  echo "- CHANGELOG.md not updated."
fi
[[ -n "$package_changed" ]] && echo "- Package.swift/Package.resolved changed. Check version ranges (swift-syntax spans majors 602..<605), platforms and the swift-tools-version."
grep -nE '^\+.*(@unchecked Sendable|nonisolated\(unsafe\)|@preconcurrency)' "$diff_file" | first 5 | sed 's/^/- New concurrency escape hatch: /' || true
grep -nE '^\+.*(try!|as!|fatalError\(|print\()' "$diff_file" | grep -v '^[0-9]*:+++ ' | first 5 | sed 's/^/- New try!\/as!\/fatalError\/print: /' || true
grep -nE '^\+.*(TODO|FIXME)' "$diff_file" | first 5 | sed 's/^/- New TODO: /' || true

echo
echo "## Suggested verification (host only; CI covers iOS, tvOS and watchOS)"
echo
filters=""
for t in $touched; do
  case "$t" in
    StoryblokClientMacros) filters="$filters StoryblokClientMacroTests StoryblokClientTests" ;;
    *) filters="$filters ${t}Tests" ;;
  esac
done
[[ -n "$package_changed" && -z "$filters" ]] && filters=" URLSessionExtensionTests StoryblokClientTests StoryblokClientMacroTests RichTextViewTests"
filters=$(echo $filters | tr ' ' '\n' | awk 'NF && !seen[$0]++' | tr '\n' ' ')
if [[ -n "$filters" ]]; then
  echo "    swift build --build-tests"
  for f in $filters; do echo "    swift test --skip-build --filter $f"; done
  echo "  (one target per process: two suites bootstrap swift-log)"
  if $worktree_mode || $in_head; then
    echo "  (the checked-out code contains the change, so these can run as is)"
  else
    echo "  (the code under review is not checked out; rely on CI unless asked to run it)"
  fi
else
  echo "- No package code changed. Nothing to run."
fi
