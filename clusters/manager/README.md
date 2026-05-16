# 🏢 Manager Cluster

This directory holds the configuration for the **NKP Manager Cluster**. The Manager cluster runs the core NKP services and the Cluster API (CAPI) controllers that reach out to Nutanix AHV/Cloud to provision the workload clusters.

### Files here:
*   `cluster.yaml`: Represents the CAPI definition of the Manager cluster.
*   `kustomization.yaml`: Tells Flux to sync the Manager cluster configurations.
