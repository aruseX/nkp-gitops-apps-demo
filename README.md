# NKP Federated Applications Demo (Pro / Ultimate)

## 📖 Overview
Welcome to the NKP Pro/Ultimate Application GitOps Demo!

This branch demonstrates two extremely powerful ways to manage applications across a fleet of clusters using NKP:

1. **Custom Applications (Helm/GitOps):** How developers deploy their own code (like a frontend UI) to their isolated Project namespaces.
2. **Platform Services (AppDeployments):** How Platform Admins turn on NKP's built-in Day 2 services (like Logging, Monitoring, and Security).

---

## 🌟 The "Wow" Factor

### 1. App Federation (Custom Apps)
Developers deploy their `HelmRelease` into the `frontend-team` namespace on the **Management Cluster**. NKP's Federation Controllers automatically detect this and push the application down to every workload cluster in the fleet attached to that Project. Your CI/CD pipelines only ever need to talk to one cluster!

### 2. Workspace vs. Cluster-Specific Platform Services
NKP allows you to target Platform Services with pinpoint accuracy:
* **Workspace-Wide:** By deploying an `AppDeployment` without a `clusterSelector`, we instantly turn on the `logging-operator` for **all** clusters in the `production-fleet`.
* **Cluster-Specific:** By adding a `clusterSelector` matching the cluster name, we can deploy `gatekeeper` strictly to the `prod-us-east` cluster, leaving `prod-us-west` untouched.

---

## 🗂️ Repository Structure

Notice the distinction between where Custom Apps live versus where Platform Services live:

    .
    ├── README.md                               
    ├── demo-runbook.md                         
    └── apps/
        └── production-fleet/
            ├── platform-services/              # Deploys to the WORKSPACE namespace
            │   ├── logging-workspace.yaml      # Turns on Logging fleet-wide
            │   ├── gatekeeper-cluster-specific.yaml # Turns on Gatekeeper ONLY for us-east
            │   └── kustomization.yaml
            ├── frontend-team/                  # Deploys to the PROJECT namespace
            │   ├── podinfo-helm-release.yaml   
            │   └── kustomization.yaml          
            └── backend-team/                   # Deploys to the PROJECT namespace
                ├── redis-helm-release.yaml     
                └── kustomization.yaml          
