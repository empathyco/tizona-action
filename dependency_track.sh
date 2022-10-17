#!/usr/bin/env bash

DTRACK_URL=$1
DTRACK_KEY=$2
DTRACK_LANGUAGE=$3
DTRACK_DIR=$4

INSECURE="--insecure"
#VERBOSE="--verbose"

apt-get upgrade -y

# Access directory where GitHub will mount the repository code
# $GITHUB_ variables are directly accessible in the script
cd $GITHUB_WORKSPACE

case $DTRACK_LANGUAGE in
    "nodejs")
        cd $DTRACK_DIR
        lscommand=$(ls)
        echo "TIZONA - Dependency Track: [*] Processing NodeJS BoM"
        apt-get install --no-install-recommends -y nodejs
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
        apt-get install --no-install-recommends -y python3 python3-pip
        freeze=$(pip freeze > requirements.txt)
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing pip freeze to get a requirements.txt with frozen parameters. Stopping the action!"
            exit 1
        fi
        pip install cyclonedx-bom
        path="$GITHUB_WORKSPACE/bom.xml"
        BoMResult=$(cyclonedx-py -o bom.xml)
        cd $GITHUB_WORKSPACE
        ;;
    
    "golang")
        cd $DTRACK_DIR
        echo "TIZONA - Dependency Track: [*]  Processing Golang BoM"
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing go build. Stopping the action!"
            exit 1
        fi
        path="$GITHUB_WORKSPACE/bom.xml"
        BoMResult=$(cyclonedx-go -o bom.xml)
        cd $GITHUB_WORKSPACE
        ;;

    "java")
        cd $DTRACK_DIR
        echo "TIZONA - Dependency Track: [*]  Processing Java BoM"
        if [ ! $? = 0 ]; then
            echo "TIZONA - Dependency Track: [-] Error executing Java build. Stopping the action!"
            exit 1
        fi

        wget https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz

        tar xzvf apache-maven-3.8.6-bin.tar.gz
        export PATH=/opt/apache-maven-3.8.6/bin:$PATH
        rm apache-maven-3.8.6-bin.tar.gz
        mv apache-maven-3.8.6 /opt
        echo "TIZONA - Dependency Track: Maven version:"
        mvn -v
        echo "JAVA VERSION:"
        java --version

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
cyclonedx convert --input-file $path --output-file sbom.xml --output-format json --output-version v1_2

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