# tizona-action
Repository to locate the GitHub security action named Tizona.
## Description

Checks and analyzes the security of the code added to the specified repository.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| permissive_mode | Enables or disables the interruption of the action in the case of finding errors in the execution of the checks. | `false` | true |
| deptrack_enable | Enables Dependency Track check. | `false` | true |
| deptrack_url | URL of OWASP Dependency Track REST API. Required if Dependency Track is enabled. | `false` | DEPTRACK_URL |
| deptrack_key | Key to access OWASP Dependency Track REST API. Required if Dependency Track is enabled. | `false` | DEPTRACK_KEY |
| deptrack_language | Programming language. Required if Dependency Track is enabled. | `false` | nodejs |
| deptrack_dir | Dependency track directory path. Required if Dependency Track is enabled. | `false` | . |
| deptrack_branch | Dependency track GitHub only runs on tags or on this branch. Required if Dependency Track is enabled. | `false` | main |
| defectdojo_url | Dependency track DefectDojo URL for its integration. Not required. | `false` | DEFECTDOJO_URL |
| defectdojo_token | Dependency track DefectDojo token for its integration. Not required. | `false` | DEFECTDOJO_TOKEN |
| defectdojo_product | Dependency track DefectDojo product name for its integration. Not required. | false | `Tizona`|
| defectdojo_engagement | Dependency track DefectDojo engagement name for its integration. Not required. | false | `TizonaEngagement`|
| nexus_url | Dependency track Nexus URL for maven and java review. Not required. | `false` | NEXUS_URL |
| nexus_user | Dependency track Nexus user for maven and java review. Not required. | `false` | NEXUS_USER |
| nexus_pass | Dependency track Nexus password for maven and java review. Not required. | `false` | NEXUS_PASS |
| code_enable | Enables SonarQube check | `false` | true |
| sonar_source | SonarQube source. Required to run SonarQube. | `false` | . |
| sonar_host | SonarQube host. Required to run SonarQube. | `false` | SONAR_HOST |
| sonar_login | SonarQube login key. Required to run SonarQube. | `false` | SONAR_LOGIN |
| sonar_report_path | Location of the scanner metadata report file. Required to run Quality Gate. | `false` | .scannerwork/report-task.txt |
| config_enable | Enables configuration check. | `false` | true |
| secrets_enable | Enables secrets check. | `false` | true |
| reviewdog_github_token | GitHub token. Required if config checker is enabled. | `false` |  |
| terraform_working_directory | Directory to run the Tfsec action on, from the repo root.. Default is . ( root of the repository). Required if config checker is enabled. | `false` | . |
| reviewdog_level | Report level for reviewdog [info,warning,error]. Required if config checker is enabled. | `false` | error |
| reviewdog_reporter | Reporter of reviewdog command [github-pr-check,github-pr-review]. Default is github-pr-check.. Required for config checker and for secrets leaks checker. | `false` | github-pr-check |
| depcheck_project | Dependency check project. Required if code checker is enabled. | `false` | MY_PROJECT |
| depcheck_path | Dependency check path.  Required if code checker is enabled. | `false` | . |
| depcheck_format | Dependency check format.  Required if code checker is enabled. | `false` | HTML |
| trivy_repo_ignore-unfixed | Ignore unfixed vulnerabilities. Required if config checker is enabled. | `false` | false |
| trivy_repo_vuln | comma-separated list of vulnerability types (os,library). Required if config checker is enabled. | `false` | os,library |
| trivy_severity | Severities of vulnerabilities to be displayed. Required if config checker is enabled. | `false` | UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL |
| trivy_timeout | Trivy timeout duration. Required if config checker is enabled. | `false` | 5m |


## Outputs

| parameter | description |
| --- | --- |
| riskscore | String with the number of vulnerabilities found |

## Runs

This action is a `docker` action.

## Requirements

### Dependency Track - Maven/Java

It is necessary to add the CycloneDX plugin to your project (only Maven/Java projects). Get the cyclonedx-maven-plugin. From the cyclonedx-maven-plugin repository, you'll be able to get the code below. Edit your `pom.xml` file by adding the plugin.

**NOTE: Tizona uses Java 17 version.**

Example

_Properties_

```xml
<project . . .>
    . . .
    <properties>
        . . .
        <cyclonedx.version>2.5.2</cyclonedx.version>
    </properties>
. . .
```

_Plugin_
```xml
            <plugin>
                <groupId>org.cyclonedx</groupId>
                <artifactId>cyclonedx-maven-plugin</artifactId>
                <version>${cyclonedx.version}</version>
                <executions>
                    <execution>
                        <phase>compile</phase>
                        <goals>
                            <goal>makeAggregateBom</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <projectType>library</projectType>
                    <schemaVersion>1.3</schemaVersion>
                    <includeBomSerialNumber>true</includeBomSerialNumber>
                    <includeCompileScope>true</includeCompileScope>
                    <includeProvidedScope>true</includeProvidedScope>
                    <includeRuntimeScope>true</includeRuntimeScope>
                    <includeSystemScope>true</includeSystemScope>
                    <includeTestScope>false</includeTestScope>
                    <includeLicenseText>false</includeLicenseText>
                    <outputFormat>all</outputFormat>
                    <outputName>bom</outputName>
                </configuration>
            </plugin>
```

Note that you must **change** the `<phase>` tag value to `compile` (`package` by default), otherwise the action won't even generate the bom.xml. This action will compile your Maven Java project and expects to find a resulting `bom.xml`. 


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
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Security check
        uses: empathyco/tizona-action@v2
        with:
          permissive_mode: 'true'
          deptrack_url: ${{ secrets.DEPENDENCY_TRACK_API_URL }}
          deptrack_key: ${{ secrets.DEPENDENCY_TRACK_API_KEY }}
          deptrack_language: 'java'
          terraform_working_directory: 'terraform'
          reviewdog_github_token: ${{ secrets.github_token }}
          reviewdog_level: 'info'
          reviewdog_reporter: 'github-pr-review'
          depcheck_project: 'example-project'
          trivy_severity: 'CRITICAL,HIGH'
          trivy_repo_ignore-unfixed: 'true'
          trivy_timeout: '10m'
```
