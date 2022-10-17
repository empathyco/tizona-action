#!/usr/bin/env bash

DEPCHECK_PROJECT=$1
DEPCHECK_PATH=$2
DEPCHECK_FORMAT=$3

set -e

echo "TIZONA - Code analysis: Run Dependency check"

/var/opt/dependency-check/bin/dependency-check.sh --project ${DEPCHECK_PROJECT} --scan ${DEPCHECK_PATH} --format ${DEPCHECK_FORMAT} --out '/github/workspace/reports' --noupdate --disableYarnAudit

SONAR_PROPERTIES="sonar-project.properties"
if [[ -f $SONAR_PROPERTIES ]]; then
  echo "TIZONA - Code analysis: SonarQube properties file found"
  SONAR_SOURCES=$4
  SONAR_HOST=$5
  SONAR_LOGIN=$6
  SONAR_PROJECT=`sed -n 's/^sonar.projectKey=\(.*\)/\1/p' < $SONAR_PROPERTIES`
  SONAR_EXCLUSION=`sed -n 's/^sonar.exclusions=\(.*\)/\1/p' < $SONAR_PROPERTIES`

  echo "TIZONA - Code analysis: Run SonarQube"
  echo "TIZONA - Code analysis: sonar-scanner -Dsonar.projectKey=$SONAR_PROJECT -Dsonar.sources=$SONAR_SOURCES -Dsonar.host.url=$SONAR_HOST -Dsonar.login=$SONAR_LOGIN -Dsonar.exclusions=$SONAR_EXCLUSION"

  sonar-scanner \
    -Dsonar.projectKey=$SONAR_PROJECT \
    -Dsonar.sources=$SONAR_SOURCES \
    -Dsonar.host.url=$SONAR_HOST \
    -Dsonar.login=$SONAR_LOGIN \
    -Dsonar.exclusions=$SONAR_EXCLUSION

  echo "TIZONA - Code analysis: SonarQube scan finished"
  echo "TIZONA - Code analysis: Run quality gate scan"

  SONAR_REPORT_PATH=$7

  if [[ ! -f "$SONAR_REPORT_PATH" ]]; then
    echo "TIZONA - Code analysis: $SONAR_REPORT_PATH does not exist."
    exit 1
  fi

  serverUrl="${SONAR_HOST%/}"
  ceTaskUrl="${SONAR_HOST%/}/api$(sed -n 's/^ceTaskUrl=.*api//p' "${SONAR_REPORT_PATH}")"

  echo "TIZONA - Code analysis: Prepare quality gate task"

  task="$(curl --location --location-trusted --max-redirs 10  --silent --fail --show-error --user "${SONAR_LOGIN}": "${ceTaskUrl}")"
  status="$(jq -r '.task.status' <<< "$task")"

  until [[ ${status} != "PENDING" && ${status} != "IN_PROGRESS" ]]; do
      sleep 10s
      task="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_LOGIN}": "${ceTaskUrl}")"
      status="$(jq -r '.task.status' <<< "$task")"
      echo "TIZONA - Code analysis: Status: ${status}. Waiting..."
  done

  echo "TIZONA - Code analysis: Quality gate task finish. Review status"

  analysisId="$(jq -r '.task.analysisId' <<< "${task}")"
  qualityGateUrl="${serverUrl}/api/qualitygates/project_status?analysisId=${analysisId}"
  qualityGateResult=`curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_LOGIN}": "${qualityGateUrl}"`
  qualityGateStatus="$(curl --location --location-trusted --max-redirs 10 --silent --fail --show-error --user "${SONAR_LOGIN}": "${qualityGateUrl}" | jq -r '.projectStatus.status')"

  echo $qualityGateResult

  printf '\n'
  if [[ ${qualityGateStatus} == "OK" ]]; then
    set_output="quality-gate-status: ${qualityGateStatus}"
    echo "TIZONA - Code analysis: Quality Gate has PASSED. ${set_output}"
  elif [[ ${qualityGateStatus} == "WARN" ]]; then
    set_output="quality-gate-status: ${qualityGateStatus}"
    echo "TIZONA - Code analysis: Warnings on Quality Gate. ${set_output}"
  elif [[ ${qualityGateStatus} == "ERROR" ]]; then
    set_output="quality-gate-status: ${qualityGateStatus}"
    echo "TIZONA - Code analysis: Errors on Quality Gate. ${set_output}"
    exit 1
  else
    set_output="quality-gate-status: FAILED"
    echo "TIZONA - Code analysis: Quality Gate not set for the project. Please configure the Quality Gate in SonarQube or remove sonarqube-quality-gate action from the workflow."
    exit 1
  fi

else
  echo "TIZONA - Code analysis: SonarQube properties file not found. Skip SonarQube Action"
fi
