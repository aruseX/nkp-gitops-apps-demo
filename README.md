# NKP Federated Applications Demo (Pro / Ultimate)

## 📖 Overview
Welcome to the NKP Pro/Ultimate Application GitOps Demo!

This branch demonstrates two extremely powerful ways to manage applications across a fleet of clusters using NKP:

1. **Custom Applications (Helm/GitOps):** How developers deploy their own code (like a frontend UI) to their isolated Project namespaces.
2. **Platform Services (AppDeployments):** How Platform Admins turn on NKP's built-in Day 2 services (like Logging, Monitoring, and Security).

---

## 🌟 The Technical "Wow" Factor

### 1. App Federation (Custom Apps)
Developers deploy their `HelmRelease` into the `frontend-team` namespace on the **Management Cluster**. NKP's Federation Controllers automatically detect this and push the application down to every workload cluster in the fleet attached to that Project. Your CI/CD pipelines only ever need to talk to one cluster!

### 2. Workspace vs. Cluster-Specific Platform Services
NKP allows you to target Platform Services with pinpoint accuracy:
* **Workspace-Wide:** By deploying an `AppDeployment` without a `clusterSelector`, we instantly turn on the `logging-operator` for **all** clusters in the `production-fleet`.
* **Cluster-Specific:** By adding a `clusterSelector` matching the cluster name, we can deploy `gatekeeper` strictly to the `prod-us-east` cluster, leaving `prod-us-west` untouched.

---

## 💰 The Business Value: Why NKP Pro/Ultimate?

Beyond the technical mechanics of federating applications, NKP Pro and Ultimate completely transform the economics, security posture, and resilience of your enterprise platform. 

When pitching this GitOps-driven, Fleet-Managed architecture to leadership, highlight these massive cost and security benefits:

### 🚫 Eliminating the "DIY Platform" Tax
Building a production-ready Kubernetes environment from scratch is notoriously expensive. 
* **The Problem:** Enterprises waste millions of dollars paying highly skilled engineers to manually evaluate, integrate, secure, and lifecycle-manage the CNCF ecosystem (Prometheus, Fluent-bit, Gatekeeper, Flux, etc.) on top of raw Kubernetes. 
* **The NKP Solution:** NKP Pro/Ultimate provides these as **curated, pre-integrated, and heavily secured Platform Services** out-of-the-box. NKP engineers ensure these components work flawlessly together. You simply turn them on via an `AppDeployment` manifest. Your engineering teams can stop "keeping the lights on" and start building business value.

### 🛡️ Accelerated Security Accreditation & Lower Cyber Costs
Information Assurance (IA), Cyber Security, and Network Security teams love codified platforms.
* **Drastically Reduced Accreditation Costs:** Because the NKP platform stack is standardized, pre-hardened, and deployed identically across every cluster, security teams only have to audit the platform architecture *once*. This drastically lowers the time and cost required to achieve an Authority to Operate (ATO).
* **Immutable Audit Trails:** Because the platform is managed 100% through GitOps, security teams get a perfect, immutable audit log of *who* requested a change, *what* was changed, and *who approved it* via Pull Requests. No one makes unauthorized manual changes via `kubectl`.
* **Instant Vulnerability Remediation:** If a CVE is found in a logging component, you don't have to manually patch 50 clusters. You update the version in Git, and NKP automatically rolls out the patched, secured version across the entire global fleet.

### 🔄 Ultimate Recoverability (GitOps as Disaster Recovery)
When your entire infrastructure, tenancy, and application layer is codified across three Git repositories, your Disaster Recovery strategy is built-in.
* **RTO in Minutes, Not Weeks:** If a datacenter burns down or a cluster is irrevocably compromised, you don't need a massive runbook to rebuild it. Cluster API (CAPI) provisions the new VMs, NKP attaches the cluster to the Workspace, and Flux instantly pulls down every Platform Service, Security Policy, and Application required. The cluster rebuilds itself exactly as it was.

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