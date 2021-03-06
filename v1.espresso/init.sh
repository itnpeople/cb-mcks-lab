#!/bin/bash
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
c_CSP_UPPER="$(echo ${CSP} | tr [:lower:] [:upper:])"



if [ "${CSP}" == "aws" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="ap-northeast-2";	c_ZONE="ap-northeast-2a"; fi
	if [ "${R}" == "tokyo" ];		then c_REGION="ap-northeast-1";	c_ZONE="ap-northeast-1a"; fi
	if [ "${R}" == "singapore" ];	then c_REGION="ap-southeast-1";	c_ZONE="ap-southeast-1a"; fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west-1";		c_ZONE="us-west-1b"; fi
	if [ "${R}" == "london" ];		then c_REGION="eu-west-2";		c_ZONE="eu-west-2a"; fi
	if [ "${R}" == "india" ];		then c_REGION="ap-south-1";		c_ZONE="ap-south-1a"; fi
fi
if [ "${CSP}" == "gcp" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="asia-northeast3";	c_ZONE="asia-northeast3-a"; fi
	if [ "${R}" == "tokyo" ];		then c_REGION="asia-northeast1";	c_ZONE="asia-northeast1-a"; fi
	if [ "${R}" == "singapore" ];	then c_REGION="asia-southeast1";	c_ZONE="asia-southeast1-a"; fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west2";			c_ZONE="us-west2-a"; fi
	if [ "${R}" == "london" ];		then c_REGION="europe-west2";		c_ZONE="europe-west2-a"; fi
fi


if [ "${c_REGION}" == "" ]; then echo "Variable 'c_REGION' empty"; exit 0; fi
if [ "${c_ZONE}" == "" ]; then echo "Variable 'c_ZONE' empty"; exit 0; fi


# ------------------------------------------------------------------------------
# 드라이버 등록
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/driver/${CSP}-driver-v1.0
curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/driver -d @- <<EOF
{
"DriverName"        : "${CSP}-driver-v1.0",
"ProviderName"      : "${c_CSP_UPPER}",
"DriverLibFileName" : "${CSP}-driver-v1.0.so"
}
EOF

# ------------------------------------------------------------------------------
# 리전 등록 #1
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/region/region-${CSP}-${R}
curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/region -d @- <<EOF
{
"RegionName"       : "region-${CSP}-${R}",
"ProviderName"     : "${c_CSP_UPPER}", 
"KeyValueInfoList" : [
	{"Key" : "Region", "Value" : "${c_REGION}"},
	{"Key" : "Zone",   "Value" : "${c_ZONE}"}]
}
EOF


# ------------------------------------------------------------------------------
# credential 환경변수
source ./credential.sh

# Credential 등록 #AWS
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/credential/credential-${CSP}-${R}

if [ "${CSP}" == "aws" ]; then 

curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential -d @- <<EOF
{
"CredentialName"   : "credential-${CSP}-${R}",
"ProviderName"     : "${c_CSP_UPPER}",
"KeyValueInfoList" : [
	{"Key" : "ClientId",       "Value" : "${c_AWS_KEY}"},
	{"Key" : "ClientSecret",   "Value" : "${c_AWS_SECRET}"}
]}
EOF

fi

# Credential 등록 #GCP
if [ "${CSP}" == "gcp" ]; then 

curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential -d @- <<EOF
{
"CredentialName"   : "credential-${CSP}-${R}",
"ProviderName"     : "${c_CSP_UPPER}",
"KeyValueInfoList" : [
	{"Key" : "ClientEmail", "Value" : "${c_GCP_SA}"},
	{"Key" : "ProjectID",   "Value" : "${c_GCP_PROJECT}"},
	{"Key" : "PrivateKey",  "Value" : "${c_GCP_KEY}"}
]}
EOF

fi


# ------------------------------------------------------------------------------
# 네임스페이스 (공통)
curl -sX DELETE -H "${c_AUTH}" -H "${c_CT}" ${c_URL_TUMBLEBUG}/ns/cb-${CSP}-namespace
curl -sX POST   -H "${c_AUTH}" -H "${c_CT}" ${c_URL_TUMBLEBUG}/ns -d @- <<EOF
{
	"name"        : "cb-${CSP}-namespace",
	"description" : "${c_CSP_UPPER}"
}
EOF



# ------------------------------------------------------------------------------
# 결과확인
echo "# ------------------------------------------------------------------------------"
echo "DRIVER";     curl -sX GET ${c_URL_SPIDER}/driver           -H "${c_CT}" | jq
echo "REGION";     curl -sX GET ${c_URL_SPIDER}/region           -H "${c_CT}" | jq
echo "CREDENTIAL"; curl -sX GET ${c_URL_SPIDER}/credential       -H "${c_CT}" | jq
echo "NAMESPACE";  curl -sX GET ${c_URL_TUMBLEBUG}/ns            -H "${c_AUTH}" -H "${c_CT}" | jq
