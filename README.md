# NKP GitOps Infrastructure Demo (Starter License)

## 📖 Overview
Welcome to the NKP Infrastructure GitOps Demo! This repository is designed as a **teaching tool** to help you understand how to manage Nutanix Kubernetes Platform (NKP) infrastructure using GitOps (FluxCD). 

This branch focuses purely on **Cluster API (CAPI)** infrastructure. In NKP Starter, Clusters and Workspaces have a strict **1-to-1 relationship**. Therefore, this repository demonstrates how to structure your GitOps repo to manage:
1. **The Manager Cluster** (The control plane of your NKP deployment)
2. **Three Workspaces**, each containing exactly **One Workload Cluster**.

---

## 🗂️ Repository Structure

Here is the complete layout of this GitOps repository. This makes it easy to understand where the Manager cluster configurations live compared to the isolated Workload clusters under the NKP Starter structure.

    nkp-gitops-infra/
    ├── README.md                                   # You are here!
    └── clusters/
        └── nkp-starter/
            ├── README.md                           # Explains the separation of Manager vs Workspaces
            ├── manager/
            │   ├── README.md                       # Details about the Manager Cluster
            │   ├── cluster.yaml                    # CAPI definition of the Manager
            │   └── kustomization.yaml              # Flux entrypoint for the Manager
            └── workspaces/
                ├── README.md                       # Explains NKP Starter Workspaces (1-to-1 mapping)
                ├── workspace-1/
                │   ├── README.md                   # Production Workspace details
                │   ├── workload-cluster-1.yaml     # Prod CAPI Cluster definition
                │   ├── nodepool-1.yaml             # Prod Worker nodes (Replicas: 5)
                │   └── kustomization.yaml          # Flux entrypoint for Workspace 1
                ├── workspace-2/
                │   ├── README.md                   # Staging Workspace details
                │   ├── workload-cluster-2.yaml     # Staging CAPI Cluster definition
                │   ├── nodepool-2.yaml             # Staging Worker nodes (Replicas: 3)
                │   └── kustomization.yaml          # Flux entrypoint for Workspace 2
                └── workspace-3/
                    ├── README.md                   # Development Workspace details
                    ├── workload-cluster-3.yaml     # Dev CAPI Cluster definition
                    ├── nodepool-3.yaml             # Dev Worker nodes (Replicas: 1)
                    └── kustomization.yaml          # Flux entrypoint for Workspace 3

---

## 🧭 How to Learn from this Repo
Navigate through the folders! **Every folder has its own `README.md`** explaining exactly what the files inside do and why they are structured that way. Start your journey here:
👉 `clusters/nkp-starter/`
