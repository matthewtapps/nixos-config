# Global rules

## Character set

- Use ASCII only in all output, including chat, code, comments, commit messages, and
  docs; no emoji, smart quotes, en/em dashes, ellipses, or box-drawing characters.

## Banned phrasings

- These apply to everything you write: chat replies to me, code, comments, commit
  messages, docs, TODO entries, PR and MR descriptions. Treat each as a hard ban, and
  do not reach for a synonym or a different connective that restores the same shape.
- Never write that something "pays" or "costs" anything, in any inflection ("pays
  that", "the cost of", "costing"). Name the concrete effect: "adds 200 MB", "runs
  once per arch", "consumes registry storage".
- Never define a thing by contrast with the alternative. This covers "X rather than
  Y", "X instead of Y", "X, not Y" ("they are bans, not preferences"), and "not X but
  Y". Say what is true and drop the discarded half.
- Never name a thing by possessive plus "own" ("this repo's own jobs", "its own pin",
  "the base's own job"). Name the thing directly.
- Never write "actually bites", or a deferral note of any kind ("Defer until X",
  "revisit when Y", "until the cost is felt"). If it is not happening now, the
  trigger for doing it later is dev-diary noise.
- Never capitalise a word for emphasis ("the FIRST match", "does NOT follow",
  "baked THAT path"). Acronyms and identifiers keep their real casing. If a
  sentence seems to need the stress, rewrite it so it does not.
- Never announce a statement with a noun phrase and a colon ("The test for
  writing one:", "The catch:", "Key insight:", "The tradeoff:", "One thing to
  know:"). Say the thing directly as an ordinary sentence.
- Never count a set and then single out a member of it ("Three separate things,
  and one is a real bug", "Six findings, two of which are wrong", "Four options,
  and the first is best"). The count carries no information and the singling out
  usually misdescribes the rest. Name the things, or name the one that matters.
- Before sending a chat reply, and before reporting a change done, re-read what you
  wrote and rewrite every line that breaks one of these.

## Commit style

- Always use [Conventional Commits](https://www.conventionalcommits.org/) for git commit
  messages: a `type(optional scope): description` subject line (e.g. `feat:`, `fix:`,
  `docs:`, `chore:`, `refactor:`, `test:`, `build:`, `ci:`), with optional body and
  footer. Use `!` or a `BREAKING CHANGE:` footer for breaking changes.

## Comment style

- Default to no comments. The threshold for writing a comment should be, would a
  maintainer who does not know what you know about the config setting plausibly
  want to change or delete this line, and would that break something? If yes, add
  a comment that says what breaks in simple, concise english that conforms to all
  comment and phrasing standards. A line that only describes a reason fails this
  test, regardless of how interesting the reason is. Plain settings, values,
  flags, list entries, and thresholds will almost always fail the test.
- If you do comment:
    - Keep the comment extremely concise.
    - Phrase the comment towards future maintainers of the code.
    - Never comment only explaining what the code does.
    - Never comment why you chose this architecture over another.
    - Never comment for status or history ("no longer needed", "now handled by X").
    - Never warn against a design the code does not contain ("a follow here would
      rebuild X", "an overlay would break Y", "without this it would poll"). That
      documents the change you just made, and is dev-diary noise from the next
      commit onwards.
    - Delete any comment a reader could get from the line below it. If a test name,
      an assertion, or a variable name already says it, the comment adds nothing.
- Do not mirror the comment density of the surrounding code, it may predate these rules.
- If touching existing long comments, take the opportunity to clean them up while we're editing this code. Commit these as separate logical doc: commits.
- Only comment file headers when the file's role is not obvious from its path. File header comments should only be two sentences at most.
- Before reporting a change done, re-read every comment that you added and delete or rewrite any that do not conform to these rules.
