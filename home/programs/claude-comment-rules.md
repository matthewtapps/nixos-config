---
name: comment-rules
description:
  What earns a code comment and what counts as slop. The shared standard behind
  review-code-comments, AGENTS.md, and any write-time check.
---

## Code comment standard

Good code needs few comments. A comment earns its place only when it carries
context the code cannot: an assumed constraint or a non-obvious gotcha.
Everything else is slop that ages badly and buries the comments that matter.

This standard specialises the general slop taxonomy for code comments: the base
categories all apply, and the code-specific rules below add to them. The base is
imported at the end of this file.

Apply this standard whenever you write, review, or generate a code comment.

### What earns a comment

Keep comments sparse and additive. A comment passes only when it tells a reader
who already knows the project something the code does not say:

- a constraint or invariant the code relies on but cannot express.
- a genuine gotcha, edge case, or foot-gun.

Do not match the surrounding comment density; it is not a quality benchmark.
Code that reads clearly on its own wants no comment.

### Code-specific slop

The base taxonomy applies in full. For code comments, read "restates its
subject" as restating the code, and add these code-only cases. Flag or remove a
comment that:

- restates the code, like `// increment i` above `i++`.
- is commented-out code; git history holds the old code.
- is a redundant docstring that only echoes the signature and parameter names.
- is noise or decoration: banner bars, an unowned `// TODO`, filler.
- is more than 2 lines long.

Less is more. Prefer deleting a comment over reworking it to add meaning.

The general slop taxonomy this builds on follows.

@~/.claude/standards/slop-rules.md
