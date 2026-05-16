# 🗂️ The Clusters Directory

This is the root of your infrastructure definitions. In a multi-cluster environment, it is best practice to separate the infrastructure that *manages* the platform from the infrastructure that *runs* the workloads.

### Folder Breakdown:
*   **`manager/`**: Contains the GitOps configuration for the NKP Manager cluster itself. 
*   **`workspaces/`**: Contains the isolated environments for your workload clusters. Because this is an **NKP Starter** environment, each Workspace maps to exactly one Workload Cluster.

👉 **Next Step:** Explore the `manager/` folder, or dive into `workspaces/`.
