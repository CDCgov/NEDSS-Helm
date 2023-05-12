#!/bin/bash

kubectl delete -f ./k8s/test-db.yaml
helm delete elasticsearch 
helm delete nifi
helm delete patient-search
