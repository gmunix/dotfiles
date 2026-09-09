---
name: setup-project
description: Initialize or update confirmed project context under ~/.agent-context without writing into the repository. Use only when the user explicitly asks to set up project context.
disable-model-invocation: true
---

# Setup Project

Create a stable identity and external context for the current project. Do not write anything until the user approves an exact preview.

## Context Layout

Store context under `~/.agent-context/projects/<project-id>/`. Prefer a portable project ID with path segments such as `github.com/owner/repository`.

Create entries lazily:

- `identity.json`: required confirmed identity.
- `context.md`: optional durable project facts and instructions.
- `tracker.md`: optional tracker location, terminology, and publication instructions.
- `writing.md`: optional writing style and document conventions.
- `snapshots/`: optional point-in-time tracker exports; snapshots are never synchronized back automatically.

Never create a repository file that points to this directory. Clones and worktrees share context by resolving to the same confirmed project ID.

## 1. Inspect Without Writing

Confirm the working directory is the intended project. For a Git repository, inspect:

```sh
git rev-parse --show-toplevel
git rev-parse --git-common-dir
git remote -v
```

Normalize remote URLs only to propose an identity:

- Treat SSH and HTTPS forms of the same host, owner, and repository as equivalent.
- Remove protocol, credentials, SSH separators, and a trailing `.git`.
- Do not assume `origin` is authoritative.
- If the remotes identify exactly one logical repository, recommend `<host>/<owner>/<repository>`.
- If remotes are missing or identify multiple repositories, ask the user for the project ID. Never infer it from the directory or branch name.

Even an unambiguous recommendation is not confirmed until the user accepts it. Reject empty IDs, absolute paths, `.` or `..` segments, and segments containing characters outside letters, numbers, `.`, `_`, and `-`.

## 2. Check Existing Context

Inspect the proposed context directory and `identity.json` if they exist.

- Reuse an existing context only when its recorded `project_id` exactly matches the confirmed ID.
- If the directory records a different identity, stop and ask the user to choose another ID or resolve the conflict.
- Preserve existing context. Do not replace optional files unless the user asked to update them.
- Never read or copy credentials, sessions, caches, or trust records into project context.

The required identity document has this shape:

```json
{
  "schema_version": 1,
  "project_id": "github.com/owner/repository",
  "repository": "github.com/owner/repository"
}
```

Set `repository` to the normalized logical repository when one was confirmed from remotes; otherwise use `null`.

## 3. Gather Optional Context

Ask only for information the environment cannot provide. Offer the optional files independently instead of creating empty placeholders.

- `context.md`: stable domain facts, important commands, and project constraints.
- `tracker.md`: tracker URL or project key, vocabulary, and instructions for publishing snapshots.
- `writing.md`: audience, tone, formatting, and documentation conventions.

Tracker data is one-way: a later workflow may write a dated file under `snapshots/`, but must not treat snapshots as live synchronization or publish changes without approval.

## 4. Preview And Confirm

Before any mutation, show:

1. The confirmed project ID and normalized repository, if any.
2. The exact destination under `~/.agent-context/projects`.
3. Every directory and file that would be created or updated.
4. The full proposed contents for new files and a diff for existing files.
5. A statement that no repository files and no chezmoi source files will change.

Ask for one explicit confirmation of that preview. If the user changes the identity or content, recompute the preview and ask again.

## 5. Apply And Verify

After confirmation, create only the approved directories and files. Write `identity.json` first, then optional context. Do not create `snapshots/` until a snapshot is requested.

Read the resulting files back and report:

- The confirmed project ID.
- The context path.
- Files created or updated.
- Optional files intentionally left absent.

Do not commit or publish runtime context.
