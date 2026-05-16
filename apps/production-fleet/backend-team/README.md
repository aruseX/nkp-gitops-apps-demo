# 🗄️ Backend Team Application

This folder simulates a developer repository for the "Backend Team". Just like the frontend team, they only need to deploy to their specific namespace.

### Files in this directory:
*   **`redis-helm-release.yaml`**: Contains a Flux `HelmRepository` and `HelmRelease` pointing to the Bitnami Redis chart. It deploys to the `backend-team` namespace.
*   **`kustomization.yaml`**: The standard Kustomize entrypoint.

By isolating the backend team into their own Project namespace, we ensure they have their own RBAC, Resource Quotas, and network boundaries, all federated across the fleet.
