# Setup Cluster Language Action

GitHub Action to install and configure the official **Cluster Programming Language** compiler (`cl`), core runtime, and standard library on GitHub Actions runners.

## Supported Platforms
- `ubuntu-latest` (Linux x86_64 / ARM64)
- `macos-latest` (macOS Apple Silicon / Intel)
- `windows-latest` (Windows with Git Bash / MSYS2)

## Usage

```yaml
name: CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Cluster
        uses: cluster-lang/setup-cluster@v1
        with:
          version: '1.0.0'

      - name: Run Test Suite
        run: |
          cl test
          cl run src/main.cl
```

## Inputs

| Input | Description | Default |
| :--- | :--- | :--- |
| `version` | The toolchain release version to install | `'1.0.0'` |

## License
Managed by Mohammad Zaid / cluster under CCFL v2.0 Terms.
