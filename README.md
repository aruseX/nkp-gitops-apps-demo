# NKP GitOps Infrastructure Demo (Pro / Ultimate License)

## 📖 Overview
Welcome to the NKP Pro/Ultimate Infrastructure GitOps Demo! 

When you upgrade from NKP Starter to **NKP Pro or Ultimate**, you unlock **Fleet Management**. This repository demonstrates how to architect your GitOps repository to manage fleets of clusters at scale.

This branch focuses purely on **Cluster API (CAPI)** infrastructure. We have specifically separated the infrastructure provisioning from NKP Projects (Tenancy) to demonstrate how the Infrastructure team's responsibilities can be cleanly isolated into their own repository or branch.

---

## 🗂️ Repository Structure

In Pro/Ultimate, a Workspace is a 1-to-Many boundary. Notice how the `production-fleet` workspace manages multiple clusters simultaneously under the `pro-ultimate` directory.

    .
    ├── README.md                               # You are here!
    ├── demo-runbook.md                         # Step-by-step instructions
    └── clusters/
        └── pro-ultimate/
            ├── manager/
            │   ├── cluster.yaml                # CAPI definition of the Manager
            │   └── kustomization.yaml              
            └── workspaces/
                ├── production-fleet/
                │   ├── cluster-us-east.yaml    # Prod East Cluster
                │   ├── cluster-us-west.yaml    # Prod West Cluster
                │   └── kustomization.yaml      # Syncs the entire Prod fleet
                └── development-fleet/
                    ├── cluster-dev-sandbox.yaml# Dev Sandbox Cluster
                    └── kustomization.yaml      # Syncs the Dev fleet

---

## 🧭 Next Steps
Check out the `demo-runbook.md` in this directory to see the exact commands for syncing these fleets to your NKP Management cluster!
