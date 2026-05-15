# Git Commit Message Conventions

## Commit Message Rules

- Use the **imperative mood** (e.g., "Add feature", not "Added feature")
- Start with a **lowercase prefix** (e.g., `feat:`, `fix:`)
- Limit the **subject line to 50 characters** if possible
- Use a **blank line** before the body (if included)
- Use the body to explain **what and why**, not how
- Wrap body lines at **72 characters**
- Make commit's small and bundle files logically together for each commit

## Message Format

```
<prefix>: <subject>

<body>
```

## Common Prefixes (Conventional Commits)

| Prefix | Description |
|--------|-------------|
| `feat:` | A new feature for the user |
| `fix:` | A bug fix |
| `docs:` | Documentation only changes |
| `style:` | Changes that do not affect code behavior (formatting, etc.) |
| `refactor:` | Code changes that neither fix a bug nor add a feature |
| `perf:` | A code change that improves performance |
| `test:` | Adding or updating tests |
| `chore:` | Routine tasks or changes (build scripts, tools, config) |
| `ci:` | Changes to CI configuration and scripts |
| `build:` | Changes that affect the build system or dependencies |
| `revert:` | Reverts a previous commit |
| `repo:` | Changes to the repository itself |

## Multi-Line Body Guidelines

### When to Include a Body

- When the change is **not self-explanatory** from the subject alone
- When explaining the **motivation** behind the change
- When documenting **side effects** or related changes
- When providing **context** that future developers will need

### Body Format

- Separate the body from the subject with a **blank line**
- Wrap lines at **72 characters**
- Use bullet points for multiple related points
- Focus on **what** was changed and **why**, not how
