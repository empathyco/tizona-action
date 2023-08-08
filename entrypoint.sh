#!/usr/bin/env bash

while getopts "a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:" o; do
   case "${o}" in
       a)
         export ACTION_MODE=${OPTARG}
       ;;
       b)
         export CODE_ENABLE=${OPTARG}
       ;;
       c)
         export SONAR_SOURCES=${OPTARG}
       ;;
       d)
         export SONAR_HOST=${OPTARG}
       ;;
       e)
         export SONAR_LOGIN=${OPTARG}
       ;;
       f)
         export SONAR_REPORT_PATH=${OPTARG}
       ;;
       g)
         export CONFIG_ENABLE=${OPTARG}
       ;;
       h)
         export SECRETS_ENABLE=${OPTARG}
       ;;
       i)
         export REVIEWDOG_GIT_TOKEN=${OPTARG}
       ;;
       j)
         export TERRAFORM_DIR=${OPTARG}
       ;;
       k)
         export REVIEWDOG_LVL=${OPTARG}
       ;;
       l)
         export REVIEWDOG_REPORTER=${OPTARG}
       ;;
       m)
         export DEPCHECK_PROJECT=${OPTARG}
       ;;
       n)
         export DEPCHECK_PATH=${OPTARG}
       ;;
       o)
         export DEPCHECK_FORMAT=${OPTARG}
       ;;
       p)
         export TRIVY_SEVERITY=${OPTARG}
       ;;
       q)
         export TRIVY_REPO_IGNORE=${OPTARG}
       ;;
       r)
         export TRIVY_REPO_VULN=${OPTARG}
       ;;
       s)
         export TRIVY_TIMEOUT=${OPTARG}
       ;;
       t)
         export JAVA_VERSION_TIZONA=${OPTARG}
       ;;
       u)
         export DOCKERLINT_ENABLE=${OPTARG}
       ;;
       v)
         export DOCKERFILE_PATH=${OPTARG}
       ;;
       w)
         export DOCKERLINT_LEVEL=${OPTARG}
       ;;
       *)
         echo "TIZONA: Arguments flag error. Exit"
         exit 1
       ;;
  esac
done

if [[ ${ACTION_MODE} == *"false"* ]]; then
  echo "TIZONA: Permissive mode disabled. The action will fail as soon as it encounters an error in the execution of the checks."
  set -e
else
  echo "TIZONA: Permissive mode enabled. The action will continue even if errors are encountered in the execution of the checks. "
fi

echo "TIZONA: Set Java 17 version (default) to JAVA_HOME"
export JAVA_HOME="/opt/java/java17"
export PATH=${JAVA_HOME}/bin:${PATH}

echo "TIZONA: Starting security checks"

if [[ ${CODE_ENABLE} == *"true"* ]]; then

    CODE_ARGS=""

    if [ $DEPCHECK_PROJECT ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_PROJECT"
    else
      echo "TIZONA: Dependency Check requires project review. Exit"
      exit 1
    fi

    if [ $DEPCHECK_PATH ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_PATH"
    else
      echo "TIZONA: Dependency Check requires path review. Exit"
      exit 1
    fi

    if [ $DEPCHECK_FORMAT ];then
      CODE_ARGS="$CODE_ARGS $DEPCHECK_FORMAT"
    else
      echo "TIZONA: Dependency Check requires output format. Exit"
      exit 1
    fi

    if [ $SONAR_SOURCES ];then
      CODE_ARGS="$CODE_ARGS $SONAR_SOURCES"
    fi

    if [ $SONAR_HOST ];then
      CODE_ARGS="$CODE_ARGS $SONAR_HOST"
    fi

    if [ $SONAR_LOGIN ];then
      CODE_ARGS="$CODE_ARGS $SONAR_LOGIN"
    fi

    if [ $SONAR_REPORT_PATH ]; then
      CODE_ARGS="$CODE_ARGS $SONAR_REPORT_PATH"
    fi

    if [ $SONAR_HOST ];then
      echo "TIZONA: Run code check action"
      /bin/bash /app/code.sh $CODE_ARGS &
    else 
      echo "TIZONA: Sonar arguments needs al leats a default value. Skipping code check action"
    fi

else
    echo "TIZONA: Skip code check action"
fi

if [[ ${CONFIG_ENABLE} == *"true"* ]]; then
    REVIEWDOG_ARGS=""

    if [ $REVIEWDOG_GIT_TOKEN ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_GIT_TOKEN"
    else
      echo "TIZONA: ReviewDog requires GitHub token. Exit"
    fi

    if [ $TERRAFORM_DIR ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $TERRAFORM_DIR"
    else
      echo "TIZONA: ReviewDog requires path to review. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_LVL ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_LVL"
    else
      echo "TIZONA: ReviewDog requires level. Exit"
      exit 1
    fi

    if [ $REVIEWDOG_REPORTER ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_REPORTER"
    else
      echo "TIZONA: ReviewDog requires reporter of reviewdog command [github-pr-check,github-pr-review]. Exit"
      exit 1
    fi

    TRIVY_CONFIG_ARGS=""

    if [ $TRIVY_REPO_IGNORE ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_IGNORE"
    else
      echo "TIZONA: Trivy requires set ignore unfixed vulnerabilities [true/false]. Exit"
      exit 1
    fi

    if [ $TRIVY_REPO_VULN ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_VULN"
    else
      echo "TIZONA: Trivy requires comma-separated list of vulnerability types (os,library). Exit"
      exit 1
    fi

    TRIVY_COMMON_ARGS=""

    if [ $TRIVY_SEVERITY ];then
      TRIVY_COMMON_ARGS="$TRIVY_COMMON_ARGS $TRIVY_SEVERITY"
    else
      echo "TIZONA: Trivy requires severity for configuration scan. Exit"
      exit 1
    fi

    if [ $TRIVY_TIMEOUT ]; then
      TRIVY_COMMON_ARGS="$TRIVY_COMMON_ARGS $TRIVY_TIMEOUT"
    else
      echo "TIZONA: Trivy requires timeout (default 5m0s). Exit"
      exit 1
    fi

    if [ $REVIEWDOG_GIT_TOKEN ];then
      echo "TIZONA: Run configuration check action"
      /bin/bash /app/config.sh $ACTION_MODE $REVIEWDOG_ARGS $TRIVY_CONFIG_ARGS $TRIVY_REPO_ARGS $TRIVY_COMMON_ARGS &
    else
      echo "TIZONA: No ReviewDog token detected. Skipping config checker"
    fi

else
    echo "TIZONA: Skip configuration check action"
fi

if [[ ${SECRETS_ENABLE} == *"true"* ]]; then

    SECRETS_ARGS=""

    if [ $REVIEWDOG_GIT_TOKEN ];then
      SECRETS_ARGS="$SECRETS_ARGS $REVIEWDOG_GIT_TOKEN"
      echo "TIZONA: Run secrets leaks action"
      /bin/bash /app/secrets_leaks.sh $SECRETS_ARGS &
    else
      echo "TIZONA: ReviewDog requires GitHub token. Exit"
    fi
else
    echo "TIZONA: Skip secrets leaks action"
fi

if [[ ${DOCKERLINT_ENABLE} == *"true"* ]]; then

    DOCKER_ARGS=""

    if [ $DOCKERFILE_PATH ];then
      DOCKER_ARGS="$DOCKER_ARGS $DOCKERFILE_PATH"
    else
      echo "TIZONA: Docker linter check requires Dockerfile path. Exit"
      exit 1
    fi

    if [ $DOCKERLINT_LEVEL ];then
      DOCKER_ARGS="$DOCKER_ARGS $DOCKERLINT_LEVEL"
      echo "TIZONA: Run Docker linter check action"
      /bin/bash /app/docker_linter.sh $DOCKER_ARGS &
    else
      echo "TIZONA: Docker linter check requires threshold level. Exit"
    fi
else
    echo "TIZONA: Skip Docker linter check action"
fi

if [[ ${ACTION_MODE} == *"false"* ]]; then
  declare -i err=0 werr=0
  while wait -fn || werr=$?; ((werr != 127)); do
    err=$werr
    ## To handle *as soon as* first failure happens:
    ((err == 0)) || break
  done
  if ((err == 0)); then
    echo "TIZONA: Success"
  else
    echo "TIZONA: Failure! At least one error found."
    exit $err
  fi
else
  wait
fi

echo "TIZONA: Security checks finished"
