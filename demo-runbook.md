# NKP Infrastructure GitOps Runbook (Starter License)

## 📖 Overview
This runbook guides an NKP Platform Administrator through using GitOps (FluxCD) to manage their underlying Nutanix Kubernetes Platform (NKP) infrastructure. 

Instead of configuring applications or security policies, this runbook focuses purely on **Cluster API (CAPI)** resource management. By using this repository, you can declaratively provision, scale, and manage your NKP Workload Clusters and Nodepools.

In an **NKP Starter** environment, Clusters and Workspaces share a strict **1-to-1 relationship**. This runbook and repository structure reflect that design.

---

## 🗂️ Repository Architecture Summary

This repository is designed with blast-radius isolation and role-based access in mind. It splits your infrastructure into two main categories: **Manager** and **Workspaces**.

1. **Manager (`clusters/nkp-starter/manager/`)**
   * **Purpose:** Represents the NKP Management Cluster itself. This cluster hosts the CAPI controllers that reach out to Nutanix AHV/Cloud to provision worker nodes.
   * **Contents:** Contains the `Cluster` definition for the manager. While typically bootstrapped via the NKP CLI, having it in Git allows you to manage its configuration post-creation.

2. **Workspaces (`clusters/nkp-starter/workspaces/`)**
   * **Purpose:** Represents the logically isolated environments for your workload clusters.
   * **Structure:** Contains sub-folders for each workspace (e.g., `workspace-1` for Production, `workspace-2` for Staging, `workspace-3` for Dev).
   * **Contents:** Each workspace folder contains:
     * `workload-cluster.yaml`: The CAPI definition for the Kubernetes control plane and networking.
     * `nodepool.yaml`: The `MachineDeployment` defining the worker nodes (vCPUs, RAM, and Replicas). Scaling your cluster is as easy as changing the `replicas` count here and pushing to Git!

---

## 🚀 Prerequisites

*   A running **NKP Management Cluster** (Starter License).
*   `kubectl` configured and pointing to your **NKP Management Cluster** context. (Infrastructure GitOps runs on the manager to spawn workload clusters).
*   `flux` CLI installed locally (`curl -s https://fluxcd.io/install.sh | sudo bash`).
*   This repository structure committed and pushed to your Git provider.

---

## 🛠️ Step-by-Step Deployment Guide

### 1. Configure Environment Variables
Create an `.env` file (ignored by Git) or run these exports directly in your terminal to define your repository connection.

```bash
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-demo"
export TARGET_BRANCH="infra-starter/v1.0"
```

### 2. Bootstrap Flux and Create Git Source
We will create a dedicated namespace on the Manager cluster to hold our infrastructure GitOps configurations, isolating it from internal NKP system namespaces.

```bash
kubectl create namespace nkp-infra-gitops

# Create the secret to authenticate with your Git repo
flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=nkp-infra-gitops

# Register the Git repository with Flux
flux create source git nkp-infra-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth \
  --namespace=nkp-infra-gitops
```

### 3. Deploy the Manager Configuration
Tell Flux to sync the Manager cluster definitions.

```bash
flux create kustomization nkp-manager-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/manager" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops
```

### 4. Deploy the Workspaces (Workload Clusters)
Next, tell Flux to sync the individual Workspaces. As soon as these Kustomizations are created, Flux will read the Git repository, pass the CAPI manifests to the NKP Manager cluster, and NKP will immediately begin provisioning the VMs on Nutanix AHV!

```bash
# Sync Workspace 1 (Production)
flux create kustomization nkp-workspace-1-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/workspaces/workspace-1" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops

# Sync Workspace 2 (Staging)
flux create kustomization nkp-workspace-2-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/workspaces/workspace-2" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops

# Sync Workspace 3 (Development)
flux create kustomization nkp-workspace-3-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/workspaces/workspace-3" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-infra-gitops
```

---

## ✅ Verification

Once you have applied the Kustomizations, you can monitor the status of your infrastructure provisioning directly from the Manager cluster.

```bash
# 1. Verify Flux successfully applied the manifests
flux get kustomizations -n nkp-infra-gitops

# 2. Check the CAPI Cluster status (Watch them change to 'Provisioned')
kubectl get clusters -A

# 3. Check the Nodepools (MachineDeployments)
kubectl get machinedeployments -A

# 4. Watch individual VMs spin up
kubectl get machines -A
```

---

## 🗑️ Teardown & Uninstall

**⚠️ CRITICAL WARNING:** Because we used the `--prune=true` flag, deleting the Flux Kustomization will instruct Flux to delete the underlying Kubernetes objects in the cluster. **Deleting a CAPI `Cluster` or `MachineDeployment` object will instantly DESTROY the workload cluster and delete its VMs from Nutanix AHV.**

If you want to completely destroy a workspace and its associated workload cluster:
```bash
kubectl delete kustomization nkp-workspace-3-sync -n nkp-infra-gitops
```

If you want to **stop using GitOps** but **keep the clusters running**, you must suspend the Kustomization and delete it without pruning:
```bash
flux suspend kustomization nkp-workspace-3-sync -n nkp-infra-gitops
kubectl delete kustomization nkp-workspace-3-sync -n nkp-infra-gitops --ignore-not-found
```

To remove the base Flux configuration:
```bash
kubectl delete gitrepository nkp-infra-repo -n nkp-infra-gitops
kubectl delete secret github-auth -n nkp-infra-gitops
kubectl delete namespace nkp-infra-gitops
```
