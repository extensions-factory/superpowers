# Minimal CI stubs (lint + test only)

Reference skeletons — adapt to the project's actual commands. The
`<install deps>` / `<lint command>` / `<test command>` tokens are
intentional fill-ins you replace per project; they are not literal.
Keep the stub minimal — the goal is a green baseline, not a full pipeline.

## GitHub Actions — `.github/workflows/ci.yml`

```yaml
name: ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: <install deps>
      - run: <lint command>
      - run: <test command>
```

## GitLab CI — `.gitlab-ci.yml`

```yaml
check:
  script:
    - <install deps>
    - <lint command>
    - <test command>
```
