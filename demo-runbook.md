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

# NKP GitOps & Gatekeeper Runbook: Starter Environment

This runbook details how to use GitOps to manage NKP `AppDeployments` (specifically for Gatekeeper Lifecycle Management) and Gatekeeper custom policies (`ConstraintTemplates` and `Constraints`) within an NKP Starter environment.

### ⚠️ The Shift from Flux `dependsOn` to Helm Hooks
To avoid the "Chicken and Egg" race condition where a Constraint fails to apply because its Template hasn't been compiled yet, we previously used Flux's `--depends-on` feature. That required splitting our manifests into separate `templates/` and `constraints/` folders and managing multiple sync jobs.

**We have now consolidated our policies into a single Helm Chart.** We use Helm hooks (`"helm.sh/hook": pre-install, pre-upgrade` and a negative weight of `"-5"`) on our `ConstraintTemplates`. This ensures Helm pushes the template to the cluster and waits for Gatekeeper to compile the CRD *before* it attempts to deploy the `Constraint`.

---

## Prerequisites
*   An NKP Starter environment consisting of a Management cluster and Workload cluster(s).
*   `kubectl` configured and pointing to your target **Workload Cluster** context (since Starter does not include Fleet Management, we apply these local GitOps resources directly to the cluster we want to manage).
*   `flux` CLI installed (`curl -s https://fluxcd.io/install.sh | sudo bash`).
*   A Git repository cloned locally in VSCode.

---

## Deploying to the Workload Cluster

### 1. Build the Git Repository Structure (Run in VSCode)
Run these commands to generate the directories and manifests. Notice we leave the `apps/` directory intact and build a new Helm Chart for the Gatekeeper policies.

```bash
# Create distinct directories for apps and charts
mkdir -p clusters/nkp-starter/apps
mkdir -p clusters/nkp-starter/charts/nkp-gatekeeper-policies/templates

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

cat << 'EOF' > clusters/nkp-starter/apps/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gatekeeper-config.yaml
EOF

# 2. Build the Helm Chart Core Files
cat << 'EOF' > clusters/nkp-starter/charts/nkp-gatekeeper-policies/Chart.yaml
apiVersion: v2
name: nkp-gatekeeper-policies
description: A Helm chart for Gatekeeper constraints and templates
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# 3. Create the Gatekeeper ConstraintTemplate (WITH HELM HOOKS)
cat << 'EOF' > clusters/nkp-starter/charts/nkp-gatekeeper-policies/templates/require-labels-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
  annotations:
    "helm.sh/hook": pre-install, pre-upgrade
    "helm.sh/hook-weight": "-5"
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

# 4. Create the Gatekeeper Constraint
cat << 'EOF' > clusters/nkp-starter/charts/nkp-gatekeeper-policies/templates/require-labels-constraint.yaml
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

```
Commit and push these files to your remote repository.

### 2. Configure the Flux Git Source & HelmRelease
Set your credentials and wire Flux to your repository. Ensure your `kubectl` context is set to your **Workload Cluster**. Because we use a Helm Chart, we only need to sync the App patch via Kustomization and create a `HelmRelease` for the policies.

```bash
export GITHUB_TOKEN="<your-github-pat>"
export GITHUB_USER="<your-github-username>"
export REPO_NAME="nkp-gitops-apps-demo"
export TARGET_BRANCH="unlicensedhelmrelease/v1.0"
```

kubectl create namespace nkp-user-gitops

# Create the Git credentials secret & source
flux create secret git github-auth \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --username=${GITHUB_USER} \
  --password=${GITHUB_TOKEN} \
  --namespace=nkp-user-gitops

flux create source git nkp-apps-repo \
  --url=https://github.com/${GITHUB_USER}/${REPO_NAME}.git \
  --branch=${TARGET_BRANCH} \
  --secret-ref=github-auth \
  --namespace=nkp-user-gitops

# 1. Sync the Apps
flux create kustomization nkp-apps-sync \
  --source=GitRepository/nkp-apps-repo \
  --path="./clusters/nkp-starter/apps" \
  --prune=true \
  --interval=10m \
  --namespace=nkp-user-gitops

# 2. Deploy the Helm Chart
cat <<EOF | kubectl apply -f -
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: nkp-gatekeeper-policies
  namespace: nkp-user-gitops
spec:
  interval: 5m
  chart:
    spec:
      chart: ./clusters/nkp-starter/charts/nkp-gatekeeper-policies
      sourceRef:
        kind: GitRepository
        name: nkp-infra-repo
      interval: 1m
EOF

```
*Note: Because of the Helm hooks, Flux will pass the chart to the Helm controller, which natively applies the Template, waits for it to be ready, and then applies the Constraint!*

---

## Verify the Gatekeeper Policy is Enforced
To prove the policy is working on your workload cluster, run these tests.

*Note on Existing Resources: Applying this policy will **not** break or delete existing namespaces that lack the label. Gatekeeper operates as an admission webhook that intercepts new `CREATE` or `UPDATE` requests. Existing non-compliant namespaces will continue to run normally, but will be flagged as violations in Gatekeeper's audit logs (which run every 5 minutes based on our `auditInterval` setting).*

```bash
# 1. Check the status of the Flux HelmRelease
kubectl get helmrelease nkp-gatekeeper-policies -n nkp-user-gitops
# EXPECTED: Ready status should be True.

# 2. Verify the custom resources exist on the cluster
kubectl get constrainttemplates k8srequiredlabels
kubectl get k8srequiredlabels ns-must-have-nkp-managed

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

```

---

## Uninstall & Teardown

Because we deployed this using GitOps, deleting the manual test resources and removing the Flux configuration will instruct the cluster to automatically clean up the Helm release and policy engine artifacts.

```bash
# 1. Clean up manual test namespaces
kubectl delete namespace test-good-ns

# 2. Remove the Flux HelmRelease
# (This signals Helm to uninstall the release, which deletes the Constraint and ConstraintTemplate)
kubectl delete helmrelease nkp-gatekeeper-policies -n nkp-user-gitops

# 3. Remove the Flux App Kustomization
# (This un-patches Gatekeeper, returning it to default settings)
kubectl delete kustomization nkp-apps-sync -n nkp-user-gitops

# 4. Remove the Git Source and Secret
kubectl delete gitrepository nkp-apps-repo -n nkp-user-gitops
kubectl delete secret github-auth -n nkp-user-gitops

# 5. Delete the namespace
kubectl delete namespace nkp-user-gitops

```
