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

## Customizing Resources

The scripts respect environment variables for minikube sizing:

```bash
MINIKUBE_CPUS=2 MINIKUBE_MEMORY=8g ./local-dev/scripts/start.sh
```

Default resource requests in the manifests are set conservatively for local dev and are much lower
than the production values (e.g. nedssdev uses `JAVA_MEMORY=2g` vs `10g` in production).
