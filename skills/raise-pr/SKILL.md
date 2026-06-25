---
name: raise-pr
description: >-
  Use whenever the user wants to ship the current branch for review — "raise a
  PR", "open a PR", "create a pull request", "push and open a PR", or similar.
  Analyses branch changes, follows the repo's PR template, and creates a
  succinct PR via the gh CLI, with an optional Cursor Bugbot review loop.
---

Raise a PR by:

1. Understand the substance of the change by:
  1. Looking at the commits in the current branch compared to main/master branch
  2. Looking at the diff between the current branch and main/master
2. Checking at .github/pull_request_template.md if there is a template to follow and if so following that template when raising the PR
  1. NOTE: If there is no template then just include a "What this PR does" heading and a "Manual testing steps" heading
3. Composing a PR message that follows the template and succinctly explains the changes being made. It is critical to keep the message
as succinct as possible!
  1. NOTE: When completing any "How to test", "Testing", or similar sections, ONLY include manual testing steps. Do NOT mention running unit tests as these are always covered by CI pipelines
4. Uses the gh CLI to raise the PR
5. Returns the link to the PR to the user
6. Asks the user (via `AskQuestion`) whether they want to run Cursor Bugbot review on the PR. If the user declines, stop here. If they accept, run the **Bugbot Review Cycle** below.

## Bugbot Review Cycle

Once the user opts in, repeat the following loop until Bugbot reports zero issues:

1. **Trigger Bugbot** — comment on the PR:
   ```
   gh pr comment <PR_NUMBER> --body "bugbot run"
   ```
2. **Poll for Bugbot response** — Bugbot leaves its findings as **review comments** on specific lines of code, not as regular PR comments. Wait 3 minutes, then check for reviews by `cursor[bot]`:
   ```
   gh pr view <PR_NUMBER> --json reviews --jq '.reviews[] | select(.author.login == "cursor[bot]")'
   ```
   If no review by `cursor[bot]` is found (or no new review since the last `bugbot run`), wait another 3 minutes and fetch again. Keep polling until a Bugbot review appears.
3. **Evaluate findings** — once a Bugbot review is detected, fetch **unresolved** review threads by `cursor[bot]`:
   ```
   gh pr view <PR_NUMBER> --json reviewThreads --jq '.reviewThreads[] | select(.comments[0].author.login == "cursor[bot]" and .isResolved == false)'
   ```
   Each review thread contains the file path, line number, and comment body describing the issue. If there are no unresolved threads, report a clean result to the user and stop.
4. **Fix reported issues** — for each valid bug in the unresolved threads:
   1. Read the relevant file(s)
   2. Apply the fix
   3. Create an atomic commit following conventional commit format (no amend)
   4. Push the commit(s)
5. **Resolve old threads** — after fixing and pushing, resolve each Bugbot review thread that was addressed using the GitHub GraphQL API:
   ```
   gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "<THREAD_ID>" }) { thread { isResolved } } }'
   ```
6. **Loop** — go back to step 1 and re-trigger Bugbot to verify the fixes.
