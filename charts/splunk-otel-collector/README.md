# splunk-otel-collector

OTEL Log Collector values for NBS environments — replaces FluentBit.

## Overview
This directory contains the Helm values file for deploying the upstream [Splunk OpenTelemetry Collector for Kubernetes](https://github.com/signalfx/splunk-otel-collector-chart) chart to NBS clusters. No wrapper chart — just a values file passed directly to the upstream chart.

### Log Destinations

| Destination | Status | How to Enable |
|---|---|---|
| **AWS S3** | Configured | Update `<S3_BUCKET_NAME>` and `<AWS_REGION>` in values.yaml |
| **Azure Blob** | Placeholder | Uncomment `azureblob` exporter and supply connection string |
| **Splunk HEC** | Placeholder | Replace `token` with real HEC token |

## Directory Structure

```
charts/splunk-otel-collector/
├── values.yaml     # All config — S3, Azure Blob, Splunk, multiline, excludePaths
└── README.md
```

## Prerequisites

- Helm 3.12+
- `kubectl` access to the target cluster
- For S3: an existing S3 bucket + IAM permissions (see [S3 Setup](#s3-setup-for-eks))
- For Azure Blob: an existing Storage Account + container + connection string
- For Splunk: a HEC token

## Deploy to EKS

```bash
# Add upstream repo
helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart
helm repo update

# Update placeholders in values.yaml:
#   clusterName, environment, s3_bucket, region

# Deploy
helm install splunk-otel-collector \
  splunk-otel-collector-chart/splunk-otel-collector \
  -f values.yaml \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/<IRSA_ROLE_NAME>" \
  -n observability --create-namespace --skip-schema-validation
```

## Deploy to AKS

1. Update `clusterName` and `environment` in values.yaml
2. Uncomment the `azureblob` exporter and add it to the pipeline exporters
3. Replace EKS `excludePaths` with AKS ones (see comments in values.yaml)
4. Comment out the `awss3` exporter if not needed

```bash
helm install splunk-otel-collector \
  splunk-otel-collector-chart/splunk-otel-collector \
  -f values.yaml \
  --set "agent.config.exporters.azureblob.connection_string=<CONNECTION_STRING>" \
  -n observability --create-namespace --skip-schema-validation
```

## S3 Setup for EKS

The OTEL collector **does NOT create S3 buckets**. Create the bucket and IAM permissions before deploying.

### Step 1: Create S3 bucket

```bash
aws s3 mb s3://<BUCKET_NAME> --region <REGION>
```

### Step 2: Create IAM policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetBucketLocation"],
      "Resource": [
        "arn:aws:s3:::<BUCKET_NAME>",
        "arn:aws:s3:::<BUCKET_NAME>/*"
      ]
    }
  ]
}
```

### Step 3: Create IRSA role

1. Get the cluster OIDC provider:
   ```bash
   aws eks describe-cluster --name <CLUSTER_NAME> --region <REGION> \
     --query "cluster.identity.oidc.issuer" --output text
   ```
2. Create an IAM role with Web Identity trust policy using the OIDC URL
3. Set the trust condition to: `system:serviceaccount:observability:splunk-otel-collector`
4. Attach the S3 write policy to the role

### Step 4: Deploy with IRSA

```bash
helm install splunk-otel-collector \
  splunk-otel-collector-chart/splunk-otel-collector \
  -f values.yaml \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>" \
  -n observability --create-namespace --skip-schema-validation
```

### Step 5: Verify logs in S3

```bash
aws s3 ls s3://<BUCKET_NAME>/otel-logs/ --recursive --region <REGION> | head -20
```

## Will this disrupt my cluster?

**No.** The OTEL collector is purely additive:

- Deploys as a new DaemonSet in its own `observability` namespace
- Reads from `/var/log/pods/` on the node filesystem (read-only)
- Does NOT modify, restart, or interfere with any existing pods
- Resource requests are modest (100m CPU / 256Mi RAM per node)

To remove: `helm uninstall splunk-otel-collector -n observability`

## How It Works

The collector deploys as a DaemonSet — one agent per node. Each agent tails `/var/log/pods/` on its node and ships logs to the configured exporters.

### Crash Log Durability

When a pod crashes:
1. Kubernetes preserves the crash logs on the node filesystem
2. The OTEL agent (separate pod) reads them and ships to S3/Blob/Splunk
3. The persistent queue buffers unsent logs to disk if the agent itself restarts

### Multiline Stack Traces

Java stack traces from NBS pods are combined into single log records. Update `namespaceName` in the multiline config to match where your NBS pods are deployed.

## Validation

```bash
# Check agent pods
kubectl get pods -n observability -l app=splunk-otel-collector

# Agent logs
kubectl -n observability logs -l app=splunk-otel-collector --tail=30

# Check S3 for recent logs
aws s3 ls s3://<BUCKET_NAME>/otel-logs/ --recursive --region <REGION> | tail -5

# Effective collector config (port-forward method)
kubectl -n observability port-forward <agent-pod> 55554:55554
# Then in separate terminal:
curl http://localhost:55554/debug/configz/effective
```

## Post-Deployment Checklist

- [ ] OTEL agent pods running on all nodes
- [ ] Logs flowing to configured destination (S3 / Blob / Splunk)
- [ ] Simulate a pod crash → confirm logs persist across agent restart

## Troubleshooting

**Agent pods won't start?**
The upstream chart requires `splunkPlatform.token` to be set. Use `"placeholder"` if Splunk isn't active.

**No logs in S3?**
1. Check agent logs: `kubectl -n observability logs <agent-pod> | grep -i s3`
2. Verify IAM: does the pod's ServiceAccount have `s3:PutObject`?
3. Verify bucket exists: `aws s3 ls s3://<bucket-name>/`
4. Check IRSA: `kubectl get sa -n observability -o yaml` — verify the role ARN annotation is present.

**No logs in Azure Blob?**
1. Check agent logs: `kubectl -n observability logs <agent-pod> | grep -i azure`
2. Verify connection string is correct and container exist

**Stack traces split across multiple log entries?**
Verify `namespaceName` in multiline config matches where your pods run.

**High memory on agent pods?**
Increase `agent.resources.limits.memory` or reduce `sendingQueue.queueSize`.