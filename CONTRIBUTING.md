---
name: Contribution guide
about: Guidelines for contributing to temporal-debug-skill
---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Make changes to `skills/temporal-debug/SKILL.md`
4. Test with your agent
5. Submit a PR

## Skill Design Principles

- **No tools required** - Agents already have `git`, `grep`, `read`, `diff`
- **Minimal surface** - Only bridge the gap: fuzzy time → commit, worktree lifecycle
- **Platform agnostic** - Works with any git repo, any language, any agent
- **Safe by default** - Never touches user's working directory, always cleans up

## Testing

```bash
# Clone into your agent's skills directory
git clone https://github.com/MeherBhaskar/temporal-debug-skill.git skills/temporal-debug-skill
# Test with your agent
```