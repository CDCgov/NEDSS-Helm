## Description

Please include a summary of the changes and any key information a reviewer may need. Review the appropriate section below.


## Creating a new Helm chart?
1. Does the service require an ingress?
    - Kubernetes Ingress resource are PATH based and only handled by modernization-api and dataingestion-service helm charts. 
    - Currently, names of Kubernetes services have to be predictable if an ingress needs to point to them
2. Chart directory structure (specific environment values.yaml files are allowed at the same level as values.yaml)
    ```  
    |── charts
        ├── new-helm-chart
            ├── templates
            |   ├── tests
            |   ├── helpers.tpl
            |   ├── *.yaml
            |   └─ Chart.yaml
            ├── values.yaml
            └─  README.md
    ```    
3. **Do not include secret values anywhere in a Helm chart, take special care when creating values.yaml**
4. values.yaml is annotated to include parameter description and format as appropriate.
    - values.yaml is considered the production/default parameter file and should point to publically available container registries, if the service is publically available.    

## Updating a Helm Chart?
1. Ensure no secrets have been committed.
2. Ensure updates to existing Helm charts follow the guidelines contained in section [Creating a new Helm chart](#creating-a-new-helm-chart).

