# Metabase Installation on EKS using Helm charts

This document will help understand the installation and running of
Metabase on AWS EKS, using Helm charts. This Metabase page can be
accessed from any browser from [EQ Metabase
Instance](https://metabase.datateam-cdc-nbs.eqsandbox.com/).

## Prerequisites

-   EKS instance is running and you are added to the admin role to
    install and run the containers

-   RDS (Postgres) for App DB running on the same VPC

-   **Install Kubernetes CLI tool** on your local machine to interact
    with containers on the EKS cluster

    -   <https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/>

-   **Install Helm CLI tool** on your local machine to run commands on
    the containers on the EKS cluster

    -   For installation on Mac OS:

        -   Make sure that your home brew package manager is up-to-date
            -- brew update

        -   Install helm using home brew -- brew install helm

        -   Verify the installation -- helm version

## Installing Metabase using EKS

### Connecting to the EKS Cluster:

-   Go to the AWS login page and click on Command line or Programmatic
    access

We need to have Admin access to the AWS console, in order to access the
cluster to install and run kubernetes containers

-   Select one of the options to Get the credentials to access the
    console using the command line access, in our case we are selecting
    the Option 1: Set AWS environment variables (Short-term credentials)

-   Copy and run the above export commands for the credentials into the
    terminal

-   Run the below command on your terminal to connect to the eks cluster
    using the provided the role

> aws eks --region us-east-1 update-kubeconfig --name cdc-nbs-sandbox-cluster;

### Installing Metabase (PostgreSQL as App DB):

-   Following command will install and run the Metabase on the EKS
    cluster

    -   use the metabase-config.yaml file to provide the additional
        connection parameters such as PostgreSQL database information
        for the Metabase's App DB, and also used to provide the App
        version information, etc.

> helm install metabase <helm_chart_path\> -f <path\>/values_sandbox.yaml

Before proceeding to Installation we need to make sure that our EKS 
and RDS are connected to allow traffic going both ways.

Please make sure you pass the correct path for the helm chart and 
path for the yaml file

-   Now you should be able to access the Metabase Instance from the host
    name provided in the ingress rules (check your values\_\<env\>.yaml)

example: In this installation, you can access metabase from
<https://metabase.datateam-cdc-nbs.eqsandbox.com/>

If you don't have a DNS setup available for metabase, use the following
steps to access the metabase instance from the POD ip address

### Accessing Metabase from browser:

-   Once the installation is done, we can access metabase app on the
    same IP address as the metabase pod, and on port 3000.

    -   Run the command kubectl get pods -o wide to identify the IP
        address of the POD running Metabase server

![](media/image4.png)

example: In the current installation you can access metabase from: http://10.52.1.60:3000/
