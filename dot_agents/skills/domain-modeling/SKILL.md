---
name: domain-modeling
description: Model a project's domain and maintain its external domain context. Use when clarifying domain concepts, terminology, scenarios, invariants, or qualifying architecture decisions.
---

# Domain Modeling

Build a precise domain model from repository evidence and user decisions. Keep all durable domain documentation outside the repository.

## Resolve Context

Inspect the Git root and all remotes without writing. Normalize remote URLs by removing protocol, credentials, SSH separators, and a trailing `.git`, so equivalent SSH and HTTPS remotes produce `<host>/<owner>/<repository>`.

Resolve identity in this order:

1. If the user explicitly identifies an existing project ID for this session, use that candidate.
2. Otherwise, use a remote-derived candidate only when all remotes identify exactly one logical repository.

Before constructing a path, reject an empty candidate, an absolute path, `.` or `..` segments, or segments containing characters outside letters, numbers, `.`, `_`, and `-`. Then inspect `~/.agent-context/projects/<candidate>/identity.json`. Require `schema_version` to be `1` and `project_id` to equal the candidate exactly. For a remote-derived candidate, require a non-null `repository` that equals that candidate. For an explicitly selected candidate, allow missing or conflicting remotes; when normalized remote identities are available and `repository` is not `null`, require it to match at least one of them. The verified project directory is `<resolved-context>`.

If any check fails, stop and direct the user to explicitly invoke `setup-project`. Never infer identity from a path, branch, repository name, missing record, or custom ID.

## Read And Model

Read general project facts from `<resolved-context>/context.md` when present. Read domain material lazily from `<resolved-context>/domain/CONTEXT.md` and `<resolved-context>/domain/adrs/`; absence is valid and does not trigger creation. When proposing glossary content, follow [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Use repository code and tests as evidence, not as automatic truth. During modeling:

- Maintain one glossary term for each concept and flag aliases, overloaded words, and inconsistent usage.
- Prefer precise domain language over implementation shorthand.
- Check every rule or invariant against concrete scenarios, including boundaries and failures.
- Surface contradictions between code behavior, existing domain documents, and proposed claims instead of silently choosing one.
- Separate observed facts, agreed rules, open questions, and implementation details.

An ADR qualifies only when the decision records a meaningful tradeoff, is hard or expensive to reverse, and would be surprising without its history. Do not create ADRs for routine implementation choices. Search existing ADRs by decision, not just title; update a matching record instead of creating a duplicate. For a new ADR, increment the highest existing four-digit number and use a short slug: `<resolved-context>/domain/adrs/NNNN-short-slug.md`. Follow [ADR-FORMAT.md](./ADR-FORMAT.md) for its content.

## Stage Mutations

Do not mutate domain files while exploring or while questions remain open. Prepare proposed changes in memory, then show every mutation with:

1. Its exact destination.
2. The full proposed content for a new file, or the complete diff for an existing file.
3. Any directories that must be created.

Ask for explicit confirmation of that exact preview. If anything changes, show a new preview and ask again. Immediately before writing, re-read every destination and the ADR directory, repeat duplicate-decision detection, and verify any proposed ADR number remains unused. If a preview baseline changed, regenerate the complete preview and obtain fresh confirmation. Otherwise write only the approved files and read them back to verify them.

The only domain destinations are `<resolved-context>/domain/CONTEXT.md` and qualifying ADRs under `<resolved-context>/domain/adrs/`. Never create repository documentation, repository pointers or mirrors, or duplicate ADRs elsewhere.
