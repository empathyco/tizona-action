#!/usr/bin/env bash

while getopts "a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:x:y:z:A:B:C:D:E:F:" o; do
   case "${o}" in
       a)
         export ACTION_MODE=${OPTARG}
       ;;
       b)
         export DTRACK_ENABLE=${OPTARG}
       ;;
       c)
         export DTRACK_URL=${OPTARG}
       ;;
       d)
         export DTRACK_KEY=${OPTARG}
       ;;
       e)
         export DTRACK_LANGUAGE=${OPTARG}
       ;;
       f)
         export DTRACK_DIR=${OPTARG}
       ;;
       g)
         export CODE_ENABLE=${OPTARG}
       ;;
       h)
         export SONAR_SOURCES=${OPTARG}
       ;;
       i)
         export SONAR_HOST=${OPTARG}
       ;;
       j)
         export SONAR_LOGIN=${OPTARG}
       ;;
       k)
         export SONAR_REPORT_PATH=${OPTARG}
       ;;
       l)
         export CONFIG_ENABLE=${OPTARG}
       ;;
       m)
         export SECRETS_ENABLE=${OPTARG}
       ;;
       n)
         export REVIEWDOG_GIT_TOKEN=${OPTARG}
       ;;
       o)
         export REVIEWDOG_DIR=${OPTARG}
       ;;
       p)
         export REVIEWDOG_LVL=${OPTARG}
       ;;
       q)
         export REVIEWDOG_REPORTER=${OPTARG}
       ;;
       r)
         export DEPCHECK_PROJECT=${OPTARG}
       ;;
       s)
         export DEPCHECK_PATH=${OPTARG}
       ;;
       t)
         export DEPCHECK_FORMAT=${OPTARG}
       ;;
       u)
         export TRIVY_CONFIG_SCANREF=${OPTARG}
       ;;
       v)
         export TRIVY_SEVERITY=${OPTARG}
       ;;
       w)
         export TRIVY_REPO_SCANREF=${OPTARG}
       ;;
       x)
         export TRIVY_REPO_IGNORE=${OPTARG}
       ;;
       y)
         export TRIVY_REPO_VULN=${OPTARG}
       ;;
       z)
         export TRIVY_TIMEOUT=${OPTARG}
       ;;
       A)
         export DEPTRACK_BRANCH=${OPTARG}
       ;;
       B)
         export DEFECTDOJO_URL=${OPTARG}
       ;;
       C)
         export DEFECTDOJO_TOKEN=${OPTARG}
       ;;
       D)
         export NEXUS_URL=${OPTARG}
       ;;
       E)
         export NEXUS_USER=${OPTARG}
       ;;
       F)
         export NEXUS_PASS=${OPTARG}
       ;;
  esac
done

if [[ ${ACTION_MODE} == *"false"* ]]; then
  echo "TIZONA: Permissive mode disabled. The action will fail as soon as it encounters an error in the execution of the checks."
  set -e
else
  echo "TIZONA: Permissive mode enabled. The action will continue even if errors are encountered in the execution of the checks. "
fi


echo "TIZONA: Starting security checks"

if [[ ${DTRACK_ENABLE} == *"true"* ]]; then
    
    DTRACK_ARGS=""

    if [ $DTRACK_URL ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_URL"
    else
      echo "TIZONA: Dependency Track requires URL of OWASP Dependency Track REST API. Exit"
      exit 1
    fi

    if [ $DTRACK_KEY ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_KEY"
    else
      echo "TIZONA: Dependency Track requires key to access OWASP Dependency Track REST API."
    fi

    if [ $DTRACK_LANGUAGE ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_LANGUAGE"
    else
      echo "TIZONA: Dependency Track requires programming language to review. Exit"
      exit 1
    fi

    if [ $DTRACK_DIR ];then
      DTRACK_ARGS="$DTRACK_ARGS $DTRACK_DIR"
    else
      echo "TIZONA: Dependency Track requires specific directory. Exit"
      exit 1
    fi

    if [ $DEFECTDOJO_URL ];then
      DTRACK_ARGS="$DTRACK_ARGS $DEFECTDOJO_URL"
    fi

    if [ $DEFECTDOJO_TOKEN ];then
      DTRACK_ARGS="$DTRACK_ARGS $DEFECTDOJO_TOKEN"
    fi

    if [ $NEXUS_URL ];then
      DTRACK_ARGS="$DTRACK_ARGS $NEXUS_URL"
    fi

    if [ $NEXUS_USER ];then
      DTRACK_ARGS="$DTRACK_ARGS $NEXUS_USER"
    fi

    if [ $NEXUS_PASS ];then
      DTRACK_ARGS="$DTRACK_ARGS $NEXUS_PASS"
    fi

    if [[ ${GITHUB_REF_TYPE} == *"tag"* || ${DEPTRACK_BRANCH} == *"$GITHUB_BASE_REF"* ]]; then
      if [ $DTRACK_KEY ];then
        echo "TIZONA: Run Dependency Track action"
        /bin/bash /app/dependency_track.sh $DTRACK_ARGS &
      else
        echo "TIZONA: No Dependency Track key was found. Skipping Dependency Track check"
      fi
    else
      echo "TIZONA: Skipping Dependency Track action. Dependency Track action only runs on tags or on the master/main branch."
      echo "TIZONA: Current action: $GITHUB_REF_TYPE"
      echo "TIZONA: Current destiny branch: $GITHUB_BASE_REF, and must be $DEPTRACK_BRANCH"
    fi
else
    echo "TIZONA: Skip Dependency Track action"
fi

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

    if [ $REVIEWDOG_DIR ];then
      REVIEWDOG_ARGS="$REVIEWDOG_ARGS $REVIEWDOG_DIR"
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

    if [ $TRIVY_CONFIG_SCANREF ];then
      TRIVY_CONFIG_ARGS="$TRIVY_CONFIG_ARGS $TRIVY_CONFIG_SCANREF"
    else
      echo "TIZONA: Trivy requires path to scan configuration. Exit"
      exit 1
    fi

    TRIVY_REPO_ARGS=""

    if [ $TRIVY_REPO_SCANREF ];then
      TRIVY_REPO_ARGS="$TRIVY_REPO_ARGS $TRIVY_REPO_SCANREF"
    else
      echo "TIZONA: Trivy requires path to scan repository. Exit"
      exit 1
    fi

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
