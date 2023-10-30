# Change Log

All notable changes to this project will be documented in this file.

## v7 2023-10-30

### Removed

- Removed Dockerlint path argument. Now Dockerlint runs if Dockerfile changes in Pull Request.

## v6 2023-08-08

### Removed

- Removed the Tfsec scan because it is now integrated in Trivy.
- Removed the Dependency Track scan and the integration with DefectDojo in order to use the [StackRox action](https://github.com/empathyco/stackrox-action) to track vulnerabilities.
- Docker linter scan is disabled by default.

## v5 2023-05-22

### Added

- Docker linter checker added.

## v4 2023-05-04

### Added

- Dependency Track now supports Scala with SBT and Gradle.

## v3 2023-01-31

### Added

- Java v8 is now supported alongside Java v17 (default).

### Changed

- Tools installation changed in Dockerfile.
- Cyclonedx cli installation from packages. 

### Removed

- Dependencies installation.
- Golang check from Dependency Track
- Python v2.7

## v2 2022-12-07

### Added

- Added integration with DefectDojo.
- Added integration with Nexus for Dependency Track.

## v1 2022-11-24

- Initial Tizona version v1