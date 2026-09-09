# Domain ADR Format

This reference defines the expected document format and summarizes its creation checklist. `SKILL.md` remains authoritative if its qualification, duplicate detection, preview, confirmation, or write rules differ.

The destination is `<resolved-context>/domain/adrs/NNNN-short-slug.md`.

## Qualification

As required by `SKILL.md`, create an ADR only when all three conditions hold:

1. Reversing the decision would be meaningfully costly.
2. The outcome would be surprising without its history.
3. The decision resolves a genuine tradeoff among alternatives.

## Shape

```md
# {Concise decision title}

{In one to three sentences, state the context, the decision, and why it won the tradeoff.}
```

Add `Status`, `Options`, or `Consequences` sections only when that information helps a future reader understand or revisit the decision.

## Naming

Inspect the existing ADR filenames and increment the highest four-digit number, starting at `0001` when none exist. Use a short lowercase hyphenated slug, then recheck that the complete destination does not collide before writing.
