#!/bin/bash

ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text) #aws account number
REGION=us-east-1                                     #aws ECR region
SECRET_NAME=${REGION}-ecr-registry                    #secret_name
EMAIL=abc@xyz.com                                     #can be anything

TOKEN=`aws ecr --region=$REGION get-login-password`

kubectl delete secret --ignore-not-found $SECRET_NAME
kubectl create secret docker-registry $SECRET_NAME \
 --docker-server=https://501715613725.dkr.ecr.${REGION}.amazonaws.com \
 --docker-username=AWS \
 --docker-password="${TOKEN}" \
 --docker-email="${EMAIL}"
