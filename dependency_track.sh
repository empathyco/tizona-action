#!/bin/sh -l

DTRACK_URL=$1
DTRACK_KEY=$2
DTRACK_LANGUAGE=$3

INSECURE="--insecure"
#VERBOSE="--verbose"

# Access directory where GitHub will mount the repository code
# $GITHUB_ variables are directly accessible in the script
cd $GITHUB_WORKSPACE

case $DTRACK_LANGUAGE in
    "nodejs")
        lscommand=$(ls)
        echo "[*] Processing NodeJS BoM"
        apt-get install --no-install-recommends -y nodejs
        npm install
        npm audit fix --force
        if [ ! $? = 0 ]; then
            echo "[-] Error executing npm install. Stopping the action!"
            exit 1
        fi
        npm install -g @cyclonedx/bom
        path="bom.xml"
        cyclonedx-bom --help
        BoMResult=$(cyclonedx-bom -o bom.xml)
        ;;
    
    "python")
        echo "[*]  Processing Python BoM"
        apt-get install --no-install-recommends -y python3 python3-pip
        freeze=$(pip freeze > requirements.txt)
        if [ ! $? = 0 ]; then
            echo "[-] Error executing pip freeze to get a requirements.txt with frozen parameters. Stopping the action!"
            exit 1
        fi
        pip install cyclonedx-bom
        path="bom.xml"
        BoMResult=$(cyclonedx-py -o bom.xml)
        ;;
    
    "golang")
        echo "[*]  Processing Golang BoM"
        if [ ! $? = 0 ]; then
            echo "[-] Error executing go build. Stopping the action!"
            exit 1
        fi
        path="bom.xml"
        BoMResult=$(cyclonedx-go -o bom.xml)
        ;;

    "java")
        echo "[*]  Processing Java BoM"
        if [ ! $? = 0 ]; then
            echo "[-] Error executing Java build. Stopping the action!"
            exit 1
        fi
        apt-get install --no-install-recommends -y build-essential default-jdk maven
        path="target/bom.xml"
        BoMResult=$(mvn compile)
        ;;
        
    *)
        "[-] Project type not supported: $DTRACK_LANGUAGE"
        exit 1
        ;;
esac    

if [ ! $? = 0 ]; then
    echo "[-] Error generating BoM file: $BomResult. Stopping the action!"
    exit 1
fi

echo "[*] BoM file succesfully generated"

# Cyclonedx CLI conversion
echo "[*] Cyclonedx CLI conversion"
#Does not upload to dtrack when output format = xml (every version available)
cyclonedx-cli convert --input-file $path --output-file sbom.xml --output-format json_v1_2

# UPLOAD BoM to Dependency track server
echo "[*] Uploading BoM file to Dependency Track server"
upload_bom=$(curl $INSECURE $VERBOSE -s --location --request POST $DTRACK_URL/api/v1/bom \
--header "X-Api-Key: $DTRACK_KEY" \
--header "Content-Type: multipart/form-data" \
--form "autoCreate=true" \
--form "projectName=$GITHUB_REPOSITORY" \
--form "projectVersion=$GITHUB_REF" \
--form "bom=@sbom.xml")

token=$(echo $upload_bom | jq ".token" | tr -d "\"")
echo "[*] BoM file succesfully uploaded with token $token"


if [ -z $token ]; then
    echo "[-]  The BoM file has not been successfully processed by OWASP Dependency Track"
    exit 1
fi

echo "[*] Checking BoM processing status"
processing=$(curl $INSECURE $VERBOSE -s --location --request GET $DTRACK_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DTRACK_KEY" | jq '.processing')


while [ $processing = true ]; do
    sleep 5
    processing=$(curl  $INSECURE $VERBOSE -s --location --request GET $DTRACK_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DTRACK_KEY" | jq '.processing')
    if [ $((++c)) -eq 10 ]; then
        echo "[-]  Timeout while waiting for processing result. Please check the OWASP Dependency Track status."
        exit 1
    fi
done

echo "[*] OWASP Dependency Track processing completed"

# wait to make sure the score is available, some errors found during tests w/o this wait
sleep 5

echo "[*] Retrieving project information"
project=$(curl  $INSECURE $VERBOSE -s --location --request GET "$DTRACK_URL/api/v1/project/lookup?name=$GITHUB_REPOSITORY&version=$GITHUB_REF" \
--header "X-Api-Key: $DTRACK_KEY")

echo "$project"

project_uuid=$(echo $project | jq ".uuid" | tr -d "\"")
risk_score=$(echo $project | jq ".lastInheritedRiskScore")
echo "Project risk score: $risk_score"

echo "::set-output name=riskscore::$risk_score"