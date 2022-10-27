#!/bin/bash



DEPCHECK_PROJECT=$1
DEPCHECK_PATH=$2
DEPCHECK_FORMAT=$3

set -e

echo "Run Dependency check"

/var/opt/dependency-check/bin/dependency-check.sh --project ${DEPCHECK_PROJECT} --scan ${DEPCHECK_PATH} --format ${DEPCHECK_FORMAT} --out '/github/workspace/reports' --noupdate

SONAR_PROPERTIES="sonar-project.properties"
if [[ -f $SONAR_PROPERTIES ]]; then
  echo "SonarQube properties file found"
  SONAR_SOURCES=$4
  SONAR_HOST=$5
  SONAR_LOGIN=$6
  SONAR_PROJECT=`sed -n 's/^sonar.projectKey=\(.*\)/\1/p' < $SONAR_PROPERTIES`
  SONAR_EXCLUSION=`sed -n 's/^sonar.exclusions=\(.*\)/\1/p' < $SONAR_PROPERTIES`

  echo "Run SonarQube"
  echo "sonar-scanner -Dsonar.projectKey=$SONAR_PROJECT -Dsonar.sources=$SONAR_SOURCES -Dsonar.host.url=$SONAR_HOST -Dsonar.login=$SONAR_LOGIN -Dsonar.exclusions=$SONAR_EXCLUSION"

  sonar-scanner \
    -Dsonar.projectKey=$SONAR_PROJECT \
    -Dsonar.sources=$SONAR_SOURCES \
    -Dsonar.host.url=$SONAR_HOST \
    -Dsonar.login=$SONAR_LOGIN \
    -Dsonar.exclusions=$SONAR_EXCLUSION
else
  echo "SonarQube properties file not found. Skip SonarQube Action"
fi