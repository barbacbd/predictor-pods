#!/bin/bash

set -eux
################################################################################
# CreatePods is intended to create the containers or pods that will            #
# execute the Predictor code on a set of input data files. A single pod        #
# is created for each file, and the artifacts of each run will be saved.       #
# Args: All data/input files to run predictor on.                              #
################################################################################

# Name of the podman/docker image.
IMAGE_NAME="predictor"
FINAL_ARTIFACTS_DIR="artifacts"
# List of files that were found
ValidFiles=()
NumClusters=50
NumFeatures=2

# Determine if an image already exists.
# in the event that the user wants a newer version of the image, then
# the user can delete the image and new one will be built here.
FoundImages=$(podman image ls | grep "${IMAGE_NAME}")


# Function to LOG or echo a string to the screen with a different color
function LOG() {
    echo -e "\033[0;34m${1}\033[0m"
}

# Function to log and FAIL immediately.
# The function can accept any number of parameters
# but 1 must be provided as it will be LOGGED
function ExitWithError() {
    LOG "${1}"
    exit 1
}

# For each file in the list of arguements,
# make sure the file exists
# Create the dockerfile information
for filename in "$@"
do
    if [ -f "$filename" ]; then
	LOG "adding ${filename} as valid ..."
	ValidFiles+=("$filename")
    else
	LOG "failed to find file: ${filename}"
    fi
done

# Error out when no valid files were found
if [ ${#ValidFiles[@]} -eq 0 ]; then
    ExitWithError "no valid files found ..."
fi

# TODO: Add in the the token rather than the id RSA file
function CreateDockerfile() {
    cat <<EOF >Dockerfile
from fedora:latest
MAINTAINER "Brent Barbachem"

# Update all packages
RUN dnf update -y

# R is a dependency to this package and must be installed
# prior to installing the R-python pacakge.
RUN dnf install -y \\
    R \\
    python3-devel \\
    python3-pip \\
    git \\
    openssh \\
    openssh-clients \\
    emacs \\
    vim \\
    gcc \\
    gcc-c++

# Copy All ssh keys over from the home environment. This
# will allow us to grab the github project
# Note: You will need to copy your ssh private key here as id_rsa
COPY id_rsa /root/.ssh/id_rsa
RUN chmod -R 600 /root/.ssh

RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# Grab the lastest package source.
RUN git clone git@github.com:barbacbd/predictor.git

# Copy the script over to the container
COPY ExecPods.sh /ExecPods.sh

# Grab my specific source code for the FEAST project
# I forked this project (do NOT own it) and have made my modifications
# so that there is an extensive python extension.
# Pull that data here and build the source on this vm
RUN git clone git@github.com:barbacbd/FEAST.git
RUN cd FEAST && git checkout pyfeast_v2
RUN cd FEAST/python && bash -c "./build.sh"

# upgrade pip
RUN python3 -m pip install pip --upgrade

# install the project requirements
RUN python3 -m pip install -r predictor/requirements.txt

RUN git config --global user.email "barbacbd@dukes.jmu.edu"
RUN git config --global user.name "Brent Barbachem"

ENTRYPOINT ["./ExecPods.sh"]

EOF
}


# If images matching the query were found, then the image will be
# used. If no image was found, then a new docker/podman image will
# be created.
if [[ ! -z "${FoundImages}" ]]; then
    LOG "${FoundImages}"
else

    if [ ! -f "Dockerfile" ]; then
	LOG "creating dockerfile ..."
	CreateDockerfile
    else
	LOG "warning: Dockerfile exists, please ensure that this is the correct file."
    fi

    LOG "building image ..."
    # Create the image from the Dockerfile that was just created
    podman build . -t ${IMAGE_NAME}:latest
fi


# Create the final location for artifacts
if [ -d "$FINAL_ARTIFACTS_DIR" ]; then
    LOG "warning: ${FINAL_ARTIFACTS_DIR} exists, possibly overriding data ..."
else
    LOG "creating ${FINAL_ARTIFACTS_DIR} directory ..."
    mkdir ${FINAL_ARTIFACTS_DIR}
fi

# change the directory by pushing artifacts dir to the stack
pushd ${FINAL_ARTIFACTS_DIR}
# Do NOT move, will be wrong if moved above the pushd
CurDir=`pwd`
LOG "Current directory set to ${CurDir}"

# [Re]find the image information, as it may not have existed when first executed
# But it should definitely exist now ...
# If it does not exist, fail immediately
ImageToUse=$(podman image ls | grep "${IMAGE_NAME}")
if [[ -z "${ImageToUse}" ]]; then
    ExitWithError "no image found ..."
fi

# Find the Name and Tag for the image that will be used.
IMAGE=$(echo $ImageToUse | awk '{print $1}')
TAG=$(echo $ImageToUse | awk '{print $2}')
LOG "using image: ${IMAGE}:${TAG}"

# For each valid file, create a container and run the
# all necessary scripts to create the output for the container
for filename in "${ValidFiles[@]}"
do
    # Remove path from the filename
    IFS="/"
    read -ra SplitFilename <<<"$filename"
    PureFilename="${SplitFilename[-1]}"

    # Remove extension from the filename
    IFS="."
    read -ra SplitPure <<<"$PureFilename"
    DirName="${SplitPure[0]}"

    if [[ ! -z "${DirName}" ]]; then
	if [ -d "$DirName" ]; then
	    LOG "warning: Deleting ${DirName}, all data will be lost ..."

	    LOG "sleeping for 5 seconds to give the user time to kill ..."
	    # provide time to stop this action
	    sleep 5

	    rm -rf "${DirName}"
	fi

	LOG "creating directory: ${DirName}"
	mkdir "${DirName}"

	LOG "creating ${DirName}/configuration.yaml"
	LOG "Number of clusters: ${NumClusters}"
	LOG "Number of features: ${NumFeatures}"
	cat <<EOF >${DirName}/configuration.yaml
cluster_algorithms:
- K_MEANS
crit_algorithms:
- Ball_Hall
- Banfeld_Raftery
- C_index
- Calinski_Harabasz
- Davies_Bouldin
- Det_Ratio
- Dunn
- Gamma
- G_plus
- Ksq_DetW
- Log_Det_Ratio
- Log_SS_Ratio
- McClain_Rao
- PBM
- Point_Biserial
- Ray_Turi
- Ratkowsky_Lance
- Scott_Symons
- SD_Scat
- SD_Dis
- S_Dbw
- Silhouette
- Tau
- Trace_W
- Trace_WiB
- Wemmert_Gancarski
- Xie_Beni
extras:
  beta: 1.0
  gamma: 1.0
  init: k-means++
filenames: ${filename}
max_number_of_clusters: ${NumClusters}
number_of_features: ${NumFeatures}
selected_features:
- CMIM
- discCMIM
- BetaGamma
- discBetaGamma
- CondMI
- discCondMI
- DISR
- discDISR
- ICAP
- discICAP
- JMI
- discJMI
- MIM
- discMIM
- mRMR_D
- disc_mRMR_D
- weightedCMIM
- discWeightedCMIM
- weightedCondMI
- discWeightedCondMI
- weightedDISR
- discWeightedDISR
- weightedJMI
- discWeightedJMI
- weightedMIM
- discWeightedMIM

EOF

	# this directory will serve as the location that will hold the artifacts
	# for a particular run. This directory will also contain the original data/
	# observations file that is copied here
	LOG "copying ${filename} to ${FINAL_ARTIFACTS_DIR}/${DirName}"
	cp "${filename}" "${DirName}"

	# Start a container and expose the new directory to the container
	# DO NOT Remove & as the pods will run until termination in the background
	podman run -v "${CurDir}/${DirName}":/artifacts ${IMAGE}:${TAG} &
    fi
done

# Wait for all pods to finish executing
wait

# Remove ARTIFACTS DIR from the stack
LOG "returning to original directory ..."
popd

