#!/bin/bash
ACCOUNTID=
REGION=
REPOSITORY=
IMAGE_TAG=
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNTID.dkr.ecr.$REGION.amazonaws.com
docker pull $ACCOUNTID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY:$IMAGE_TAG