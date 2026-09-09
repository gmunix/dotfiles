---
name: to-spec
description: "Turn the current conversation into a canonical external spec: no interview, just synthesis of what you've already discussed."
disable-model-invocation: true
---

# To Spec

This skill takes the current conversation context and codebase understanding and produces a spec. Do NOT interview the user; just synthesize what you already know. Surface unresolved product decisions instead of inventing answers or reopening a broad interview.

## Resolve Context

Inspect the Git root and all remotes without writing. Normalize remote URLs by removing protocol, credentials, SSH separators, and a trailing `.git`, so equivalent SSH and HTTPS remotes produce `<host>/<owner>/<repository>`.

Resolve identity in this order:

1. If the user explicitly identifies an existing project ID for this session, use that candidate.
2. Otherwise, use a remote-derived candidate only when all remotes identify exactly one logical repository.

Before constructing a path, reject an empty candidate, an absolute path, `.` or `..` segments, or segments containing characters outside letters, numbers, `.`, `_`, and `-`. Resolve `~/.agent-context/projects` and every existing candidate ancestor first; reject a symlinked candidate directory or `identity.json`, and require the resolved candidate to remain beneath the resolved projects directory. Only then inspect `~/.agent-context/projects/<candidate>/identity.json`. Require `schema_version` to be `1` and `project_id` to equal the candidate exactly. For a remote-derived candidate, require a non-null `repository` that equals that candidate. For an explicitly selected candidate, allow missing or conflicting remotes; when normalized remote identities are available and `repository` is not `null`, require it to match at least one of them. The verified project directory is `<resolved-context>`.

If any check fails, stop and direct the user to explicitly invoke `setup-project`. Never infer identity from a path, branch, repository name, missing record, or custom ID.

Before reading or writing any context path, resolve every existing ancestor, reject a symlink at the destination, and verify the resolved path remains beneath `<resolved-context>`. Repeat this containment check immediately before mutation.

Read existing optional context from `<resolved-context>/context.md`, `<resolved-context>/writing.md`, and `<resolved-context>/tracker.md` when present. Read domain material lazily from `<resolved-context>/domain/CONTEXT.md` and the ADRs under `<resolved-context>/domain/adrs/` that are relevant to the feature. Absence is valid and does not trigger creation. Reading vocabulary and decisions is passive context gathering; it does not invoke `domain-modeling`.

## Process

### 1. Gather and explore

Work from decisions already present in the conversation. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

### 2. Select test seams

Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

Check with the user that these seams match their expectations. This focused confirmation is required even though the rest of the skill is synthesis-only.

### 3. Draft the spec

Write the spec using the template below. The canonical destination is `<resolved-context>/specs/<feature-slug>.md`; create `specs/` only after the write is approved. The feature slug must be one valid path segment using only letters, numbers, `.`, `_`, and `-`. Never write a spec, pointer, or mirror into the source repository.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Acceptance Criteria

A checklist of observable outcomes for the feature as a whole. State what a user or external consumer can verify, not internal implementation steps.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)
- The user-confirmed test seam or seams

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature, including unresolved product decisions that require later resolution.

</spec-template>

### 4. Preview and write the canonical spec

Do not mutate files while exploring, selecting test seams, or drafting. Show:

1. The exact canonical destination and any directory to create.
2. The full proposed content for a new file, or the complete diff for an existing file.
3. A statement that no spec, pointer, or mirror will be written to the source repository.

Ask for explicit confirmation of that exact local preview. Immediately before writing, repeat **Resolve Context** against the current Git root and remotes, revalidate `identity.json`, and re-read the destination and every context file used to draft the spec. Recheck the destination and context baselines, slug, and resolved containment. Create a new destination exclusively; update an existing one only with a conditional replacement that still matches the approved content hash and file identity. If identity, remotes, a baseline, or a decision changed, or the conditional write fails, regenerate the complete preview and obtain fresh confirmation. Otherwise write only the approved canonical file and read it back to verify it.

Local approval does not imply approval for tracker publication.

### 5. Optionally publish a tracker snapshot

Tracker publication is optional and separately confirmation-gated. It is available only when `<resolved-context>/tracker.md` explicitly configures a tracker and publication instructions; never infer a tracker from Git remotes. The canonical external spec remains authoritative, and publication is a point-in-time snapshot, never bidirectional synchronization.

Derive and display a desired remote projection from the canonical spec according to `tracker.md`; compare that projection rather than the canonical file directly, so omitted internal content and tracker-only fields are explicit. Before each create, search prior receipts and the tracker for an existing mapping or plausible duplicate. If that search is indeterminate, record the uncertainty and stop. Before republishing a linked item, make a field-by-field three-way comparison of the desired projection, the selected latest matching receipt, and the current remote, including title, body, comments, native blocking relationships, and parent/sub-issue relationships. Record comments read-only with their IDs, authors, timestamps, and bodies. Classify each difference as canonical-only, remote-only, or divergent, and require the user to choose explicitly whether to leave the remote unchanged, publish the canonical projection, first revise the canonical spec through its local preview gate, or abort. Never silently merge, pull, overwrite, or push a difference.

Show the exact remote operations and full payloads, together with the exact path and full initial content of a pending write-ahead receipt. Use `<resolved-context>/snapshots/<UTC-timestamp>-<feature-slug>-<random-suffix>.md`, with a freshly generated suffix and exclusive creation, so the receipt path cannot collide. The explicit remote-operation approval also approves creating this previewed pending receipt and making only factual status/result updates to it.

Create and read back the pending receipt before the first remote mutation. It must contain the canonical source path and content hash, desired remote projection, identity and publication baselines, selected prior receipt, reconciliation decisions, ordered approved operations and payloads, and a pending status for each operation. Immediately before every remote mutation, re-run identity/remotes and containment validation and re-read `tracker.md`, the canonical spec, the selected latest matching receipt, and the current remote title, body, comments, native blocking relationships, and parent/sub-issue relationships. Before a create, repeat the mapping and duplicate search in place of reading a known remote item. Abort and re-preview on any baseline drift or newly found mapping or duplicate; if the search is indeterminate, record that result and stop.

After each operation, immediately update and read back the receipt with its status, exact payload, response or error, returned ID and URL, and observed remote state. Any failed or indeterminate mutation stops publication. If receipt persistence or verification fails, stop all further remote operations. If a create response omits its ID or URL, resolve it through a read-only lookup or record the unresolved outcome and stop. Never retry an indeterminate create blindly.

Allowed publication mutations are only: create an item, update the explicitly identified non-parent item's approved title/body, and create an approved blocking relationship. Never close, reopen, delete, replace, transfer, comment, edit comments, or remove relationships without a separate explicit request and approval. Never mutate an item that has sub-issues, modify a referenced parent issue, or create parent/sub-issue relationships. Use native blocking relationships when available; otherwise use body references. Never create, apply, rename, or require remote labels, states, or custom fields. Internal readiness, including `ready-for-agent`, must never be published. Do not mutate `tracker.md` as an index.
