#/bin/bash -x
PROJECT=$1
ZONE=$2
gcloud config set compute/zone ${ZONE}
gcloud config set project ${PROJECT}