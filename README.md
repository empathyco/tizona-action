# tizona-action
Repository to locate the GitHub security action named Tizona.
## Description

Checks and analyzes the security of the code added to the specified repository.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| permissive_mode | Enables or disables the interruption of the action in the case of finding errors in the execution of the checks. | `false` | true |
| code_enable | Enables SonarQube check | `false` | true |
| sonar_source | SonarQube source. Required to run SonarQube. | `false` | . |
| sonar_host | SonarQube host. Required to run SonarQube. | `false` | SONAR_HOST |
| sonar_login | SonarQube login key. Required to run SonarQube. | `false` | SONAR_LOGIN |
| sonar_report_path | Location of the scanner metadata report file. Required to run Quality Gate. | `false` | .scannerwork/report-task.txt |
| config_enable | Enables configuration check. | `false` | true |
| secrets_enable | Enables secrets check. | `false` | true |
| reviewdog_github_token | GitHub token. Required if config checker is enabled. | `false` |  |
| depcheck_project | Dependency check project. Required if code checker is enabled. | `false` | MY_PROJECT |
| depcheck_path | Dependency check path.  Required if code checker is enabled. | `false` | . |
| depcheck_format | Dependency check format.  Required if code checker is enabled. | `false` | HTML |
| trivy_repo_ignore-unfixed | Ignore unfixed vulnerabilities. Required if config checker is enabled. | `false` | false |
| trivy_repo_vuln | comma-separated list of vulnerability types (os,library). Required if config checker is enabled. | `false` | os,library |
| trivy_severity | Severities of vulnerabilities to be displayed. Required if config checker is enabled. | `false` | UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL |
| trivy_timeout | Trivy timeout duration. Required if config checker is enabled. | `false` | 5m |
| dockerlint_enable | Enables Docker lint check. | `false` | false |
| dockerfile_path | Dockerfile path. Required if Docker linter checker is enabled. | `false` | ./Dockerfile |
| dockerlint_level | Exit with failure code only when rules with a severity equal to or above THRESHOLD are violated. Accepted values: error, warning, info, style, ignore & none. Required if Docker linter checker is enabled. | `false` | error |

## Outputs

| parameter | description |
| --- | --- |
| riskscore | String with the number of vulnerabilities found |

## Runs

This action is a `docker` action.

## Requirements

### SonarQube

We will need the file `sonar-project.properties` in the root of the repository to be analyzed, with at least, the following content: 

```
sonar.projectKey=<PROJECT_KEY>
sonar.dependencyCheck.htmlReportPath=<REPORT_PATH>
sonar.exclusions=<EXCLUSIONS>
```

## Workflow 

Basic example

```yaml
name: tizona
on:
  pull_request:
  push:
    branches:
      - main

jobs:
  security_check_job:
    runs-on: [self-hosted, platform]
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Security check
        uses: empathyco/tizona-action@v6
        with:
          permissive_mode: 'true'
          reviewdog_github_token: ${{ secrets.github_token }}
          depcheck_project: 'example-project'
          trivy_severity: 'CRITICAL,HIGH'
          trivy_repo_ignore-unfixed: 'true'
          trivy_timeout: '10m'
          dockerfile_path: docker/Dockerfile
          dockerlint_level: warning
```
