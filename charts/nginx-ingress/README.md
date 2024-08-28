# Overview

Contained are the assests needed for nginx-ingress.

## Values

Default values for nginx-ingress charts.

| Key | Type | Default | Description |
| -------------- | -------------- | -------------- | -------------- |
| controller | string |  | Ingress controller configuration |


No defaults for this, needs to be documented in install guide if used
AND a placeholder added to make searches easier
loadBalancerSourceRanges:
  - ""  # Enter the CIDR range of the EKS VPC or pass it at run time as: controller.service.loadBalancerSourceRanges[0]
