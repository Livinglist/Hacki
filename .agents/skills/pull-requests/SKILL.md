---
name: pull-requests
description: Use when creating or updating a pull request in Hacki, including its title and description.
---

# Pull requests

Before creating or renaming a PR, inspect several recent human-authored PR
titles in this repository and follow their established pattern. Exclude bot
dependency updates when inferring the convention.

The current title pattern is `<type>: <short description>`:

- Use a lowercase type, such as `fix`, `feat`, or `chore`, matching the change.
- Start the description in lowercase, preserving proper names such as Flutter.
- Describe the final change concisely; do not use a sentence-style title without
  the type prefix or append a PR number.

Examples from existing PRs:

- `fix: use upstream stable tags for Flutter version bumps` (#940)
- `feat: enhanced navigation buttons` (#935)
- `chore: bump Flutter version to 3.50.0` (#934)

Write the description around the final behavior and relevant validation. When
the scope changes, update the title and description to match. Verify the saved
PR title follows the repository convention before reporting the PR link.
