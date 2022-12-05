#!/usr/bin/env bash

ACTION_MODE=${1}

if [[ ${ACTION_MODE} == *"false"* ]]; then
  set -e
fi

REVIEWDOG_GIT_TOKEN=${2}
TERRAFORM_DIR=${3}
REVIEWDOG_LVL=${4}
REVIEWDOG_REPORTER=${5}

TRIVY_REPO_IGNORE=${6}
TRIVY_REPO_VULN=${7}
TRIVY_SEVERITY=${8}
TRIVY_TIMEOUT=${9}


echo "TIZONA - Configuration analysis: Run Tfsec"
/bin/bash /app/tfsec_check.sh ${REVIEWDOG_GIT_TOKEN} ${TERRAFORM_DIR} ${REVIEWDOG_LVL} ${REVIEWDOG_REPORTER}

if [ "pull_request" = "$GITHUB_EVENT_NAME" ]; then
  echo "TTIZONA - Configuration analysis: Trivy configuration enabled for Pull Requests"

  echo "TIZONA - Configuration analysis: Run Trivy for config"
  /bin/bash /app/trivy_config.sh ${TRIVY_SEVERITY} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}

  echo "TIZONA - Configuration analysis: Run Trivy for repository"
  /bin/bash /app/trivy_repo.sh ${TRIVY_REPO_IGNORE} ${TRIVY_SEVERITY} ${TRIVY_REPO_VULN} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}
else
  echo "TTIZONA - Configuration analysis: Trivy configuration only available for Pull Requests. Skipping"
fi
