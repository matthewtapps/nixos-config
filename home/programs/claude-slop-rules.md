---
name: slop-rules
description:
  The general slop taxonomy - what content earns its place in any authored
  text and what ages badly. The shared base behind comment-rules and
  review-documentation.
---

## Slop standard

Every line you author is read later by someone who did not write it. A line
earns its place only when it carries context the surface itself cannot. Anything
else is slop: it ages badly, drifts out of date, and buries the lines that
matter.

Apply this standard to any authored text - a code comment, a doc, a merge
request or issue description. The consuming standards and skills name the
surface; this file names the slop.

### What earns its place

Keep the text sparse and additive. A line passes only when it tells a reader who
already knows the project something the surface does not say:

- a constraint, invariant, or assumption the surface relies on but cannot state.
- a genuine gotcha, edge case, or foot-gun.
- for a change description, what changed and why, and how to verify it.

### What counts as slop

Flag or cut a line that:

- restates its subject - the code, the diff, or the adjacent text.
- narrates history, like "changed X on 2026-05-01", "previously used Y", "added
  for #42", "why this branch exists", or "which MR this followed". Git commits,
  issues, and merge requests own history.
- duplicates content that already lives in a ticket, merge request, wiki, or
  another doc.
- is out of scope: it does not describe the change or help the reader act on it.
  Local-setup or environment detail, and a checks or test-output section that CI
  already runs and gates, both belong elsewhere.
- is stale or misleading, describing behaviour the subject no longer has.

Historical narration, duplicate content, and out-of-scope content are the
sharpest calls. They add the most bloat and are the hardest to manage later.

Less is more. Prefer cutting a line over reworking it to add meaning.

### Style of the lines that survive

A line that earns its place still has to read well. Write it in the Australian
Government Style Manual style slop-cop enforces:
`~/.claude/output-styles/agsm.md`. Do not flag identifiers, symbols, or API
names for spelling; match them as the surface spells them.
