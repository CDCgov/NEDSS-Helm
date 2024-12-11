# Troubleshooting EKS Cluster/Pod Issues

This document will list and describe all the identified or common
troubleshooting issues that could occur with EKS cluster and Pods

## Basic Troubleshooting

#### Checking Logs of a running Pods

> *We can only check logs on any running and active pods, using the command below.*
>
> kubectl logs \<pod_name\> -f (use -f flag to see the real time logs)

#### Checking Issue of the failed/evicted Pods

> *We can use the following command to describe the Pods and also help understand the issue that caused the Pod to fail*
>
> kubectl describe pods \<pod_name\>

#### Accessing the Pod's file system using terminal

> *We can use the following command to access the home directory of the running Pod (only on the running and live pod)*
>
> mode kubectl exec -it \<pod_name\> -n \<namespace\> \-- /bin/bash