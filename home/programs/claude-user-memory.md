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

- Keep your comments extremely concise.
- Only comment where necessary: When the reason for code is not clear from the code itself, or an outcome was unintuitive to arrive at.
- Phrase your comments so that they are aimed at future project maintainers.
- Never comment in a "dev diary" style, like "No longer need to start the network service" as a comment where code was deleted.
