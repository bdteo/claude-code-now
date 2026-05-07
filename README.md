# CodeNow Has Moved

This repository has moved to:

https://github.com/bdteo/code-now

The old `claude-code-now` repository is archived and kept only as a redirect for existing links.

Install from the new repository:

```bash
claude plugin marketplace add bdteo/code-now
claude plugin install code-now
```

For Codex, enable hooks first:

```toml
[features]
codex_hooks = true
```

Then add the new marketplace:

```bash
codex plugin marketplace add bdteo/code-now
```
