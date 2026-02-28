# Contributing to doomcr

Thanks for contributing.

## Development Setup

### Prerequisites

- [Crystal](https://crystal-lang.org/install/) >= 1.19.1 (using [mise](https://github.com/jdx/mise) is recommended)
- [Lefthook](https://github.com/evilmartians/lefthook) for git hooks (optional)

### Setup

```bash
shards install
shards build ameba
shards build hace
```

Optional git hooks:

```bash
lefthook install
```

## Common Commands

```bash
# Run specs
crystal spec

# Run one spec file
crystal spec spec/doomcr_spec.cr

# Format
crystal tool format

# Lint
bin/ameba

# Project task runner
bin/hace all
```

## Code Coverage

Coverage CI uses `run_specs.cr` with `kcov` and uploads to Codecov.

## Pull Requests

1. Create a branch for your change.
2. Add or update tests.
3. Run `bin/hace all`.
4. Open a PR with a concise summary of what changed and why.
