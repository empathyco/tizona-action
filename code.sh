#!/usr/bin/env bash

DEPCHECK_PROJECT=$1
DEPCHECK_PATH=$2
DEPCHECK_FORMAT=$3

set -e

echo "Run Dependency check"

/var/opt/dependency-check/bin/dependency-check.sh --project ${DEPCHECK_PROJECT} --scan ${DEPCHECK_PATH} --format ${DEPCHECK_FORMAT} --out '/github/workspace/reports' --noupdate --disableYarnAudit

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

  echo "SonarQube scan finished"
  echo "Run quality gate scan"

  SONAR_REPORT_PATH=$7

  if [[ ! -f "$SONAR_REPORT_PATH" ]]; then
    echo "$SONAR_REPORT_PATH does not exist."
    exit 1
  fi

  serverUrl="${SONAR_HOST%/}"
  ceTaskUrl="${SONAR_HOST%/}/api$(sed -n 's/^ceTaskUrl=.*api//p' "${SONAR_REPORT_PATH}")"

  echo "Prepare quality gate task"

  task="$(curl --location --location-trusted --max-redirs 10  --silent --fail --show-error --user "${SONAR_LOGIN}": "${ceTaskUrl}")"
  status="$(jq -r '.task.status' <<< "$task")"

  until [[ ${status} != "PENDING" && ${status} != "IN_PROGRESS" ]]; do
      sleep 5s
      task="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_LOGIN}": "${ceTaskUrl}")"
      status="$(jq -r '.task.status' <<< "$task")"
      echo "Status: ${status}. Waiting..."
  done

  echo "Quality gate task finish. Review status"

  analysisId="$(jq -r '.task.analysisId' <<< "${task}")"
  qualityGateUrl="${serverUrl}/api/qualitygates/project_status?analysisId=${analysisId}"
  qualityGateStatus="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_LOGIN}": "${qualityGateUrl}" | jq -r '.projectStatus.status')"

  printf '\n'
  if [[ ${qualityGateStatus} == "OK" ]]; then
    set_output="quality-gate-status" "PASSED"
    echo "Quality Gate has PASSED."
  elif [[ ${qualityGateStatus} == "WARN" ]]; then
    set_output="quality-gate-status" "WARN"
    echo "Warnings on Quality Gate."
  elif [[ ${qualityGateStatus} == "ERROR" ]]; then
    set_output="quality-gate-status" "ERROR"
    echo "Errors on Quality Gate."
    exit 1
  else
    set_output="quality-gate-status" "FAILED"
    echo "Quality Gate not set for the project. Please configure the Quality Gate in SonarQube or remove sonarqube-quality-gate action from the workflow."
    exit 1
  fi


else
  echo "SonarQube properties file not found. Skip SonarQube Action"
fi
