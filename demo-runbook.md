# nkp-gitops-demo

## Create a file in your root with these variables setup for use when running this repo from you bastion and doing operations
I have reserved .env* in the .gitignore for this use
>cat .env
```
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-demo"
export TARGET_BRANCH="apps-federation-pro-ult/v1.0"
```

# NKP GitOps & Gatekeeper Runbook: Starter vs. Pro/Ultimate

This runbook details how to use GitOps (FluxCD) to manage NKP `AppDeployments` (specifically for Gatekeeper Lifecycle Management) and Gatekeeper custom policies (`ConstraintTemplates` and `Constraints`). 

To avoid the "Chicken and Egg" race condition where a Constraint fails to apply because its Template hasn't been compiled yet, this guide separates Templates and Constraints into different directories and uses Flux's `dependsOn` feature to enforce a strict order of operations.

---

## Prerequisites (Both Paths)
*   `kubectl` configured for your target cluster (Starter) or Management cluster (Pro/Ultimate).
*   `flux` CLI installed (`curl -s https://fluxcd.io/install.sh | sudo bash`).
*   A Git repository cloned locally in VSCode.

---

## Path A: NKP Starter (Standalone Cluster)

### 1. Build the Git Repository Structure (Run in VSCode)

Run these commands to generate the directories and manifests. Notice we now use separate `templates` and `constraints` folders.

```bash
# Create distinct directories for ordering
mkdir -p clusters/nkp-starter/apps
mkdir -p clusters/nkp-starter/templates
mkdir -p clusters/nkp-starter/constraints

# 1. Create the ConfigMap & Patch for Gatekeeper AppDeployment
cat << 'EOF' > clusters/nkp-starter/apps/gatekeeper-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gatekeeper-custom-config
  namespace: kommander
data:
  values.yaml: |
    auditInterval: 300
    auditMatch:
      - excludedNamespaces:
        - kube-system
        - kommander
---
apiVersion: apps.kommander.d2iq.io/v1alpha3
kind: AppDeployment
metadata:
  name: gatekeeper
  namespace: kommander
spec:
  configOverrides:
    name: gatekeeper-custom-config
EOF

# 2. Create the Gatekeeper ConstraintTemplate
cat << 'EOF' > clusters/nkp-starter/templates/require-labels-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items: { type: string }
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("you must provide labels: %v", [missing])
        }
EOF

# 3. Create the Gatekeeper Constraint
cat << 'EOF' > clusters/nkp-starter/constraints/require-labels-constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-nkp-managed
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels:
      - "nkp-managed"
EOF

# 4. Create individual kustomization.yaml files for each folder
cat << 'EOF' > clusters/nkp-starter/apps/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gatekeeper-config.yaml
EOF

cat << 'EOF' > clusters/nkp-starter/templates/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - require-labels-template.yaml
EOF

cat << 'EOF' > clusters/nkp-starter/constraints/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - require-labels-constraint.yaml
EOF
```

Commit and push these files to your remote repository.

### 2. Configure the Flux Git Source & Dependencies

Set your credentials and wire Flux to your repository. We will create TWO Kustomizations and link them with `--depends-on`.

```bash
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-infra"

kubectl create namespace nkp-user-gitops

# Create the Git credentials secret & source
flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=nkp-user-gitops

flux create source git nkp-infra-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=main \
  --secret-ref=github-auth \
  --namespace=nkp-user-gitops

# 1. Sync the Apps & Templates FIRST
flux create kustomization nkp-templates-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/templates" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-user-gitops

# 2. Sync the Constraints (Depends on Templates)
flux create kustomization nkp-constraints-sync \
  --source=GitRepository/nkp-infra-repo \
  --path="./clusters/nkp-starter/constraints" \
  --prune=true \
  --interval=10m \
  --depends-on=nkp-templates-sync \
  --namespace=nkp-user-gitops
```
*Note: Because of `--depends-on`, Flux will not even attempt a dry-run on the constraints until `nkp-templates-sync` reports a healthy, finished status!*

---

## Path B: NKP Pro & Ultimate (Fleet Management)

In Pro/Ultimate, we apply the same structural split, but target the Workspace namespace on the Management cluster.

### 1. Build the Git Repository Structure (Run in VSCode)

```bash
export WORKSPACE_NS="ws-production"

mkdir -p workspaces/${WORKSPACE_NS}/apps
mkdir -p workspaces/${WORKSPACE_NS}/templates
mkdir -p workspaces/${WORKSPACE_NS}/constraints

# (Create the same 3 YAML files from Path A, but place them in the workspace directories)
# Example: workspaces/ws-production/templates/require-labels-template.yaml

# Create individual kustomization.yaml files for each folder
cat << EOF > workspaces/${WORKSPACE_NS}/apps/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gatekeeper-config.yaml
EOF

cat << EOF > workspaces/${WORKSPACE_NS}/templates/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - require-labels-template.yaml
EOF

cat << EOF > workspaces/${WORKSPACE_NS}/constraints/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - require-labels-constraint.yaml
EOF
```

Commit and push these files to your repository.

### 2. Configure the Flux Git Source & Dependencies (On Management Cluster)

```bash
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-infra"
export WORKSPACE_NS="ws-production"

flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=${WORKSPACE_NS}

flux create source git workspace-gitops \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=main \
  --secret-ref=github-auth \
  --namespace=${WORKSPACE_NS}

# 1. Sync the Templates FIRST
flux create kustomization ws-templates-sync \
  --source=GitRepository/workspace-gitops \
  --path="./workspaces/${WORKSPACE_NS}/templates" \
  --prune=true \
  --interval=10m \
  --namespace=${WORKSPACE_NS}

# 2. Sync the Constraints (Depends on Templates)
flux create kustomization ws-constraints-sync \
  --source=GitRepository/workspace-gitops \
  --path="./workspaces/${WORKSPACE_NS}/constraints" \
  --prune=true \
  --interval=10m \
  --depends-on=ws-templates-sync \
  --namespace=${WORKSPACE_NS}
```

---

## Verify the Gatekeeper Policy is Enforced (Both Paths)

To prove the policy is working, run these tests (if on Pro/Ultimate, run against the Workload Cluster).

*Note on Existing Resources: Applying this policy will **not** break or delete existing namespaces that lack the label. Gatekeeper operates as an admission webhook that intercepts new `CREATE` or `UPDATE` requests. Existing non-compliant namespaces will continue to run normally, but will be flagged as violations in Gatekeeper's audit logs (which run every 5 minutes based on our `auditInterval` setting).*

```bash
# 1. View all namespaces and their current labels to see what is compliant/non-compliant
kubectl get namespaces --show-labels

# 2. Verify the custom resources exist on the cluster
kubectl get constrainttemplates
kubectl get k8srequiredlabels

# 3. Test REJECTION: Try to create a namespace WITHOUT the required label
kubectl create namespace test-bad-ns
# EXPECTED: Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request...

# 4. Test ACCEPTANCE: Try to create a namespace WITH the required label
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: test-good-ns
  labels:
    nkp-managed: "true"
EOF
# EXPECTED: namespace/test-good-ns created

# 5. Check the Audit Log (Optional)
# This will show you a list of all those existing namespaces that are currently violating the policy
kubectl describe k8srequiredlabels ns-must-have-nkp-managed

# 6. Clean up
kubectl delete namespace test-good-ns
```

---

## Troubleshooting: The Chicken-and-Egg CRD Race Condition

**Symptom:** 
You run `flux get kustomization -n <namespace>` and see the following error:
`dry-run failed: no matches for kind "X" in version "constraints.gatekeeper.sh/v1beta1"`

**Cause:**
This happens when Flux tries to validate a Gatekeeper `Constraint` before Gatekeeper has finished compiling the corresponding `ConstraintTemplate` (which registers the CRD with the Kubernetes API). 

**The Quick Fix (Without modifying Git):**
You can manually "prime" the Kubernetes API server by applying the template directly via `kubectl`. This creates the CRD so Flux's dry-run succeeds on its next attempt.

1. Apply the template directly from your local repository:
   ```bash
   kubectl apply -f clusters/nkp-starter/templates/require-labels-template.yaml
   ```
2. Wait 10 seconds for Gatekeeper to compile it.
3. Force Flux to retry the sync:
   ```bash
   flux reconcile kustomization nkp-constraints-sync -n nkp-user-gitops --with-source
   ```

**The Long-Term Fix:**
Separate your policies into two distinct directories (`templates` and `constraints`) and use the Flux `--depends-on` flag when creating the Kustomizations (as shown in the main runbook steps). This guarantees Flux will always wait for templates to fully deploy before attempting to validate constraints.




#
