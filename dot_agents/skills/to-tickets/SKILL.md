---
name: to-tickets
description: Break a plan, spec, or the current conversation into canonical external tracer-bullet tickets, each declaring its blocking edges, with optional separately approved tracker publication.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

## Resolve Context

Inspect the Git root and all remotes without writing. Normalize remote URLs by removing protocol, credentials, SSH separators, and a trailing `.git`, so equivalent SSH and HTTPS remotes produce `<host>/<owner>/<repository>`.

Resolve identity in this order:

1. If the user explicitly identifies an existing project ID for this session, use that candidate.
2. Otherwise, use a remote-derived candidate only when all remotes identify exactly one logical repository.

Before constructing a path, reject an empty candidate, an absolute path, `.` or `..` segments, or segments containing characters outside letters, numbers, `.`, `_`, and `-`. Resolve `~/.agent-context/projects` and every existing candidate ancestor first; reject a symlinked candidate directory or `identity.json`, and require the resolved candidate to remain beneath the resolved projects directory. Only then inspect `~/.agent-context/projects/<candidate>/identity.json`. Require `schema_version` to be `1` and `project_id` to equal the candidate exactly. For a remote-derived candidate, require a non-null `repository` that equals that candidate. For an explicitly selected candidate, allow missing or conflicting remotes; when normalized remote identities are available and `repository` is not `null`, require it to match at least one of them. The verified project directory is `<resolved-context>`.

If any check fails, stop and direct the user to explicitly invoke `setup-project`. Never infer identity from a path, branch, repository name, missing record, or custom ID.

Before reading or writing any context path, resolve every existing ancestor, reject symlinks at destinations, and verify every resolved path remains beneath `<resolved-context>`. Repeat this containment check immediately before mutation.

Read existing optional context from `<resolved-context>/context.md`, `<resolved-context>/writing.md`, and `<resolved-context>/tracker.md` when present. Read domain material lazily from `<resolved-context>/domain/CONTEXT.md` and the ADRs under `<resolved-context>/domain/adrs/` that are relevant to the feature. Absence is valid and does not trigger creation. Reading vocabulary and decisions is passive context gathering; it does not invoke `domain-modeling`.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Each ticket has observable acceptance criteria that can be satisfied independently by that ticket
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand-contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket; green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Prepare canonical ticket files

The canonical destination is `<resolved-context>/tickets/<feature-slug>/<NN>-<ticket-slug>.md`: one artifact per ticket, numbered from `01` in dependency order with blockers first. Create `tickets/` and the feature directory only after the write is approved. Feature and ticket slugs must each be one valid path segment using only letters, numbers, `.`, `_`, and `-`.

Each file's **Blocked by** entry lists the numbers and titles it depends on. Every canonical ticket contains the internal `Status: ready-for-agent`. This status is canonical planning metadata, not a request to mutate a remote tracker.

Never write tickets, pointers, or mirrors into the source repository. Never combine tickets into one artifact.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective, not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Observable acceptance criterion 1, independently satisfiable by this ticket
- [ ] Observable acceptance criterion 2, independently satisfiable by this ticket

</local-ticket-template>

In canonical artifacts, avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

### 6. Preview and write canonical tickets

Do not mutate files while gathering, exploring, drafting, or quizzing. Show:

1. Every exact canonical destination and directory to create.
2. The full proposed content of every new file, or the complete diff for every existing file.
3. The dependency order and explicit blocking edges.
4. A statement that no ticket, pointer, or mirror will be written to the source repository.

Ask for explicit confirmation of that exact local preview. Immediately before writing, repeat **Resolve Context** against the current Git root and remotes, revalidate `identity.json`, and re-read every destination and context file used to draft the tickets. Recheck destination and context baselines, resolved containment, duplicate ticket scope, and the dependency graph. Require unique destinations, numbers, and slugs; require every blocker to resolve to exactly one ticket; reject self, missing, duplicate, or cyclic blocking edges; and require numbering to be topological. Preserve existing canonical ticket numbers and publication mappings rather than renumbering or remapping them.

Stage and verify the complete approved ticket set before exposing it. Create a new feature directory by exclusive atomic rename. For updates, use a previewed write-ahead transaction record and conditional replacements tied to each approved content hash and file identity; mark the transaction complete only after every destination verifies. On any failure, stop, preserve the record, report the exact written subset, and require recovery plus a fresh preview before treating the set as authoritative. If identity, remotes, a baseline, source decision, blocker, duplicate finding, or number changed, or any conditional operation fails, do not continue with the original approval.

Local approval does not imply approval for tracker publication.

### 7. Optionally publish tickets to the configured tracker

Tracker publication is optional and separately confirmation-gated. It is available only when `<resolved-context>/tracker.md` explicitly configures a tracker and publication instructions; never infer a tracker from Git remotes. Canonical external ticket files remain authoritative, and publication is a point-in-time snapshot, never bidirectional synchronization.

Publish approved tickets in dependency order, blockers first, so blocking edges can reference returned remote identifiers. Work the **frontier**: a ticket is eligible only when every blocker is publication-complete, with its remote ID and every approved inbound blocking relationship verified and recorded in the receipt. Preview and approve one frontier at a time, after payloads contain concrete blocker IDs. Approve blocking-relationship operations only after both endpoint IDs exist. Any failed or indeterminate mutation stops the frontier and leaves its ticket incomplete. Use the platform's native blocking relationship where available; otherwise include remote references in each ticket's **Blocked by** section.

Do NOT close or modify any parent issue, and do not create parent/sub-issue relationships.

Derive and display a desired remote projection for each canonical ticket according to `tracker.md`; exclude internal readiness and include approved tracker-only parent and blocker references. Compare that projection rather than the canonical file directly. Before each create, search prior receipts and the tracker for an existing mapping or plausible duplicate. If that search is indeterminate, record the uncertainty and stop. Before republishing a linked item, make a field-by-field three-way comparison of its desired projection, the selected latest matching receipt, and the current remote, including title, body, comments, native blocking relationships, and parent/sub-issue relationships. Record comments read-only with their IDs, authors, timestamps, and bodies. Classify each difference as canonical-only, remote-only, or divergent, and require the user to choose explicitly whether to leave the remote unchanged, publish the canonical projection, first revise the canonical ticket through its local preview gate, or abort. Never silently merge, pull, overwrite, or push a difference.

For each frontier, show the exact ordered remote operations and full payloads, together with the exact path and full initial content of a pending write-ahead receipt. Use `<resolved-context>/snapshots/<UTC-timestamp>-<feature-slug>-<random-suffix>.md`, with a freshly generated suffix and exclusive creation, so the receipt path cannot collide. The explicit remote-operation approval also approves creating this previewed pending receipt and making only factual status/result updates to it.

Create and read back the pending receipt before the frontier's first remote mutation. It must contain canonical source paths and content hashes, desired remote projections, preserved ticket-number and remote mappings, identity and publication baselines, selected prior receipt, reconciliation decisions, ordered approved operations and payloads, and a pending status for each operation. Immediately before every remote mutation, re-run identity/remotes and containment validation and re-read `tracker.md`, the affected canonical ticket, the selected latest matching receipt, and the current remote title, body, comments, native blocking relationships, and parent/sub-issue relationships. Before a create, repeat the mapping and duplicate search in place of reading a known remote item. Abort and re-preview the frontier on any baseline drift or newly found mapping or duplicate; if the search is indeterminate, record that result and stop.

After each operation, immediately update and read back the receipt with its status, exact payload, response or error, returned ID and URL, and observed remote state. If receipt persistence or verification fails, stop all further remote operations. If a create response omits its ID or URL, resolve it through a read-only lookup or record the unresolved outcome and stop. If any create outcome is indeterminate, record it and stop; never retry blindly.

Allowed publication mutations are only: create an item, update the explicitly identified non-parent item's approved title/body, and create an approved blocking relationship. Never close, reopen, delete, replace, transfer, comment, edit comments, or remove relationships without a separate explicit request and approval. Never mutate an item that has sub-issues or the referenced parent issue, and never create parent/sub-issue relationships. A ticket may still contain a body reference to its parent. Never create, apply, rename, or require remote labels, states, or custom fields. Internal readiness, including `ready-for-agent`, must never be published.

Use this shape for a remote issue payload unless `tracker.md` requires another one:

<issue-template>

## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective, not layer-by-layer implementation.

## Acceptance criteria

- [ ] Observable criterion 1, independently satisfiable by this ticket
- [ ] Observable criterion 2, independently satisfiable by this ticket

## Blocked by

- A reference to each blocking ticket, or "None (can start immediately)".

</issue-template>

Keep the receipt as the durable publication snapshot, including represented blocking relationships and all observed remote state. Do not mutate `tracker.md` as an index.
