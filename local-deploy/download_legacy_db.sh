#!/bin/bash
ACCOUNTID=
REGION=
REPOSITORY=
IMAGE_TAG=1.0.7-SNAPSHOT.83fd108
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNTID.dkr.ecr.$REGION.amazonaws.com
docker pull $ACCOUNTID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY:$IMAGE_TAG