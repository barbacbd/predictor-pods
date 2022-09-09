<h1 align="center">
<br>Containerization</br>
  <a href="https://www.docker.com/">
    <img src=".images/docker.png" width="100" border-radius="50%"/>
  </a>
  <a href="https://podman.io/">
    <img src=".images/podman.png" width="100" border-radius="50%"/> 
  </a>
</h1>


The project contains the instructions and scripts for creating the [docker](https://www.docker.com/) or [podman](https://podman.io/) release pods for predictor. The pods will be used for batching runs of the predictor software on several input files. The entire predictor process can take a long
(unspecified) amout of time. The goal of this project is to reduce the overhead and time to execute the runs.

**Note**: _Podman and Docker can be used interchangeably throughout this document, unless specified otherwise_.

# Initialization


```bash
./CreatePods.sh
```

The [script to create pods](./CreatePods.sh) will build a Dockerfile and create the image, if an image does not exist. The Dockerfile is removed
at the end of the script, if it was created. At the conclusion of the script, the containers will be run and their results will be added to the
`artifacts` directory.

