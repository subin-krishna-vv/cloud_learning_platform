# Cloud-Native GitOps Platform — Learning & Build Plan

> A single GitHub project that covers every missing skill for a senior DevOps role
> at a mid-size product company.
>
> **Estimated timeline:** 16 weekends (roughly 4 months alongside your job)
> **Outcome:** One well-documented GitHub repo that answers every interview question
> on GitOps, observability, SRE, security, secrets, policy, and automation.

---

## What You Are Building

A production-inspired **GitOps platform** that deploys a simple Python Flask API using:

- **ArgoCD** for GitOps-based continuous delivery
- **HashiCorp Vault** for secrets management with Kubernetes auth
- **Kyverno** for cluster-level policy enforcement
- **RBAC + NetworkPolicy** for cluster security and isolation
- **Trivy** for container image and manifest security scanning in CI/CD
- **OpenTelemetry + Grafana Tempo** for distributed tracing (third observability pillar)
- **Prometheus + Grafana SLO Dashboard** for SRE-style service level objectives
- **Kubecost** for Kubernetes namespace-level cost visibility
- **Python scripts** for operational automation
- **GitHub Actions** for the CI/CD pipeline

The application is intentionally simple. The complexity and learning
is entirely in the platform around it — which is exactly how product company
infrastructure works.

---

## GitHub Repository Structure

```
cloudnative-platform/
│
├── app/                              # Sample Python Flask application
│   ├── src/
│   │   └── main.py                   # Flask app with OTel instrumentation
│   ├── tests/
│   │   └── test_main.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── helm/                             # Helm chart for the application
│   └── flask-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── serviceaccount.yaml
│           └── networkpolicy.yaml    # Added in Phase 4
│
├── gitops/                           # ArgoCD manifests
│   ├── bootstrap/
│   │   └── argocd-install.yaml
│   ├── apps/
│   │   ├── app-of-apps.yaml
│   │   └── flask-app.yaml
│   └── environments/
│       ├── dev/
│       │   └── values.yaml
│       └── prod/
│           └── values.yaml
│
├── vault/                            # HashiCorp Vault setup
│   ├── policies/
│   │   └── flask-app-policy.hcl
│   ├── setup.sh
│   └── README.md
│
├── security/
│   ├── rbac/                         # Added in Phase 4
│   │   ├── flask-app-role.yaml
│   │   ├── flask-app-rolebinding.yaml
│   │   └── namespace-admin-rolebinding.yaml
│   ├── kyverno/
│   │   └── policies/
│   │       ├── disallow-latest-tag.yaml
│   │       ├── require-resource-limits.yaml
│   │       ├── disallow-privileged-containers.yaml
│   │       ├── require-labels.yaml
│   │       └── require-networkpolicy.yaml  # Added in Phase 4
│   └── trivy/
│       └── .trivyignore
│
├── observability/                    # Added in Phase 6
│   ├── otel/
│   │   ├── collector-config.yaml     # OpenTelemetry Collector config
│   │   └── otel-collector-deploy.yaml
│   ├── tempo/
│   │   └── tempo-values.yaml         # Grafana Tempo Helm values
│   ├── prometheus/
│   │   ├── prometheus-values.yaml
│   │   └── recording-rules.yaml      # SLO recording rules (Phase 7)
│   └── grafana/
│       ├── grafana-values.yaml
│       ├── dashboards/
│       │   ├── flask-app-dashboard.json
│       │   ├── slo-dashboard.json     # Built in Phase 7
│       │   └── traces-dashboard.json  # Built in Phase 6
│       └── datasources/
│           ├── prometheus.yaml
│           ├── loki.yaml
│           └── tempo.yaml             # Added in Phase 6
│
├── kubecost/                          # Added in Phase 8
│   ├── kubecost-values.yaml
│   └── README.md
│
├── automation/                        # Python scripts
│   ├── k8s_health_check.py
│   ├── aws_cost_report.py
│   └── log_parser.py
│
├── .github/
│   └── workflows/
│       ├── ci.yaml                    # Build → Test → Trivy → Push
│       └── update-image-tag.yaml      # GitOps trigger
│
├── docs/
│   ├── architecture.md
│   ├── local-setup.md
│   └── decisions.md                   # Architecture Decision Records
│
└── README.md
```

---

## Phase 1 — Local Kubernetes and the Sample App

**Duration:** Weekend 1–2
**Goal:** Get a local K8s cluster running and deploy the Flask app manually using Helm.

### Core Concepts to Learn

**Kind (Kubernetes in Docker)**
Kind runs a real Kubernetes cluster inside Docker containers on your laptop.
It is the standard tool for local K8s development because it closely mirrors
production clusters. You are not learning a simplified version — Kind uses
the same control plane components as EKS.

Key things to understand:
- How Kind creates a multi-node cluster using Docker containers as nodes
- The Kind config file and how to define control plane and worker nodes
- How `kubectl` connects to the Kind cluster via kubeconfig context

**Helm — Going Deeper Than You Think**
You likely know Helm basics. For this project, focus on what product company
interviews actually probe:
- `values.yaml` override hierarchy — base values, environment-specific values, and `--set` flags
- What `helm upgrade --install` does atomically and why it matters for deployments
- Helm hooks — `pre-install`, `post-upgrade` — and when to use them
- Difference between `helm template` (renders manifests locally) and `helm install`
- How Helm stores release history as Secrets and how rollback works

**Helm Chart Authoring — Writing Templates from Scratch**

Most engineers can run `helm install`. Far fewer can write a well-structured chart
from scratch and debug it when templates fail. This is the gap interviewers look for
at senior level. You are going to write every template file in this project yourself
— not copy from a generator.

**Template Language Fundamentals**
Helm uses Go's `text/template` engine. Every `.yaml` file in `templates/` is processed
through this engine before being sent to Kubernetes. The key mental model: the template
is not YAML — it is a program that generates YAML. If you think of it as YAML with
some variables, you will be confused by whitespace and indentation issues.

Built-in objects you will use constantly:
- `{{ .Values.image.repository }}` — reads from `values.yaml` or overrides
- `{{ .Release.Name }}` — the name you gave when running `helm install myrelease ./chart`
- `{{ .Release.Namespace }}` — the Kubernetes namespace of the release
- `{{ .Chart.Name }}` — reads from `Chart.yaml`
- `{{ .Chart.AppVersion }}` — the application version from `Chart.yaml`
- `{{ .Capabilities.APIVersions }}` — what API versions the cluster supports
  (useful for writing charts compatible with multiple K8s versions)

Template functions you must know:
- `default` — provides a fallback value: `{{ .Values.replicas | default 1 }}`
- `quote` — wraps in quotes for YAML safety: `{{ .Values.name | quote }}`
- `toYaml` — converts a YAML object to a string: `{{ toYaml .Values.resources | nindent 12 }}`
- `nindent` — adds a newline and indentation: critical for embedding multi-line YAML
- `include` — calls a named template and captures the output as a string
- `required` — fails the render if a value is missing:
  `{{ required "image.repository is required" .Values.image.repository }}`
- `tpl` — renders a string as a template: useful for values that contain template expressions

Pipelines chain functions left to right, just like Unix pipes:
```
{{ .Values.name | default "flask-app" | quote }}
```
This reads `.Values.name`, falls back to `"flask-app"` if not set, then wraps it in quotes.

**Flow Control in Templates**
Templates are not just variable substitution — they have full programming logic.

`if/else` — conditionally include entire Kubernetes resources:
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "flask-app.fullname" . }}
  # ... rest of Ingress spec
{{- end }}
```
This is the production pattern: your chart supports Ingress but it is optional.
Teams without an ingress controller set `ingress.enabled: false` and the resource
is not created at all.

`range` — loop over lists or maps:
```yaml
env:
  {{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value | quote }}
  {{- end }}
```
This lets you define environment variables in `values.yaml` as a list and the
template generates the correct YAML for each entry. No hardcoded env vars in templates.

`with` — change the scope to avoid repetition:
```yaml
{{- with .Values.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
```
Inside the `with` block, `.` refers to `.Values.resources` — shorter and cleaner.
But be careful: inside `with`, you cannot access `.Release.Name` — you need `$` for the root scope.

**Whitespace control — the most common source of Helm bugs:**
`{{-` trims all whitespace before the tag. `-}}` trims all whitespace after.
Without these, your rendered YAML will have blank lines that either break parsing
or create resources with empty fields. When debugging a Helm chart that produces
invalid YAML, whitespace is almost always the cause. Use `helm template` to render
locally and inspect the output.

**Named Templates and _helpers.tpl**
The `_helpers.tpl` file is where you define reusable template snippets. Files starting
with `_` are not rendered as Kubernetes manifests — they only define helpers.

The standard pattern every production chart follows:

```yaml
# templates/_helpers.tpl

{{/* Generate the full name of the release */}}
{{- define "flask-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Common labels applied to every resource */}}
{{- define "flask-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels — used in Deployment matchLabels and Service selector */}}
{{- define "flask-app.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Why this matters:
- Every resource in your chart uses `{{ include "flask-app.labels" . | nindent 4 }}`
  for consistent labelling. If you need to add a label, you change one file.
- Selector labels are a subset of all labels. Deployment `matchLabels` and Service
  `selector` must use only immutable labels — they cannot change after creation.
  Separating selector labels from metadata labels is not optional, it is required.
- `include` is preferred over `template` because `include` captures the output as a
  string that you can pipe through `nindent`. `template` outputs directly and cannot
  be indented — this breaks nested YAML every time.

**Chart Dependencies and Subcharts**
A Helm chart can depend on other charts. You declare dependencies in `Chart.yaml`:

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

Running `helm dependency update` downloads the dependency into the `charts/` directory.
You pass values to the subchart by nesting under its name in `values.yaml`:

```yaml
# values.yaml
postgresql:
  enabled: true
  auth:
    postgresPassword: "changeme"
    database: "flaskdb"
```

The `condition` field means the subchart is only deployed when `postgresql.enabled`
is true. This is how you make dependencies optional — dev environments might use
a local PostgreSQL, while prod uses an external RDS.

When to use subcharts vs separate Helm releases:
- Use subcharts when the dependency is tightly coupled and should be deployed atomically
  (e.g., an app bundled with its database for local dev)
- Use separate releases when the dependency is shared infrastructure managed by a
  different team (e.g., Prometheus, Vault, Kyverno)

For this project, your Flask app chart does not need subcharts — all platform
components are separate Helm releases managed through ArgoCD. But understanding
subcharts is critical because you will encounter them in every third-party chart you install.

**Chart Testing and Validation**
Before deploying, validate your chart at three levels:

`helm lint ./helm/flask-app/` — checks for syntax errors, missing required fields
in `Chart.yaml`, and best practice violations. Run this in CI on every PR. A chart
that fails lint should never be deployed.

`helm template myrelease ./helm/flask-app/ -f helm/flask-app/values-dev.yaml` —
renders all templates locally without contacting a cluster. This is the most important
debugging tool. When a template produces broken YAML, run this command, inspect the
output, and find the issue. Pipe through `kubectl apply --dry-run=client -f -` for
full validation including Kubernetes schema checks.

`helm test myrelease` — runs test pods defined in `templates/tests/`. Write a simple
test that curls the `/health` endpoint and asserts a 200 response. Helm tests run
after install and are used in CI to verify a release actually works.

`values.schema.json` — a JSON Schema file at the root of your chart that validates
`values.yaml` before rendering. If someone forgets to set `image.repository`, the
chart fails immediately with a clear error instead of deploying a broken manifest.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["image"],
  "properties": {
    "image": {
      "type": "object",
      "required": ["repository", "tag"],
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" }
      }
    },
    "replicaCount": { "type": "integer", "minimum": 1 }
  }
}
```

### What to Build

1. Install Kind and create a 3-node cluster (1 control plane, 2 workers) using a `kind-config.yaml`
2. Write the Flask app — two endpoints: `GET /health` returns `{"status": "ok"}`,
   `GET /items` returns a hardcoded list
3. Write the Dockerfile — use a non-root user, multi-stage build, pin the base image to a specific version
4. Write the Helm chart with proper resource requests/limits, liveness and readiness probes,
   and meaningful labels on every resource
5. Write `templates/_helpers.tpl` with three named templates: `fullname` (release name
   generation with 63-char truncation), `labels` (standard Kubernetes labels including
   chart version and managed-by), and `selectorLabels` (immutable subset for Deployment
   matchLabels and Service selector). Use `include` with `nindent` in every template file.
6. Add conditional Ingress creation — the Ingress resource only renders when
   `ingress.enabled: true` in values. Set it to `true` in `values-dev.yaml` and
   `false` in `values-prod.yaml`. Verify with `helm template` that the Ingress
   appears in dev output and is absent in prod output.
7. Add a `range` loop for environment variables in `templates/deployment.yaml` —
   define env vars as a list in `values.yaml` instead of hardcoding them. Include
   at least `FLASK_ENV`, `LOG_LEVEL`, and `APP_PORT` with different values per environment.
8. Write `values.schema.json` at the chart root that enforces: `image.repository`
   and `image.tag` are required strings, `replicaCount` is an integer with minimum 1.
   Test that omitting `image.tag` causes `helm template` to fail with a schema error.
9. Run `helm lint ./helm/flask-app/` and fix any warnings. Run
   `helm template myrelease ./helm/flask-app/ -f helm/flask-app/values-dev.yaml`
   and inspect the rendered output for both dev and prod values. Verify clean YAML
   with no blank lines or indentation errors.
10. Deploy manually with `helm install` and verify it works end to end

### Why This Matters in Interviews

Non-root containers and resource limits are things Kyverno will enforce later.
If you understand why they matter now, you can explain the entire security posture
of your cluster end to end. That is a complete, senior-level interview answer.

### Interview Scenario You Can Now Answer — Helm Chart Authoring

*"Walk me through how you write and structure a Helm chart for a new service."*

I start with `Chart.yaml` defining the chart name, version, and appVersion. The
`values.yaml` has sensible defaults for everything — replicas, image, resources,
ingress — so the chart works out of the box with `helm install`. Environment-specific
overrides go in `values-dev.yaml` and `values-prod.yaml` — different replica counts,
resource limits, and feature flags per environment.

For templates, `_helpers.tpl` defines three named templates: `fullname` for consistent
resource naming with 63-character truncation, `labels` for standard Kubernetes labels
on every resource, and `selectorLabels` as an immutable subset used in Deployment
matchLabels and Service selectors. Every template file uses `include` with `nindent`
rather than `template` — because `include` returns a string you can pipe through
indentation functions, while `template` outputs directly and breaks nested YAML.

Optional resources like Ingress are wrapped in `{{- if .Values.ingress.enabled }}`
so they only render when needed. Environment variables use `range` loops over a list
in values rather than being hardcoded. I validate with `helm lint` in CI on every PR,
render with `helm template` piped through `kubectl apply --dry-run=client` for full
schema validation, and enforce required values with a `values.schema.json` at the
chart root. A missing `image.tag` fails the pipeline before it ever reaches the cluster.

---

## Phase 2 — GitOps with ArgoCD

**Duration:** Weekend 3–4
**Goal:** Replace manual `helm install` with fully automated GitOps delivery via ArgoCD.

### Core Concepts to Learn

**What GitOps Actually Means**
GitOps is not just "deploy from Git." It is a specific operational model with four principles:
1. Git is the single source of truth for desired state
2. Desired state is declared, not imperative
3. Approved changes to Git are applied automatically
4. Software agents continuously reconcile actual state with desired state

The key mental model: in GitOps you never run `kubectl apply` manually in production.
You push to Git, ArgoCD detects the diff and applies it. If someone manually changes
something in the cluster, ArgoCD detects drift and auto-corrects it.

**ArgoCD Architecture — Understand Each Component**
- **API Server** — exposes the ArgoCD API and UI, handles authentication
- **Repository Server** — clones Git repos, renders Helm/Kustomize manifests
- **Application Controller** — the core reconciliation loop, watches cluster state vs Git state
- **Dex** — optional OIDC provider for SSO integration

**The App of Apps Pattern**
Instead of manually creating each ArgoCD Application, you create one root Application
that points to a folder containing other Application manifests. ArgoCD deploys the root
app, which deploys all child apps automatically. This is how product companies manage
tens or hundreds of services without manual setup.

**Sync Policies and Sync Waves**
- `automated` sync — ArgoCD polls Git every 3 minutes and applies changes automatically
- `selfHeal` — ArgoCD reverts manual kubectl changes back to Git state
- `prune` — ArgoCD deletes resources that were removed from Git
- Sync waves — control the order of resource deployment using the annotation
  `argocd.argoproj.io/sync-wave: "1"` — Vault must be up before the app

### What to Build

1. Install ArgoCD into your Kind cluster using the official manifest
2. Create a `bootstrap/` folder with the root App of Apps manifest
3. Create an ArgoCD Application for the Flask app pointing to your Helm chart
4. Set up two environments — `dev` and `prod` — as separate namespaces with different Helm values
5. Make a change to `values-dev.yaml`, push to Git, watch ArgoCD sync it automatically
6. Enable `selfHeal` and manually scale a deployment via `kubectl` — watch ArgoCD correct it back
7. Port-forward the ArgoCD UI and explore sync history and diff views

### Interview Scenario You Can Now Answer

*"Walk me through how a code change reaches production in your GitOps setup."*

Developer merges PR → GitHub Actions CI runs (build, test, scan) → on success,
the pipeline updates the image tag in the Helm values file in Git → ArgoCD detects
the diff within 3 minutes → ArgoCD syncs the new Helm release to the cluster →
sync history and diff are visible in the ArgoCD UI. Rollback is a Git revert —
no kubectl commands, full audit trail.

---

## Phase 3 — Secrets Management with HashiCorp Vault

**Duration:** Weekend 5–6
**Goal:** Remove all hardcoded secrets. Pull secrets dynamically from Vault at pod startup.

### Core Concepts to Learn

**Why Kubernetes Secrets Are Not Enough**
Kubernetes Secrets are base64 encoded, not encrypted. Anyone with cluster access
can read them. They also lack audit trails — you cannot answer "who read this secret
and when?" Vault solves both problems.

**Vault Architecture — Key Components**
- **Storage Backend** — where Vault persists encrypted data
- **Auth Methods** — how clients authenticate to Vault. For Kubernetes, pods authenticate
  using their ServiceAccount JWT token
- **Secret Engines** — plugins that store or generate secrets. KV (key-value) is the most
  common. Dynamic secrets (database credentials that expire) is the advanced use case
- **Policies** — HCL files that define what a given identity can read or write in Vault
- **Leases and TTLs** — every secret has a lease. When it expires, the app renews or
  fetches a new one

**Kubernetes Auth Method — The Full Flow**
1. Pod starts with a mounted ServiceAccount token
2. Vault Agent (sidecar) authenticates to Vault using that ServiceAccount token
3. Vault validates the token against the Kubernetes API
4. Vault returns a Vault token based on the bound role and its associated policy
5. Vault Agent fetches secrets and writes them as files into a shared volume in the pod
6. Your app reads secrets from files, not environment variables

This is the production pattern. Environment variables are visible in process listings
and container inspect output. Files with restricted permissions are safer.

**The Vault Agent Injector**
The injector is a Kubernetes mutating admission webhook. When it sees a pod with
specific Vault annotations, it automatically injects a Vault Agent init container
and sidecar. You do not change your application code at all — only annotations
on the deployment.

### What to Build

1. Install Vault in dev mode on your Kind cluster using the official Helm chart
2. Enable the Kubernetes auth method and configure it with your cluster details
3. Write a Vault policy (`flask-app-policy.hcl`) that allows read access to
   `secret/data/flask-app/*`
4. Create a Vault role that binds the policy to the Flask app's Kubernetes ServiceAccount
5. Store a fake database password in Vault at `secret/flask-app/db`
6. Add Vault annotations to your Helm chart's deployment template
7. Verify the secret appears as a file inside the running pod at `/vault/secrets/db`
8. Update the Flask app to read the secret from the file instead of an environment variable
9. Write `vault/setup.sh` that automates steps 1–4 (this is also Python-adjacent automation)

### Interview Scenario You Can Now Answer

*"How do you handle secrets in Kubernetes? Why not just use K8s Secrets?"*

K8s Secrets are base64, not encrypted, and lack audit trails. We use HashiCorp Vault
with the Kubernetes auth method and the Vault Agent Injector. Pods authenticate to Vault
using their ServiceAccount JWT — Vault validates it against the K8s API and the agent
injects secrets as files into the pod. This gives us encryption at rest, fine-grained
RBAC policies, full audit logs, and TTL-based secret rotation without restarting pods.

---

## Phase 4 — Security: Kyverno, RBAC, and NetworkPolicy

**Duration:** Weekend 7–8
**Goal:** Enforce security standards at three layers — policy admission (Kyverno),
identity and access (RBAC), and network (NetworkPolicy).

### Part A: Policy as Code with Kyverno

**Core Concepts**

Kyverno is a Kubernetes-native policy engine that integrates with the admission
webhook. It intercepts every resource creation and update request and either
blocks it (enforce mode) or flags it (audit mode).

**Types of Kyverno Policies**
- **Validation** — blocks resources violating a rule. Example: block pods using `latest` tag
- **Mutation** — modifies resources before storage. Example: auto-add a default resource limit
- **Generation** — creates new resources when a trigger fires. Example: auto-create a
  NetworkPolicy when a new Namespace is created

**The Admission Webhook Flow**
1. `kubectl apply` sends the resource to the K8s API server
2. API server calls Kyverno's validating/mutating webhook
3. Kyverno evaluates all policies against the resource
4. Kyverno returns Allow or Deny
5. If Deny, the apply fails with a clear policy violation message in the terminal

**Policies to Write — All Five**

Policy 1: Disallow Latest Tag — block any container using `image:latest`.
Reason: latest is not reproducible and breaks GitOps traceability.

Policy 2: Require Resource Limits — block pods without CPU and memory limits.
Reason: unbounded pods can starve other workloads on the same node.

Policy 3: Disallow Privileged Containers — block containers running as privileged or root UID 0.
Reason: privilege escalation is the most common container breakout vector.

Policy 4: Require Standard Labels — require `app`, `env`, and `team` labels on all Deployments.
Reason: without labels, cost allocation and incident response are impossible.

Policy 5: Require NetworkPolicy — every namespace must have at least one NetworkPolicy.
Reason: without this, any pod can reach any other pod across the cluster.

**What to Build**

1. Install Kyverno using its Helm chart
2. Write all five policies in `security/kyverno/policies/`
3. Start in audit mode — Kyverno logs violations but does not block
4. Run `kubectl get policyreport -A` to see what your existing resources violate
5. Fix your Flask app Helm chart to pass all five policies
6. Switch to enforce mode
7. Try deploying a bad pod (with `latest` tag) and capture the error message in your README

---

### Part B: Kubernetes RBAC

**Core Concepts**

RBAC (Role-Based Access Control) controls who can do what inside the cluster.
It is one of the most commonly tested K8s topics in senior DevOps interviews.

**The Four Objects — Know Them Deeply**

`Role` — defines a set of permissions within a single namespace.
Example: allow get and list on Pods in the `flask-app` namespace.

`ClusterRole` — same as Role but applies across all namespaces or to
cluster-scoped resources (like Nodes and PersistentVolumes).

`RoleBinding` — binds a Role or ClusterRole to a Subject (User, Group, or
ServiceAccount) within a specific namespace.

`ClusterRoleBinding` — binds a ClusterRole to a Subject across the entire cluster.

**The Principle of Least Privilege**
Every workload should have only the permissions it actually needs. A Flask API
that only reads from a database needs no Kubernetes API access at all. Its
ServiceAccount should have zero RBAC permissions. This is the default when
you create a ServiceAccount — no permissions unless you explicitly bind a Role.

**What to Build**

1. Create a dedicated ServiceAccount for the Flask app (not the `default` SA)
2. Write `security/rbac/flask-app-role.yaml` — a Role in the `flask-app` namespace
   that allows the app to `get` and `list` its own ConfigMaps only
3. Write `security/rbac/flask-app-rolebinding.yaml` — bind the Role to the ServiceAccount
4. Update the Helm chart to reference the dedicated ServiceAccount
5. Test with `kubectl auth can-i get pods --as=system:serviceaccount:flask-app:flask-app-sa`
   — it should return `no`
6. Test with `kubectl auth can-i get configmaps --as=system:serviceaccount:flask-app:flask-app-sa`
   — it should return `yes`
7. Write an ADR in `docs/decisions.md` explaining your RBAC model

---

### Part C: NetworkPolicy

**Core Concepts**

By default in Kubernetes, all pods can communicate with all other pods — across
namespaces and across nodes. NetworkPolicy objects restrict this using label selectors
and namespace selectors.

**The Default Deny Pattern**
The production pattern is to start with a default-deny-all NetworkPolicy in every
namespace, then add explicit allow rules for only the traffic that is needed.

```
default-deny-all  →  allow ingress from ingress-controller  →  allow egress to database namespace
```

NetworkPolicies are enforced by the CNI plugin (not Kubernetes itself). Kind uses
Kindnet by default which does not enforce NetworkPolicies. You need to switch to
Calico or Cilium in your Kind config for this to actually work. Do it — it teaches
you that NetworkPolicy is CNI-dependent, which is a real interview question.

**What to Build**

1. Recreate your Kind cluster with Calico as the CNI plugin
2. Write a default-deny-all NetworkPolicy for the `flask-app` namespace
3. Write an allow-ingress rule permitting traffic only from the ingress-controller namespace
4. Write an allow-egress rule permitting DNS resolution (UDP port 53 to kube-system)
5. Add a Kyverno policy that ensures every new Namespace has the default-deny NetworkPolicy
   generated automatically (use Kyverno's Generate policy type)
6. Test that a pod in the `default` namespace cannot reach the Flask app
7. Test that a request through the ingress controller can reach the Flask app

### Interview Scenario You Can Now Answer

*"How do you enforce security standards across a multi-team Kubernetes cluster?"*

Three layers. Policy admission via Kyverno — every resource is validated at the
admission webhook before it is stored. If it violates a policy like using latest tags
or missing resource limits, the deployment fails with a clear message. Identity via
RBAC — every workload runs with a dedicated ServiceAccount with only the permissions
it needs. We use `kubectl auth can-i` in our CI pipeline to validate permissions
don't drift. Network via NetworkPolicy with Calico — default-deny in every namespace,
with explicit allow rules for only the traffic flows we actually need. Kyverno
auto-generates the default-deny policy for every new namespace so teams can't skip it.

---

## Phase 5 — Security Scanning with Trivy in CI/CD

**Duration:** Weekend 9
**Goal:** Scan your Docker image for vulnerabilities in GitHub Actions and fail
the build on critical issues.

### Core Concepts to Learn

**What Trivy Scans**
Trivy is a comprehensive vulnerability scanner covering:
- OS packages inside the container (apt, rpm packages)
- Language dependencies (Python pip, Node npm packages)
- Kubernetes manifests for misconfigurations
- Terraform files for misconfigurations
- Secret detection in files and git history

**Vulnerability Severity Levels**
`CRITICAL → HIGH → MEDIUM → LOW → UNKNOWN`

A production CI/CD pipeline fails on `CRITICAL` and `HIGH`. `MEDIUM` and below
are tracked but not blocking. Configure this with `--severity CRITICAL,HIGH --exit-code 1`.

**The `.trivyignore` File**
Sometimes you cannot immediately update a dependency with a known CVE and need
to accept the risk temporarily. The `.trivyignore` file lists CVE IDs to suppress
with a comment explaining why and when it will be revisited. This shows maturity —
you are documenting accepted risk, not silently ignoring security.

**Shift Left Security**
Moving security checks earlier in the development lifecycle — from production audits
to pre-merge CI. When Trivy runs on every PR, developers see vulnerabilities before
they merge, not after deployment.

### The GitHub Actions CI Pipeline to Build

```
Workflow: ci.yaml
Trigger: push to main, pull_request

Job 1 — test
  - checkout code
  - set up Python
  - run pytest

Job 2 — build-and-scan  (needs: test)
  - build Docker image
  - run Trivy scan on the image
  - upload Trivy SARIF report to GitHub Security tab
  - fail the job if CRITICAL or HIGH found

Job 3 — push-image  (needs: build-and-scan)
  - login to GitHub Container Registry (ghcr.io)
  - push image tagged with git SHA (never latest)

Job 4 — update-gitops  (needs: push-image)
  - checkout repo
  - update the image tag in helm/flask-app/values.yaml
  - commit and push
  - ArgoCD detects the change and deploys
```

Job 4 is the GitOps trigger. CI does not run `kubectl apply`. It updates
a file in Git and lets ArgoCD take over. This is the clean separation of
CI and CD in a GitOps model.

### What to Build

1. Create `.github/workflows/ci.yaml` with all four jobs
2. Set up GitHub Container Registry (ghcr.io) — it is free and built in
3. Add Trivy SARIF output and upload it to GitHub Security tab
4. Create a `.trivyignore` with one suppressed CVE, a reason, and a review date
5. Deliberately use an old base image (`python:3.9`) and see real vulnerabilities
6. Update to `python:3.12-alpine` — see the vulnerability count drop significantly
7. Document the before/after vulnerability counts in your README

### Interview Scenario You Can Now Answer

*"How do you handle container security in your CI/CD pipeline?"*

We run Trivy in GitHub Actions on every PR. It scans the Docker image before it
is pushed to the registry — we fail on CRITICAL and HIGH. The SARIF report uploads
to GitHub's Security tab so developers see findings inline with their code. For
accepted risks we can't immediately fix, we use a `.trivyignore` file with the CVE ID,
business justification, and a review date — a documented exception, not silent
suppression. We also scan Helm charts and Terraform with Trivy for misconfigurations
in the same pipeline.

---

## Phase 6 — Distributed Tracing with OpenTelemetry and Grafana Tempo

**Duration:** Weekend 10–11
**Goal:** Add the third pillar of observability — tracing. Follow a single request
from the HTTP call through the Flask app to the database and see exactly where
time is spent.

### Core Concepts to Learn

**The Three Pillars of Observability**
- **Metrics** — aggregated numbers over time. "How many requests per second?"
  You have this with Prometheus.
- **Logs** — discrete events with context. "What happened at 14:32:05?"
  You have this with Loki and Fluentbit.
- **Traces** — the journey of a single request through multiple services.
  "Why is this specific user's request slow?" This is what you are adding.

Without traces, when a request is slow, you see a spike in your Prometheus
latency metric but cannot tell which service caused it. With traces, you see
the exact breakdown: 5ms in the API gateway, 200ms in the auth service, 800ms
waiting for a database query. This is how product companies do incident root cause
analysis.

**OpenTelemetry — What It Is**
OpenTelemetry (OTel) is the CNCF standard for instrumentation. It is vendor-neutral —
you instrument your code once and can send the data to any backend (Tempo, Jaeger,
Datadog, Honeycomb). It has three components:

- **SDK** — the library you add to your application code to generate telemetry
- **Collector** — a standalone service that receives, processes, and exports telemetry.
  The collector is the hub — your app sends to the collector, the collector sends
  to the backend. This decouples your app from the observability backend.
- **Protocol (OTLP)** — the wire format used to transmit traces, metrics, and logs

**Grafana Tempo — The Tracing Backend**
Tempo is Grafana's distributed tracing backend. It integrates natively with Grafana,
which means your traces appear in the same UI as your Prometheus metrics and Loki logs.
This is the key: you can click on a spike in a Grafana metric panel, jump directly to
the traces from that time window, click on a trace, and see the exact log lines from
that span. This is called **correlated observability** and it is what product company
SRE interviews ask about.

**Trace Anatomy — Know These Terms**
- **Trace** — the complete journey of one request, represented as a tree of spans
- **Span** — a single unit of work within a trace (e.g., "handle HTTP request",
  "query database", "call external API"). Has a start time, duration, and attributes.
- **Context Propagation** — how trace context (trace ID and span ID) is passed between
  services via HTTP headers (W3C Trace Context standard: `traceparent` header)
- **Sampling** — you do not trace 100% of requests in production. Head-based sampling
  decides at the start whether to trace a request. Tail-based sampling decides after
  the request completes based on whether it was slow or errored.

### What to Build

**Step 1: Instrument the Flask App with OpenTelemetry SDK**

Add these packages to `requirements.txt`:
```
opentelemetry-sdk
opentelemetry-api
opentelemetry-instrumentation-flask
opentelemetry-exporter-otlp
```

The `opentelemetry-instrumentation-flask` package auto-instruments Flask — it creates
a span for every HTTP request automatically without you manually adding trace code.
You only need a few lines of initialisation in `main.py`:

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor

provider = TracerProvider()
exporter = OTLPSpanExporter(endpoint="http://otel-collector:4317")
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)
FlaskInstrumentor().instrument_app(app)
```

This sends traces to the OTel Collector on port 4317.

**Step 2: Deploy the OpenTelemetry Collector**

Write `observability/otel/collector-config.yaml` with:
- Receiver: `otlp` (receives from your Flask app)
- Processor: `batch` (batches spans for efficiency)
- Exporter: `otlp/tempo` (forwards to Grafana Tempo)

Write `observability/otel/otel-collector-deploy.yaml` with the Deployment and Service
for the collector in your cluster.

**Step 3: Deploy Grafana Tempo**

Install Tempo using its Helm chart with `observability/tempo/tempo-values.yaml`.
Tempo is a single binary in monolithic mode — it is simple to run locally.

**Step 4: Connect Tempo to Grafana**

Add a Tempo datasource to Grafana in `observability/grafana/datasources/tempo.yaml`.
Also configure `traceToLogs` in the Tempo datasource so clicking a span in a trace
automatically jumps to the corresponding Loki log lines. This is the correlated
observability feature.

**Step 5: Create a Traces Dashboard**

Build a Grafana dashboard that shows:
- Request rate and error rate (from Prometheus)
- p95 and p99 latency (from Prometheus)
- A link panel that opens Tempo trace search filtered to the last time window

**Step 6: Generate and Observe Traces**

Write a simple Python script `automation/generate_traffic.py` that sends
100 requests to your Flask app. Then open Grafana → Explore → Tempo and search
for traces. Click on a slow trace and observe the span breakdown.

### Interview Scenario You Can Now Answer

*"You said you have Prometheus and Grafana. How do you handle distributed tracing?
What happens when a request is slow but your metrics don't tell you why?"*

We use OpenTelemetry for instrumentation — vendor-neutral, so we can switch backends
without touching application code. The OTel Collector receives spans from all services
and forwards to Grafana Tempo. In Grafana, I can see a latency spike in the Prometheus
panel, click the time range, jump directly to Tempo traces from that window, click the
slowest trace, and see which span caused it — down to the exact database query or
external API call. The Tempo datasource also has `traceToLogs` configured so I can
jump from a span directly to the Loki log lines from that exact request. That is the
full three-pillar observability stack — metrics, logs, and traces all correlated.

---

## Phase 7 — SRE Concepts: SLI, SLO, and Error Budget Dashboard

**Duration:** Weekend 12
**Goal:** Define formal SLOs for your Flask app, implement them as Prometheus recording
rules, and build a Grafana SLO dashboard that shows error budget burn rate.

### Core Concepts to Learn

**Why This Is The Biggest Interview Gap**
When your CV says "99.9% availability" and an interviewer asks "how did you define
and measure that, and what happened when you breached the error budget" — you need
a specific, structured answer. Vague availability claims are red flags at senior level.
Formal SLO thinking is what distinguishes SRE-aware engineers from traditional DevOps.

**SLI — Service Level Indicator**
The actual metric you measure. Must be something directly observable from your
monitoring stack. Good SLIs are ratio-based and measure from the user's perspective.

Examples for your Flask app:
- Availability SLI: proportion of HTTP requests returning 2xx status codes
- Latency SLI: proportion of HTTP requests completing in under 300ms
- Error rate SLI: proportion of requests not returning 5xx status codes

**SLO — Service Level Objective**
The target you commit to for your SLI over a rolling time window.
Example: 99.9% of HTTP requests return 2xx over a rolling 30-day window.

99.9% over 30 days = 99.9% × 30 × 24 × 60 = 43,156 minutes of allowed downtime.
That is 43.2 minutes of allowed failures per 30 days.

**Error Budget**
The amount of unreliability you are allowed before you must freeze new deployments
and focus on reliability work.

Error budget = 1 - SLO target = 0.1% of requests over 30 days can fail.
When the error budget is consumed, you stop shipping features until the budget recovers.
This is the mechanism that aligns development velocity with reliability.

**Error Budget Burn Rate**
How fast you are consuming your error budget. A burn rate of 1 means you will
exactly consume the budget by the end of the window. A burn rate of 14 means you
will consume the entire 30-day budget in about 2 days — that is a critical alert.

Google's SRE book recommends alerting at:
- Burn rate > 14 (1-hour window) — page immediately, budget gone in 2 days
- Burn rate > 6 (6-hour window) — ticket, budget gone in 5 days

**Prometheus Recording Rules for SLOs**

Recording rules pre-compute expensive queries and store them as new metrics.
SLO recording rules follow a naming convention standardised by the OpenSLO
and Sloth projects.

Write `observability/prometheus/recording-rules.yaml` with:

```yaml
# 5-minute window availability
- record: flask_app:availability:ratio_rate5m
  expr: |
    sum(rate(flask_http_requests_total{status=~"2.."}[5m]))
    /
    sum(rate(flask_http_requests_total[5m]))

# 30-day window availability (used for SLO compliance)
- record: flask_app:availability:ratio_rate30d
  expr: |
    sum(rate(flask_http_requests_total{status=~"2.."}[30d]))
    /
    sum(rate(flask_http_requests_total[30d]))

# Error budget remaining (percentage)
- record: flask_app:error_budget_remaining
  expr: |
    1 - (
      (1 - flask_app:availability:ratio_rate30d)
      /
      (1 - 0.999)
    )
```

**Grafana SLO Dashboard — Panels to Build**

Build `observability/grafana/dashboards/slo-dashboard.json` with these panels:

Panel 1 — Current SLO Compliance: Single stat showing 30-day availability as a percentage.
Red below 99.9%, yellow between 99.9% and 99.95%, green above.

Panel 2 — Error Budget Remaining: Gauge panel showing percentage of error budget
left for the current 30-day window. Red below 25%, yellow between 25% and 50%.

Panel 3 — Error Budget Burn Rate: Time series showing burn rate over the last 72 hours.
Horizontal reference lines at burn rate 14 (critical) and 6 (warning).

Panel 4 — Request Rate: Time series of total requests per second.

Panel 5 — Error Rate: Time series of 5xx responses as a percentage of total.

Panel 6 — Latency Percentiles: Time series of p50, p95, p99 request latency.

**Alerting Rules to Write**

Write two Prometheus alert rules:
- Page alert: `ErrorBudgetBurnRateCritical` — fires when burn rate > 14 over 1 hour
- Ticket alert: `ErrorBudgetBurnRateHigh` — fires when burn rate > 6 over 6 hours

### What to Build

1. Add Prometheus Flask instrumentation to the Flask app (`prometheus-flask-exporter`)
2. Expose a `/metrics` endpoint that Prometheus scrapes
3. Write the three recording rules above
4. Write the two alert rules above
5. Build the six-panel SLO dashboard in Grafana
6. Use your traffic generation script to simulate a high error rate
7. Watch the error budget burn rate spike in real time on the dashboard
8. Screenshot the dashboard for your README

### Interview Scenario You Can Now Answer

*"You mentioned 99.9% availability. How did you define and measure that? What did
you do when you were at risk of breaching it?"*

We defined formal SLOs rather than vague availability claims. Our availability SLI
is the ratio of 2xx responses to total requests over a rolling 30-day window.
The SLO target is 99.9%, which gives us 43 minutes of error budget per month.
We implemented this using Prometheus recording rules and built a Grafana dashboard
showing real-time error budget consumption and burn rate. When burn rate exceeds 14
over a 1-hour window — meaning we'll consume the entire 30-day budget in 2 days —
we get paged. When it exceeds 6 over 6 hours, we get a ticket. When the budget is
below 25%, we freeze feature deployments and focus on reliability work until it recovers.

---

## Phase 8 — Kubernetes Cost Visibility with Kubecost

**Duration:** Weekend 13
**Goal:** Add namespace-level and workload-level cost visibility to your cluster.
Demonstrate that you think about cost at the platform level, not just the AWS console level.

### Core Concepts to Learn

**Why Kubecost Matters**
Your CV mentions a 30% cost reduction at the infrastructure level — EC2 rightsizing,
reserved instances, eliminating idle resources. That is good. But product companies
running EKS also want cost visibility at a finer grain:

- Which team's namespace is consuming the most cost?
- Which specific deployment is over-provisioned?
- What is the cost of running the monitoring stack vs the application?
- Is the dev environment costing more than it should?

Kubecost answers these questions by combining K8s resource usage metrics with cloud
pricing data to produce per-namespace, per-deployment, per-label cost estimates.

**How Kubecost Works**
Kubecost runs as a pod in your cluster. It reads resource requests and limits
from the Kubernetes API, tracks actual usage via Prometheus metrics, and applies
cloud pricing (or configurable on-prem pricing) to calculate cost estimates.

Key concepts:
- **Cost allocation** — distributing cluster cost to namespaces, labels, and teams
- **Efficiency score** — ratio of resource usage to resource requests. A pod requesting
  1 CPU but using 0.1 CPU has 10% efficiency — it is over-provisioned by 10x
- **Shared cost** — how to allocate the cost of shared infrastructure like the
  monitoring stack or ingress controller across teams
- **Idle cost** — the cost of resources provisioned but never used

**The Efficiency Score in Interviews**
When you can say "I implemented cost visibility that showed team A's namespace had
40% CPU efficiency — meaning they were over-provisioning by 2.5x — and we worked
with them to right-size their resource requests, reducing their namespace cost by 30%"
— that is a complete, credible cost optimisation story.

### What to Build

1. Install Kubecost using its Helm chart with `kubecost/kubecost-values.yaml`
2. Port-forward the Kubecost UI and explore the cost allocation view by namespace
3. Take a screenshot of the cost breakdown between `flask-app`, `monitoring`,
   `argocd`, and `vault` namespaces — add it to your README
4. Note the efficiency score for each namespace (your monitoring stack will likely
   be over-provisioned — this is realistic)
5. Write `kubecost/README.md` explaining:
   - What cost allocation model you used
   - What the efficiency scores revealed
   - What resource request changes you would make based on the data
6. Write one Prometheus alert: `NamespaceCostThresholdBreached` — fires when a
   namespace cost exceeds a configurable daily threshold

### Interview Scenario You Can Now Answer

*"Beyond AWS cost optimisation, how do you manage costs at the Kubernetes level?"*

At the K8s level we use Kubecost for namespace and workload-level cost visibility.
It combines resource request and actual usage data with cloud pricing to show cost
per namespace, per deployment, and per team label. The key metric is efficiency score —
the ratio of actual usage to requested resources. A score of 20% means you are
paying for 5x more than you use. We run monthly efficiency reviews and work with
teams to right-size their resource requests. We also alert when any namespace cost
exceeds a daily threshold, which catches runaway dev workloads before they become
a large bill.

---

## Phase 9 — Python Automation Scripts

**Duration:** Weekend 14–15
**Goal:** Write three practical Python scripts using AWS and Kubernetes APIs.

### The Right Mindset

You are not trying to become a Python developer. You are demonstrating that you can
write automation using AWS APIs (`boto3`) and Kubernetes APIs (`kubernetes` Python
client) — the two libraries that distinguish DevOps Python from general Python.

---

### Script 1: `k8s_health_check.py`

Connects to your cluster, checks all pods across namespaces, reports pods not in
Running state, and sends a Slack alert if unhealthy pods are found.

**Concepts to learn:**
- The `kubernetes` Python client and how to load kubeconfig with `config.load_kube_config()`
- Listing pods with `CoreV1Api().list_pod_for_all_namespaces()`
- Pod phase and container status conditions
- Structuring a Python script with functions, not just procedural code
- `argparse` for command-line arguments like `--namespace` and `--alert-slack`

**Script structure:**
```
load_kube_config()
get_all_pods(namespace=None)
check_pod_health(pod)
format_report(unhealthy_pods)
send_slack_alert(webhook_url, message)
main()
```

---

### Script 2: `aws_cost_report.py`

Uses `boto3` to pull AWS Cost Explorer data for the last 30 days, breaks it
down by service, and outputs a formatted report. Optionally sends to Slack.

**Concepts to learn:**
- `boto3` client vs resource — the difference and when to use each
- AWS Cost Explorer API — `get_cost_and_usage()`
- Handling AWS credentials safely — environment variables or instance profile, never hardcoded
- JSON response parsing from AWS APIs
- Formatting tabular output with `tabulate` or f-strings

This script is directly relatable to your 30% cost reduction achievement.
In interviews you can say you built tooling to track and report cost — not
just manually checked the console.

---

### Script 3: `log_parser.py`

Reads a log file (simulating application logs), finds ERROR and CRITICAL lines
in the last N minutes, counts them, and sends a Slack alert if count exceeds a threshold.

**Concepts to learn:**
- File I/O and reading large files efficiently
- `datetime` parsing from log timestamps
- `re` module — two patterns: timestamp extraction and log level detection
- Environment variables with `os.environ` for webhook URLs and thresholds
- Writing a `requirements.txt` properly

This script directly supports your "reduced MTTR by 30%" CV bullet — you can
say you automated log analysis instead of manually grepping log files.

---

### Python Learning Path

If you need to build confidence first, do this in order over 3 weeks:

**Week 1 — Basics refresher:**
Variables, functions, loops, conditionals, lists, dictionaries, file reading.
Resource: Python.org official tutorial — chapters 3, 4, 5, 7 only.

**Week 2 — DevOps libraries:**
- `boto3` — write one script that lists your S3 buckets
- `requests` — write one script that calls the GitHub API and prints repo names
- `os` and `subprocess` — run shell commands from Python
- `argparse` — add command-line arguments to an existing script

**Week 3:** Write the three scripts above.

You do not need decorators, classes, async, generators, or advanced Python.
Functions, dictionaries, and libraries are enough.

---

## Phase 10 — README and Documentation

**Duration:** Weekend 16
**Goal:** Write a README that makes the project immediately understandable to
a hiring manager or senior engineer in under 5 minutes.

### Why This Phase Is Not Optional

The README is what an interviewer reads before your interview. A great README
signals engineering maturity more than any individual tool. It shows you think
about communication and collaboration, not just implementation.

### README Structure

```markdown
# Cloud-Native GitOps Platform

One sentence: what this project demonstrates and why.

## Architecture Diagram
Mermaid or ASCII diagram showing:
GitHub → GitHub Actions → ghcr.io
→ ArgoCD → K8s Namespaces (dev, prod)
→ Vault sidecar → Flask App
→ OTel Collector → Tempo → Grafana
→ Prometheus → Grafana (SLO Dashboard)
Kyverno intercepting all admission requests

## Stack
| Tool | Version | Purpose |
|------|---------|---------|
| ArgoCD | 2.x | GitOps controller |
| HashiCorp Vault | 1.x | Secrets management |
| Kyverno | 1.x | Policy enforcement |
| Trivy | 0.x | Security scanning |
| OpenTelemetry | 0.x | Distributed tracing |
| Grafana Tempo | 2.x | Trace backend |
| Prometheus | 2.x | Metrics + SLO recording rules |
| Grafana | 10.x | Dashboards + SLO dashboard |
| Kubecost | 1.x | K8s cost visibility |

## Getting Started
Step-by-step local setup. Every command must actually work. Test it.

## GitOps Workflow
What happens when you push a code change — step by step.

## Observability
Three pillars: metrics (Prometheus), logs (Loki), traces (Tempo).
SLO dashboard and error budget burn rate explained.

## Security
Vault secrets injection, Kyverno policies enforced, Trivy CI scanning,
RBAC model, NetworkPolicy design.

## Cost Visibility
Kubecost setup, efficiency scores, how to read the cost allocation view.

## Python Automation
Description and usage example for each of the three scripts.

## Decisions
Link to docs/decisions.md
```

### The `decisions.md` File — Architecture Decision Records

Write one ADR for each major tool choice. Example:

```markdown
## ADR-002: OpenTelemetry over Direct Jaeger SDK

**Decision:** Use OpenTelemetry SDK for instrumentation

**Context:** Needed distributed tracing. Options were direct Jaeger client,
direct Zipkin client, or the vendor-neutral OpenTelemetry SDK.

**Reasons:**
- OTel is CNCF standard — vendor lock-in is eliminated
- Switching backends (Tempo → Honeycomb → Datadog) requires zero code changes
- Auto-instrumentation for Flask means minimal application code change
- Active community, adopted by all major observability vendors

**Trade-offs:**
- OTel Collector adds an extra infrastructure component to manage
- Slightly more initial setup compared to direct SDK integration
```

Write ADRs for: ArgoCD vs Flux, Kyverno vs OPA, Vault vs AWS Secrets Manager,
Tempo vs Jaeger, Kubecost vs manual dashboards. Five ADRs minimum.

---

## Complete Week-by-Week Schedule

| Weekend | Phase | Deliverable |
|---------|-------|-------------|
| 1 | Phase 1 — Part A | Kind cluster running, Flask app built and containerised |
| 2 | Phase 1 — Part B | Helm chart deployed, probes and limits working |
| 3 | Phase 2 — Part A | ArgoCD installed, first app syncing from Git |
| 4 | Phase 2 — Part B | App of Apps, dev/prod environments, selfHeal tested |
| 5 | Phase 3 — Part A | Vault installed, auth method configured, policy written |
| 6 | Phase 3 — Part B | Vault Agent injecting secrets, app reading from file |
| 7 | Phase 4 — Part A | Five Kyverno policies in enforce mode |
| 8 | Phase 4 — Part B | RBAC manifests done, NetworkPolicy with Calico working |
| 9 | Phase 5 | Full GitHub Actions CI pipeline, Trivy scan, GitOps trigger |
| 10 | Phase 6 — Part A | OTel SDK in Flask app, Collector deployed, Tempo installed |
| 11 | Phase 6 — Part B | Traces dashboard in Grafana, traceToLogs configured |
| 12 | Phase 7 | Recording rules, SLO dashboard, error budget burn rate alerts |
| 13 | Phase 8 | Kubecost installed, cost allocation screenshot in README |
| 14 | Phase 9 — Part A | k8s_health_check.py and log_parser.py done |
| 15 | Phase 9 — Part B | aws_cost_report.py done, all scripts tested and documented |
| 16 | Phase 10 | README complete, architecture diagram, 5 ADRs, final push |

---

## Resources for Each Phase

### Phase 1 — Kind and Helm
- [Kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)

### Phase 2 — ArgoCD
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ArgoCD Sync Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)

### Phase 3 — Vault
- [Vault on Kubernetes Tutorial](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes)

### Phase 4 — Kyverno, RBAC, NetworkPolicy
- [Kyverno Getting Started](https://kyverno.io/docs/introduction/)
- [Kyverno Sample Policies](https://kyverno.io/policies/)
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kind with Calico CNI](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind)
- [NetworkPolicy Editor (visual tool)](https://editor.networkpolicy.io/)

### Phase 5 — Trivy
- [Trivy GitHub Action](https://github.com/aquasecurity/trivy-action)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [GitHub SARIF Upload](https://docs.github.com/en/code-security/code-scanning)

### Phase 6 — OpenTelemetry and Tempo
- [OpenTelemetry Python Getting Started](https://opentelemetry.io/docs/languages/python/getting-started/)
- [Flask Auto-Instrumentation](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/flask/flask.html)
- [OTel Collector Configuration](https://opentelemetry.io/docs/collector/configuration/)
- [Grafana Tempo Getting Started](https://grafana.com/docs/tempo/latest/getting-started/)
- [Grafana TraceToLogs](https://grafana.com/docs/grafana/latest/datasources/tempo/configure-tempo-data-source/#trace-to-logs)

### Phase 7 — SRE and SLOs
- [Google SRE Book — SLO Chapter (free)](https://sre.google/sre-book/service-level-objectives/)
- [Prometheus Recording Rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Sloth — SLO generator for Prometheus](https://sloth.dev/)
- [Error Budget Burn Rate Alerting](https://sre.google/workbook/alerting-on-slos/)

### Phase 8 — Kubecost
- [Kubecost Installation](https://www.kubecost.com/install)
- [Kubecost Cost Allocation](https://docs.kubecost.com/using-kubecost/navigating-the-kubecost-ui/cost-allocation)

### Phase 9 — Python
- [boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
- [Kubernetes Python Client](https://github.com/kubernetes-client/python)
- [Real Python Boto3 Guide](https://realpython.com/python-boto3-aws-s3/)

---

## How to Talk About This Project in Interviews

*"Tell me about a personal project you have worked on."*

> "I built a cloud-native GitOps platform to systematically close gaps I identified
> in my current work. It deploys a Python Flask API through a full GitOps pipeline —
> GitHub Actions handles CI including Trivy image scanning, and ArgoCD handles delivery
> by watching Git for changes. Secrets are injected at runtime using HashiCorp Vault's
> agent injector. Kyverno enforces cluster policies — resource limits, no privileged
> containers, no latest tags — as code through the same PR process as everything else.
> RBAC is explicitly defined per workload with least-privilege ServiceAccounts, and
> NetworkPolicy with Calico enforces default-deny between namespaces.
>
> On the observability side, I implemented all three pillars — Prometheus for metrics
> with formal SLO recording rules and an error budget burn rate dashboard, Grafana Loki
> for logs, and OpenTelemetry with Grafana Tempo for distributed traces — all correlated
> in a single Grafana instance. I also added Kubecost for namespace-level cost visibility
> and efficiency scoring. The entire setup runs locally on Kind so anyone can reproduce
> it, and every architectural decision is documented as an ADR."

That answer covers every gap. It shows systems thinking, security depth, observability
maturity, and cost awareness. It is a complete senior-level answer.

---

## Final Checklist Before Applying

- [ ] Repo is public on GitHub with a pinned profile entry
- [ ] README has an architecture diagram (Mermaid is fine)
- [ ] Every command in the README actually works end to end
- [ ] GitHub Actions pipeline shows a green checkmark
- [ ] Trivy scan results visible in GitHub Security tab
- [ ] Kyverno policies in enforce mode with violation example documented
- [ ] RBAC manifests present with `kubectl auth can-i` test results documented
- [ ] NetworkPolicy working with Calico — test results documented
- [ ] Tempo traces visible in Grafana with traceToLogs working
- [ ] SLO dashboard screenshot in README showing error budget panel
- [ ] Kubecost cost allocation screenshot in README
- [ ] Python scripts have `requirements.txt` and usage examples
- [ ] `decisions.md` has at least 5 ADRs
- [ ] `.gitignore` present — no secrets or kubeconfigs committed
- [ ] At least one PR in the repo history showing your development workflow

---

*Start with Phase 1, Weekend 1. Build first, understand as you go.
The concepts become clear once you have something running and can break it.*
