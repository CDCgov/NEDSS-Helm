# Deploying Keycloak with Helm

This Helm chart is forked from bitnami keycloak helm chart
and uses bitnami configs with stock image maintained by keycloak
organization


## Internal references, github links, other documentation
1. https://github.com/CDCgov/NEDSS-Modernization/pull/814
2. https://helm.sh/docs/helm/helm/

## Prerequisites

1. IAM user or credentials to assume in a single account.
2. Helm executable
3. SQL client with the ability to connect to database instance

## Prepare Database:

1. copy nbs_keycloak.sql and edit to replace EXAMPLE password 
2. get RDS admin password from secrets manager 
3. connect to RDS instance in account with SSMS (install w/ powershell) 
4. install/use the aws cli if you have to fetch files from s3 
* msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi 
5. install SSMS to run sql
* connect with powershell
* cd Users\sso-username\Desktop
* & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' s3 cp s3://cdc-nbs-shared-software/SSMS-Setup-ENU.exe .
* connect to gui and install SSMS
6. run SQL Server Management Studio 19 and run SQL
* Authenticate to db server with DB endpoint, SQL auth, (in AWS retrieve
  admin user from RDS and "password" from secrets manager)
* select new query
* paste nbs_keycloak.sql into window
* "execute" 
* refresh in left pane and confirm keycloak db exists

## Copy and modify Values file
Need to change jdbc connect string and EXAMPLE passwords in values file
1. copy values.yaml file for specific environment

***AWS/Shell Example***
* paste aws credentials in session
* TMP_DB_ENDPOINT=$(aws rds describe-db-instances --query 'DBInstances[*].Endpoint.Address' --output text)
* TMP_SITE=<sitename>
* cp values.yaml values-keycloak-${TMP_SITE}.yaml
* sed --in-place "s/EXAMPLE_DB_ENDPOINT/${TMP_DB_ENDPOINT}/g" values-keycloak-${TMP_SITE}.yaml
2. Make KC_DB_PASSWORD match sql from above
* Other Values to update
  *   adminUser
  *   adminPassword
  *   KC_DB
  *   KC_DB_URL
  *   KC_DB_USERNAME
  *   KC_DB_PASSWORD
  *   KC_TRANSACTION_XA_ENABLED 
  *   externalDatabase.host
  *   externalDatabase.port
Search for EXAMPLE_ and replace

## Install Helm chart with new values
1. Connect to Kubernetes

***AWS/EKS example***
* TMP_CLUSTER=$(aws eks list-clusters --query 'clusters' --output text)
* aws eks update-kubeconfig --region us-east-1 --name ${TMP_CLUSTER}

2. test this worked
* kubectl get pods

###` Install Keycloak with Helm

1. change to parent directory
2. helm install keycloak --namespace keycloak --create-namespace -f keycloak/values-keycloak-${TMP_SITE}.yaml keycloak;  

## Port Forward to allow connection to Web UI
* export POD_NAME=$(kubectl get pods --namespace keycloak -o name) ; echo "Visit http://127.0.0.1:8080 to use your application"; kubectl --namespace keycloak port-forward "$POD_NAME" 8080;

## Connect to Web UI
* http://127.0.0.1:8080

## Add NBS Realm and clients
This can be done with the following command lines:
1. set file name
* TMP_REALM_FILE=NBS_Realm_with_DI_Client.json
2. copy json export file to container
* cat ${TMP_REALM_FILE} | kubectl exec --stdin -n keycloak "${POD_NAME}" -- /bin/bash -c "cat > /opt/keycloak/data/import/${TMP_REALM_FILE}" 
3. actually import the json file
* kubectl exec -it --namespace keycloak "${POD_NAME}" -- /opt/keycloak/bin/kc.sh  import --file /opt/keycloak/data/import/${TMP_REALM_FILE} 
Or via GUI using Create Realm then import

## Regenerate the client secret (and record to use with app integrations)
1. navigate to NBS realm
1. select clients
1. select di client
1. select credentials
1. regenerate secret
1. store client secret in secrets manager keycloak/client/secret/di

## cleanup
1. helm delete keycloak --namespace keycloak -f keycloak/values-keycloak-${TMP_SITE}.yaml keycloak;  


