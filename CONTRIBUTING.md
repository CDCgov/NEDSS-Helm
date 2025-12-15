# Welcome!
Thank you for contributing to CDC's Open Source projects! If you have any
questions or doubts, don't be afraid to send them our way. We appreciate all
contributions, and we are looking forward to fostering an open, transparent, and
collaborative environment.

Before contributing, we encourage you to also read or [LICENSE](https://github.com/CDCgov/template/blob/master/LICENSE),
[README](https://github.com/CDCgov/template/blob/master/README.md), and
[code-of-conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md)
files, also found in this repository. If you have any inquiries or questions not
answered by the content of this repository, feel free to [contact us](mailto:surveillanceplatform@cdc.gov).

## Development Guidelines

### Prerequisites

To contribute to this repository, you'll need:
- [Helm](https://helm.sh/docs/intro/install/) v3.x or later

### Testing Helm Charts

Before submitting a pull request with Helm chart changes, please ensure your charts pass linting:

**PowerShell:**
```powershell
# Lint a specific chart
helm lint charts/modernization-api

# Lint all charts
Get-ChildItem -Path charts -Directory | Where-Object { Test-Path "$($_.FullName)\Chart.yaml" } | ForEach-Object { helm lint $_.FullName }
```

**Bash/Zsh:**
```bash
# Lint a specific chart
helm lint charts/modernization-api

# Lint all charts
for chart in charts/*/; do [ -f "$chart/Chart.yaml" ] && helm lint "$chart"; done
```

All pull requests will automatically run `helm lint` via GitHub Actions. Charts must pass linting before they can be merged.

#### What is Helm Linting?

Helm linting validates that your Helm chart follows best practices and has no template errors. It checks:
- Valid YAML syntax
- Required Chart.yaml fields
- Template rendering without errors
- Values file structure

## Public Domain
This project is in the public domain within the United States, and copyright and
related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
All contributions to this project will be released under the CC0 dedication. By
submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

## Requesting Changes
Our pull request/merging process is designed to give the CDC Surveillance Team
and other in our space an opportunity to consider and discuss any suggested
changes. This policy affects all CDC spaces, both on-line and off, and all users
are expected to abide by it.

### Open an issue in the repository
If you don't have specific language to submit but would like to suggest a change
or have something addressed, you can open an issue in this repository. Team
members will respond to the issue as soon as possible.

### Submit a pull request
If you would like to contribute, please submit a pull request. In order for us
to merge a pull request, it must:
   * Be at least seven days old. Pull requests may be held longer if necessary
     to give people the opportunity to assess it.
   * Receive a +1 from a majority of team members associated with the request.
     If there is significant dissent between the team, a meeting will be held to
     discuss a plan of action for the pull request.
