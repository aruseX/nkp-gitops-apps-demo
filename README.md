# NKP GitOps Platform Tenancy Demo (Pro / Ultimate License)

## 📖 Overview
Welcome to the NKP Platform Tenancy GitOps Demo! 

This branch demonstrates the responsibilities of a **Platform Administrator**. The infrastructure team has already provisioned a fleet of clusters (in another repository/branch). Your job is to create **Projects**.

In NKP, a `Project` is a multi-tenant boundary. It carves out isolated namespaces and manages RBAC across an *entire fleet of clusters* simultaneously.

---

## 🗂️ Repository Structure

Notice that there are no `Cluster` or `MachineDeployment` files here. We are purely managing access for our development teams (Frontend and Backend).

    .
    ├── README.md                               # You are here!
    ├── demo-runbook.md                         # Step-by-step instructions
    └── clusters/
        └── pro-ultimate/
            └── workspaces/
                ├── production-fleet/
                │   ├── project-frontend.yaml   # Creates 'frontend' namespaces across the prod fleet
                │   ├── project-backend.yaml    # Creates 'backend' namespaces across the prod fleet
                │   └── kustomization.yaml      # Syncs the Prod tenancy configs
                └── development-fleet/
                    ├── project-sandbox.yaml    # Creates sandbox namespaces for devs
                    └── kustomization.yaml      # Syncs the Dev tenancy configs

---

## 🧭 Next Steps
Check out the `demo-runbook.md` in this directory to see how to sync these Projects to your NKP Management cluster!
