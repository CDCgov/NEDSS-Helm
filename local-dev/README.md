# NBS Local Development (Minikube)

This directory provides the scripts and manifests needed to stand up a local NBS environment
using [minikube](https://minikube.sigs.k8s.io/). The goal is to give developers a working
cluster with the core infrastructure services running — database, legacy application server, and
message broker — so that the Helm charts in this repository can be deployed and tested locally
without needing access to a shared or cloud environment.

The scripts here provision the services that **do not** have Helm charts in this repo
(nedssdb, nedssdev, and kafka) as standalone Kubernetes manifests. Once those are up and
healthy, the cluster is ready for developers to install and iterate on any of the charts
under `charts/` against a realistic local stack.

> **Note:** These manifests are intentionally separate from the production Helm charts.
> The `nbs6` chart targets Windows nodes and the `kafka` chart uses an AWS EBS StorageClass —
> neither works on a local Linux-based minikube node.

## Stack

| Service | Image | Purpose |
|---------|-------|---------|
| **nedssdb** | `ghcr.io/cdcent/nedssdb:6.0.17.0-replacement-beta` | SQL Server with NBS databases pre-seeded |
| **nedssdev** | `ghcr.io/cdcent/nedssdev:6.0.18.1` | WildFly application server (NBS classic) |
| **kafka** | `confluentinc/cp-kafka:7.8.7` | Kafka broker (KRaft mode — no Zookeeper) |

## Prerequisites

- [helm](https://helm.sh/docs/intro/install)
- [minikube](https://minikube.sigs.k8s.io/docs/start/) >= 1.32
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Docker](https://docs.docker.com/get-docker/) (used as the minikube driver)
- At least **8 GB RAM** and **2 CPUs** available to allocate

## Quick Start

```bash
# From the repo root
./local-dev/scripts/start.sh
```

The script will:
1. Start a minikube cluster (`nbs-local` profile) with 2 CPUs and 8 GB RAM
2. Enable the ingress addon
3. Deploy nedssdb and wait for it to be ready (~1-2 min)
4. Deploy kafka (KRaft mode)
5. Deploy nedssdev (WildFly)

nedssdev takes a few minutes to fully initialize after the pod starts. Monitor progress:

```bash
kubectl get pods -w
kubectl logs -f deployment/nedssdev
```

## Recommended Local Overrides

When using the local Helm values files under [local-dev/values](local-dev/values), a couple of settings are worth adjusting for a smoother first run:

- In [local-dev/values/debezium-rtr-local.yaml](local-dev/values/debezium-rtr-local.yaml), set `connect.properties.default_replication_factor` to `1` so it matches the single-broker local Kafka setup.
- In [local-dev/values/reporting-pipeline-service-local.yaml](local-dev/values/reporting-pipeline-service-local.yaml), override the probe startup delay if the service needs more time to become healthy during the initial boot. For example:

  ```yaml
  probes.readiness.initialDelaySeconds: 300
  probes.liveness.initialDelaySeconds: 300
  ```

## Using a Local Docker Image in Minikube

If you want to run a Helm chart against a locally built image instead of pulling from a remote registry, build the image into Minikube’s Docker environment and set the chart to use `imagePullPolicy: Never`.

Example for `reporting-pipeline-service`:

```bash
# Point Docker at the Minikube daemon for the nbs-local profile
eval "$(minikube -p nbs-local docker-env)"

# Build the image locally inside Minikube
cd <path-to-reporting-pipeline-service-repo>
docker build -t reporting-pipeline-service:local .
```

Then install or upgrade the chart with local image values:

```yaml
# local-dev/values/reporting-pipeline-service-local.yaml
image:
  repository: reporting-pipeline-service
  tag: local
  pullPolicy: Never
```

```bash
helm upgrade --install reporting-pipeline-service ./charts/reporting-pipeline-service \
  -f local-dev/values/reporting-pipeline-service-local.yaml
```

If you built the image with your normal Docker daemon instead, load it into Minikube directly:

```bash
minikube -p nbs-local image load reporting-pipeline-service:local
```

After the install, if the pod does not start, confirm the image is present in Minikube:

```bash
minikube -p nbs-local image ls | grep reporting-pipeline-service
kubectl describe pod -l app.kubernetes.io/name=reporting-pipeline-service
```

## Connection Details

### In-cluster (helm chart values)

When deploying charts from this repo into the same cluster, use these hostnames and ports:

| Service | Host | Port |
|---|---|---|
| nedssdb (SQL Server) | `nbs-mssql` | `1433` |
| kafka | `kafka` | `29092` |

Kafka runs in KRaft mode (no Zookeeper). In-cluster clients connect on the `INTERNAL` listener at
`kafka:29092`. Port `9092` is the `EXTERNAL` listener and advertises `localhost:9092` — it's only
useful via port-forward from your laptop.

### From your laptop (port-forward)

To connect local tooling (SQL clients, kafka CLI, browser) to the in-cluster services:

```bash
kubectl port-forward svc/nbs-mssql 1433:1433   # SQL Server -> localhost:1433
kubectl port-forward svc/kafka    9092:9092   # Kafka      -> localhost:9092
kubectl port-forward svc/nedssdev 7001:7001     # NBS UI     -> http://localhost:7001/nbs/login
```

The start script prints these details again after deployment.

## Credentials

Database credentials are defined in `manifests/nedssdb.yaml` under the `nbs-mssql-secret` Secret.
The 'sa-password' value can be adjusted if needed, but the others are set to match the DB image.

| Secret key | Default value |
|---|---|
| `sa-password` | `PizzaIsGood33!` |
| `odse-user` / `odse-password` | `nbs_ods` / `ods` |
| `srte-user` / `srte-password` | `nbs_srte` / `admin` |
| `rdb-user` / `rdb-password` | `nbs_rdb` / `rdb` |

## Stopping

```bash
./local-dev/scripts/stop.sh
```

To fully remove the cluster and reclaim disk:

```bash
minikube delete --profile nbs-local
```

## Minikube Resource Management

The start script creates a single-node Minikube cluster with 2 CPUs and 8 GB of memory by default. The workloads deployed by `start.sh` request most of that capacity:

| Deployment | Replicas | CPU request | Memory request | Memory limit |
|---|---:|---:|---:|---:|
| `nbs-mssql` | 1 | `500m` | `2Gi` | `4Gi` |
| `kafka` | 1 | `200m` | `512Mi` | `1Gi` |
| `nedssdev` | 1 | `500m` | `4Gi` | `6Gi` |
| **Total** | **3** | **`1200m`** | **`6.5Gi`** | **`11Gi`** |

Kubernetes schedules pods using requests, not current usage or limits. Minikube also reserves capacity for Kubernetes system pods and the ingress addon, so not all 2 CPUs and 8 GB are allocatable to application workloads. For example, two default Debezium replicas add 1 CPU and 2 GiB of requested capacity, bringing the total to 2.2 CPUs and 8.5 GiB before system workloads; one of those replicas will generally remain `Pending`.

Check scheduling and capacity with:

```bash
kubectl describe node nbs-local
kubectl describe pod <pending-pod-name>
kubectl get events --sort-by=.lastTimestamp
```

Look for `Insufficient cpu` or `Insufficient memory` in the pending pod's events.

To inspect current usage, enable Metrics Server and use `kubectl top`:

```bash
minikube addons enable metrics-server --profile nbs-local
kubectl top node nbs-local
kubectl top pods --all-namespaces --containers
```

The start script accepts environment variables for larger clusters:

```bash
MINIKUBE_CPUS=4 MINIKUBE_MEMORY=12g ./local-dev/scripts/start.sh
```

To resize an existing profile reliably, delete and recreate it. This removes local cluster data:

```bash
minikube delete --profile nbs-local
MINIKUBE_CPUS=4 MINIKUBE_MEMORY=12g ./local-dev/scripts/start.sh
```

Alternatively, reduce workload resource requests in a local Helm values file. Keep enough memory above the JVM heap maximum for metaspace, thread stacks, native buffers, and other non-heap usage.
