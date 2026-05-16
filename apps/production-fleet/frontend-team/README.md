# 🎨 Frontend Team Application

This folder simulates a developer repository for the "Frontend Team". Developers using NKP do not need to know about infrastructure, virtual machines, or multiple clusters. They only care about deploying their code to their assigned Project namespace.

### Files in this directory:
*   **`podinfo-helm-release.yaml`**: Contains a standard Flux `HelmRepository` and `HelmRelease`. It tells Flux to pull the `podinfo` chart and deploy it into the `frontend-team` namespace.
*   **`kustomization.yaml`**: The standard Kustomize entrypoint used by Flux to sync these files.

**The NKP Magic:** Because these files are synced to a Project namespace on the Management Cluster, NKP's Federation controllers will automatically wrap this application and push it down to every workload cluster attached to this Project!
