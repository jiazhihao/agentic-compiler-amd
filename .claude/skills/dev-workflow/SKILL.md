---
name: dev-workflow
description: >-
  Mandatory development workflow for agentic-compiler-amd. Load before any code or docs
  change. Issue per task, branch + PR reviewed and merged by a human, keep the issue and
  the roadmap (#1) current.
---

# Development workflow

1. **GitHub issues are the source of truth.** Roadmap: #1, one sub-issue per phase.
   Work one issue at a time; record decisions, measurements, blockers and progress on
   the issue so another agent or developer can continue without the chat.
2. **No direct commits to `main`** (the initial bootstrap commit of the empty repo
   excepted). Every change goes on a branch `issue-N-<slug>` and reaches `main` through
   a PR that is reviewed (by Codex and a human) and merged by a human. Agents never merge, approve their own PR,
   enable auto-merge or force-push.
3. **Stacking.** Every PR is stackable. When a phase depends on a phase whose PR is not merged yet, branch
   from that PR's branch and open the new PR against it (`--base issue-M-<slug>`), so
   GitHub shows the stack. State the merge order in the PR body. When a PR below merges,
   merge `origin/main` into the branches above it.

## Per issue

```
git fetch origin
gh issue comment N --body "Starting: ... Branch: issue-N-<slug>."
git checkout -b issue-N-<slug> <base>       # main, or the PR branch below in the stack
# small commits; subject "<area>: <what> (#N)"; push early
make test
gh pr create --base <base> --title "<area>: <what> (#N)" --body-file -   # Closes #N / Part of #N
```

- PR body: `## What`, `## How verified` (tests, GPU numbers), `## Notes for the reviewer`.
- Tick the task boxes in the phase issue and in `docs/roadmap.md`; add the
  `docs/progress.md` entry in the same PR.
- New work discovered along the way gets its own issue (linked from the phase issue
  and added to the roadmap issue #1).
- Never report a fallback (e.g. the unmodified amdclang build) as a win; a speedup
  needs a passing battery and a paired timing whose CI separates.
