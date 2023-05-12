#!/bin/bash

JDBC_USER=
JDBC_PASS=

kubectl create -f ./k8s/test-db.yaml

sleep 30
kubectl wait --for=condition=ready pod -l app=NBS

helm install elasticsearch -f ../charts/elasticsearch/values-local.yaml ../charts/elasticsearch

sleep 30
kubectl wait --for=condition=ready pod -l app=NBS

helm upgrade --install patient-search -f ../charts/patient-search/values-local.yaml --set jdbc.connectionString="jdbc:sqlserver://test-db.default.svc.cluster.local:1433;databaseName=NBS_ODSE;user=$JDBC_USER;password=$JDBC_PASS;encrypt=true;trustServerCertificate=true;" ../charts/patient-search

sleep 30
kubectl wait --for=condition=ready pod -l app=NBS

helm upgrade --install nifi -f ../charts/nifi/values-local.yaml --set jdbcConnectionString="jdbc:sqlserver://test-db.default.svc.cluster.local:1433;databaseName=NBS_ODSE;user=$JDBC_USER;password=$JDBC_PASS;encrypt=true;trustServerCertificate=true;',singleUserCredentialsPassword='fake.fake.fake.1234" ../charts/nifi