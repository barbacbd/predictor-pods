#!/bin/bash

REPO_NAME="predictor"
BRANCH="master"
ARTIFACTS_DIR="artifacts"
DEPS_FILE="dependencies.txt"


# If a new dependencies.txt file exists in the ARTIFACTS_DIR, all
# new dependencies and/or upgrades should be installed
if [ -f "${ARTIFACTS_DIR}/${DEPS_FILE}" ]; then
    LOG "installing dependencies ..."
    yum install -y $(cat "${ARTIFACTS_DIR}/${DEPS_FILE}")
else
    LOG "did not find ${DEPS_FILE} ..."
fi


# Upgrade all dependencies of the predictor project and install the latest version
# of the predictor project from the main/master branch
if [ ! -d "${REPO_NAME}" ]; then
    ExitWithError "failed to find ${REPO_NAME}"
fi

LOG "pushing ${REPO_NAME} on to stack ..."
pushd ${REPO_NAME}

LOG "pulling latest source ..."
git checkout ${BRANCH}
git pull

LOG "installing latest dependencies ..."
pip3 install -r requirements.txt

LOG "installing latest source ..."
pip3 install . --upgrade


# Find all files that we need to run this software against
DataFiles=$(find ${ARTIFACTS_DIR} -type f -not -name ${DEPS_FILE})
if [ ${#DataFiles[@]} -ne 1 ]; then
    ExitWithError "the software should only have one data file provided ..."
fi

# execute the prediction software
predictor execute -vvvv -d "$ARTIFACTS_DIR"
