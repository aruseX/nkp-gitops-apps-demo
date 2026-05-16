# NKP GitOps Demonstrations

Welcome to the NKP GitOps Demo repository! This repository is designed to teach you how to use GitOps (FluxCD) with the Nutanix Kubernetes Platform (NKP). 

Because NKP scales from single-cluster Starter deployments to massive Pro/Ultimate fleet-managed environments, the concepts are broken down into isolated, easy-to-understand branches. 

---

## 💡 [Why is this repository important?](#-why-is-this-repository-important)

Beyond just learning the technical mechanics of Flux and Kubernetes, this repository demonstrates how NKP Pro and Ultimate completely transform the **economics, security posture, and resilience** of an enterprise platform. 

When evaluating the patterns in this repository, consider these massive business benefits:

### 🚫 Eliminating the "DIY Platform" Tax
Building a production-ready Kubernetes environment from scratch is notoriously expensive. Enterprises waste millions of dollars paying highly skilled engineers to manually evaluate, integrate, secure, and lifecycle-manage the CNCF ecosystem (Prometheus, Fluent-bit, Gatekeeper, Flux, etc.) on top of raw Kubernetes. 
* **The NKP Solution:** NKP Pro/Ultimate provides these as **curated, pre-integrated, and heavily secured Platform Services** out-of-the-box. As you will see in this repo, you simply turn them on via an `AppDeployment` manifest. Your engineering teams can stop "keeping the lights on" and start building business value.

### 🛡️ Accelerated Security Accreditation & Lower Cyber Costs
Information Assurance (IA), Cyber Security, and Network Security teams love codified platforms.
* **Drastically Reduced Accreditation Costs:** Because the NKP platform stack is standardized, pre-hardened, and deployed identically across every cluster, security teams only have to audit the platform architecture *once*. This drastically lowers the time and cost required to achieve an Authority to Operate (ATO).
* **Immutable Audit Trails:** Because the platform is managed 100% through GitOps, security teams get a perfect, immutable audit log of *who* requested a change, *what* was changed, and *who approved it* via Pull Requests. No one makes unauthorized manual changes via `kubectl`.
* **Instant Vulnerability Remediation:** If a CVE is found in a logging component, you don't have to manually patch 50 clusters. You update the version in Git, and NKP automatically rolls out the patched, secured version across the entire global fleet.

### 🔄 Ultimate Recoverability (GitOps as Disaster Recovery)
When your entire infrastructure, tenancy, and application layer is codified across Git repositories, your Disaster Recovery strategy is built-in.
* **RTO in Minutes, Not Weeks:** If a datacenter burns down or a cluster is irrevocably compromised, you don't need a massive runbook to rebuild it. Cluster API (CAPI) provisions the new VMs, NKP attaches the cluster to the Workspace, and Flux instantly pulls down every Platform Service, Security Policy, and Application required. The cluster rebuilds itself exactly as it was.

---

## 🌿 Repository Branches

### 1. Application GitOps (NKP Starter - Raw Flux & `dependsOn`)
**Branch:** `apps-flux-dependson/v1.0`
This branch demonstrates the foundational way to deploy Applications and Gatekeeper policies to a standalone NKP Starter cluster. It solves the Kubernetes "Chicken-and-Egg" CRD problem using raw FluxCD `dependsOn` mechanics and Kustomize patches.
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/apps-flux-dependson/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/apps-flux-dependson/v1.0/demo-runbook.md)

### 2. Application GitOps (NKP Starter - Helm Hooks)
**Branch:** `apps-helm/v1.0`
This branch takes the application deployment from the previous branch and improves upon it. It replaces the complex multi-sync Flux Kustomization setup with a single, highly portable Helm Chart, leveraging Helm Hooks to safely deploy Gatekeeper ConstraintTemplates before Constraints.
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/apps-helm/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/apps-helm/v1.0/demo-runbook.md)

### 3. Infrastructure GitOps (NKP Starter)
**Branch:** `infra-starter/v1.0`
This branch completely removes the application layer and focuses purely on Cluster API (CAPI) infrastructure provisioning. It teaches how to deploy workload clusters using NKP Starter, where Workspaces and Clusters have a strict 1-to-1 relationship.
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/infra-starter/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/infra-starter/v1.0/demo-runbook.md)

### 4. Infrastructure GitOps (NKP Pro / Ultimate)
**Branch:** `infra-pro-ult/v1.0`
This branch demonstrates **Fleet Management**. It shows how upgrading to Pro/Ultimate changes the architecture, allowing a single Workspace to manage a fleet of multiple clusters (e.g., grouping `us-east` and `us-west` into a single `production-fleet` workspace).
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/infra-pro-ult/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/infra-pro-ult/v1.0/demo-runbook.md)

### 5. Platform Tenancy & Projects (NKP Pro / Ultimate)
**Branch:** `tenancy-pro-ult/v1.0`
This branch acts as the "Platform Administrator" repository. It builds on the fleet management concept by demonstrating how to use NKP `Projects` to carve out multi-tenant namespaces, set Resource Quotas, and manage RBAC across an entire fleet of clusters simultaneously.
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/tenancy-pro-ult/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/tenancy-pro-ult/v1.0/demo-runbook.md)

### 6. Application Fleet Federation (NKP Pro / Ultimate)
**Branch:** `apps-federation-pro-ult/v1.0`
This branch represents the "Applications Repository" in an enterprise environment. It demonstrates how developers can deploy a Helm Chart to their specific Project namespace on the *Management Cluster*, and let NKP automatically push (federate) that application down to every workload cluster across the global fleet.
* [📖 Readme](https://github.com/aruseX/nkp-gitops-demo/blob/apps-federation-pro-ult/v1.0/README.md)
* [🛠️ Demo Runbook](https://github.com/aruseX/nkp-gitops-demo/blob/apps-federation-pro-ult/v1.0/demo-runbook.md)

---

## 🏢 The Enterprise 3-Repo Pattern

While this repository uses branches to teach individual concepts, a real-world enterprise production environment separates these concerns to enforce security, ownership, and the separation of duties. 

If you were to deploy this in a massive production environment, you would combine the lessons from these branches into **Three Separate Git Repositories**:

### 1. The Infrastructure Repo
* **Who owns it:** Cloud/Infrastructure Administrators
* **What it does:** Provisions the actual VMs and bare-metal nodes. 
* **What lives here:** CAPI `Cluster` and `MachineDeployment` manifests (from the `infra-pro-ult` branch).
* **Where it syncs:** Applied strictly to the NKP Management Cluster.

### 2. The Platform / Tenancy Repo
* **Who owns it:** Kubernetes Platform Administrators
* **What it does:** Slices up the physical clusters into secure, multi-tenant boundaries for development teams.
* **What lives here:** NKP `Workspace`, `Project`, `ProjectRole`, and Quota manifests (from the `tenancy-pro-ult` branch).
* **Where it syncs:** Applied to the NKP Management Cluster (NKP then federates these namespaces down to the workload clusters).

### 3. The Applications Repo
* **Who owns it:** Software Developers / Application Owners
* **What it does:** Deploys the actual business applications, APIs, and policies.
* **What lives here:** Helm Charts, Kustomizations, and Gatekeeper policies (from the `apps-federation-pro-ult` branch).
* **Where it syncs:** Applied directly to the specific Project namespaces on the Management Cluster, and NKP automatically pushes them to the clusters.
