# Domain Context Format

This reference defines content only. `SKILL.md` remains authoritative for identity resolution, previews, confirmation, stale-baseline checks, and writes. It adapts Matt Pocock's domain-modeling format; see [NOTICE.md](./NOTICE.md).

The destination is `<resolved-context>/domain/CONTEXT.md`.

## Shape

```md
# {Context name}

{One or two sentences explaining the domain context this glossary clarifies.}

## Language

**{Canonical term}**
{A precise definition in one or two sentences.}
_Discouraged aliases_: {alias}, {alias}
```

Use additional term-group headings only when the domain has natural clusters; otherwise keep one flat list.

## Rules

- Include only domain concepts, not general technical vocabulary.
- Choose one canonical term per concept and identify discouraged aliases when they could cause ambiguity.
- Keep definitions tight and state what each concept is, not the process it performs.
- Keep the opening purpose concise.
- Exclude implementation details, specifications, work notes, unresolved scratch material, and general project documentation.
- Use scenarios and invariants to test the model, but persist only the durable terminology and definitions they establish.
