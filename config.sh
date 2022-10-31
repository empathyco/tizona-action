#!/usr/bin/env bash

ACTION_MODE=${1}

if [[ ${ACTION_MODE} == *"false"* ]]; then
  set -e
fi

REVIEWDOG_GIT_TOKEN=${2}
REVIEWDOG_DIR=${3}
REVIEWDOG_LVL=${4}
REVIEWDOG_REPORTER=${5}

TRIVY_CONFIG_SCANREF=${6}
TRIVY_REPO_SCANREF=${7}
TRIVY_REPO_IGNORE=${8}
TRIVY_REPO_VULN=${9}
TRIVY_SEVERITY=${10}
TRIVY_TIMEOUT=${11}

echo "TIZONA - Configuration analysis: Run Tfsec"
/bin/bash /app/tfsec_check.sh ${REVIEWDOG_GIT_TOKEN} ${REVIEWDOG_DIR} ${REVIEWDOG_LVL} ${REVIEWDOG_REPORTER}

echo "TIZONA - Configuration analysis: Run Trivy for config"
/bin/bash /app/trivy_config.sh ${TRIVY_CONFIG_SCANREF} ${TRIVY_SEVERITY} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}

echo "TIZONA - Configuration analysis: Run Trivy for repository"
/bin/bash /app/trivy_repo.sh  ${TRIVY_REPO_SCANREF} ${TRIVY_REPO_IGNORE} ${TRIVY_SEVERITY} ${TRIVY_REPO_VULN} ${TRIVY_TIMEOUT} ${REVIEWDOG_GIT_TOKEN}