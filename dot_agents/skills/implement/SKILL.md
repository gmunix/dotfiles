---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement exactly one approved canonical ticket from `<resolved-context>/tickets/...`.

Resolve an already-confirmed `<resolved-context>` using the `setup-project` identity contract. If it is unavailable or ambiguous, tell the user to invoke `setup-project`. Read the ticket's full contents, any spec it references, `<resolved-context>/context.md`, and relevant material under `<resolved-context>/domain/` when present.

Before editing, agree with the user on the implementation scope, resolve any open questions, and agree the test seams, then capture the starting `HEAD` and working-tree status. Preserve and exclude pre-existing unrelated changes from the review and commit; if the ticket overlaps them, stop and ask before editing. Do not begin implementation until the ticket, scope, and seams are confirmed.

Load the `tdd` skill where possible, at the pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, load the `code-review` skill to review the ticket's committed and working-tree changes since the captured starting state against the canonical ticket/spec. Fix its findings, rerun the relevant focused checks, and run the full test suite again if fixes changed code after the final full-suite run.

Set the ticket's **Status** to `in-progress` when implementation starts. Statuses (`ready-for-agent`, `in-progress`, `done`) are internal and never published.

Commit your work to the current branch. Never push it.

## Close out

The canonical ticket and spec must let a fresh agent continue without this conversation. After committing:

1. Set the ticket's **Status** to `done` and append a `## Completion notes` section: the commit(s), deviations from the ticket or spec and why, how it was verified, and remaining risks.
2. Copy any caveat that affects a later ticket into that ticket under `## Notes from <NN>`.
3. If a decision changed during implementation, amend the spec so it states the current decision.
4. When `<resolved-context>/tracker.md` configures a remote tracker and the ticket was published, draft a comment for its remote item with the completion notes. Post it only after explicit approval, unless `tracker.md` grants standing authorization. Leave the remote item open; it closes when the branch merges.

Show the close-out edits to the user in the final report.
