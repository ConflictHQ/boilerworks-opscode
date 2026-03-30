# Kubernetes Base Platform

Opinionated base platform for Boilerworks Kubernetes clusters (EKS, GKE, AKS). Installs the foundational tools every cluster needs before application workloads can deploy.

**This is the platform layer, not the application layer.** Application Helm charts and manifests belong in the application repo.

## What Gets Installed

| Component | Purpose | Chart Source |
|-----------|---------|--------------|
| Gateway API CRDs | Kubernetes standard routing API | `gateway-api/standard-install` |
| Envoy Gateway | Gateway API implementation | `envoyproxy/gateway-helm` |
| AWS Load Balancer Controller | ALB management (EKS only) | `eks/aws-load-balancer-controller` |
| cert-manager | TLS certificate automation | `jetstack/cert-manager` |
| external-secrets | Sync secrets from cloud provider | `external-secrets/external-secrets` |
| external-dns | Automatic DNS record management | `external-dns/external-dns` |
| Fluent Bit | Log collection (CNCF standard) | `fluent/fluent-bit` |
| Loki | Log aggregation backend | `grafana/loki-stack` |
| Prometheus + Grafana | Metrics, alerting, dashboards | `prometheus-community/kube-prometheus-stack` |
| Argo CD | GitOps continuous delivery | `argo/argo-cd` |

Uses [Gateway API](https://gateway-api.sigs.k8s.io/) instead of the [retired ingress-nginx](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/).

## Usage

```bash
# EKS
./kubernetes/base/install.sh aws dev

# GKE
./kubernetes/base/install.sh gcp dev

# AKS
./kubernetes/base/install.sh azure dev
```

The script:
1. Adds required Helm repos
2. Installs each component with cloud-specific values
3. Waits for rollout
4. Verifies health

## Values Files

Cloud-specific Helm values live in `values/{aws,gcp,azure}/`. Each component has a values file per cloud provider. Edit these to customize.

## Prerequisites

- `helm` >= 3.12
- `kubectl` configured for the target cluster
- For EKS: ALB controller IRSA role ARN (from Terraform output)
- For GKE: Workload Identity service account (from Terraform output)
