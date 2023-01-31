#!/usr/bin/env bash

DTRACK_URL=${1}
DTRACK_KEY=${2}
DTRACK_LANGUAGE=${3}
DTRACK_DIR=${4}
DEFECTDOJO_URL=${5}
DEFECTDOJO_TOKEN=${6}
DEFECTDOJO_PRODUCT=${7}
DEFECTDOJO_ENGAGEMENT=${8}
NEXUS_URL=${9}
NEXUS_USER=${10}
NEXUS_PASS=${11}

INSECURE="--insecure"
#VERBOSE="--verbose"

apt-get upgrade -y

# Access directory where GitHub will mount the repository code
# $GITHUB_ variables are directly accessible in the script

echo "TIZONA - Dependency Track: Install cyclondex-cli"
wget https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.24.2/cyclonedx-linux-x64
cp cyclonedx-linux-x64 /usr/bin/cyclonedx-cli
chmod +x /usr/bin/cyclonedx-cli
echo "TIZONA - Dependency Track: cyclondex-cli installed"

cd $GITHUB_WORKSPACE

case $DTRACK_LANGUAGE in
    "nodejs")
        cd $DTRACK_DIR
        lscommand=$(ls)
        echo "TIZONA - Dependency Track: [*] Processing NodeJS BoM"
        apt-get install --no-install-recommends -y nodejs npm
        npm install
        npm audit fix --force
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing npm install. Stopping the action!"
            exit 1
        fi
        npm install -g cyclonedx-bom
        path="$GITHUB_WORKSPACE/bom.xml"
        BoMResult=$(cyclonedx-bom -o $path)
        cd $GITHUB_WORKSPACE
        ;;
    
    "python")
        cd $DTRACK_DIR
        echo "TIZONA - Dependency Track: [*]  Processing Python BoM"
        apt-get install --no-install-recommends -y python3 python3-pip python3-packaging
        echo "TIZONA - Dependency Track: Upgrade pip"
        pip3 install --upgrade pip
        echo "TIZONA - Dependency Track: pip install packagin"
        pip3 install packaging==21.3
        # Current version 22.0 fail
        freeze=$(pip freeze > requirements.txt)
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing pip freeze to get a requirements.txt with frozen parameters. Stopping the action!"
            exit 1
        fi
        pip install cyclonedx-bom
        path="$GITHUB_WORKSPACE/bom.xml"
        BoMResult=$(cyclonedx-py -o bom.xml -r)
        cd $GITHUB_WORKSPACE
        ;;

    "java")
        cd $DTRACK_DIR
        echo "TIZONA - Dependency Track: [*]  Processing Java BoM"
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing Java build. Stopping the action!"
            exit 1
        fi

        wget https://dlcdn.apache.org/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
        tar xzvf apache-maven-3.8.7-bin.tar.gz
        export PATH=/opt/apache-maven-3.8.7/bin:$PATH
        rm apache-maven-3.8.7-bin.tar.gz
        mv apache-maven-3.8.7 /opt

        echo "TIZONA - Dependency Track: Maven version:"
        mvn -v
        echo "JAVA VERSION:"
        java -version

        if [[ ${NEXUS_URL} == *"NEXUS_URL"* ]]; then
            echo "TIZONA - Dependency Track: Nexus access not established. No Nexus libraries will be downloaded"
        else
            ROOT_DIR="/root"
            mkdir $ROOT_DIR/.m2
            cp /app/nexus_settings.xml $ROOT_DIR/.m2/settings.xml
            sed -i -e "s#NEXUS_USER#$NEXUS_USER#g" $ROOT_DIR/.m2/settings.xml
            sed -i -e "s#NEXUS_PASS#$NEXUS_PASS#g" $ROOT_DIR/.m2/settings.xml
            sed -i -e "s#NEXUS_URL#$NEXUS_URL#g" $ROOT_DIR/.m2/settings.xml

            echo "TIZONA - Dependency Track: Nexus access established. Nexus libraries will be downloaded"

        fi
        path="$GITHUB_WORKSPACE/target/bom.xml"
        echo "TIZONA - Dependency Track: maven compile"
        BoMResult=$(mvn compile)
        echo "TIZONA - Dependency Track: maven compiled"
        cd $GITHUB_WORKSPACE
        ;;
        
    *)
        "[-] Project type not supported: $DTRACK_LANGUAGE"
        exit 1
        ;;
esac    

if [ ! $? = 0 ]; then
    echo "TIZONA - Dependency Track: [-] Error generating BoM file: $BomResult. Stopping the action!"
    exit 1
fi

echo "TIZONA - Dependency Track: [*] BoM file succesfully generated"

# Cyclonedx CLI conversion
echo "TIZONA - Dependency Track: [*] Cyclonedx CLI conversion"
#Does not upload to dtrack when output format = xml (every version available)
cyclonedx-cli convert --input-file $path --output-file sbom.xml --output-format json --output-version v1_4

if [[ ${DEFECTDOJO_TOKEN} == *"DEFECTDOJO_TOKEN"* ]];then
    echo "TIZONA - Dependency Track: DefectDojo integration not configured. Skipping"
else
    echo "TIZONA - Dependency Track: Trivy sbom scan"
    trivy sbom sbom.xml -o trivy_scan.json -f json

    current_date=$(date '+%Y-%m-%d')

    echo "TIZONA - Dependency Track: Import Trivy scan to DefectDojo"
    curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" -H  "accept: application/json" -H  "Content-Type: multipart/form-data"  -H "Authorization: Token ${DEFECTDOJO_TOKEN}" -F "minimum_severity=High" -F "active=true" -F "verified=true" -F "close_old_findings=false" -F "push_to_jira=false" -F "file=@trivy_scan.json" -F "product_name=${DEFECTDOJO_PRODUCT}" -F "scan_date=${current_date}" -F "engagement_name=${DEFECTDOJO_ENGAGEMENT}" -F "scan_type=Trivy Scan"
fi

# UPLOAD BoM to Dependency track server
echo "TIZONA - Dependency Track: [*] Uploading BoM file to Dependency Track server"

upload_bom=$(curl $INSECURE $VERBOSE -s --location --request POST $DTRACK_URL/api/v1/bom \
--header "X-Api-Key: $DTRACK_KEY" \
--header "Content-Type: multipart/form-data" \
--form "autoCreate=true" \
--form "projectName=$GITHUB_REPOSITORY" \
--form "projectVersion=$GITHUB_REF" \
--form "bom=@sbom.xml")

token=$(echo $upload_bom | jq ".token" | tr -d "\"")
echo "TIZONA - Dependency Track: [*] BoM file succesfully uploaded with token $token"

if [ -z $token ]; then
    echo "TIZONA - Dependency Track: [-]  The BoM file has not been successfully processed by OWASP Dependency Track"
    exit 1
fi

echo "TIZONA - Dependency Track: [*] Checking BoM processing status"
processing=$(curl $INSECURE $VERBOSE -s --location --request GET $DTRACK_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DTRACK_KEY" | jq '.processing')


while [ $processing = true ]; do
    sleep 5
    processing=$(curl  $INSECURE $VERBOSE -s --location --request GET $DTRACK_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DTRACK_KEY" | jq '.processing')
    if [ $((++c)) -eq 60 ]; then
        echo "TIZONA - Dependency Track: [-]  Timeout while waiting for processing result. Please check the OWASP Dependency Track status."
        exit 1
    fi
done

echo "TIZONA - Dependency Track: [*] OWASP Dependency Track processing completed"

# wait to make sure the score is available, some errors found during tests w/o this wait
sleep 5

echo "TIZONA - Dependency Track: [*] Retrieving project information"
project=$(curl  $INSECURE $VERBOSE -s --location --request GET "$DTRACK_URL/api/v1/project/lookup?name=$GITHUB_REPOSITORY&version=$GITHUB_REF" \
--header "X-Api-Key: $DTRACK_KEY")

echo "TIZONA - Dependency Track: $project"

project_uuid=$(echo $project | jq ".uuid" | tr -d "\"")
risk_score=$(echo $project | jq ".lastInheritedRiskScore")
echo "TIZONA - Dependency Track: Project risk score: $risk_score"

echo "TIZONA - Dependency Track: ::set-output name=riskscore::$risk_score"