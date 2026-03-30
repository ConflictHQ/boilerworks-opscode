# Kubernetes Base Platform

Opinionated base platform for Boilerworks Kubernetes clusters (EKS, GKE, AKS). Installs the foundational tools every cluster needs before application workloads can deploy.

**This is the platform layer, not the application layer.** Application Helm charts and manifests belong in the application repo.

## What Gets Installed

| Component | Purpose | Chart Source |
|-----------|---------|--------------|
| AWS Load Balancer Controller | Ingress via ALB (EKS only) | `eks/aws-load-balancer-controller` |
| ingress-nginx | Ingress controller (GKE, AKS) | `ingress-nginx/ingress-nginx` |
| cert-manager | TLS certificate automation | `jetstack/cert-manager` |
| external-secrets | Sync secrets from cloud provider | `external-secrets/external-secrets` |
| metrics-server | Pod autoscaling metrics | `metrics-server/metrics-server` |

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
