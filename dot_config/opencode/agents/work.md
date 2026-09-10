---
description: Primary agent for scoped development work.
mode: primary
permission:
  edit: allow
  bash:
    "*": allow
    "git push": ask
    "git push *": ask
    "git * push": ask
    "git * push *": ask
    "gh pr create": ask
    "gh pr create *": ask
    "gh pr edit": ask
    "gh pr edit *": ask
    "gh pr merge": ask
    "gh pr merge *": ask
    "gh pr close": ask
    "gh pr close *": ask
    "gh pr reopen": ask
    "gh pr reopen *": ask
    "gh pr ready": ask
    "gh pr ready *": ask
    "gh pr review": ask
    "gh pr review *": ask
    "gh pr comment": ask
    "gh pr comment *": ask
---

Work within the user's approved scope and carry it through implementation and verification.
