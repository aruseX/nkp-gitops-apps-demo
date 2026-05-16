#!/bin/bash

# -------------------------------------------------------------------------
# 1. FRONTEND TEAM README
# -------------------------------------------------------------------------
cat << 'EOF' > apps/production-fleet/frontend-team/README.md
# 🎨 Frontend Team Application

This folder simulates a developer repository for the "Frontend Team". Developers using NKP do not need to know about infrastructure, virtual machines, or multiple clusters. They only care about deploying their code to their assigned Project namespace.

### Files in this directory:
*   **`podinfo-helm-release.yaml`**: Contains a standard Flux `HelmRepository` and `HelmRelease`. It tells Flux to pull the `podinfo` chart and deploy it into the `frontend-team` namespace.
*   **`kustomization.yaml`**: The standard Kustomize entrypoint used by Flux to sync these files.

**The NKP Magic:** Because these files are synced to a Project namespace on the Management Cluster, NKP's Federation controllers will automatically wrap this application and push it down to every workload cluster attached to this Project!
EOF

# -------------------------------------------------------------------------
# 2. BACKEND TEAM README
# -------------------------------------------------------------------------
cat << 'EOF' > apps/production-fleet/backend-team/README.md
# 🗄️ Backend Team Application

This folder simulates a developer repository for the "Backend Team". Just like the frontend team, they only need to deploy to their specific namespace.

### Files in this directory:
*   **`redis-helm-release.yaml`**: Contains a Flux `HelmRepository` and `HelmRelease` pointing to the Bitnami Redis chart. It deploys to the `backend-team` namespace.
*   **`kustomization.yaml`**: The standard Kustomize entrypoint.

By isolating the backend team into their own Project namespace, we ensure they have their own RBAC, Resource Quotas, and network boundaries, all federated across the fleet.
EOF

# -------------------------------------------------------------------------
# 3. PLATFORM SERVICES README
# -------------------------------------------------------------------------
cat << 'EOF' > apps/production-fleet/platform-services/README.md
# 🛠️ Platform Services (Day 2 NKP Apps)

This folder belongs to the **Platform Administrator**. Unlike developers who deploy custom Helm charts to Project namespaces, Platform Admins deploy pre-packaged NKP Day-2 services (like Logging, Monitoring, and Gatekeeper) to **Workspace namespaces**.

### Files in this directory:
*   **`logging-workspace.yaml`**: An NKP `AppDeployment` resource. Because it has no `clusterSelector`, NKP will automatically deploy the Logging Operator to **every cluster** in the `production-fleet` workspace.
*   **`gatekeeper-cluster-specific.yaml`**: An NKP `AppDeployment` resource for security policies. Because this file *does* include a `clusterSelector` matching `prod-us-east`, NKP will **only** install Gatekeeper on that specific cluster.
*   **`kustomization.yaml`**: The entrypoint used by Flux to sync these Platform Services.
EOF

# -------------------------------------------------------------------------
# 4. UPDATED DEMO RUNBOOK (With Summaries)
# -------------------------------------------------------------------------
cat << 'EOF' > demo-runbook.md
# NKP Federated Apps & Services GitOps Runbook

## 📖 Overview
This runbook shows how to deploy both custom developer applications AND built-in NKP Platform Services across an entire fleet of clusters.

---

## 🗂️ Directory Summaries (What's in this repo?)
Before running the deployment, here is a quick summary of the files we are applying:

*   **`apps/production-fleet/frontend-team/` & `backend-team/`**: These folders represent developer apps. They contain standard Flux `HelmReleases` (like Podinfo and Redis) targeting Project namespaces. NKP will federate these apps to every cluster the teams have access to.
*   **`apps/production-fleet/platform-services/`**: This folder represents the Platform Admin's configuration. It contains NKP `AppDeployment` manifests. `logging` is configured to deploy Workspace-wide (all clusters), while `gatekeeper` is configured with a `clusterSelector` to deploy only to a specific cluster (`prod-us-east`).

---

## 🚀 Prerequisites
*   The Infrastructure (`infra-pro-ult`) and Tenancy (`tenancy-pro-ult`) must already be deployed.
*   `kubectl` pointing to your **NKP Management Cluster**.

---

## 🛠️ Step-by-Step Deployment Guide

### 1. Configure Environment Variables

```bash
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-demo"
export TARGET_BRANCH="apps-federation-pro-ult/v1.0"

```

### 2. Deploy Built-in Platform Services (Workspace & Cluster Specific)
Platform Services are managed at the **Workspace** level using `AppDeployments`. We sync this using the Platform Admin's GitOps instance.

```bash
# Set up Git source for Platform Apps
flux create source git nkp-platform-apps-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth \
  --namespace=nkp-infra-gitops

# Sync Platform Services (Logging and Gatekeeper)
flux create kustomization platform-services-sync \
  --source=GitRepository/nkp-platform-apps-repo \
  --path="./apps/production-fleet/platform-services" \
  --prune=true \
  --interval=2m \
  --namespace=nkp-infra-gitops

```

### 3. Deploy Custom Federated Applications (Frontend)
Custom applications are deployed to the **Project** level. Developers sync their apps to their assigned namespaces, and NKP federates them to the fleet.

```bash
# Set up Git source for the Frontend Developer
flux create secret git github-auth-apps \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=frontend-team

flux create source git nkp-apps-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth-apps \
  --namespace=frontend-team

# Sync the Frontend App
flux create kustomization frontend-app-sync \
  --source=GitRepository/nkp-apps-repo \
  --path="./apps/production-fleet/frontend-team" \
  --prune=true \
  --interval=2m \
  --namespace=frontend-team

```

---

## ✅ The "Wow" Moment: Verification

**1. Verify the Platform Services (Targeted Deployments)**
* **Logging** was deployed workspace-wide. It should be on BOTH clusters.
* **Gatekeeper** was deployed cluster-specific. It should ONLY be on `us-east`.

```bash
# Check us-east (Should have BOTH logging and gatekeeper)
kubectl --context=prod-us-east get pods -n kommander

# Check us-west (Should ONLY have logging)
kubectl --context=prod-us-west get pods -n kommander

```

**2. Verify the Custom App (Frontend)**
NKP detected the `HelmRelease` in the `frontend-team` namespace and pushed it down to all clusters in the project!

```bash
kubectl --context=prod-us-east get pods -n frontend-team
kubectl --context=prod-us-west get pods -n frontend-team

```
EOF

echo "✅ Success! Sub-directory READMEs generated and demo-runbook.md updated!"
