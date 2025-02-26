# NEDSS ArgoCD Application Deployment

## Overview

This repository contains helm chart to deploy ArgoCD applications related to the NBS7. The purpose is to deploy or upgrade a version of NBS7 services in bulk. Once deployed, users can manage each application using ArgoCD UI.

### Install ArgoCD Applications

- If deploying in **Azure**, move Azure folder in templates directory
- `helm install nbs .\argocd -f .\argocd\<ADD-VALUES-FILE>.yaml --debug`

### Upgrade ArgoCD Applications

- `helm upgrade nbs .\argocd-7.8.2 -f .\argocd\<ADD-VALUES-FILE>.yaml --debug`

### Delete ArgoCD Applications

- `helm uninstall nbs`
- `kubectl delete applications --all -n argocd`


## Notes
- Deleting helm will not delete ArgoCD Applications.
    - If helm upgrade is failing or stuck, delete and deploy helm. Since ArgoCD Application are not deleted, previous Application will be updated.
- job-wait.yaml adds a sleep in order to orchestrate service deployment
- Following annotation are required allow helm orchestration (https://argo-cd.readthedocs.io/en/stable/user-guide/helm/#helm-hooks)
    - helm.sh/hook: post-install, post-upgrade = This annotation specifies that the associated resource should be executed after the installation (post-install) and after an upgrade (post-upgrade) of the Helm release.
    - helm.sh/hook-weight: "4" = This annotation assigns a weight to the hook, determining the order in which hooks are executed when multiple hooks of the same type are defined. Helm executes hooks with lower weights first. Weights can be positive or negative numbers but must be represented as strings.
    - helm.sh/hook-delete-policy: "hook-succeeded,hook-failed" = This annotation defines the deletion policies for the hook resource. The specified policies determine when the resource should be deleted after execution:
        - hook-succeeded: Delete the resource after the hook has successfully executed.
        - hook-failed: Delete the resource if the hook failed during execution.
