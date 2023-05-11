# Deploy Desired Microservices Locally

## Overview
(WIP and subject to substantial changes)
The aim of this README is to provide step-by-step instructions in deploying existing microservices into a local kubernetes cluster.

## Prerequisites
1. Docker Desktop https://docs.docker.com/desktop/
   - Select either Windows or MAC installation
2. (WINDOWS ONLY) WSL2 installed: https://docs.docker.com/desktop/windows/wsl/.
3. Access to required AWS ECR 
4. Access to required AWS S3

## Quick Guide
(WIP and subject to substantial changes)
This section is intended to be used if you are familiar with docker desktop and kubernetes and want to run a few commands to get your microservice running. 
**NOTE: Check EACH shell script for additional parameters to be set within.**
1. Run the aws_kube_auth.sh file (ensure you are authenticated with AWS credentials locally).
2. Run download_legacy_db.sh
3. Run install_dependencies.sh
4. Create the local database from the provided kubernetes manifest [test-db.yaml](./k8s/test-db.yaml) (**ensure the proper image tag is set within**).
5. Use helm to deploy desired microservice with the reference to the **values-local.yaml** file provided within each helm chart directory.

## Enable Kubernetes in Docker Desktop (https://docs.docker.com/desktop/kubernetes/)
Once Docker Desktop has been successfully installed follow the steps below to enable Kubernetes.
1. Launch the application and click on the settings wheel next to your username/login
2. Select Kubernetes from menu
3. Select Enable Kubernetes then click on **Apply & restart**
4. (WINDOWS only) Kubernetes integration provides the Kubernetes CLI command at /usr/local/bin/kubectl on Mac and at C:\Program Files\Docker\Docker\Resources\bin\kubectl.exe on Windows. This location may not be in your shell’s PATH variable, so you may need to type the full path of the command or add it to the PATH
5. Open you command line interface and type `kubectl config use-context docker-desktop`
6. Verify the above steps have been completed successfully by using the command `kubectl get pods`. The output at this time should be: "No resources found in default namespace."

## Authentication to ECR
1. AWS credentials periodically expire. You must update your local credentials that allow access to ECR. 
2. Ensure Docker Desktop is running with Kubernetes enabled and run the following `sh aws_kube_auth.sh`. 
   - (WINDOWS) For windows users the same script can be from something like Git bash (this can be easily acheive through VS code's terminal). 
3. Authentication to ECR expires every 12 hours and so the script must be run again *only if* pulling a new/fresh image from the remote ECR is required.  

## Using Helm Charts
1. Helm charts for each microservice can be found within this repository under the [charts directory](../charts/)
2. Where specific parameters are required, a **values-local.yaml** file should be referenced for your local deployment of the helm chart. Minimal configuration is required. For your local deployment please modify the following under the **image** block in the yaml file.
   -  repository - This value can point to either the image in ECR (authentication required) or to your local images (by default local images are checked image first). If you do not know your local image repository it can be found either in Docker Desktop under Images or by running `docker image ls` on the command line.
   - tag - The image tag within the specified repository. If local, it can be found either in Docker Desktop under Images or by running `docker image ls` on the command line.
3. 

## Accessing Applications
The goal of this deployment is give developers access to resources in their local environments similar to those in a production setting. As such services are intended, where possible, to be accessed via localhost. Below is a list of microservices and how to access them should they be deployed in your local Kubernetes cluster.

1. nifi - in your browser naviaget to https://localhost/nifi/login

helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace