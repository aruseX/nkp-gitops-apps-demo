# NKP Platform Tenancy GitOps Runbook

## 📖 Overview
This runbook guides a Platform Administrator through using GitOps to create **Projects** across a fleet of NKP clusters. 

By applying these manifests to the NKP Management cluster, NKP will automatically federate the Projects down to the attached workload clusters, creating namespaces, setting up RoleBindings, and applying Resource Quotas.

---

## 🚀 Prerequisites
*   A running **NKP Management Cluster** (Pro or Ultimate License).
*   Workload clusters already attached to the `production-fleet` and `development-fleet` Workspaces.
*   `kubectl` configured and pointing to your **NKP Management Cluster**.
*   `flux` CLI installed locally.
*   This branch pushed to your Git repository.

---

## 🛠️ Step-by-Step Deployment Guide

### 1. Configure Environment Variables

#### Create a file in your root with these variables setup for use when running this repo from you bastion and doing operations
I have reserved .env* in the .gitignore for this use
>cat .env
```
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-demo"
export TARGET_BRANCH="tenancy-pro-ult/v1.0"
```

### 2. Bootstrap Flux and Create Git Source

```bash
kubectl create namespace nkp-tenancy-gitops

flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=nkp-tenancy-gitops

flux create source git nkp-tenancy-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth \
  --namespace=nkp-tenancy-gitops

```

### 3. Deploy the Projects
When you apply these Kustomizations, NKP will create the Project namespaces on the matching workload clusters in the fleet.

```bash
# Sync Production Tenancy (Frontend & Backend teams)
flux create kustomization nkp-production-tenancy-sync \
  --source=GitRepository/nkp-tenancy-repo \
  --path="./clusters/pro-ultimate/workspaces/production-fleet" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-tenancy-gitops

# Sync Development Tenancy (Sandbox)
flux create kustomization nkp-development-tenancy-sync \
  --source=GitRepository/nkp-tenancy-repo \
  --path="./clusters/pro-ultimate/workspaces/development-fleet" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-tenancy-gitops

```

---

## ✅ Verification
Verify that the projects were created in your Workspaces:

```bash
kubectl get projects -n production-fleet
kubectl get projects -n development-fleet

```
