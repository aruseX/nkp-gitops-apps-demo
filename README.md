# NKP GitOps & Gatekeeper Demo

> ## ⚠️ Upgrade Disclaimer: Starter to Pro/Ultimate
> This repository defines a GitOps pattern optimized for **NKP Starter**.
> If you plan to apply a license upgrade to **NKP Pro** or **NKP Ultimate**, please read this carefully.
>
> **Will anything break if I upgrade? Immediately? No.** Because we safely isolated your GitOps resources into the `nkp-user-gitops` namespace, the NKP upgrade engine will simply ignore them. Your cluster will not crash, and your Gatekeeper policies will remain active.
>
> **However, long-term, it will cause a "Split-Brain" management problem.** NKP Pro and Ultimate introduce **Fleet Management** and **Workspaces**. In these tiers, GitOps is managed natively via the NKP UI/CLI at the Workspace level. If you leave this standalone Starter pattern running, your cluster will receive policy updates from a localized Flux deployment that the NKP Management UI knows nothing about. This causes configuration drift and constant overwrites if an admin tries to use the official Workspace GitOps method.
>
> **The Fix:** Before or immediately after upgrading, delete the local `Kustomization` and `GitRepository` resources in the `nkp-user-gitops` namespace, and seamlessly migrate the repository connection to the official NKP Workspace.
>
> **Why didn't we just use the `kommander-flux` namespace?**
> If we had put our `GitRepository` and `Kustomization` manifests directly into NKP's native `kommander-flux` namespace, upgrading (or even applying a patch) could **break your cluster**.
> 1. **The Pruning Reaper:** `kommander-flux` is strictly owned by NKP's lifecycle manager. During an upgrade, NKP reconciles that namespace. It will likely delete any unrecognized custom Flux resources, instantly severing your GitOps pipeline.
> 2. **Resource Collisions:** Naming collisions could cause Flux controllers to hang or enter a crash loop, taking down NKP's ability to heal or upgrade core apps (Traefik, Dex, Gatekeeper).
> 3. **AppDeployment Overwrites:** Managing the core `AppDeployment` directly without our safe "patching" method would result in NKP forcefully overwriting our changes and wiping out our custom settings.
>
> *By using the `nkp-user-gitops` namespace, we successfully "piggyback" on the underlying Flux engine while maintaining total logical isolation from NKP's blast radius.*

---

## 📖 Overview
This repository demonstrates a best-practice GitOps workflow for managing Nutanix Kubernetes Platform (NKP) platform applications and Gatekeeper security policies using FluxCD and Kustomize.

I show you how to create this repo in your own environment and link it to you your custom installed flux.cd deployment (that NKP will ignore), and then use that configuration to make minor tweaks and usage of an NKP Starter application called OPA Gatekeeper.

### ⚠️ Why We Moved to Helm (From Flux `dependsOn`)
Gatekeeper policies introduce a classic **"Chicken and Egg" problem**:
1. You cannot apply a `Constraint` until the `ConstraintTemplate` has been compiled by Gatekeeper.
2. If you try to apply both simultaneously, the Kubernetes API will reject the `Constraint` because it doesn't recognize the Custom Resource yet, causing a `dry-run failed` error.

**The Old Way (Flux `dependsOn`):** Previously, we solved this by splitting our manifests into separate `templates/` and `constraints/` directories. We then created multiple Flux Kustomization sync jobs and used the `--depends-on` flag to force Flux to wait for the templates to finish deploying before looking at the constraints. This worked, but it created unnecessary complexity, multi-sync management overhead, and scattered our related policies across different folders.

**The New Way (Helm Hooks):** We have moved to **Helm**. By packaging our Gatekeeper policies into a single Helm chart, we can consolidate everything into one folder. We use native **Helm Hooks** (annotating the `ConstraintTemplate` with `"helm.sh/hook": pre-install, pre-upgrade` and a negative weight). This tells Helm to push the template to the cluster and wait for it to be accepted *before* applying the standard `Constraint` resources. This replaces the complex multi-sync Flux Kustomization setup with a single, highly portable artifact.

---

## 🗂️ Repository Structure

Because we are using Helm, our repository is strictly organized into a standard chart structure, consolidating our application patches and policies.