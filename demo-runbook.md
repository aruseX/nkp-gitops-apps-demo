# NKP Infrastructure GitOps Runbook (Pro/Ultimate License)

## 📖 Overview
This runbook guides an NKP Platform Administrator through using GitOps (FluxCD) to manage fleets of clusters using **NKP Pro or Ultimate**. 

With Fleet Management unlocked, you no longer create a workspace for every single cluster. Instead, you create Workspaces based on environments (e.g., `production-fleet`) and group multiple CAPI workload clusters inside them.

---

## 🚀 Prerequisites
*   A running **NKP Management Cluster** (Pro or Ultimate License).
*   `kubectl` configured and pointing to your **NKP Management Cluster**.
*   `flux` CLI installed locally.
*   This branch pushed to your Git repository.

---

## 🛠️ Step-by-Step Deployment Guide

### 1. Configure Environment Variables

## Create a file in your root with these variables setup for use when running this repo from you bastion and doing operations
I have reserved .env* in the .gitignore for this use
>cat .env
```
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-demo"
export TARGET_BRANCH="infra-pro-ult/v1.0"
```

### 2. Bootstrap Flux and Create Git Source

```bash
kubectl create namespace nkp-infra-gitops

flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=nkp-infra-gitops

flux create source git nkp-infra-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth \
  --namespace=nkp-infra-gitops

```

### 3. Deploy the Fleets
As soon as you create these Kustomizations, Flux will instruct the CAPI controllers on the Manager cluster to provision these VMs on Nutanix AHV.

```bash
# Sync Production Fleet (us-east and us-west)
flux create kustomization nkp-production-fleet-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/pro-ultimate/workspaces/production-fleet" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops

# Sync Development Fleet
flux create kustomization nkp-development-fleet-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/pro-ultimate/workspaces/development-fleet" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops

```

---

## ✅ Verification
Monitor the status of your infrastructure provisioning:

```bash
kubectl get clusters -A
kubectl get machinedeployments -A
kubectl get machines -A

```
