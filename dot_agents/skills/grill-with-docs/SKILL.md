---
name: grill-with-docs
description: Stress-test a plan and stage external domain documentation from the result.
disable-model-invocation: true
---

# Grill With Docs

Load `grilling` and `domain-modeling` through the harness's skill mechanism.

Let `grilling` exclusively own the dependency-aware frontier rounds and determine when the frontier is empty. Use `domain-modeling` during those rounds to read existing external domain documents, check terminology and scenarios against repository evidence, surface contradictions, qualify ADRs, and keep proposed documentation deltas staged in memory. Do not run a separate interview loop.

Do not write while any frontier question remains. Once the frontier is empty, use `grilling`'s final confirmation gate to present the staged domain mutations with `domain-modeling`'s exact destinations and full new content or diffs. Write only after the user explicitly confirms that preview, then verify the approved files. If no domain delta is warranted, confirm the shared understanding without creating files.
