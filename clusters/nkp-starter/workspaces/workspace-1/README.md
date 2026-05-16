# 📦 Workspace 1: Production

This folder represents your first Workspace, dedicated to the **Production Workload Cluster**. 

### Files here:
*   **`workload-cluster-1.yaml`**: The CAPI definition for the Kubernetes control plane and networking.
*   **`nodepool-1.yaml`**: The MachineDeployment defining the worker nodes (vCPUs, RAM, Replicas).
*   **`kustomization.yaml`**: The Flux manifest that syncs this specific workspace.
