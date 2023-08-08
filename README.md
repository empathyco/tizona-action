# tizona-action
Repository to locate the GitHub security action named Tizona.
## Description

Checks and analyzes the security of the code added to the specified repository.

## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| permissive_mode | Enables or disables the interruption of the action in the case of finding errors in the execution of the checks. | `false` | true |
| java_version | Sets the Java version to be used in the checks. Java versions available: 8, 17(default) | `false` | 17 |
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

### Dependency Track - Maven/Java

It is necessary to add the CycloneDX plugin to your project (only Maven/Java projects). Get the cyclonedx-maven-plugin. From the cyclonedx-maven-plugin repository, you'll be able to get the code below. Edit your `pom.xml` file by adding the plugin.

Example

_Properties_

```xml
<project . . .>
    . . .
    <properties>
        . . .
        <cyclonedx.version>2.7.3</cyclonedx.version>
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

### Dependency Track - Scala

- Gradle

[Github reference](https://github.com/CycloneDX/cyclonedx-gradle-plugin)

Configuration:

To generate BOM for a single project add the plugin to the `build.gradle`.

```gradle
plugins {
    id 'org.cyclonedx.bom' version '1.7.4'
}
```

You can add the following configuration to `build.gradle` to control various options in generating a BOM:

```gradle
cyclonedxBom {
    // includeConfigs is the list of configuration names to include when generating the BOM (leave empty to include every configuration)
    includeConfigs = ["runtimeClasspath"]
    // skipConfigs is a list of configuration names to exclude when generating the BOM
    skipConfigs = ["compileClasspath", "testCompileClasspath"]
    // skipProjects is a list of project names to exclude when generating the BOM
    skipProjects = [rootProject.name, "yourTestSubProject"]
    // Specified the type of project being built. Defaults to 'library'
    projectType = "application"
    // Specified the version of the CycloneDX specification to use. Defaults to '1.4'
    schemaVersion = "1.4"
    // Boms destination directory. Defaults to 'build/reports'
    destination = file("build/reports")
    // The file name for the generated BOMs (before the file format suffix). Defaults to 'bom'
    outputName = "bom"
    // The file format generated, can be xml, json or all for generating both. Defaults to 'all'
    outputFormat = "xml"
    // Exclude BOM Serial Number. Defaults to 'true'
    includeBomSerialNumber = false
    // Exclude License Text. Defaults to 'true'
    includeLicenseText = false
    // Override component version. Defaults to the project version
    componentVersion = "2.0.0"
}
```

- SBT

[GitHub reference](https://github.com/siculo/sbt-bom)

Configuration:

Add the plugin dependency to the file `project/plugins.sbt` using addSbtPlugin :

```sbt
addSbtPlugin("io.github.siculo" %% "sbt-bom" % "0.3.0")
```

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
        uses: empathyco/tizona-action@v5
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
          dockerfile_path: docker/Dockerfile
          dockerlint_level: warning
```
