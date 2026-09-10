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

Commit your work to the current branch. Never push it.
