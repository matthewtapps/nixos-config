# Global rules

## Character set

- Use ASCII only in all output, including chat, code, comments, commit messages, and
  docs; no emoji, smart quotes, en/em dashes, ellipses, or box-drawing characters.

## Commit style

- Always use [Conventional Commits](https://www.conventionalcommits.org/) for git commit
  messages: a `type(optional scope): description` subject line (e.g. `feat:`, `fix:`,
  `docs:`, `chore:`, `refactor:`, `test:`, `build:`, `ci:`), with optional body and
  footer. Use `!` or a `BREAKING CHANGE:` footer for breaking changes.

## Comment style

- Default to no comments.
- If you do comment:
    - Keep the comment extremely concise.
    - Phrase the comment towards future maintainers of the code.
    - Never comment only explaining what the code does.
    - Never comment why you chose this architecture over another.
    - Never comment for status or history ("no longer needed", "now handled by X").
- Do not mirror the comment density of the surrounding code, it may predate these rules.
- If touching existing long comments, take the opportunity to clean them up while we're editing this code. Commit these as separate logical doc: commits.
- Only comment file headers when the file's role is not obvious from its path. File header comments should only be two sentences at most.
- Before reporting a change done, re-read every comment that you added and delete or rewrite any that do not conform to these rules.
