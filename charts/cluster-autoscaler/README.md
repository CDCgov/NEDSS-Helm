# cluster-autoscaler

AWS Cluster Autoscaler values for NBS EKS environments.

## Overview

This directory contains the Helm values file for deploying the upstream [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) chart to NBS EKS clusters. No wrapper chart — just a values file passed directly to the upstream chart.

Primary use case: automatically scale EKS node groups up when pods can't be scheduled due to insufficient resources, and scale down when nodes are underutilized.

> **Note:** This is AWS-only. Azure AKS has node pool autoscaling built in via Terraform (`auto_scaling_enabled = true`), so no separate Helm chart is needed.

## How It Works

The autoscaler runs as a Deployment in `kube-system` and:

1. Monitors for unschedulable pods (pods stuck in `Pending` due to insufficient node resources)
2. Discovers EKS managed node group ASGs via auto-discovery tags
3. Scales up by increasing the ASG desired count to provision new nodes
4. Scales down by draining underutilized nodes and reducing the ASG desired count

## Directory Structure

```
charts/cluster-autoscaler/
├── values.yaml     # All config — autoDiscovery, IRSA, region
└── README.md
```

## Prerequisites

- Helm 3.12+
- `kubectl` access to the target EKS cluster
- IRSA role created via Terraform (see [IRSA Setup for EKS](#irsa-setup-for-eks) below)
- EKS managed node group ASGs tagged for auto-discovery (see [ASG Tags](#asg-tags) below)

## Deploy to EKS

Before deploying, complete the [IRSA Setup for EKS](#irsa-setup-for-eks) section below to create the IAM role and policy.

```bash
# Add upstream repo
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

# Update placeholders in values.yaml:
#   autoDiscovery.clusterName, awsRegion, rbac.serviceAccount.annotations

# Deploy
helm install cluster-autoscaler \
  autoscaler/cluster-autoscaler \
  -f values.yaml \
  -n kube-system
```

## Verify the Deployment

```bash
# Check pod is running
kubectl -n kube-system get pods \
  -l "app.kubernetes.io/name=aws-cluster-autoscaler,app.kubernetes.io/instance=cluster-autoscaler"

# Verify SA has the IRSA annotation
kubectl get sa cluster-autoscaler-aws-cluster-autoscaler \
  -n kube-system \
  -o jsonpath='{.metadata.annotations}'

# Check autoscaler logs for successful ASG discovery
kubectl logs -l app.kubernetes.io/name=aws-cluster-autoscaler \
  -n kube-system --tail=30
```

Healthy logs show:
- `Found multiple availability zones for ASG "eks-..."` — ASG discovered
- `Starting main loop` every 10 seconds — autoscaler running
- No `AccessDenied` or `NoCredentialProviders` errors

## ASG Tags

Auto-discovery requires the EKS managed node group ASGs to have these tags:

| Tag Key | Tag Value |
|---|---|
| `k8s.io/cluster-autoscaler/enabled` | `true` |
| `k8s.io/cluster-autoscaler/<YOUR_CLUSTER_NAME>` | `owned` |

If using the `terraform-aws-modules/eks` module, these tags are set automatically on managed node groups. Verify in the EC2 console under Auto Scaling Groups.

## IRSA Setup for EKS

The autoscaler needs AWS IAM permissions to discover and scale ASGs. IRSA (IAM Roles for Service Accounts) provides these credentials without static access keys.

### Step 1: Enable the IRSA module

In your Terraform configuration that calls the `eks-nbs` module from [NEDSS-Infrastructure](https://github.com/CDCgov/NEDSS-Infrastructure), set:

```hcl
create_cluster_autoscaler_irsa  = true
cluster_autoscaler_cluster_name = "<YOUR_EKS_CLUSTER_NAME>"
```

### Step 2: Apply Terraform

```bash
terraform plan   # Expect 3 new resources: IAM policy, IRSA role, role-policy attachment
terraform apply
```

### Step 3: Get the role ARN

```bash
terraform output -json | jq '.cluster_autoscaler_irsa_role_arn'
```

Use this ARN as the value for `rbac.serviceAccount.annotations.eks.amazonaws.com/role-arn` in `values.yaml`.

### IAM Policy Details

The IRSA policy grants:

- **Describe** (read-only): `autoscaling:DescribeAutoScalingGroups`, `autoscaling:DescribeTags`, `ec2:DescribeInstanceTypes`, `ec2:DescribeLaunchTemplateVersions`, `eks:DescribeNodegroup`, and related actions. These use `Resource: "*"` as the APIs do not support resource-level restrictions.
- **Scale** (write): `autoscaling:SetDesiredCapacity`, `autoscaling:TerminateInstanceInAutoScalingGroup`. These are scoped via tag-based IAM conditions (`k8s.io/cluster-autoscaler/enabled` and `k8s.io/cluster-autoscaler/<cluster-name>`) per [upstream best practices](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md).

## Private Clusters

If your EKS cluster has public endpoint access disabled (`endpointPublicAccess: false`), you need a VPC interface endpoint for the EKS API so the autoscaler can call `eks:DescribeNodegroup`.

Check your cluster's endpoint access:

```bash
aws eks describe-cluster --name <CLUSTER_NAME> --region <REGION> \
  --query 'cluster.resourcesVpcConfig.{publicAccess:endpointPublicAccess,privateAccess:endpointPrivateAccess}'
```

If `publicAccess: false`, create a VPC interface endpoint for `com.amazonaws.<region>.eks` with `private_dns_enabled = true`. See [Access Amazon EKS using AWS PrivateLink](https://docs.aws.amazon.com/eks/latest/userguide/vpc-interface-endpoints.html).

## Recommendations

## **PodDisruptionBudgets:** It is strongly recommended to configure PDBs for critical services before enabling the autoscaler. Without PDBs, scale-down events may cause brief service disruptions as pods are evicted and rescheduled. For single-replica services, consider running 2 replicas with `minAvailable: 1` for zero-downtime scale-down.

**Resource Requests:** Ensure all workloads have accurate resource requests. The autoscaler uses requests (not actual usage) to determine node utilization and scheduling feasibility.

## Will This Disrupt My Cluster?

**Scale-up: No.** The autoscaler adds nodes — existing pods are unaffected.

**Scale-down: Possible brief disruption.** When the autoscaler removes an underutilized node, pods on that node are evicted and rescheduled on remaining nodes. Single-replica services will experience a brief outage during rescheduling. PDBs and multiple replicas mitigate this.

To remove: `helm uninstall cluster-autoscaler -n kube-system`

## Troubleshooting

**Autoscaler pod running but no ASG discovery?**
Check the SA annotation is set and correct. Missing IRSA annotation means no AWS credentials.

**`AccessDenied` in logs?**
The IRSA role ARN in the SA annotation doesn't match the role, or the IAM policy is missing permissions.

**ASG not scaling up?**
Verify ASG tags (`k8s.io/cluster-autoscaler/enabled=true`). Check `max_nodes_count` in Terraform — the autoscaler won't exceed the ASG max.

**ASG not scaling down?**
Check node utilization thresholds in logs. Nodes above `scale-down-utilization-threshold` (default 50%) won't be considered. Pods with `safe-to-evict: "false"` annotation or PDBs with `minAvailable` equal to replica count will block scale-down.
