---
name: to-tickets
description: Break a plan, spec, or the current conversation into canonical external tracer-bullet tickets, each declaring its blocking edges, with optional separately approved tracker publication.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

Resolve an already-confirmed `<resolved-context>` using the `setup-project` identity contract. If it is unavailable or ambiguous, tell the user to invoke `setup-project`. Read relevant optional external context and domain files from `<resolved-context>` when present.

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
- Each ticket has independently observable acceptance criteria
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

### 5. Write the canonical tickets

Write one file per ticket under `<resolved-context>/tickets/<feature-slug>/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below: one ticket per file, never a single combined file.

Before writing, show every exact destination and the full proposed content, then get explicit confirmation. Write only the canonical external tickets; do not write pointers or mirrors in the source repository.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective, not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Observable acceptance criterion 1, independently satisfiable by this ticket
- [ ] Observable acceptance criterion 2, independently satisfiable by this ticket

</local-ticket-template>

### 6. Optionally publish tickets to the configured tracker

Publish only when `<resolved-context>/tracker.md` configures a remote tracker, and only after separate explicit approval of the remote payloads and operations. Canonical external ticket files remain authoritative.

Publish approved tickets in dependency order, blockers first, so blocking edges can reference returned remote identifiers. Work the **frontier**: a ticket is eligible only when every blocker has been published and its remote ID is known.

Do NOT close or modify any parent issue, and do not create parent/sub-issue relationships.

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

Store returned remote IDs/URLs and published payloads in a dated receipt under `<resolved-context>/snapshots/`. Before updating an already linked remote item, fetch it, including comments, compare it with the prior receipt and canonical ticket, and surface differences for manual reconciliation. Never silently synchronize.

`ready-for-agent` is internal and must not be published as a remote label, state, or field. Never create tracker labels, states, or custom fields.

In either form, avoid specific file paths or code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.
