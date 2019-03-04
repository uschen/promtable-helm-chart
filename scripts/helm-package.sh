#!/bin/bash
#
# Generate all etcd protobuf bindings.
# Run from repository root.
#
set -e

## Control script
SYNC_CHART_REPO=${SYNC_CHART_REPO:=false}

function usage()
{
    echo "helm-package"
    echo ""
    echo "./helm-package.sh"
    echo "\t-h --help"
    echo "\t--sync-repo=$SYNC_CHART_REPO"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --sync-repo)
            SYNC_CHART_REPO=true
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


function main() {
gen_helm_package
gen_index

if [ "$SYNC_CHART_REPO" = true ] ; then
    echo "Will Sync Chart Repo ..."
    sync_repo
fi

}


CURRENT_GIT_BRANCH=$(git branch | grep \* | cut -d ' ' -f2)
CHART_DESTINATION_FOLDER=${CHART_DESTINATION_FOLDER:="./_charts"}
CHART_REPO_BUCKET=${CHART_REPO_BUCKET:="promtable-chart"}
CHART_REPO_FOLDER=${CHART_REPO_FOLDER:=""}
CHART_REPO_URL=${CHART_REPO_URL:="https://$CHART_REPO_BUCKET.storage.googleapis.com/$CHART_REPO_FOLDER"}
CHART_DEPENDENCY_UPDATE=${CHART_DEPENDENCY_UPDATE:="true"}


function gen_helm_package() 
{
mkdir -p $CHART_DESTINATION_FOLDER

rm -rf $CHART_DESTINATION_FOLDER/*

echo "
#######################################
##   Generate Helm Chart Packages    ##
#######################################
"

mkdir -p $CHART_DESTINATION_FOLDER

echo "
---------------------------------------
DESTINATION: ${CHART_DESTINATION_FOLDER}
---------------------------------------
"

## Generate a list of paths of charts

CHART_DIRS="./promtable"


for CHART_FOLDER in ${CHART_DIRS}; do
helm package $CHART_FOLDER \
--destination=$CHART_DESTINATION_FOLDER \
--dependency-update=$CHART_DEPENDENCY_UPDATE \
--save=false \
--version=$CHART_VERSION \
--debug

done

}


function gen_index()
{

echo "
#######################################
##   Generate Helm Chart Index       ##
#######################################
"

echo "
---------------------------------------
REPO: ${CHART_REPO_URL}
---------------------------------------
"

helm repo index $CHART_DESTINATION_FOLDER/ --url $CHART_REPO_URL

}

function sync_repo()
{
./scripts/helm-sync-repo.sh $CHART_DESTINATION_FOLDER $CHART_REPO_BUCKET/$CHART_REPO_FOLDER
}


main
