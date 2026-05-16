# 🛠️ Platform Services (Day 2 NKP Apps)

This folder belongs to the **Platform Administrator**. Unlike developers who deploy custom Helm charts to Project namespaces, Platform Admins deploy pre-packaged NKP Day-2 services (like Logging, Monitoring, and Gatekeeper) to **Workspace namespaces**.

### Files in this directory:
*   **`logging-workspace.yaml`**: An NKP `AppDeployment` resource. Because it has no `clusterSelector`, NKP will automatically deploy the Logging Operator to **every cluster** in the `production-fleet` workspace.
*   **`gatekeeper-cluster-specific.yaml`**: An NKP `AppDeployment` resource for security policies. Because this file *does* include a `clusterSelector` matching `prod-us-east`, NKP will **only** install Gatekeeper on that specific cluster.
*   **`kustomization.yaml`**: The entrypoint used by Flux to sync these Platform Services.
