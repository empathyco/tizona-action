# tizona-action
Repository to locate the GitHub security action named Tizona.
## Description

Checks and analyzes the security of the code added to the specified repository.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| deptrack_enable | Enables Dependency Track check | `true` | true |
| deptrack_url | URL of OWASP Dependency Track REST API. Required if Dependency Track is enabled. | `false` |  |
| deptrack_key | Key to access OWASP Dependency Track REST API. Required if Dependency Track is enabled. | `false` |  |
| deptrack_language | Programming language. Required if Dependency Track is enabled. | `false` | nodejs |
| code_enable | Enables SonarQube check | `true` | true |
| sonar_source | SonarQube source. Required to run SonarQube. | `false` | . |
| sonar_host | SonarQube host. Required to run SonarQube. | `false` |  |
| sonar_login | SonarQube login key. Required to run SonarQube. | `false` |  |
| config_enable | Enables configuration check. | `true` | true |
| secrets_enable | Enables secrets check | `true` | true |
| reviewdog_github_token | GitHub token. Required if config checker is enabled. | `false` |  |
| reviewdog_working_directory | Directory to run the action on, from the repo root.. Default is . ( root of the repository). Required if config checker is enabled. | `false` | . |
| reviewdog_level | Report level for reviewdog [info,warning,error]. Required if config checker is enabled. | `false` | error |
| reviewdog_reporter | Reporter of reviewdog command [github-pr-check,github-pr-review]. Default is github-pr-check.. Required if config checker is enabled. | `false` | github-pr-check |
| reviewdog_fail_on_error | Exit code for reviewdog when errors are found [true,false]. Default is `false`. Required if config checker is enabled. | `false` | false |
| depcheck_project | Dependency check project. Required if code checker is enabled. | `false` | . |
| depcheck_path | Dependency check path.  Required if code checker is enabled. | `false` | . |
| depcheck_format | Dependency check format.  Required if code checker is enabled. | `false` | HTML |
| trivy_config_scan-ref | Config scan reference. Required if config checker is enabled. | `false` | . |
| trivy_config_severity | Severities of vulnerabilities to be displayed. Required if config checker is enabled. | `false` | UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL |
| trivy_repo_scan-ref | FS scan reference. Required if config checker is enabled. | `false` | . |
| trivy_repo_ignore-unfixed | Ignore unfixed vulnerabilities. Required if config checker is enabled. | `false` | false |
| trivy_repo_severity | Severities of vulnerabilities to be displayed. Required if config checker is enabled. | `false` | UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL |
| trivy_repo_vuln | comma-separated list of vulnerability types (os,library). Required if config checker is enabled. | `false` | os,library |
| trivy_timeout | Trivy timeout duration. Required if config checker is enabled. | `false` | 5m |


## Outputs

| parameter | description |
| --- | --- |
| riskscore | String with the number of vulnerabilities found |
| tfsec-return-code | tfsec command return code |
| reviewdog-return-code | reviewdog command return code |


## Runs

This action is a `docker` action.


