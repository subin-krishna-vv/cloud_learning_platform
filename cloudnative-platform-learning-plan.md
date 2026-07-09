# Cloud-Native GitOps Platform — Learning & Build Plan

> A comprehensive learning project to master cloud-native technologies and DevOps practices.
>
> **Estimated timeline:** 16 weekends (roughly 4 months)
> **Outcome:** One well-documented GitHub repo covering GitOps, observability, SRE, security, secrets, policy, and automation.

---

## How to Use This Plan

This is a **self-directed learning workbook**, not a step-by-step tutorial.

- Each phase introduces a **practical scenario** on the shared platform project below.
- Tasks are **problems** covering beginner → intermediate → advanced features of each tool.
- **Hints** point you to concepts, documentation, and common failure modes — not complete answers.
- **Expected outcomes** tell you how to verify a task is done (cluster state, UI, command output).
- Research, design configs, and validate yourself. Break things intentionally — that is how you learn.
- Complete tasks in order within each phase. Check off the **Phase Completion Checklist** before moving on.

**Task table format:**

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| Phase.Level# | What you must figure out and build | Where to look, what to watch for | Observable proof it works |

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
is entirely in the platform around it — which is exactly how modern cloud infrastructure works.

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

### Practical Scenario

The platform does not exist yet. You need a reproducible local Kubernetes environment and a containerised Flask API deployed via Helm before any GitOps, security, or observability layers can be added.

### Core Concepts (condensed)

**Kind**
- Runs a real Kubernetes control plane inside Docker containers on your laptop
- Kind config file defines control plane and worker node topology
- `kubectl` connects via kubeconfig context pointing at the Kind cluster

**Docker**
- Multi-stage builds reduce image size and attack surface
- Non-root users limit container breakout impact
- Pin base image versions — never use floating tags in production charts

**Helm**
- Charts package Kubernetes manifests with templating and value overrides
- `values.yaml` hierarchy: base → environment file → `--set` flags
- `helm template` renders locally; `helm upgrade --install` applies atomically
- Release history stored as Secrets; rollback reverts to prior revision
- Templates use Go `text/template` — not YAML with variables; whitespace control (`{{-`, `-}}`) matters
- Built-in objects: `.Values`, `.Release`, `.Chart`, `.Capabilities`
- Key functions: `default`, `quote`, `toYaml`, `nindent`, `include`, `required`
- Flow control: `if/else`, `range`, `with` — scope changes inside `with` blocks
- `_helpers.tpl` defines named templates (`fullname`, `labels`, `selectorLabels`)
- `include` preferred over `template` for nested YAML indentation
- `values.schema.json` validates values before render
- `helm lint`, `helm template`, `helm test` for validation

### Tasks

#### Beginner — Kind and kubectl

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 1.B1 | Stand up a local Kubernetes cluster you can reach with kubectl | Kind quick start docs; define cluster topology in a config file under `kind/` | `kubectl get nodes` shows expected nodes Ready |
| 1.B2 | Deploy a minimal workload and confirm the cluster is functional | Use any simple image first if needed before your app chart | Pod reaches Running; you can reach it via port-forward or service |

#### Beginner — Docker and Flask app

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 1.B3 | Build a Flask API with `GET /health` and `GET /items` endpoints | Keep the app simple — platform complexity comes later | `pytest` passes; endpoints return expected JSON locally |
| 1.B4 | Containerise the app with production-minded Dockerfile choices | Non-root user, pinned base image version, multi-stage build | Image builds; container runs and serves `/health` |

#### Intermediate — Helm deployment

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 1.I1 | Create a Helm chart under `helm/flask-app/` that deploys the Flask app | Deployment, Service, probes, resource requests/limits, labels on every resource | `helm install` succeeds; `/health` returns 200 from inside cluster |
| 1.I2 | Support environment-specific configuration via separate values files | `values-dev.yaml` and `values-prod.yaml` with different replica counts and resource limits | Same chart renders different configs per environment file |

#### Advanced — Helm chart authoring

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 1.A1 | Write `templates/_helpers.tpl` with `fullname`, `labels`, and `selectorLabels` named templates | 63-char name truncation; selector labels must be immutable subset; use `include` with `nindent` | All templates use helpers consistently; rendered YAML has no indentation errors |
| 1.A2 | Make Ingress optional via values; loop env vars from a list in values | `if .Values.ingress.enabled`; `range` over `.Values.env` | `helm template` with dev values includes Ingress; prod values omit it; env vars differ per environment |
| 1.A3 | Add `values.schema.json` and validate the chart before deploy | Required fields for image; minimum replica count; run `helm lint` and `helm template` | Schema error when required values missing; lint passes; dry-run apply validates rendered manifests |

### Why This Matters

Non-root containers and resource limits are things Kyverno will enforce later.
Understanding why they matter helps you grasp the security posture of your cluster.

### Phase Completion Checklist

- [ ] Kind cluster running with expected node count → **Expected:** all nodes Ready
- [ ] Flask app containerised and tested → **Expected:** image runs non-root; tests pass
- [ ] Helm chart deploys app end-to-end → **Expected:** `/health` and `/items` reachable in cluster
- [ ] Environment values produce different rendered output → **Expected:** dev vs prod `helm template` diff is meaningful
- [ ] Chart passes lint and schema validation → **Expected:** `helm lint` clean; missing required values fail fast

---

## Phase 2 — GitOps with ArgoCD

**Duration:** Weekend 3–4
**Goal:** Replace manual `helm install` with fully automated GitOps delivery via ArgoCD.

### Practical Scenario

The Flask app deploys only when you run Helm manually. Changes are not auditable, drift goes undetected, and there is no single source of truth. Git must become the desired state for the cluster.

### Core Concepts (condensed)

- **GitOps:** Git is the source of truth; desired state is declared; agents reconcile continuously
- **ArgoCD components:** API server (UI/API), repository server (renders charts), application controller (reconciliation loop)
- **Application CRD:** defines source repo/path/chart, destination cluster/namespace, sync policy
- **App of Apps:** one root Application deploys a folder of child Application manifests
- **Sync policies:** `automated`, `selfHeal` (revert manual drift), `prune` (delete removed resources)
- **Sync waves:** annotation `argocd.argoproj.io/sync-wave` controls deployment order
- **Rollback:** Git revert restores prior desired state — no imperative kubectl in production

### GitOps Code Change Flow

Developer merges PR → GitHub Actions CI runs (build, test, scan) → on success,
the pipeline updates the image tag in the Helm values file in Git → ArgoCD detects
the diff within 3 minutes → ArgoCD syncs the new Helm release to the cluster →
sync history and diff are visible in the ArgoCD UI. Rollback is a Git revert —
no kubectl commands, full audit trail.

### Tasks

#### Beginner — ArgoCD basics

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 2.B1 | Install ArgoCD and deploy the Flask Helm chart via a single Application | Official install manifest; Application spec fields; `argocd` namespace | `argocd app get` shows Synced/Healthy; app reachable in cluster |
| 2.B2 | Access the ArgoCD UI and inspect sync status | Port-forward or ingress; initial admin credentials | UI loads; application health and sync state visible |

#### Intermediate — Multi-environment GitOps

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 2.I1 | Structure `gitops/` with bootstrap and app manifests | Deliverables go in `gitops/bootstrap/` and `gitops/apps/` | ArgoCD manages Flask app from Git without manual `helm install` |
| 2.I2 | Run separate dev and prod environments with different Helm values | Separate namespaces; different value files in `gitops/environments/` | Dev and prod deployments differ; both sync from Git |

#### Advanced — Drift, rollback, and App of Apps

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 2.A1 | Implement App of Apps so child applications deploy automatically | Root Application points at `gitops/apps/` folder | Child apps appear without manual per-app setup |
| 2.A2 | Enable selfHeal and prove drift is corrected | Manually scale deployment via kubectl; watch reconciliation | Replica count reverts to Git-defined value within a sync cycle |
| 2.A3 | Roll back a bad change using Git only | ArgoCD sync history; git revert workflow | Previous revision restored; sync history shows rollback event |

### Phase Completion Checklist

- [ ] ArgoCD UI accessible → **Expected:** login works via port-forward or ingress
- [ ] Flask app syncs from Git → **Expected:** no manual `helm install` needed for routine deploys
- [ ] Dev and prod environments isolated → **Expected:** different namespaces, different Helm values
- [ ] Drift self-healed → **Expected:** manual replica scale reverted within one sync cycle
- [ ] Rollback demonstrated via Git revert → **Expected:** sync history shows restored revision

---

## Phase 3 — Secrets Management with HashiCorp Vault

**Duration:** Weekend 5–6
**Goal:** Remove all hardcoded secrets. Pull secrets dynamically from Vault at pod startup.

### Practical Scenario

Database credentials or API keys are hardcoded in manifests or Kubernetes Secrets. There is no encryption at rest, no audit trail of who read what, and no path to rotation. Vault must inject secrets at runtime.

### Core Concepts (condensed)

- **K8s Secrets limitation:** base64 encoded, not encrypted; weak audit story
- **Vault components:** storage backend, auth methods, secret engines (KV), policies (HCL), leases/TTLs
- **Kubernetes auth flow:** pod ServiceAccount JWT → Vault validates against K8s API → Vault token → secrets fetched
- **Vault Agent Injector:** mutating webhook injects init container and sidecar via pod annotations
- **Production pattern:** secrets as files with restricted permissions, not environment variables
- **Dynamic secrets:** advanced use case — credentials generated on demand with TTL

### Tasks

#### Beginner — Vault fundamentals

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 3.B1 | Run Vault locally on the cluster and store a KV secret | Official Vault Helm chart; dev mode for learning only | Secret written and read back via Vault CLI |
| 3.B2 | Understand the difference between K8s Secrets and Vault for this platform | Compare audit, encryption, and access control models | Short note in `vault/README.md` explaining your choice |

#### Intermediate — Kubernetes auth and injection

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 3.I1 | Enable Kubernetes auth and write a least-privilege policy for the Flask app | Policy in `vault/policies/`; bind to ServiceAccount via role | Policy allows read only on intended secret paths |
| 3.I2 | Configure Vault Agent Injector so secrets appear as files in the running pod | Deployment annotations; shared volume path | Secret file visible inside pod at expected mount path |
| 3.I3 | Update Flask app to read secret from file instead of environment variable | File read at startup; handle missing secret gracefully | App starts with Vault-injected credential; no secret in manifest or env |

#### Advanced — Automation and hardening

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 3.A1 | Write `vault/setup.sh` to automate Vault bootstrap steps | Script covers auth method, policy, role creation | Fresh cluster bootstrap repeatable from script |
| 3.A2 | Document policy boundaries and what the Flask app cannot access | Least privilege — app should not read unrelated paths | Attempt to read forbidden path fails; documented in README or ADR |

### Phase Completion Checklist

- [ ] Vault running on cluster → **Expected:** `vault status` succeeds
- [ ] Kubernetes auth configured → **Expected:** pod authenticates via ServiceAccount
- [ ] Secret injected as file → **Expected:** no plaintext secret in Git or K8s Secret manifest
- [ ] Flask app reads injected secret → **Expected:** app functions with Vault-sourced credential
- [ ] Bootstrap script works → **Expected:** `vault/setup.sh` reproduces auth setup

---

## Phase 4 — Security: Kyverno, RBAC, and NetworkPolicy

**Duration:** Weekend 7–8
**Goal:** Enforce security standards at three layers — policy admission (Kyverno), identity and access (RBAC), and network (NetworkPolicy).

### Practical Scenario

The cluster accepts any workload configuration and any pod can talk to any other pod. Insecure images, missing limits, excessive permissions, and flat network trust are all allowed. You need defence in depth at admission, identity, and network layers.

### Core Concepts (condensed)

**Kyverno**
- Kubernetes-native policy engine at the admission webhook
- Policy types: Validation (block), Mutation (modify), Generation (create resources on trigger)
- Modes: audit (log violations) vs enforce (block violations)
- PolicyReport shows cluster-wide compliance state

**RBAC**
- `Role` / `ClusterRole` — permissions; `RoleBinding` / `ClusterRoleBinding` — who gets them
- Subjects: User, Group, ServiceAccount
- Least privilege: workloads get only permissions they need

**NetworkPolicy**
- Restricts pod traffic by label and namespace selectors
- Default-deny pattern: deny all, then add explicit allows
- **CNI dependency:** Kindnet does not enforce policies — Calico or Cilium required

### Tasks

#### Beginner — Kyverno and RBAC foundations

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 4.B1 | Install Kyverno and write one validation policy in audit mode | Kyverno Helm chart; start non-blocking | PolicyReport shows violations without blocking deploys |
| 4.B2 | Create a dedicated ServiceAccount for the Flask app | Not the `default` SA; reference in Helm chart | Deployment runs under named ServiceAccount |

#### Intermediate — Policy enforcement and RBAC

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 4.I1 | Write five Kyverno policies in `security/kyverno/policies/` | Disallow `latest` tag; require limits; disallow privileged; require labels; require NetworkPolicy | All five policies exist; chart updated to comply |
| 4.I2 | Fix Flask Helm chart to pass all policies; switch to enforce mode | Run `kubectl get policyreport -A` in audit first | Non-compliant deploy blocked with clear error message |
| 4.I3 | Define Role and RoleBinding with least privilege for the Flask app | `security/rbac/` manifests; ConfigMap read only if needed | `kubectl auth can-i` shows allowed and denied actions match intent |

#### Advanced — Network isolation and generation policies

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 4.A1 | Recreate Kind cluster with Calico; implement default-deny NetworkPolicy | Kind + Calico docs; DNS egress to kube-system on UDP 53 | Policy objects applied; CNI actually enforces rules |
| 4.A2 | Allow ingress only from ingress-controller; block cross-namespace access | Label selectors; test from `default` namespace | Ingress traffic works; unauthorized pod cannot reach Flask app |
| 4.A3 | Write Kyverno Generate policy to auto-create default-deny NetworkPolicy on new namespaces | Generation policy type; namespace trigger | New namespace gets default-deny without manual step |
| 4.A4 | Document RBAC model in `docs/decisions.md` | ADR format: context, decision, trade-offs | ADR explains why permissions were granted or withheld |

### Phase Completion Checklist

- [ ] Five Kyverno policies in enforce mode → **Expected:** bad pod with `latest` tag rejected
- [ ] PolicyReport clean for platform workloads → **Expected:** Flask chart passes all policies
- [ ] RBAC least privilege verified → **Expected:** `kubectl auth can-i` results documented
- [ ] NetworkPolicy enforced with Calico → **Expected:** default-deny blocks; ingress allow works
- [ ] Kyverno generates NetworkPolicy on new namespace → **Expected:** new namespace auto-protected

---

## Phase 5 — Security Scanning with Trivy in CI/CD

**Duration:** Weekend 9
**Goal:** Scan your Docker image for vulnerabilities in GitHub Actions and fail the build on critical issues.

### Practical Scenario

Vulnerable container images can be built and deployed without anyone noticing until runtime. Security checks must run before images reach the registry, with a clear policy on what blocks a merge.

### Core Concepts (condensed)

- **Trivy scans:** OS packages, language deps, K8s manifests, IaC, secrets in files/git
- **Severity:** CRITICAL → HIGH → MEDIUM → LOW → UNKNOWN
- **CI gate:** fail on CRITICAL/HIGH with `--exit-code 1`
- **SARIF:** upload results to GitHub Security tab for inline visibility
- **`.trivyignore`:** documented exceptions with CVE ID, reason, review date
- **Shift left:** scan on every PR, not after deployment
- **GitOps CI/CD split:** CI updates image tag in Git; ArgoCD deploys — CI never runs `kubectl apply`

### Tasks

#### Beginner — Local scanning

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 5.B1 | Scan your Flask Docker image locally with Trivy | Trivy CLI docs; severity flags | Report lists vulnerabilities by severity |
| 5.B2 | Compare scan results between an old and a hardened base image | Try an older Python base vs pinned minimal image | Documented before/after vulnerability count difference |

#### Intermediate — CI pipeline

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 5.I1 | Build `.github/workflows/ci.yaml` that tests, builds, scans, and gates on severity | Job dependencies; pytest first; Trivy before push | PR with vulnerable image fails CI; clean image passes |
| 5.I2 | Push passing images to ghcr.io tagged with git SHA | Never tag `latest`; use GitHub Container Registry | Image in registry with immutable SHA tag |
| 5.I3 | Upload Trivy SARIF to GitHub Security tab | SARIF upload action docs | Findings visible in repo Security tab |

#### Advanced — Exceptions and GitOps trigger

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 5.A1 | Create `.trivyignore` with one documented exception | CVE ID, business reason, review date in comment | Suppressed CVE no longer fails build; justification recorded |
| 5.A2 | Add GitOps trigger job that updates image tag in Helm values on success | Separate workflow or final CI job; commit back to Git | Image tag change in Git triggers ArgoCD sync |

### Phase Completion Checklist

- [ ] CI runs on push and PR → **Expected:** green pipeline for clean build
- [ ] CRITICAL/HIGH vulnerabilities block merge → **Expected:** deliberate bad image fails CI
- [ ] SARIF visible in Security tab → **Expected:** scan results browsable in GitHub UI
- [ ] Image tagged with git SHA in ghcr.io → **Expected:** no `latest` tag in registry
- [ ] GitOps image update triggers deploy → **Expected:** ArgoCD syncs new tag from Git change

---

## Phase 6 — Distributed Tracing with OpenTelemetry and Grafana Tempo

**Duration:** Weekend 10–11
**Goal:** Add the third pillar of observability — tracing. Follow a single request through the Flask app and see exactly where time is spent.

### Practical Scenario

Prometheus shows a latency spike but cannot explain which part of a specific request was slow. You need distributed traces correlated with your existing metrics and logs.

### Core Concepts (condensed)

- **Three pillars:** metrics (aggregated), logs (discrete events), traces (single request journey)
- **OpenTelemetry:** vendor-neutral instrumentation standard (SDK, Collector, OTLP protocol)
- **Collector pattern:** app → Collector → backend; decouples app from observability vendor
- **Grafana Tempo:** trace backend; integrates with Grafana for correlated observability
- **Trace anatomy:** trace (full journey), span (unit of work), context propagation (`traceparent` header)
- **Sampling:** head-based vs tail-based — you do not trace 100% of requests in production
- **traceToLogs:** jump from span to related Loki log lines in Grafana

### Tasks

#### Beginner — Application instrumentation

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 6.B1 | Instrument Flask app with OpenTelemetry SDK | Python OTel getting started; Flask auto-instrumentation package; OTLP exporter | Spans generated for HTTP requests |
| 6.B2 | Confirm traces reach an OpenTelemetry Collector endpoint | Collector receiver on OTLP gRPC port; check collector logs | Collector receives spans from the app |

#### Intermediate — Collector and Tempo

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 6.I1 | Deploy OTel Collector with receiver, batch processor, and Tempo exporter | Config in `observability/otel/`; Deployment and Service manifests | Collector forwards spans to Tempo |
| 6.I2 | Install Grafana Tempo and connect as Grafana datasource | Helm values in `observability/tempo/` | Traces searchable in Grafana Explore |

#### Advanced — Correlated observability

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 6.A1 | Configure traceToLogs on Tempo datasource | Grafana datasource config in `observability/grafana/datasources/` | Clicking span jumps to related log lines |
| 6.A2 | Build traces dashboard linking metrics panels to Tempo search | Dashboard in `observability/grafana/dashboards/` | Dashboard shows rate, latency percentiles, trace drill-down |
| 6.A3 | Generate traffic and observe span breakdown for slow requests | Traffic script in `automation/`; search traces in Explore | Slow trace shows identifiable span causing delay |

### Phase Completion Checklist

- [ ] Flask app emits OTLP traces → **Expected:** Collector logs show incoming spans
- [ ] Tempo stores and serves traces → **Expected:** traces visible in Grafana Explore
- [ ] traceToLogs configured → **Expected:** span-to-log navigation works
- [ ] Traces dashboard built → **Expected:** metrics and traces linked in one view
- [ ] Traffic generation produces observable traces → **Expected:** 100+ requests yield searchable trace data

---

## Phase 7 — SRE Concepts: SLI, SLO, and Error Budget Dashboard

**Duration:** Weekend 12
**Goal:** Define formal SLOs for your Flask app, implement them as Prometheus recording rules, and build a Grafana SLO dashboard that shows error budget burn rate.

### Practical Scenario

Availability and latency are discussed informally but not measured. Without formal SLIs, SLOs, and error budgets you cannot tell when reliability is degrading fast enough to act, or when to pause feature work.

### Core Concepts (condensed)

- **SLI:** observable metric measuring user-facing behaviour (ratio-based is best)
- **SLO:** target for an SLI over a rolling window (e.g. 99.9% availability over 30 days)
- **Error budget:** allowed unreliability = 1 − SLO; when exhausted, prioritise reliability over features
- **Burn rate:** speed of budget consumption; multi-window alerts catch fast and slow burns
- **Recording rules:** pre-compute expensive PromQL; naming conventions from OpenSLO/Sloth
- **Example SLIs for Flask:** 2xx ratio (availability), sub-300ms ratio (latency), non-5xx ratio (errors)
- **Alert tiers:** critical burn (e.g. >14 over 1h), warning burn (e.g. >6 over 6h)

### Tasks

#### Beginner — Metrics and SLIs

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 7.B1 | Expose Prometheus metrics from Flask app | `prometheus-flask-exporter` or equivalent; `/metrics` endpoint | Prometheus scrapes request counters and latency histograms |
| 7.B2 | Define and query SLIs in PromQL for availability and latency | Ratio of good events to total events | PromQL queries return sensible values under load |

#### Intermediate — SLO implementation

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 7.I1 | Write recording rules for availability and error budget remaining | Rules in `observability/prometheus/recording-rules.yaml` | New metrics appear in Prometheus for SLO calculations |
| 7.I2 | Build Grafana SLO dashboard with compliance, budget, and burn rate panels | Dashboard in `observability/grafana/dashboards/slo-dashboard.json` | Dashboard shows SLO status, budget remaining, burn rate over time |

#### Advanced — Alerting and breach simulation

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 7.A1 | Write multi-window burn rate alert rules | Google SRE workbook alerting guidance | Alerts fire at configured burn thresholds |
| 7.A2 | Simulate high error rate and observe budget consumption in real time | Reuse traffic generation; inject errors | Burn rate spikes on dashboard; alerts trigger or enter pending |

### Phase Completion Checklist

- [ ] `/metrics` scraped by Prometheus → **Expected:** `flask_http_requests_total` visible
- [ ] Recording rules compute SLO metrics → **Expected:** availability and budget metrics queryable
- [ ] SLO dashboard complete → **Expected:** six panels covering compliance, budget, burn rate, rate, errors, latency
- [ ] Burn rate alerts configured → **Expected:** critical and warning thresholds defined
- [ ] Simulated breach observable → **Expected:** dashboard shows budget consumption under load

---

## Phase 8 — Kubernetes Cost Visibility with Kubecost

**Duration:** Weekend 13
**Goal:** Add namespace-level and workload-level cost visibility to your cluster.

### Practical Scenario

Cluster cost is a black box. You cannot see which namespace or deployment is over-provisioned, how much the monitoring stack costs versus the app, or whether dev environments are wasteful.

### Core Concepts (condensed)

- **Kubecost:** combines K8s resource requests/usage with pricing data for cost estimates
- **Cost allocation:** distribute cost by namespace, label, deployment, team
- **Efficiency score:** actual usage ÷ requested resources — low score means over-provisioning
- **Shared cost:** allocate monitoring, ingress, and platform overhead across consumers
- **Idle cost:** resources provisioned but unused

### Tasks

#### Beginner — Kubecost setup

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 8.B1 | Install Kubecost via Helm with values in `kubecost/` | Kubecost install docs; port-forward to UI | Kubecost UI loads and shows cluster cost data |
| 8.B2 | Navigate cost allocation by namespace | Cost allocation view in UI | Per-namespace cost breakdown visible |

#### Intermediate — Analysis and documentation

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 8.I1 | Document cost split across platform namespaces | Compare `flask-app`, `monitoring`, `argocd`, `vault` | Screenshot and written summary in README or `kubecost/README.md` |
| 8.I2 | Record efficiency scores and identify over-provisioned workloads | Efficiency panel; compare requests vs actual usage | At least one namespace flagged as over-provisioned with explanation |

#### Advanced — Actionable cost controls

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 8.A1 | Write `kubecost/README.md` with allocation model, findings, and right-sizing recommendations | What you would change and why | Document ties data to concrete resource request changes |
| 8.A2 | Create Prometheus alert for namespace daily cost threshold breach | `NamespaceCostThresholdBreached` or equivalent | Alert fires when configured namespace exceeds daily cost limit |

### Phase Completion Checklist

- [ ] Kubecost installed and accessible → **Expected:** UI shows live cost data
- [ ] Namespace cost breakdown documented → **Expected:** screenshot in README or kubecost README
- [ ] Efficiency analysis complete → **Expected:** over-provisioned workload identified with score
- [ ] Right-sizing recommendations written → **Expected:** concrete request/limit changes proposed
- [ ] Cost threshold alert configured → **Expected:** alert rule exists and is testable

---

## Phase 9 — Python Automation Scripts

**Duration:** Weekend 14–15
**Goal:** Write three practical Python scripts using AWS and Kubernetes APIs.

### Practical Scenario

Health checks, cost reports, and log analysis are done manually. Operational tasks should be automatable scripts you can run on demand or schedule.

### Core Concepts (condensed)

- **kubernetes Python client:** load kubeconfig; `CoreV1Api` for pod listing; check phase and conditions
- **boto3:** AWS SDK; client vs resource; Cost Explorer `get_cost_and_usage()`
- **Script structure:** functions over procedural code; `argparse` for CLI flags
- **Credentials:** environment variables or instance profile — never hardcode
- **Libraries enough for DevOps automation:** functions, dicts, `os`, `re`, `datetime` — no need for advanced Python patterns

### Tasks

#### Beginner — Cluster health

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 9.B1 | Write `automation/k8s_health_check.py` that reports unhealthy pods | `kubernetes` client; `list_pod_for_all_namespaces`; pod phase checks | Script prints pods not in Running state; `--namespace` filter works |

#### Intermediate — Cost reporting

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 9.I1 | Write `automation/aws_cost_report.py` for last 30 days by service | `boto3` Cost Explorer API; tabulate or formatted output | Report shows per-service cost breakdown |
| 9.I2 | Add optional Slack notification to health check script | `requests` or webhook; `--alert-slack` flag | Unhealthy pods trigger webhook message when configured |

#### Advanced — Log analysis and packaging

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 9.A1 | Write `automation/log_parser.py` that alerts on ERROR/CRITICAL threshold in last N minutes | `re` for timestamps and log levels; `os.environ` for config | Alert fires when error count exceeds threshold |
| 9.A2 | Package all scripts with `requirements.txt` and usage examples | One requirements file covering all scripts; document in README | Scripts run in clean venv with documented CLI examples |

### Phase Completion Checklist

- [ ] `k8s_health_check.py` works against Kind cluster → **Expected:** correct report of pod health
- [ ] `aws_cost_report.py` returns cost data → **Expected:** 30-day breakdown by service
- [ ] `log_parser.py` detects threshold breach → **Expected:** alert on synthetic error log file
- [ ] All scripts have CLI arguments → **Expected:** `argparse` help text documents flags
- [ ] `requirements.txt` and usage docs complete → **Expected:** scripts run from clean environment

---

## Phase 10 — README and Documentation

**Duration:** Weekend 16
**Goal:** Document the platform so future-you (or anyone reproducing your setup) can understand and run it without guessing.

### Practical Scenario

You have built ten layers of infrastructure but the knowledge lives only in your head. Without clear documentation the platform cannot be reproduced, extended, or explained to others.

### Core Concepts (condensed)

- **README:** architecture diagram, stack table, getting started, per-area explanations
- **ADRs (`docs/decisions.md`):** context, decision, reasons, trade-offs for major tool choices
- **Reproducibility:** every command in getting started must actually work on a fresh Kind cluster
- **Evidence:** screenshots and test output for security, observability, and cost features

### Tasks

| ID | Problem | Hints | Expected Outcome |
|----|---------|-------|------------------|
| 10.1 | Write README with architecture diagram and stack table | Mermaid or ASCII; link to each platform area | Reader understands full system in under 5 minutes |
| 10.2 | Document getting started with working commands | Test every command on fresh setup | New clone can reach running app following README alone |
| 10.3 | Write minimum five ADRs for major tool choices | ArgoCD vs Flux, Kyverno vs OPA, Vault vs alternatives, Tempo vs Jaeger, Kubecost approach | `docs/decisions.md` has 5+ ADRs with trade-offs |
| 10.4 | Add evidence from each phase to README | Screenshots: Trivy, Kyverno violation, traces, SLO dashboard, Kubecost | README proves each layer works, not just exists |

### Phase Completion Checklist

- [ ] Architecture diagram in README → **Expected:** full data flow from Git to cluster to observability
- [ ] Getting started reproducible → **Expected:** tested end-to-end on clean environment
- [ ] Five ADRs written → **Expected:** each covers context, decision, and trade-offs
- [ ] Phase evidence documented → **Expected:** screenshots or test output for security, observability, cost
- [ ] All prior phase checklists complete → **Expected:** every phase checklist ticked before calling project done

---

## Complete Week-by-Week Schedule

| Weekend | Phase | Deliverable (checklist milestone) |
|---------|-------|-----------------------------------|
| 1 | Phase 1 — Part A | Phase 1: Kind cluster + Flask app containerised |
| 2 | Phase 1 — Part B | Phase 1 checklist complete: Helm chart deployed end-to-end |
| 3 | Phase 2 — Part A | Phase 2: ArgoCD installed, app syncing from Git |
| 4 | Phase 2 — Part B | Phase 2 checklist complete: App of Apps, drift correction, rollback |
| 5 | Phase 3 — Part A | Phase 3: Vault installed, auth and policy configured |
| 6 | Phase 3 — Part B | Phase 3 checklist complete: secrets injected, app reads from file |
| 7 | Phase 4 — Part A | Phase 4: Kyverno policies in enforce mode |
| 8 | Phase 4 — Part B | Phase 4 checklist complete: RBAC + NetworkPolicy with Calico |
| 9 | Phase 5 | Phase 5 checklist complete: CI pipeline, Trivy gate, GitOps trigger |
| 10 | Phase 6 — Part A | Phase 6: OTel instrumentation, Collector, Tempo installed |
| 11 | Phase 6 — Part B | Phase 6 checklist complete: traceToLogs, traces dashboard |
| 12 | Phase 7 | Phase 7 checklist complete: SLO dashboard, burn rate alerts |
| 13 | Phase 8 | Phase 8 checklist complete: Kubecost analysis and cost alert |
| 14 | Phase 9 — Part A | Phase 9: `k8s_health_check.py` and `log_parser.py` done |
| 15 | Phase 9 — Part B | Phase 9 checklist complete: `aws_cost_report.py`, all scripts documented |
| 16 | Phase 10 | Phase 10 checklist complete: README, ADRs, all phase evidence |

---

## Resources for Each Phase

### Phase 1 — Kind and Helm
- [Kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Chart Tutorial: A Simple Guide for Beginners - Devopscube](https://devopscube.com/create-helm-chart/)

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

## How to Talk About This Project to Others

Use this when explaining the project to peers, in study groups, on a blog,
or when helping someone else reproduce your setup.

### The One-Minute Overview

This is a cloud-native GitOps learning platform built around a simple Python Flask API.
The app itself is minimal — the learning is in the platform: GitHub Actions builds and
scans images, ArgoCD deploys from Git, Vault injects secrets at runtime, Kyverno enforces
cluster policies, RBAC and NetworkPolicy provide identity and network isolation, and
Prometheus, Loki, Tempo, and Grafana give correlated metrics, logs, and traces with
formal SLOs. Kubecost adds namespace-level cost visibility. Python scripts automate
operational checks. Everything runs locally on Kind so it is reproducible, and architectural
decisions are documented as ADRs.

### Architecture Walkthrough (layer by layer)

- **Delivery:** GitHub Actions → ghcr.io → ArgoCD → Helm → Kind (dev/prod namespaces)
- **Secrets:** Vault Kubernetes auth → Agent Injector → secret files in pod
- **Security:** Kyverno admission policies → RBAC least privilege → NetworkPolicy default-deny with Calico
- **Observability:** OTel SDK → Collector → Tempo; Prometheus recording rules → SLO dashboard; traceToLogs correlation
- **Operations:** Kubecost cost allocation; Python scripts for health, cost, and log analysis

### Questions Others Might Ask — and What to Explain

| Question | What to cover |
|----------|---------------|
| Why GitOps instead of `kubectl apply`? | Git as single source of truth, drift detection, audit trail, rollback via revert |
| Why Vault instead of Kubernetes Secrets? | Encryption at rest, audit logs, fine-grained policies, injection without app code changes |
| Why Kyverno at admission time? | Blocks non-compliant resources before they run; policies versioned in Git like everything else |
| Why default-deny NetworkPolicy? | Flat network trust is the K8s default; explicit allows only for required traffic flows |
| Why OpenTelemetry instead of a vendor SDK? | Instrument once, switch backends without code changes; Collector decouples app from backend |
| Why formal SLOs? | Vague "available" claims are not actionable; error budgets align reliability work with feature velocity |
| Why Kubecost on top of cloud billing? | Namespace and workload granularity; efficiency score reveals over-provisioning |

Tie each answer to something you built, tested, and can demonstrate on your Kind cluster.

### Teaching Back What You Learned

Can you explain each phase's **problem**, **solution**, and **trade-off** without reading the README?

- Phase 1: Why non-root containers and resource limits matter before policy enforcement
- Phase 2: What happens when someone manually changes the cluster outside Git
- Phase 3: Why secrets as files beat environment variables for sensitive data
- Phase 4: Three security layers — what each catches that the others miss
- Phase 5: What Trivy blocks in CI and how documented exceptions work
- Phase 6: What traces reveal that metrics alone cannot
- Phase 7: How error budget burn rate drives operational decisions
- Phase 8: What efficiency score tells you about resource requests
- Phase 9: What each automation script replaces that you used to do manually

If you cannot explain a phase, revisit its checklist before moving on.

---

## Final Learning Completion Checklist

- [ ] All ten phase completion checklists ticked with evidence (screenshots, test output, or notes in `docs/`)
- [ ] README has an architecture diagram (Mermaid is fine)
- [ ] Every command in the README getting started section works end to end on a fresh Kind cluster
- [ ] GitHub Actions pipeline runs green
- [ ] Trivy scan results visible in GitHub Security tab
- [ ] Kyverno policies in enforce mode with violation example documented
- [ ] RBAC manifests present with `kubectl auth can-i` test results documented
- [ ] NetworkPolicy working with Calico — test results documented
- [ ] Tempo traces visible in Grafana with traceToLogs working
- [ ] SLO dashboard showing error budget panel
- [ ] Kubecost cost allocation documented with efficiency analysis
- [ ] Python scripts have `requirements.txt` and usage examples
- [ ] `decisions.md` has at least 5 ADRs
- [ ] `.gitignore` present — no secrets or kubeconfigs committed
- [ ] Repo is reproducible and shareable (optional: public on GitHub for peer learning)

---

*Start with Phase 1, Weekend 1. Build first, understand as you go.
The concepts become clear once you have something running and can break it.*
