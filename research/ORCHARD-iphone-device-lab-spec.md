# ORCHARD — Autonomous AI-First iPhone Device Lab

### Product Specification, Technical Guide & Development Roadmap

| Field | Value |
|---|---|
| **Document ID** | ORCHARD-SPEC-001 |
| **Version** | 1.0.0 |
| **Status** | Approved for Phase 0 execution |
| **Date** | 17 September 2026 |
| **Classification** | Internal — On-Premises R&D |
| **Codename** | ORCHARD (control plane `orchardd`, CLI `labctl`) |
| **Supersedes** | `compass_artifact_wf-e3ee5ef2...md` (Doc A), `deep-research-report.md` (Doc B) |
| **Owner** | Platform Engineering — Device Lab |

---

## Contents

| § | Section | For |
|---|---|---|
| [0](#0-document-control) | Document Control — provenance, evidence grading, glossary | Everyone |
| [1](#1-product-definition) | Product Definition — thesis, the Honesty Principle, goals, SLOs | Leadership |
| [2](#2-reconciliation-decision-log) | **Reconciliation Decision Log** — 10 ADRs settling where the research diverged | Architects |
| [3](#3-the-capability-model--normative-core) | **The Capability Model** — device classes, the matrix, the contract, errors | **Normative core** |
| [4](#4-system-architecture) | System Architecture — five planes, context, control flow, tech selection | Architects |
| [5](#5-fleet-composition--physical-infrastructure) | Fleet & Physical Infrastructure — cells, research matrix, BOM, scaling | Lab ops |
| [6](#6-control-plane) | Control Plane — registry, scheduler, fencing, recovery ladder, policy | Implementers |
| [7](#7-the-mac-worker) | The Mac Worker — components, adapters, WDA lifecycle, instrumentation | Implementers |
| [8](#8-api-cli--mcp-surface) | API, CLI & MCP — semantic API, `labctl`, gateway, client configs | Implementers |
| [9](#9-ai-orchestration) | AI Orchestration — modes, agent roles, escalation, injection defence | AI engineers |
| [10](#10-repository-structure--engineering-standards) | Repository Structure & Engineering Standards | Implementers |
| [11](#11-testing-strategy) | Testing Strategy — pyramid, **Phase-0 certification**, chaos | QA + SRE |
| [12](#12-cicd) | CI/CD — three pipelines, signing service, rollback | Platform |
| [13](#13-observability--sre) | Observability & SRE — traces, evidence bundles, retention, runbooks | SRE |
| [14](#14-security-legal--compliance) | Security, Legal & Compliance — threat model, segmentation, licensing | Security + Legal |
| [15](#15-development-roadmap) | **Development Roadmap** — Phases 0–4, gates, staffing, cost | Leadership |
| [16](#16-risk-register--open-questions) | Risk Register & Open Questions | Everyone |
| [17](#17-appendices) | Appendices — decision tree, Android↔iOS table, requirement index, anti-patterns, bibliography | Everyone |

**Read these three first if you read nothing else:** §1.3 (the Honesty Principle), §3 (the capability
model), §15.2 (Phase 0 — the gate that must not be skipped).

---


## §0. Document Control

### 0.1 Provenance

This specification is the **reconciled merge** of two independent research passes against the same
brief ("design a state-of-the-art autonomous AI-first iPhone device lab"):

- **Doc A** — `compass_artifact_wf-e3ee5ef2-84c7-562b-bfea-27bc59b25267_text_markdown.md`
  Strength: ecosystem survey, hardware/USB economics, commercial escalation paths (Corellium, SRD),
  concrete numbers, AI/MCP project landscape.
- **Doc B** — `deep-research-report.md`
  Strength: capability contract, evidence discipline, distributed-systems rigor (fencing, recovery
  ladders, failure domains), Apple management/profiling planes, refusal to over-claim.

Where the two agreed, this document states the conclusion as settled. Where they diverged, §2 records
the disagreement, the ruling, and the rationale. **No claim from either source is carried forward
ungraded.**

### 0.2 How to read this document

```mermaid
flowchart LR
  A["§1 Product<br/>definition"] --> B["§2 Decision<br/>log"]
  B --> C["§3 Capability<br/>model"]
  C --> D["§4 System<br/>architecture"]
  D --> E["§5-§9<br/>Subsystems"]
  E --> F["§10-§14<br/>Engineering<br/>practice"]
  F --> G["§15 Roadmap<br/>Phase 0-4"]
  G --> H["§16 Risks &<br/>open questions"]

  style C fill:#2d4a6b,color:#fff
  style G fill:#2d4a6b,color:#fff
```

- **Executives / funding** → §1, §15, §16, §17.4 (cost model).
- **Architects** → §3, §4, §6, §7, §8.
- **Implementers** → §5 through §12, plus §17 appendices.
- **SRE / security** → §6.4, §13, §14.

> **§3 (Capability Model) is the normative core.** Every other section derives from it. If any
> subsystem contradicts §3, §3 wins.

### 0.3 Evidence grading (inherited from Doc B, applied to Doc A's claims)

Every capability, number and third-party claim in this document carries a grade.

| Grade | Meaning | Permitted use |
|---|---|---|
| **V** — Verified | Official Apple / upstream project documentation confirms it. | Safe to architect on. |
| **E** — Experimental | Documented upstream but depends on private/reverse-engineered protocol or carries substantial restrictions. | Must sit behind an adapter; must have a fallback. |
| **C** — Community | Community tooling or reports; no vendor guarantee. | Planning estimate only; **must be certified in Phase 0**. |
| **R** — Research | Academic / early-stage prototype. | Inspiration; never a dependency. |
| **T** — Theoretical | Architecturally plausible, no current implementation evidence. | Requires a spike before commitment. |
| **U** — Unsupported | No supported mechanism exists. | The API must return `CAPABILITY_UNAVAILABLE`. |

**Rule ORCHARD-E1:** A **C**-graded number may appear in a procurement plan but may **never** appear
in a capacity guarantee, an SLO, or a scheduler default. It must be promoted to **V** by local
measurement (§11.3) or dropped.

### 0.4 Normative language

`MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT`, `MAY` follow RFC 2119. Requirements are numbered
`ORCHARD-<AREA><n>` and are tracked in the compliance matrix (§17.5).

### 0.5 Glossary

| Term | Definition |
|---|---|
| **Cell** | The smallest schedulable fault domain: one Mac worker + its hubs + its attached iPhones. |
| **Lease** | A time-bounded exclusive claim on a device, carrying a monotonic fencing token. |
| **Fencing token** | A per-device monotonically increasing generation number; stale holders are rejected. |
| **Capability contract** | The per-device, dynamically computed set of operations the platform will actually perform. |
| **Plane** | One of five orthogonal technology stacks (§4.1). Planes are never conflated. |
| **Research tier** | Pinned, frozen, network-isolated jailbroken / SRD / virtualized devices. |
| **Stock tier** | Retail iPhones, optionally Developer Mode and/or supervised. |
| **Evidence bundle** | The immutable, content-addressed artifact set proving what a run did and observed. |
| **RSD / RemoteXPC** | Apple's iOS 17+ encrypted tunnel transport for developer services. |
| **WDA** | WebDriverAgent — the XCTest-based on-device HTTP server that exposes UI control. |

---

## §1. Product Definition

### 1.1 Problem statement

An on-premises R&D organisation needs to test, debug, security-research and continuously integrate
iOS software against a heterogeneous fleet of **physical iPhones**, driven both by deterministic CI
and by autonomous AI agents operating through Claude Code and OpenCode.

Android solves this with ADB: one transport, one shell, one root switch, one `logcat`. **iOS has no
such primitive.** Apple deliberately partitions UI testing, app development, device administration,
debugging, filesystem access, process access and privileged instrumentation into separate,
separately-gated mechanisms. Developer Mode does not grant a shell. Supervision does not grant root.
XCUITest is not a system-management API. [V]

Every existing open-source project in this space is a **thin wrapper over the same small set of
primitives**, and none of them own inventory, leases, fencing, USB fault domains, quarantine,
capability negotiation, RBAC, evidence retention, or CI fairness. Both research passes reached this
conclusion independently. [V]

### 1.2 Product thesis

> **ORCHARD is a capability-negotiating control plane for physical iOS hardware.**
> The unified thing is the control plane and the capability model — never the underlying iOS
> mechanism. ORCHARD composes Apple-native tooling, XCUITest/WDA, CoreDevice, libimobiledevice /
> pymobiledevice3 / go-ios, MDM, LLDB / Instruments, Frida, and a deliberately isolated research
> tier, behind one typed API exposed as REST, gRPC, a CLI (`labctl`) and MCP.

### 1.3 The Honesty Principle (ORCHARD-P1)

This is the single most important product rule, and both research passes independently demanded it.

> **ORCHARD offers an ADB-like *ergonomic experience* without ever claiming ADB-like *capability
> parity*.**

Concretely:

```text
labctl ios shell exec --lease L --cmd "ls /"   on a stock iPhone
  -> exit 2
  -> { "error": "CAPABILITY_UNAVAILABLE",
       "capability": "ios.shell.exec",
       "device_class": "stock_developer",
       "reason": "Stock iOS provides no general shell. This is a platform property, not a defect.",
       "remediation": ["reserve a device with class in (research_jailbroken, apple_srd, corellium)"],
       "eligible_device_count": 4 }
```

`MUST NOT`: silently degrade, attempt a brittle workaround, emulate the capability, or let an LLM
"try harder". A capability gap is a **first-class, structured, actionable API response**.

### 1.4 Goals

| # | Goal | Measured by |
|---|---|---|
| G1 | Maximum *technically achievable* control of heterogeneous physical iPhones. | Capability matrix coverage (§3.3) verified per device class in Phase 0. |
| G2 | Deterministic CI is the release gate; AI is exploration + investigation. | 0 release gates depend on a non-deterministic agent decision. |
| G3 | Horizontal scale 2 → 500+ devices without architectural rewrite. | Phase 4 runs the Phase 1 API unchanged. |
| G4 | Every autonomous run is replayable and auditable. | 100% of runs produce a complete evidence bundle (§13.4). |
| G5 | One model-agnostic MCP boundary serves Claude Code, OpenCode and CI identically. | Same tool surface, 3 clients, 1 gateway. |
| G6 | Research (privileged) capability without contaminating the production fleet. | 0 signing secrets reachable from research VLAN; 100% re-image after security runs. |
| G7 | On-premises operation with tightly controlled Apple egress. | Documented egress allowlist; measured offline-survival window (§11.3.4). |

### 1.5 Non-goals

| # | Non-goal | Rationale |
|---|---|---|
| NG1 | A new iOS UI automation driver. | XCUITest/WDA is the only sanctioned touch-injection path. [V] Rebuilding it is pure cost. |
| NG2 | A new MobileDevice protocol implementation. | libimobiledevice + pymobiledevice3 + CoreDevice already cover it. |
| NG3 | A shell on stock iOS, by any means. | Violates ORCHARD-P1 and the iOS security model. |
| NG4 | A general-purpose Android farm. | Architecture is iOS-shaped. Android may reuse the control plane later; it is out of scope for v1. |
| NG5 | Fully air-gapped operation as a hard requirement. | Signing validation and device activation retain Apple-service dependencies. [V] We target *controlled egress*. |
| NG6 | Replacing deterministic tests with agents. | Current agent benchmarks are far from CI-grade reliability. [R] |
| NG7 | Public / multi-tenant SaaS. | Single-organisation, on-prem, trusted-operator model. |

### 1.6 Personas

| Persona | Primary need | Primary interface |
|---|---|---|
| **App engineer** | "Run my branch on an iPhone 15 Pro on iOS 27 and show me the failure." | `labctl`, Claude Code + MCP |
| **QA / SDET** | Deterministic suites across a device matrix, stable evidence, flake attribution. | CI pipeline, `labctl test run` |
| **Security researcher** | Frida/LLDB/PCAP on an authorised target, on an isolated device. | `labctl` + MCP with `security_researcher` role |
| **Lab SRE** | Fleet health, quarantine, capacity, recovery, replacement. | Dashboards, `labctl admin`, runbooks |
| **AI agent** | Reserve → observe → act → investigate → release, under policy. | MCP gateway only |
| **Release manager** | "Is the gate green, and what is the evidence?" | Report + evidence bundle |

### 1.7 Service level objectives

These are the contractual targets from Phase 2 onward. Phase 0/1 measure the baselines that make
them real; **no SLO is published before its baseline is measured** (ORCHARD-E1).

| SLO | Target | Window | Notes |
|---|---|---|---|
| Device availability (stock tier) | ≥ 97% | 30d rolling | Excludes scheduled maintenance windows. |
| Device availability (research tier) | ≥ 85% | 30d rolling | Jailbreak/tether instability is expected. |
| Session success rate | ≥ 99.0% | 7d | Session = reserve → install → execute → release, excluding `TEST_FAILURE`/`APP_FAILURE`. |
| Reservation wait, p95 | ≤ 90 s | 7d | For a satisfiable capability predicate. |
| Recovery MTTR (automated ladder) | ≤ 5 min p90 | 30d | From detection to `available` or `quarantined`. |
| Evidence bundle completeness | 100% | always | A run without a complete bundle is a platform defect. |
| Control-plane API availability | ≥ 99.5% | 30d | Phase 3+ with HA. |
| False-positive product bugs | ≤ 1% of reported failures | 30d | Requires the failure-domain taxonomy (§6.5). |

### 1.8 What "done" means for v1.0

ORCHARD v1.0 ships when **all** hold:

1. A capability contract is served per device and honoured by every adapter (§3.4).
2. A CI job can reserve, install, test, collect evidence and release via `labctl` with fencing.
3. Claude Code and OpenCode drive the same MCP gateway with RBAC-scoped tools.
4. An AI investigator can autonomously root-cause a failure across ≥ 2 devices and produce a
   replayable evidence bundle a human can verify.
5. A Frida investigation runs on a research device and is **refused** on a stock device with a
   structured error.
6. The recovery ladder handles USB pull, WDA death and tunnel loss without human hands.
7. Phase-0 measured capacity numbers — not estimates — drive the scheduler's host limits.

---

## §2. Reconciliation Decision Log

Both research passes converged on the architecture. They diverged on ten material points. Each is
recorded here as an Architecture Decision Record so that no future reader has to re-litigate it.

### 2.1 Settled by unanimous convergence (no ADR required)

These are stated once and never re-argued. Independent agreement between two research passes is
treated as the strongest available non-experimental evidence.

| # | Settled conclusion | Grade |
|---|---|---|
| S1 | There is no "ADB for iPhone"; no existing project is the platform. | V |
| S2 | Build an internal control plane that **composes** primitives; adopt nothing as the architecture. | V |
| S3 | UI control ≠ device services ≠ debug/profile ≠ privileged instrumentation ≠ management. Five planes. | V |
| S4 | iOS 17+ CoreDevice/RemoteXPC tunnelling is the defining transport fact; direct `lockdownd StartService` is dead for developer services. | V |
| S5 | Stock iOS: no shell, no root FS, no arbitrary process/memory access, no `frida-server`. | V |
| S6 | Two-tier fleet: broad stock/dev tier + small pinned isolated research tier. Never assume a jailbreak exists for the hardware you need. | V |
| S7 | Jailbroken devices are hostile infrastructure: isolated VLAN, no secrets, re-image after use. | V |
| S8 | MCP is the interface, not the lab. One HTTP gateway serves Claude Code + OpenCode + CI. | V |
| S9 | Deterministic tests are the gate; AI explores and investigates. A verifier may not self-certify. | V |
| S10 | Prebuilt/preinstalled WDA; unique `wdaLocalPort`, `mjpegServerPort`, `derivedDataPath` per session. | V |
| S11 | pymobiledevice3 is GPL-3.0 and must be isolated behind a process boundary. | V |
| S12 | Continuous per-iOS-release maintenance is a standing, budgeted cost — not a project phase. | V |

### 2.2 ADR-001 — Devices per Mac: benchmark, never assume

```mermaid
flowchart TD
  A["Doc A: ~10-15 iPhones per<br/>USB 2.0 controller (endpoint limit)<br/>~22 cfgutil ceiling"] --> C{"Ruling"}
  B["Doc B: refuses any number.<br/>'Appium documents parallel isolation,<br/>not host ceilings'"] --> C
  C --> D["A's numbers = PROCUREMENT estimate, grade C<br/>B's benchmark = SCHEDULER truth, grade V"]
  D --> E["Phase 0 certifies 1/2/4/8/N<br/>under 4 workload profiles"]
  E --> F["Measured value becomes<br/>worker.max_concurrent_sessions"]
  style C fill:#6b3d2d,color:#fff
  style F fill:#2d6b3d,color:#fff
```

**Decision.** Both are right about different things. The USB endpoint limit is a real *physical
ceiling* (an iPhone consumes ~8–9 of its endpoints; a 15-port industrial hub saturates around
15 devices) [C]. It is **not** a *workload ceiling* — one MJPEG stream plus a continuous OSLog plus an
Instruments trace costs vastly more than a bare UI session.

- **Procurement** plans against **10–12 devices per USB 2.0 controller**, with headroom. [C]
- **Scheduler** admits sessions against `worker.max_concurrent_sessions`, a **measured** value from
  the Phase-0 concurrency matrix (§11.3.1), defaulting to `2` until measured.
- ORCHARD **MUST NOT** ship a documented "N iPhones per Mac" figure. Commercial farms do not publish
  one because it is workload-dependent, not because it is secret.

### 2.3 ADR-002 — Corellium is in scope as the modern-silicon escalation path

**Divergence.** Doc A treats Corellium as a first-class pillar (18 mentions, priced, air-gappable
appliance). Doc B does not mention it once and offers only "SRD or nothing".

**Decision: adopt Doc A's position.** Doc B leaves an unfillable hole. Its own guidance is
simultaneously (a) *never assume a jailbreak on current hardware* and (b) *use an SRD* — but an SRD
is premises-bound, Apple-owned, report-to-Apple, scarce, and excludes third-party apps from scope.
That leaves **no path at all** to root on iOS ≥ 18 / A14+ silicon, which is precisely where modern
security research must happen.

**Escalation ladder (normative):**

```mermaid
flowchart TD
  Q["Need privileged access?"] --> Q1{"Target OS / silicon"}
  Q1 -->|"A8-A11, iOS 15-16"| P1["palera1n / checkm8<br/>pinned physical device<br/>COST: hardware only"]
  Q1 -->|"A12-A13, covered build"| P2["Dopamine rootless<br/>pinned physical device<br/>COST: hardware only"]
  Q1 -->|"A14+ or iOS >= 18"| P3{"Is the target<br/>first-party and in<br/>SRD programme scope?"}
  P3 -->|Yes, and SRD obtainable| P4["Apple Security Research Device<br/>COST: programme relationship<br/>CONSTRAINT: premises-bound, report-to-Apple"]
  P3 -->|"No / unobtainable / 3rd-party target"| P5["Corellium virtualized iOS<br/>on-prem or air-gapped appliance<br/>COST: commercial licence"]
  P5 --> P6["NOTE: no radios, no Secure Enclave,<br/>no hardware fidelity.<br/>Complements, never replaces,<br/>the physical fleet."]
  style P5 fill:#2d4a6b,color:#fff
  style P6 fill:#6b3d2d,color:#fff
```

**Trigger (normative):** escalate to Corellium procurement when a required research target needs
root on **iOS ≥ 18 or A14+ silicon**, which no public physical jailbreak provides. Corellium is
modelled as device class `corellium_virtual` with its own capability contract (§3.2) and its own
fidelity caveats recorded on every evidence bundle it produces.

### 2.4 ADR-003 — go-ios is adopted as the MIT-licensed device-services path

**Divergence.** Doc A leans heavily on `go-ios` (26 mentions: tunnels, `runwda`, REST API, JSON,
`devicestate` thermal/network emulation). Doc B never mentions it and stacks on
devicectl + libimobiledevice + pymobiledevice3 only.

**Decision: adopt go-ios.** Doc B independently raises pymobiledevice3's GPL-3.0 risk as a top
unresolved concern and then offers no mitigation. go-ios is the mitigation: MIT-licensed, Go, JSON
output, a built-in REST surface, and overlapping coverage of the iOS 17+ tunnel. ORCHARD therefore
implements a **three-way adapter preference order** per operation (§7.3):

```text
1. Apple-supported   -> xcrun devicectl / simctl / xcodebuild / xctrace   [V]
2. MIT open path     -> go-ios                                            [C->V in Phase 0]
3. Mature open path  -> libimobiledevice                                  [V]
4. Advanced fallback -> pymobiledevice3 (GPL-3.0, subprocess-isolated)    [E]
```

No business logic calls any of these directly. The adapter chooses, records which path served the
call, and the evidence bundle stores that choice.

### 2.5 ADR-004 — MDM and supervision are a first-class plane

**Divergence.** Doc B: 29 mentions, a full management plane, Return to Service, iOS 27 declarative
device-health telemetry. Doc A: 3 mentions, mostly "block OTA updates".

**Decision: adopt Doc B.** Supervision is the only supported destructive-recovery and
configuration-enforcement channel, and at 100+ devices "wipe and return to managed operation without
manual reconfiguration" is the difference between a fleet and a museum. MDM becomes **Plane 5**
(§4.1). It is explicitly *not* responsible for high-frequency UI execution.

**Boundary rule (normative):** these are four independent booleans, never collapsed:

```text
supervised      = administratively controllable
developer_mode  = development/test execution permitted
jailbroken      = privileged research access
srd             = Apple-sanctioned research access
```

### 2.6 ADR-005 — `xctrace` / Instruments / MetricKit are first-class evidence

**Divergence.** Doc B: 17 `xctrace` mentions, profiling in the investigator loop. Doc A: zero.

**Decision: adopt Doc B.** `xctrace` is the supported command-line path to programmatic Instruments
recordings [V] — exactly what an automated investigation service needs. MetricKit belongs in the
*application telemetry* layer, not the interactive debugging layer, because its delivery is periodic
rather than live. XCTest attachments become the native evidence format for deterministic suites and
are ingested into the ORCHARD evidence model unchanged.

### 2.7 ADR-006 — Fencing tokens are mandatory from Phase 1

**Divergence.** Doc B specifies monotonic lease generations; Doc A has TTL + heartbeat only.

**Decision: adopt Doc B, and make it non-negotiable.** A physical iPhone is a shared mutable
resource; a lease without a generation counter has the same split-brain failure mode as a
distributed lock. Without fencing, an expired CI job keeps typing into a phone that has already been
reassigned, and the resulting cross-contamination is attributed as a product bug.

```mermaid
sequenceDiagram
  participant W1 as Worker job A gen 917
  participant S as Scheduler
  participant W2 as Worker job B gen 918
  participant D as iPhone lab-ios-0042

  S->>W1: lease granted, gen=917
  Note over W1: job A stalls (GC pause / network)
  S->>S: TTL expires, revoke
  S->>W2: lease granted, gen=918
  W2->>D: tap(x,y) [gen 918]
  D-->>W2: ok
  W1->>D: type("password") [gen 917]
  D-->>W1: 409 STALE_FENCE (expected 918)
  Note over W1: job A fails fast, releases,<br/>no cross-contamination
```

### 2.8 ADR-007 — Fleet passcode policy: no passcode by default

**Divergence.** Doc A suggests "WDA unlock with stored passcode". Doc B marks unattended passcode
unlock as `U` — unsupported by design — and prescribes a no-passcode fleet.

**Decision: adopt Doc B.** Unattended post-reboot access to a passcode-protected stock iPhone is
deliberately restricted by Apple [V]; building on "stored passcode" is building on sand and will
fail exactly when the recovery ladder needs it most (after a reboot).

- General QA devices: **no passcode** (`labels: [no-passcode]`).
- A separate, smaller **passcode-enabled sub-pool** exists for Data Protection / keychain / lock-state
  scenarios, tagged `labels: [passcode-required]`, and is scheduled only by explicit predicate.
- palera1n A11 devices additionally *require* the passcode disabled under jailbroken conditions [V] —
  this policy is compatible with that constraint by construction.

### 2.9 ADR-008 — Air-gap is a posture, not a requirement

**Divergence.** Doc A assumes air-gappable (offline provisioning profiles, air-gapped Corellium
appliance). Doc B says a full air-gap cannot preserve every stock-iPhone development/MDM workflow
indefinitely.

**Decision: adopt Doc B's framing, keep Doc A's mitigations.** Target **on-premises with a tightly
controlled Apple egress allowlist**. Phase 0 must *measure* the offline-survival window empirically
(§11.3.4) rather than assert it. Doc A's offline provisioning profiles and local re-signing pipeline
are adopted as the mitigations that extend that window.

| Component | On-prem? | Residual external dependency |
|---|---|---|
| Registry, scheduler, API, MCP, artifacts, OTel | Yes | None |
| Appium / WDA runtime, libimobiledevice, go-ios, pymobiledevice3, Frida | Yes | Initial mirror only |
| LiteLLM + local models | Yes | None if models are local |
| Xcode / XCTest | Mac-local | Apple distribution + licensing for acquisition |
| WDA / dev app signing | Local once provisioned | Apple Developer programme; online validation considerations [V] |
| MDM | Server on-prem | Apple push notification service |
| Device activation | No | Apple services |
| SRD | On-prem device | Apple programme relationship |

### 2.10 ADR-009 — Evidence discipline is inherited wholesale

**Decision: adopt Doc B's epistemics as process, not just as prose.**

- The V/E/C/R/T/U grading (§0.3) is enforced in review: an ungraded capability claim blocks merge.
- Doc A propagated two unresolved contradictions rather than grading them down — the SRD application
  window (press said "ended October 2025", Apple's page said "through October 2026") and the
  Dopamine 3.0 claims. Both are recorded in the risk register (§16) as **U — must be confirmed with
  the vendor before procurement**, not as facts.
- A project is not admitted to the stack on name recognition. Doc B correctly refused to promote
  "TestCat" without evidence, and correctly flagged that Maestro's current README advertises
  *physical Android* while iOS appears in the simulator matrix — so physical-iPhone Maestro support
  is **Phase-0 revalidation gated**, not assumed.

### 2.11 ADR-010 — Apple generation: target iOS 27 / Xcode 27, verify locally

**Divergence.** Doc A targets iOS 26 / Xcode 15–16. Doc B, dated this research date, targets
iOS 27 / Xcode 27 and Appium 3, and notes Appium's iOS 27 handling no longer assumes the older
`devicectl` fallback can start a preinstalled XCTest runner.

**Decision: adopt Doc B's generation.** Doc A's version-specific claims are therefore treated as one
generation stale — including its go-ios iOS 26 tunnel caveat and its WDA behaviour notes. **All
version-dependent behaviour from either document is demoted to grade C and must be re-certified in
Phase 0 against the actual fleet.** This is not a criticism of Doc A; it is the predictable half-life
of iOS tooling research, and it is exactly why §15 makes Phase 0 a hard gate before procurement.

### 2.12 Decision summary

| ADR | Subject | Ruling | Source adopted |
|---|---|---|---|
| 001 | Devices per Mac | Estimate from A, truth from B's benchmark | Both |
| 002 | Corellium | In scope; the A14+/iOS 18+ escalation path | **A** |
| 003 | go-ios | Adopted; the MIT mitigation for GPL exposure | **A** |
| 004 | MDM / supervision | First-class management plane | **B** |
| 005 | xctrace / Instruments / MetricKit | First-class evidence | **B** |
| 006 | Lease fencing tokens | Mandatory from Phase 1 | **B** |
| 007 | Passcode policy | No passcode by default + tagged sub-pool | **B** |
| 008 | Air-gap | Controlled egress; measure the offline window | **B** framing, **A** mitigations |
| 009 | Evidence grading | Enforced in review; ungraded claims block merge | **B** |
| 010 | Apple generation | iOS 27 / Xcode 27; all version claims re-certified | **B** |

---

## §3. The Capability Model — Normative Core

Everything in ORCHARD derives from this section. The capability model is the product.

### 3.1 Why a capability model and not a feature list

A device is not "an iPhone". It is a **tuple** of (chip, OS build, developer mode, supervision,
jailbreak state and variant, TrollStore presence, signing validity, WDA health, network placement,
policy scope). Any one of these changes what the platform can honestly do.

Both research passes independently concluded that a single `jailbroken: true/false` boolean is
inadequate. TrollStore is the canonical illustration: it permanently installs entitled applications
and enables root-helper possibilities on supported versions, yet it explicitly **cannot** perform
ordinary tweak injection into system processes on its own [V]. It is neither "jailbroken" nor
"stock".

```text
trollstore   = capability
jailbreak    = capability
frida_server = capability
root_shell   = capability
srd          = capability

Never collapse them into one boolean.
```

### 3.2 Device classes

ORCHARD defines **seven** classes (Doc B's six, plus `corellium_virtual` from ADR-002).

```mermaid
graph TD
  subgraph "Stock tier — broad, production fleet"
    A["stock_retail<br/>paired, no Developer Mode<br/>diagnostics + MDM only"]
    B["stock_developer<br/>Developer Mode on<br/>WDA, XCTest, dev-signed debug"]
    C["managed_supervised<br/>+ MDM authority<br/>restart/erase/RtS/profiles"]
  end
  subgraph "Research tier — narrow, pinned, isolated"
    D["research_jailbroken<br/>SSH, frida-server, broad FS"]
    E["apple_srd<br/>shell, custom entitlements,<br/>kernel research"]
    F["corellium_virtual<br/>instant root on modern iOS<br/>no radios / no SEP fidelity"]
  end
  subgraph "Host tier"
    G["simulator<br/>high density, deterministic<br/>not hardware iOS"]
  end

  A --> B --> C
  D -.->|escalate A14+/iOS18+| F
  D -.->|if programme access| E

  style D fill:#6b2d2d,color:#fff
  style E fill:#6b2d2d,color:#fff
  style F fill:#6b2d2d,color:#fff
```

| Class | Definition | Network zone | Scheduling default |
|---|---|---|---|
| `stock_retail` | Paired retail iPhone, Developer Mode not assumed. | Stock device VLAN | Diagnostics/MDM workloads only |
| `stock_developer` | Developer Mode enabled; XCTest/WDA and debug of eligible apps permitted. [V] | Stock device VLAN | Default CI target |
| `managed_supervised` | Supervised + MDM enrolled. Administrative authority, **not root**. [V] | Stock device VLAN | Default CI target, preferred for lifecycle |
| `research_jailbroken` | Pinned jailbreak (palera1n / Dopamine), exact chip+build frozen. | **Research VLAN (untrusted)** | Explicit predicate only |
| `apple_srd` | Apple Security Research Device: shell, arbitrary entitlements, kernel customisation. [V] | **Research VLAN (untrusted)** + policy gate | Explicit predicate + programme-scope check |
| `corellium_virtual` | Virtualized modern iOS on an on-prem/air-gapped appliance. | Research VLAN | Explicit predicate; fidelity caveat stamped on evidence |
| `simulator` | `simctl`-managed simulator on a Mac worker. | Worker VLAN | Scale-out functional tests only |

**Fidelity warning (normative):** `simulator` and `corellium_virtual` **MUST** stamp every evidence
bundle with `fidelity_caveat`, because neither reproduces Secure Enclave behaviour, radios, real
power/thermal characteristics, or full hardware security boundaries. [V] A release gate **MUST NOT**
depend solely on either.

### 3.3 The comprehensive capability matrix

**Legend:** `S` supported · `P` partial/conditional · `U` unsupported through ordinary mechanisms ·
`N/A` not applicable. Grades in the mechanism column.

| Capability | `stock_retail` | `stock_developer` | `managed_supervised` | `research_jailbroken` | `apple_srd` | `corellium_virtual` | `simulator` | Mechanism / limitation |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| Discover device | S | S | S | S | S | S | S | devicectl / go-ios / usbmuxd; `simctl` [V] |
| Pair device | S | S | S | S | S | N/A | N/A | lockdown / CoreDevice trust [V] |
| Reserve device | S | S | S | S | S | S | S | **ORCHARD scheduler — not an iOS API** |
| USB connectivity | S | S | S | S | S | N/A | N/A | MobileDevice / CoreDevice / usbmuxd [V] |
| Network connectivity | P | S | S | S | S | S | S | Paired wireless dev; SSH on research [V] |
| RSD / RemoteXPC tunnel | P | S | S | S | S | N/A | N/A | iOS 17+ requirement; go-ios / pymobiledevice3 / devicectl [V] |
| Automatic reconnect | P | P | P | S | S | S | S | Worker recovery ladder (§6.5) |
| Install IPA | P | S | S | S | S | S | P | Signing/distribution required; simulator takes sim builds [V] |
| Uninstall app | P | S | S | S | S | S | S | installation proxy / devicectl / MDM [V] |
| Launch / terminate app | P | S | P | S | S | S | S | devicectl / WDA / XCTest; MDM is not a generic launcher [V] |
| Reboot / shutdown | P | P | S | S | S | S | S | diagnostics relay / MDM / shell [V] |
| Lock device | P | P | S | S | S | S | S | MDM / XCTest depending on context [V] |
| **Unattended passcode unlock** | **U** | **U** | P | P | P | S | S | Deliberately restricted. See ADR-007. [V] |
| Change orientation | U | S | P | S | S | S | S | XCTest / WDA [V] |
| Screenshot | P | S | P | S | S | S | S | screenshot service / WDA; `simctl` [V] |
| Record / stream screen | U/P | P | P | S | S | S | S | WDA MJPEG; not raw framebuffer [V] |
| Tap / swipe / type / long-press | U | S | P | S | S | S | S | **XCTest/WDA is the only sanctioned HID path** [V] |
| Multi-touch | U | P | P | P/S | P/S | S | S | Coordinate actions; framework/version dependent [C] |
| Read accessibility / UI tree | U | S | P | S | S | S | S | XCTest accessibility snapshot [V] |
| App's own container files | U | P | P | S | S | S | S | AFC / House Arrest, dev-signed only [V] |
| **Broad / root filesystem** | **U** | **U** | **U** | S | S | S | P | AFC mount is *not* the root FS [V] |
| **Shell execution** | **U** | **U** | **U** | S | S | S | P | ORCHARD-P1. Host shell on simulator only. [V] |
| List / kill arbitrary processes | U | P | P | S | S | S | S | Own/debuggable via DVT only on stock [V] |
| Dump process memory | U | P | P | S | S | S | P | Own debug target only on stock [V] |
| Attach LLDB | U | P | P | S | S | S | S | Debuggable/dev-signed targets only on stock [V] |
| Frida Gadget (own app) | U | P | P | S | S | S | P | Repackage + re-sign; jailed Interceptor constraints [V] |
| **`frida-server`** | **U** | **U** | **U** | S | S | S | U | Jailbreak/SRD/virtualized only [V] |
| Hook system daemon | U | U | U | P | S | S | U | Subject to jailbreak mitigations [V] |
| Syslog / OSLog stream | P | S | S | S | S | S | S | libimobiledevice / pymobiledevice3 / go-ios [V] |
| Crash reports | S | S | S | S | S | S | S | CrashReports service [V] |
| sysdiagnose / diagnostics | S | S | S | S | S | S | P | diagnostics relay [V] |
| Packet capture | P | S | S | S | S | S | S | RVI / pymobiledevice3 PCAP [E] |
| Instruments / `xctrace` profiling | U | S | P | S | S | S | S | DVT over tunnel [V] |
| MetricKit app telemetry | N/A | S | S | S | S | S | P | Periodic delivery, not live [V] |
| Install proxy / VPN profile | P | S | S | S | S | S | S | Configuration profile; MDM preferred [V] |
| Keychain inspection | U | U | P | S | S | S | P | Authorised environments only [V] |
| Entitlement / signing inspection | S | S | S | S | S | S | S | Static analysis of artifact [V] |
| Kernel customisation | U | U | U | P | S | S | U | Rootful/old JB partial; SRD sanctioned [V] |
| Declarative device health | U | P | S | S | S | N/A | N/A | iOS 27 declarative management [V] |
| Return to Service wipe | U | U | S | U | U | S | S | MDM RtS on supported devices [V] |

### 3.4 The capability contract

Every device serves a **dynamically computed** contract. It is never a static per-class lookup: a
`stock_developer` device with an expired provisioning profile is not capable of `ios.ui.tap`, and the
contract must say so *before* a job wastes a lease discovering it.

```mermaid
flowchart LR
  subgraph Inputs
    I1["device class"]
    I2["OS version + build"]
    I3["developer_mode<br/>supervised flags"]
    I4["jailbreak facts<br/>(name, variant, verified build)"]
    I5["WDA health +<br/>provisioning expiry"]
    I6["tunnel / RSD state"]
    I7["policy + RBAC scope<br/>of the CALLER"]
    I8["last probe results<br/>(TTL'd)"]
  end
  I1 & I2 & I3 & I4 & I5 & I6 & I7 & I8 --> CE["Capability Engine"]
  CE --> OUT["Capability contract<br/>per (device, principal)"]
  OUT --> MCP["MCP tool advertisement"]
  OUT --> SCH["Scheduler predicate matching"]
  OUT --> ADP["Adapter admission control"]
  style CE fill:#2d4a6b,color:#fff
```

**ORCHARD-C1:** The contract is computed per `(device, principal)`. A `developer` role and a
`security_researcher` role querying the same jailbroken phone receive **different** contracts. The
LLM receives no authority merely by requesting a tool.

**ORCHARD-C2:** The MCP gateway **MUST** advertise only tools present in the caller's contract for
the leased device. An agent should never see `ios.shell.exec` on a stock phone — the strongest
possible defence against an agent "trying anyway".

#### 3.4.1 Contract schema

```json
{
  "$schema": "https://orchard.internal/schemas/capability-contract/v1.json",
  "device_id": "lab-ios-0042",
  "device_class": "stock_developer",
  "computed_at": "2026-09-17T09:14:03Z",
  "ttl_seconds": 300,
  "principal": {"role": "developer", "subject": "svc-ci-auth-regression"},
  "fidelity_caveat": null,
  "capabilities": {
    "ios.ui.tap":            {"supported": true},
    "ios.ui.inspect":        {"supported": true},
    "ios.logs.stream":       {"supported": true},
    "ios.crashes.collect":   {"supported": true},
    "ios.network.capture":   {"supported": true, "grade": "E",
                              "note": "RVI path; revalidate per iOS build"},
    "ios.trace.record":      {"supported": true, "scope": "xctrace-templates-only"},
    "ios.debug.attach":      {"supported": true, "scope": "debuggable-apps-only",
                              "allowed_bundle_ids": ["com.example.internalapp"]},
    "ios.instrument.attach": {"supported": true, "scope": "eligible-app-gadget-or-debugger"},
    "ios.memory.read":       {"supported": true, "scope": "debuggable-target-only"},
    "ios.process.list":      {"supported": false, "reason": "CAPABILITY_UNAVAILABLE",
                              "detail": "Stock iOS exposes only own/debuggable processes via DVT."},
    "ios.shell.exec":        {"supported": false, "reason": "CAPABILITY_UNAVAILABLE",
                              "detail": "Stock iOS provides no general shell.",
                              "remediation": ["device_class in (research_jailbroken, apple_srd, corellium_virtual)"]}
  },
  "degraded": [
    {"capability": "ios.ui.*", "until": "2026-10-04T00:00:00Z",
     "reason": "WDA provisioning profile expires in 17 days"}
  ]
}
```

A `research_jailbroken` device under a `security_researcher` principal returns instead:

```json
{
  "device_class": "research_jailbroken",
  "fidelity_caveat": null,
  "capabilities": {
    "ios.shell.exec":        {"supported": true, "scope": "approved-research-targets"},
    "ios.process.list":      {"supported": true},
    "ios.process.inspect":   {"supported": true},
    "ios.memory.read":       {"supported": true},
    "ios.instrument.attach": {"supported": true, "backend": "frida-server"},
    "ios.instrument.trace":  {"supported": true, "scope": "reviewed-templates",
                              "raw_script": "requires role=security_researcher_expert"}
  },
  "authorisation": {
    "target_scope": ["com.example.internalapp", "com.example.sdk-harness"],
    "note": "Device availability is NOT authorisation to attach to every process."
  }
}
```

**ORCHARD-C3:** `research device available != permission to attach to anything`. Target scope is a
separate authorisation object, issued per engagement, and enforced at the adapter.

### 3.5 Error taxonomy

Structured, machine-actionable, never a bare string.

| Code | HTTP | Meaning | Agent guidance |
|---|---|---|---|
| `CAPABILITY_UNAVAILABLE` | 501 | Platform cannot do this on this class. Permanent. | Re-plan. Do not retry. Consider a different device class. |
| `CAPABILITY_DEGRADED` | 503 | Normally supported, currently not (WDA down, profile expired). | Retry after recovery, or request another device. |
| `NOT_AUTHORISED` | 403 | Capability exists; principal or target scope forbids it. | Do not retry. Escalate to a human. |
| `STALE_FENCE` | 409 | Lease generation superseded. | Abort immediately. Release. Do not re-acquire silently. |
| `LEASE_EXPIRED` | 410 | TTL elapsed without renewal. | Abort, collect evidence, re-reserve if the job permits. |
| `DEVICE_QUARANTINED` | 423 | Device removed from service. | Re-plan onto another device. |
| `NO_ELIGIBLE_DEVICE` | 404 | Predicate satisfiable by no device in inventory. | Relax predicate or report capacity gap. |
| `CAPACITY_EXHAUSTED` | 429 | Predicate satisfiable but all matching devices busy. | Queue; honour `Retry-After`. |
| `ADAPTER_FAILURE` | 502 | Underlying tool failed. Carries `failure_domain` (§6.5). | Recovery ladder handles it; do not interpret as a product bug. |
| `POLICY_BUDGET_EXCEEDED` | 429 | Model/tool/step budget hit. | Terminate the agent loop and report. |

**ORCHARD-C4:** Every error carries `failure_domain` (§6.5) so that a `WDA_FAILURE` is never reported
to a developer as an application bug. Doc B correctly identified misattribution as the dominant
source of false product bugs in device labs.

---

## §4. System Architecture

### 4.1 The five capability planes

ORCHARD's foundational design rule: **five orthogonal planes, never conflated.** Each plane has a
distinct technology stack, a distinct failure mode, and a distinct privilege story. Conflating them
is the root cause of nearly every wrong assumption about iOS automation.

```mermaid
graph TB
  subgraph P1["Plane 1 — UI"]
    U1["XCTest / XCUITest"] --> U2["WebDriverAgent"] --> U3["Appium 3 XCUITest driver"]
  end
  subgraph P2["Plane 2 — Device services"]
    D1["CoreDevice / devicectl"]
    D2["go-ios (MIT)"]
    D3["libimobiledevice"]
    D4["pymobiledevice3 (GPL, isolated)"]
  end
  subgraph P3["Plane 3 — Debug & profile"]
    B1["LLDB / debugserver"]
    B2["Instruments / xctrace"]
    B3["MetricKit"]
  end
  subgraph P4["Plane 4 — Privileged research"]
    R1["jailbreak SSH"]
    R2["frida-server"]
    R3["Frida Gadget (jailed)"]
    R4["SRD toolchain"]
    R5["Corellium API"]
  end
  subgraph P5["Plane 5 — Management"]
    M1["MDM commands"]
    M2["Supervision / profiles"]
    M3["Return to Service"]
    M4["Declarative device health"]
  end

  P1 --> CE["Capability Engine"]
  P2 --> CE
  P3 --> CE
  P4 --> CE
  P5 --> CE
  CE --> API["Unified typed API"]

  style CE fill:#2d4a6b,color:#fff
  style P4 fill:#6b2d2d,color:#fff
```

| Plane | Gives you | Does **not** give you |
|---|---|---|
| 1 — UI | Tap, swipe, type, a11y tree, screenshot, MJPEG, app launch/kill | Shell, root FS, arbitrary memory |
| 2 — Device services | Discovery, pairing, install, logs, crashes, diagnostics, PCAP, tunnels | An ADB-equivalent Unix shell |
| 3 — Debug & profile | LLDB on eligible targets, Instruments traces, app metrics | Arbitrary system-process attach, runtime hooking |
| 4 — Privileged research | Shell, root FS, process/memory, system-wide hooking | Availability on arbitrary current hardware/iOS |
| 5 — Management | Restart, shutdown, lock, erase, RtS, profiles, restrictions, fleet health | Shell, root, arbitrary process control |

### 4.2 System context

```mermaid
graph TB
  subgraph Consumers
    CC["Claude Code"]
    OC["OpenCode"]
    CI["CI systems<br/>GitHub / GitLab / Jenkins / Buildkite"]
    HU["Lab SRE<br/>dashboards + labctl admin"]
  end

  subgraph Edge
    GW["MCP Gateway<br/>Streamable HTTP"]
    REST["REST / gRPC API"]
    CLI["labctl"]
  end

  AUTH["Identity, RBAC & Policy Engine"]

  subgraph ControlPlane["Control Plane (Linux, containers)"]
    ORCH["AI Orchestrator"]
    DET["Deterministic Runner"]
    SCHED["Scheduler & Lease Service"]
    REG["Registry & Capability Engine"]
    REC["Recovery Engine"]
    CAP["Capacity Controller"]
    POL["Policy Store"]
  end

  subgraph Data
    PG[("PostgreSQL<br/>registry, leases, audit")]
    NATS["NATS JetStream<br/>events"]
    S3[("S3-compatible<br/>artifact store")]
    OTEL["OpenTelemetry<br/>traces / metrics / logs"]
  end

  subgraph Workers["Mac Worker Cells (macOS, bare metal)"]
    W1["worker-a1<br/>stock cell"]
    W2["worker-a2<br/>stock cell"]
    W3["worker-r1<br/>research cell"]
    W4["worker-s1<br/>simulator cell"]
  end

  subgraph Fleet
    PH1["Stock / supervised iPhones"]
    PH2["Pinned jailbroken iPhones"]
    PH3["SRD pool"]
    PH4["Corellium appliance"]
    SIM["Simulators"]
  end

  LLM["LiteLLM gateway<br/>LOW / MID / HIGH classes"]
  SIGN["Signing & Build Service"]
  MDM["MDM server"]

  CC --> GW
  OC --> GW
  CI --> CLI --> REST
  HU --> CLI
  GW --> AUTH
  REST --> AUTH
  AUTH --> ORCH & DET & SCHED & REG
  ORCH --> LLM
  ORCH --> SCHED
  DET --> SCHED
  SCHED --> REG
  SCHED <--> NATS
  REC <--> NATS
  CAP --> SCHED
  POL --> AUTH
  REG --> PG
  SCHED --> PG
  NATS <--> W1 & W2 & W3 & W4
  W1 --> PH1
  W2 --> PH1
  W3 --> PH2
  W3 --> PH3
  W4 --> SIM
  REG -.-> PH4
  W1 & W2 & W3 & W4 --> S3
  W1 & W2 & W3 & W4 --> OTEL
  SIGN --> W1 & W2
  MDM --> PH1

  style GW fill:#2d4a6b,color:#fff
  style W3 fill:#6b2d2d,color:#fff
  style PH2 fill:#6b2d2d,color:#fff
  style PH3 fill:#6b2d2d,color:#fff
```

### 4.3 Layered responsibility model

```mermaid
flowchart TD
  L7["L7 — Harness<br/>Claude Code, OpenCode, CI"]
  L6["L6 — Interface<br/>MCP gateway, REST/gRPC, labctl"]
  L5["L5 — Policy<br/>identity, RBAC, target scope, budgets"]
  L4["L4 — Orchestration<br/>AI orchestrator, deterministic runner"]
  L3["L3 — Control<br/>scheduler, leases+fencing, registry,<br/>capability engine, recovery, capacity"]
  L2["L2 — Worker<br/>Mac daemon, session mgr, port mgr,<br/>tunnel mgr, health, adapters"]
  L1["L1 — Adapters<br/>devicectl, go-ios, libimobiledevice,<br/>pymobiledevice3, Appium/WDA, Frida,<br/>LLDB, xctrace, SSH, MDM, Corellium"]
  L0["L0 — Physical<br/>iPhones, managed USB hubs,<br/>cables, racks, PDUs, VLANs"]

  L7 --> L6 --> L5 --> L4 --> L3 --> L2 --> L1 --> L0

  style L3 fill:#2d4a6b,color:#fff
  style L5 fill:#6b3d2d,color:#fff
```

**ORCHARD-A1:** The control plane **MUST NOT** directly manipulate a USB device. A worker is
authoritative for the devices physically attached to it. This is what makes cells real fault domains.

**ORCHARD-A2:** No business logic may import an adapter library directly. All adapter access is
through the L1 typed adapter interface, so that iOS churn is absorbed in one place (§7.3).

**ORCHARD-A3:** Every layer boundary is a policy enforcement point for *fencing*. A command carrying
a stale generation is rejected at L2 (worker), not merely at L3.

### 4.4 Primary control flow — reserve to release

```mermaid
sequenceDiagram
  autonumber
  actor CI as CI job
  participant CLI as labctl
  participant API as REST API
  participant POL as Policy
  participant SCH as Scheduler
  participant REG as Registry / Capability
  participant N as NATS
  participant W as Mac worker
  participant D as iPhone
  participant S3 as Artifact store

  CI->>CLI: labctl devices reserve --where '...' --ttl 45m
  CLI->>API: POST /v1/leases
  API->>POL: authorise(principal, predicate)
  POL-->>API: ok, scope=[com.example.internalapp]
  API->>SCH: reserve(predicate, priority, ttl)
  SCH->>REG: compile predicate -> eligible set
  REG-->>SCH: [lab-ios-0042, lab-ios-0051] ranked by health+affinity
  SCH->>SCH: allocate, gen := gen+1 (918)
  SCH-->>CLI: lease{id, device, gen=918, expires_at}

  CI->>CLI: labctl ios app install --artifact MyApp.ipa
  CLI->>API: POST /v1/leases/{id}/app/install
  API->>N: publish cmd{lease, gen=918, op=install}
  N->>W: deliver
  W->>W: verify gen == device.current_gen
  W->>D: devicectl device install app
  D-->>W: installed
  W->>S3: put evidence{install log, artifact sha256}
  W->>N: result{ok, adapter="devicectl", duration_ms}
  N-->>CLI: ok

  loop every ttl/3
    CLI->>API: POST /v1/leases/{id}/renew
  end

  CI->>CLI: labctl test run --suite auth-regression
  CLI->>API: POST /v1/runs
  API->>N: cmd{gen=918, op=test.run}
  N->>W: deliver
  W->>D: Appium/XCUITest session (wda:8117, mjpeg:9117)
  D-->>W: results + attachments
  W->>S3: put evidence bundle
  W->>N: result{failed: 1}

  CI->>CLI: labctl investigate --on-failure --model-class MID
  Note over CLI,W: see §9.3 investigation loop

  CI->>CLI: labctl devices release (trap EXIT)
  CLI->>API: DELETE /v1/leases/{id}
  API->>SCH: release
  SCH->>N: cmd{op=sanitise, gen=918}
  N->>W: deliver
  W->>D: uninstall test app, clear state, health probe
  W->>N: device available
  SCH->>REG: state=available
```

### 4.5 Capability negotiation flow

```mermaid
sequenceDiagram
  autonumber
  actor AG as AI agent
  participant MCP as MCP Gateway
  participant POL as Policy
  participant CE as Capability Engine
  participant W as Worker probes

  AG->>MCP: tools/list (lease=L, device=lab-ios-0042)
  MCP->>POL: principal role + target scope
  POL-->>MCP: role=developer, scope=[com.example.internalapp]
  MCP->>CE: contract(device, principal)
  CE->>W: probe cache (TTL 300s)
  W-->>CE: wda=healthy, tunnel=up, profile_expiry=17d, dev_mode=true
  CE-->>MCP: contract (see §3.4.1)
  MCP-->>AG: ONLY the supported tools are advertised
  Note over AG: ios.shell.exec is not in the tool list.<br/>The agent cannot "try anyway".

  AG->>MCP: ios.debug.attach(bundle=com.other.app)
  MCP->>POL: check target scope
  POL-->>MCP: deny
  MCP-->>AG: 403 NOT_AUTHORISED {capability exists, target out of scope}
```

### 4.6 Technology selection summary

| Layer | Choice | Adopt / Fork / Build | Licence | Grade | Primary risk |
|---|---|---|---|---|---|
| Apple foundation | Xcode, XCTest/XCUITest, CoreDevice/devicectl, simctl, xctrace | **Adopt** | Apple proprietary | V | Version churn |
| UI / WebDriver | Appium 3 + XCUITest driver | **Adopt behind adapter** | Apache-2.0 | V | WDA + signing churn |
| On-device UI bridge | WebDriverAgent, prebuilt + internally signed | **Adopt via Appium** | BSD-family | V | XCTest API breakage |
| Device services (MIT) | go-ios | **Adopt behind adapter** | MIT | C→V Phase 0 | Tunnel breakage on new iOS |
| Device services (mature) | libimobiledevice | **Adopt behind adapter** | LGPL/GPL parts | V | Protocol drift |
| Device services (advanced) | pymobiledevice3 | **Optional adapter, subprocess-isolated** | **GPL-3.0** | E | Private protocol churn + licence |
| Debugging | LLDB / debugserver | **Adopt** | Apple + OSS | V | Stock entitlement limits |
| Profiling | Instruments / `xctrace` | **Adopt** | Apple | V | Heavy sessions |
| App telemetry | MetricKit | **Adopt** | Apple | V | Periodic delivery semantics |
| Instrumentation | Frida + Objection | **Adopt + wrap, capability-gated** | Component-specific | V | Jailed fragility on iOS 17+ |
| Research JB (old silicon) | palera1n / checkm8 | **Adopt on pinned pool only** | MIT | V | A11 passcode constraint |
| Research JB (newer) | Dopamine (rootless) | **Adopt on exact pinned builds only** | MIT | V/U | v3.0 claims ungraded — see §16 |
| Persistent jailed install | TrollStore | **Optional; legal review first** | NOASSERTION upstream | V | Narrow version window |
| Sanctioned deep research | Apple SRD | **Use if programme access** | Apple programme | V | Premises-bound, scope-limited |
| Modern-iOS deep research | Corellium appliance | **Adopt (commercial)** per ADR-002 | Commercial | C | Cost; no hardware fidelity |
| Dev-agent helper | XcodeBuildMCP | **Adopt alongside, never as control plane** | MIT | C | Not a fleet manager |
| UI MCP reference | mobile-mcp / mobile-device-mcp / iOS-agent-bridge | **Study / fork tool schemas** | MIT/OSS | C | Thin, single-device |
| Deterministic DSL | Maestro | **Conditional — Phase 0 physical-iOS gate** | Apache-2.0 | U | Physical iOS unverified |
| Scheduler seed | appium-device-farm | **Study; do not adopt as core** | MIT + proprietary parts | C | No capability model |
| Registry / leases | PostgreSQL + internal service | **Build** | OSS | — | Fencing correctness |
| Event transport | NATS JetStream | **Adopt** | Apache-2.0 | V | Operational complexity |
| Artifact store | S3-compatible (MinIO/Ceph) | **Adopt** | OSS | V | Volume / retention |
| Observability | OpenTelemetry + Grafana/Tempo/Loki/Mimir | **Adopt** | Apache-2.0 | V | Cardinality |
| Model gateway | LiteLLM | **Adopt (org standard)** | MIT | V | Model drift |
| Agent interface | MCP (Streamable HTTP) | **Adopt protocol, build server** | Open protocol | V | Client capability differences |
| CLI / API | `labctl` + REST/gRPC | **Build** | Internal | — | API maintenance |
| RBAC / policy | Internal policy engine + org IAM | **Build / integrate** | Internal | — | Privilege escalation |

**Do not build:** a new iOS UI automation driver, a new Frida, a new MobileDevice protocol
implementation, or a fake stock-iOS shell.

**Build internally:** registry, capability model, scheduler, leases + fencing, recovery manager, Mac
worker daemon, security policy, evidence model, unified API, unified MCP, auditability, AI
orchestration.

---

## §5. Fleet Composition & Physical Infrastructure

### 5.1 Cell topology — the schedulable fault domain

```mermaid
graph TB
  subgraph Lab
    subgraph RackA["Rack A — stock tier"]
      subgraph CellA1["Cell A1"]
        WA1["Mac worker a1<br/>Apple silicon, 64GB"]
        HA1["Managed hub A1<br/>per-port power"]
        WA1 --- HA1
        HA1 --- P1["iPhone x10-12"]
      end
      subgraph CellA2["Cell A2"]
        WA2["Mac worker a2"]
        HA2["Managed hub A2"]
        WA2 --- HA2
        HA2 --- P2["iPhone x10-12"]
      end
      PDUA["Smart PDU A"]
      PDUA -.-> WA1 & WA2
    end
    subgraph RackR["Research enclave — isolated VLAN"]
      WR1["Mac worker r1<br/>disposable / reimageable"]
      HR1["Dedicated hub R1<br/>NEVER shared with stock"]
      WR1 --- HR1
      HR1 --- PR["Pinned jailbroken iPhones<br/>SRD pool"]
      CORE["Corellium appliance"]
    end
    subgraph RackS["Simulator tier"]
      WS1["Mac worker s1<br/>128GB, high RAM"]
      WS1 --- SIMS["Simulator pool"]
    end
  end

  style RackR fill:#3b1f1f,color:#fff
  style WR1 fill:#6b2d2d,color:#fff
  style PR fill:#6b2d2d,color:#fff
```

**ORCHARD-H1:** A cell is the smallest schedulable fault domain. A hub, cable or upstream controller
failure **MUST** affect exactly one cell. Never put the whole fleet on one hub, and never put
research and stock devices on the same hub or the same worker.

**ORCHARD-H2:** A worker owns everything about its devices: CoreDevice sessions, WDA processes,
RemoteXPC tunnels, Appium session state, usbmux forwarding, log streams, `xctrace` processes,
temporary artifacts. The control plane orchestrates; it never touches USB.

### 5.2 Transport policy

USB is primary. Wireless is secondary and purposeful, not a convenience.

| Transport | Use when | Why |
|---|---|---|
| **USB (default)** | All routine CI and interactive sessions | Deterministic physical association, charging, low latency, easy fault localisation, host ownership, port forwarding independent of lab Wi-Fi |
| **Wireless (RemotePairing)** | Network-behaviour tests, resilience tests, workloads where a cable changes the result | Real wireless behaviour; survives cable faults |
| **SSH over research VLAN** | `research_jailbroken` / `apple_srd` privileged operations | Key-only; isolated; never carries signing material |
| **Corellium REST** | `corellium_virtual` | Appliance API; no physical layer |

### 5.3 Stock-tier fleet planning

**Procurement estimate** (grade **C** — see ADR-001): **10–12 iPhones per USB 2.0 controller**,
derived from device endpoint consumption (an iPhone consumes roughly 8–9 of its available endpoints;
a 15-port industrial hub saturates near 15 devices) and community `cfgutil` ceilings near 22.

**Scheduler truth** (grade **V** only after Phase 0): `worker.max_concurrent_sessions`, measured per
workload profile in §11.3.1. Default `2` until measured.

```mermaid
flowchart LR
  A["Procurement<br/>10-12 per controller<br/>grade C"] -->|buy hubs and cables| B["Phase 0<br/>concurrency matrix<br/>1/2/4/8/N"]
  B -->|measured| C["worker.max_concurrent_sessions<br/>per workload profile<br/>grade V"]
  C --> D["Scheduler admission control"]
  B -.->|if measurement < estimate| E["Add workers, not devices per worker"]
  style C fill:#2d6b3d,color:#fff
```

**Workload cost ordering (normative planning heuristic):**

```text
bare UI session
  <<  UI + MJPEG stream
  <<  UI + MJPEG + continuous OSLog
  <<  + Instruments/xctrace trace
  <<  + concurrent xcodebuild/WDA cold starts
```

An eight-port hub purchase is **not** evidence that eight simultaneous high-observability sessions
are safe.

### 5.4 Research-tier device matrix

**Policy ORCHARD-R1:** Never design the research tier around "we can jailbreak whatever we need."
**Buy and freeze known-good combinations.** Eligibility is a function of **chip + exact OS build**,
never marketing model name.

| Device family | Chip | Route | OS envelope | Suitability | Grade |
|---|---|---|---|---|---|
| iPhone 6s / SE 1 | A9 | palera1n (checkm8) | iOS 15-era max | Excellent exploit-reliability devices; old OS | V |
| iPhone 7 | A10 | palera1n (checkm8) | iOS 15-era max | Same | V |
| iPhone 8 / 8 Plus / X | A11 | palera1n (checkm8) | through their iOS 16 generation | Excellent low-level tier. **Passcode must be disabled** under jailbroken conditions; iOS 16 adds setup caveats | V |
| iPhone XS / XR | A12 | Dopamine (rootless) | exact documented builds only | Valuable newer tier | V |
| iPhone 11 / 11 Pro / SE 2 | A13 | Dopamine (rootless) | unusually broad later-build coverage documented | **Most attractive research inventory** | V |
| iPhone 12 and later arm64e | A14+ | Dopamine only where the exact build is covered | do not extrapolate | Buy only against the exact matrix | V |
| Current generation on iOS 27 | modern | **No public jailbreak assumption** | — | Stock QA, SRD, or `corellium_virtual` | V |

**Freeze record (immutable registry facts):**

```yaml
research:
  jailbreak:
    name: dopamine
    version: "2.x"                # exact; 3.0 claims are grade U until confirmed
    root_model: rootless
    persistence: semi_untethered
    verified_boot_build: "22Hxxx"
    verified_at: "2026-10-02T11:00:00Z"
    verified_by: "phase0-cert-run-0041"
    auto_update_disabled: true
    reflash_runbook: "docs/runbooks/rejailbreak-dopamine.md"
```

**ORCHARD-R2:** The MDM controller, the OS-update policy and any human **MUST NOT** be able to
upgrade a research device. These devices carry `labels: [no-auto-update, frozen]`, are excluded from
all update policy groups, and an attempted update is a **P1 incident**.

**Rootless is not a limitation for most work.** A modern rootless jailbreak still provides SSH,
process enumeration and control, `frida-server`, runtime injection, broad application-container
access, launch/service inspection, network tooling, a package bootstrap, root-helper processes and
system log access. What it gives up is free mutation of the sealed system volume — which does not
block most runtime-security research. [V]

**TrollStore** is a distinct capability, not a jailbreak: permanent installation of entitled
applications, arbitrary-entitlement experimentation, root-helper possibilities and JIT research on
supported versions — but explicitly **not** ordinary tweak injection into system processes. [V] It
carries no standard SPDX licence assertion upstream, so §14.5 requires legal review before it is
redistributed inside the platform.

### 5.5 Escalation to SRD and Corellium

| Asset | When to use | Constraints to model in the registry |
|---|---|---|
| **Apple SRD** | First-party target, within programme scope, programme access obtained | 12-month renewable loan; remains Apple's property; **must stay on participant premises**; access limited to authorised people; discovered vulnerabilities must be reported to Apple; Apple Pay and third-party apps excluded from ordinary scope [V] |
| **Corellium** | Root needed on **iOS ≥ 18 or A14+** where no physical jailbreak exists; or high-density modern-iOS research | Commercial licence; on-prem/air-gappable appliance; **no radios, no real Secure Enclave, no hardware fidelity** — complements, never replaces, physical devices |

**ORCHARD-R3:** SRD devices are their own class with their own policy gate. They are **not** pooled
with jailbroken devices, because programme conditions and eligible research scope differ.

### 5.6 Hardware bill of materials — per cell

| Item | Specification | Rationale |
|---|---|---|
| Mac worker | Apple silicon Mac, **64 GB RAM** (stock cell), **128 GB** (simulator cell), ≥ 2 TB NVMe | Xcode + DerivedData + traces + MJPEG buffers. 32 GB is the *minimum* engineering starting point, not a target. |
| USB hubs | Industrial managed hub with **per-port power control** and endpoint headroom | Per-port toggle is the single most valuable automated recovery primitive. |
| Cables | Short, labelled, quality, **individually asset-tracked** | A failed $10 cable becomes a fleet-management datum at 500 devices. |
| Power | Per-port 7.5–10 W charging | Battery management: keep devices in a 30–80% band for longevity. |
| PDU | Smart PDU with per-outlet control | Out-of-band worker power-cycle. Macs have no IPMI. |
| Network | Managed switch; separate device Wi-Fi VLAN + AP | Segmentation (§14.2) is enforced physically. |
| Environment | Rack with forced airflow, temperature monitoring | Thermal throttling silently corrupts performance measurements. |
| Out-of-band | USB/IP KVM per worker | Recovery when macOS itself is wedged. |
| DFU capability | One host port per target for DFU re-imaging | DFU does not pass through arbitrary hubs. |

**ORCHARD-H3:** Consumer USB hubs are prohibited in production cells. The recovery ladder (§6.5)
depends on programmatic per-port power control; without it, half the ladder degrades to "send a
human".

### 5.7 Physical inventory model

At 100+ devices, "device disconnected" must not become physical archaeology. The inventory tracks
the **full physical path**:

```mermaid
graph LR
  R["rack-a"] --> H["host controller<br/>on mac-worker-a1"]
  H --> HUB["hub-a1<br/>asset HUB-0007"]
  HUB --> PORT["port 4"]
  PORT --> CBL["cable asset CBL-0413<br/>installed 2026-08-02"]
  CBL --> DEV["lab-ios-0042<br/>slot A-12"]
  DEV --> META["UDID (restricted)<br/>model, chip, build,<br/>battery health,<br/>jailbreak state,<br/>last failure, replacements"]
```

Every recovery event writes to the component's history. A cable with three quarantine events in
30 days is auto-flagged for replacement **before** it causes a fourth false product bug.

### 5.8 Scaling stages

| Stage | Devices | Topology | Required additions |
|---|---|---|---|
| **POC** | 2 stock + 1 research + simulators | 1 worker, 1 hub | Nothing beyond Phase 1 deliverables |
| **Small** | 10–20 | 2+ workers, 2+ hubs, real failure domains from day one | Scheduler, fencing, health, CI integration, central artifacts, automated recovery |
| **Medium** | ~50 | Multiple cells, spare pool | NATS event transport, central OTel, auto-quarantine, automated USB/power recovery |
| **Production** | ~100 | Multi-rack, HA | Control-plane HA, DB HA + backups, dedicated signing service, worker draining, maintenance windows, capacity controller, replacement inventory |
| **Large** | 100–500+ | Cell/rack-aware sharding | Partitioned worker pools, capacity reservations, global + cell-local health, spare worker/device percentage, maintenance coordinator, network QoS, artifact lifecycle tiers, high-volume OTel sampling, component asset history |

**ORCHARD-H4:** Do not build a single flat "500 phones hanging off Macs" environment. Racks and cells
are schedulable fault domains, and the scheduler is cell-aware from Phase 3.

### 5.9 Device onboarding runbook (summary)

```mermaid
stateDiagram-v2
  [*] --> Received
  Received --> AssetTagged: record serial, model, chip, rack slot
  AssetTagged --> Pinned: set OS build, disable OTA via supervision
  Pinned --> Supervised: enrol MDM, apply lab profile
  Supervised --> DevModeOn: enable Developer Mode (manual, iOS 16+)
  DevModeOn --> Paired: pair + store pairing record in vault
  Paired --> NoPasscode: apply passcode policy (ADR-007)
  NoPasscode --> WDAProvisioned: install signed prebuilt WDA
  WDAProvisioned --> Certified: run onboarding conformance suite
  Certified --> Available: register capabilities, join pool
  Available --> [*]

  Pinned --> ResearchFreeze: research tier only
  ResearchFreeze --> Jailbroken: apply pinned jailbreak, verify build
  Jailbroken --> ResearchCertified: SSH + frida + reboot-recovery probe
  ResearchCertified --> Available
```

Steps that **cannot** be automated and must appear as explicit human tasks: initial Developer Mode
enablement (toggle + reboot on iOS 16+), first-time pairing trust where supervision is unavailable,
and signing certificate provisioning. Everything else is automated.

---

## §6. Control Plane

### 6.1 Services

| Service | Language | Responsibility | State |
|---|---|---|---|
| `orchard-registry` | Go | Device inventory, capability engine, physical topology, component asset history | PostgreSQL |
| `orchard-scheduler` | Go | Predicate compilation, ranking, leases, fencing, queues, priorities, affinity | PostgreSQL + NATS |
| `orchard-recovery` | Go | Recovery ladder, failure-domain classification, quarantine | NATS + PostgreSQL |
| `orchard-capacity` | Go | Worker admission limits, draining, maintenance windows, spare pool | PostgreSQL |
| `orchard-policy` | Go | RBAC, target scope, budgets, capability masking | PostgreSQL + policy files |
| `orchard-api` | Go | REST + gRPC, OpenAPI/proto source of truth | stateless |
| `orchard-mcp` | TypeScript | MCP gateway, tool generation from the API schema | stateless |
| `orchard-orchestrator` | Python | AI agent state machines, model routing, evidence assembly | PostgreSQL + S3 |
| `orchard-runner` | Go | Deterministic suite execution, matrix fan-out | NATS |
| `orchard-signing` | Go | Certificate/profile lifecycle, re-signing, expiry prediction | Vault + PostgreSQL |

**Why Go for the control plane:** static binaries, trivial cross-compilation to the macOS workers,
strong concurrency primitives for lease/fencing correctness, and — critically — **no GPL linkage
risk**, keeping pymobiledevice3 firmly on the far side of a subprocess boundary (§14.5).

**Why Python for the orchestrator:** the AI/agent ecosystem lives there, and the orchestrator is the
one component where iteration speed beats deployment simplicity.

### 6.2 Device registry schema

```yaml
device_id: lab-ios-0042          # stable, human-usable, never reused
udid: "<vault-reference>"        # restricted; never logged in plaintext
platform: ios
class: stock_developer

hardware:
  marketing_model: "iPhone 15 Pro"
  model_identifier: "iPhone16,1"
  chip_family: A17Pro
  serial_ref: "<vault-reference>"
  rack: rack-a
  slot: A-12

software:
  ios_version: "27.0"
  ios_build: "25A331"
  developer_mode: true
  supervised: true
  mdm_enrolled: true
  ota_policy: blocked

research:                         # null for stock tier
  jailbreak: null
  trollstore: false
  frida_server: false
  root_shell: false
  srd: false

topology:
  host_id: mac-worker-a1
  usb_controller: "controller-0"
  hub_id: HUB-0007
  hub_port: 4
  cable_asset: CBL-0413
  power_control: per_port

automation:
  wda_state: healthy
  wda_bundle_id: com.example.lab.WebDriverAgentRunner
  wda_build_hash: "sha256:7f3a..."
  provisioning_expires_at: "2026-10-04T00:00:00Z"
  remotexpc: available
  appium_driver_version: "9.x"

health:
  state: available               # see §6.4 lifecycle
  battery_percent: 74
  battery_health: 91
  thermal_state: nominal
  consecutive_failures: 0
  quarantine_reason: null
  last_probe_at: "2026-09-17T09:13:58Z"

lease:
  current_generation: 918
  holder: null

labels: [auth-test, no-passcode, no-auto-update]
```

**ORCHARD-REG1:** `udid` and `serial` are vault references, never plaintext columns. Evidence bundles
carry `device_id`, not UDID, unless the principal holds `lab_admin`.

**ORCHARD-REG2:** The worker continuously **reconciles** discovery views (`xcrun devicectl list
devices` as primary, `go-ios list` / `idevice_id -l` as cross-check) into the registry. A one-time
boot inventory is prohibited — devices appear, vanish and re-enumerate constantly.

### 6.3 Scheduler

#### 6.3.1 Predicate language

```text
platform = ios AND ios >= 27 AND class = stock_developer AND NOT label:passcode-required
platform = ios AND jailbroken = true AND frida = true AND chip_family in (A11, A13)
platform = ios AND model_identifier = "iPhone16,1" AND ios_build = "25A331"
capability:ios.network.capture = true AND capability:ios.trace.record = true
```

Predicates compile to a **capability predicate** first, then rank. Requesting a *capability* rather
than a *device attribute* is the preferred style and is what makes the fleet substitutable.

#### 6.3.2 Ranking

Eligible devices are ordered by:

```text
1. affinity        (same device as a prior run in this pipeline — reproduction fidelity)
2. health score    (consecutive_failures, recent recovery events, battery, thermal)
3. anti-affinity   (spread across cells for matrix runs, so one hub failure != whole matrix)
4. cell load       (prefer the least-loaded worker under its measured concurrency limit)
5. battery band    (prefer 40-80%; deprioritise <30%)
6. least-recently-used
```

#### 6.3.3 Lease semantics

| Property | Rule |
|---|---|
| Exclusivity | Exclusive by default. Shared/observer leases are read-only and never permit UI actions. |
| TTL | Required. Max 4 h. Default 45 min. |
| Renewal | Heartbeat at `ttl/3`. Missing two consecutive heartbeats revokes. |
| Fencing | Every grant increments `device.current_generation` monotonically. |
| Priority | `release-gate > ci > interactive > exploratory > background`. |
| Queue fairness | Aged queue: effective priority rises with wait time to prevent starvation. |
| Affinity | A pipeline may request the same device for reproduction; honoured if healthy and free. |
| Isolation | `test-history isolation` — a device that just ran a security/malware suite is not scheduled to a normal CI job until sanitised and re-imaged. |

**ORCHARD-SCH1:** A database row lock alone is **not** sufficient. Every device command carries the
lease generation; workers reject mismatches with `STALE_FENCE` (§2.7). This is a Phase-1 requirement,
not a Phase-3 nicety.

```sql
-- Grant is a single atomic transaction.
UPDATE devices
   SET current_generation = current_generation + 1,
       health_state       = 'leased',
       lease_holder       = $1,
       lease_expires_at   = now() + $2::interval
 WHERE device_id = $3
   AND health_state = 'available'
RETURNING current_generation;   -- this value is the fencing token
```

### 6.4 Device lifecycle state machine

```mermaid
stateDiagram-v2
  [*] --> onboarding
  onboarding --> available: conformance suite passes

  available --> leased: scheduler grants (gen++)
  leased --> sanitising: release or TTL expiry
  sanitising --> available: probe healthy
  sanitising --> recovering: probe fails

  leased --> recovering: adapter failure detected
  recovering --> available: ladder succeeded
  recovering --> quarantined: ladder exhausted

  available --> maintenance: scheduled window / OS pin change
  maintenance --> available: re-certified

  quarantined --> maintenance: SRE triage
  quarantined --> retired: hardware failure confirmed

  available --> draining: worker drain requested
  leased --> draining: drain after current lease
  draining --> offline: worker stopped
  offline --> onboarding: worker returns

  retired --> [*]

  note right of quarantined
    Quarantine writes to component
    asset history: hub, port, cable.
    3 events in 30d -> auto replace-flag.
  end note
```

### 6.5 Failure-domain taxonomy

The single highest-leverage idea for avoiding false product bugs. Every error, at every layer,
carries exactly one domain.

```mermaid
flowchart TD
  F["Failure observed"] --> C{"Classify"}
  C --> T1["TEST_FAILURE<br/>assertion failed"]
  C --> T2["APP_FAILURE<br/>app crashed / hung"]
  C --> T3["WDA_FAILURE<br/>runner dead, leak, port"]
  C --> T4["DEVICE_SERVICE_FAILURE<br/>installd, afc, tunnel, DVT"]
  C --> T5["USB_FAILURE<br/>enumeration, cable, hub, controller"]
  C --> T6["DEVICE_OS_FAILURE<br/>panic, springboard restart, thermal"]
  C --> T7["WORKER_FAILURE<br/>macOS, Xcode, disk, memory"]
  C --> T8["MODEL_FAILURE<br/>LLM timeout, budget, malformed tool call"]
  C --> T9["CONTROL_PLANE_FAILURE<br/>scheduler, registry, transport"]

  T1 --> R1["Report to developer<br/>as a product signal"]
  T2 --> R1
  T3 --> R2["Recovery ladder<br/>NEVER reported as a product bug"]
  T4 --> R2
  T5 --> R2
  T6 --> R2
  T7 --> R2
  T8 --> R3["Abort agent loop,<br/>capture state, escalate"]
  T9 --> R4["Page SRE"]

  style R1 fill:#2d6b3d,color:#fff
  style R2 fill:#6b3d2d,color:#fff
```

**ORCHARD-SCH2:** Only `TEST_FAILURE` and `APP_FAILURE` may appear in a developer-facing test report
as a product signal. Everything else is a platform event, is retried by the ladder, and is counted
against the platform's own SLOs.

### 6.6 Recovery ladder

Graduated, cheapest-first, with the cost of each rung recorded. **Never start at the bottom.**

```mermaid
flowchart TD
  A0["Action fails"] --> A1["1. Retry idempotent operation"]
  A1 -->|still failing| A2["2. Restart target app"]
  A2 --> A3["3. Restart WDA session"]
  A3 --> A4["4. Restart / relaunch WDA runner"]
  A4 --> A5["5. Reinstall WDA<br/>if build hash or signature wrong"]
  A5 --> A6["6. Repair RemoteXPC tunnel"]
  A6 --> A7["7. Reconnect usbmux forwarding"]
  A7 --> A8["8. Reset USB port<br/>managed hub power toggle"]
  A8 --> A9["9. Reboot iPhone"]
  A9 --> A10["10. Restart worker services"]
  A10 --> A11["11. Drain + reboot Mac worker"]
  A11 --> A12["12. Power-cycle worker via PDU"]
  A12 --> A13["13. Quarantine device + hub port + cable"]
  A13 --> A14["14. Human intervention ticket"]

  A1 -->|ok| OK["available"]
  A3 -->|ok| OK
  A8 -->|ok| OK

  style A8 fill:#2d4a6b,color:#fff
  style A14 fill:#6b2d2d,color:#fff
```

**ORCHARD-REC1:** Do not reboot a phone because a single element lookup timed out. Each rung requires
`n` consecutive failures at the rung above, and each rung has a budget: a device may consume at most
`3` rungs ≥ 8 per hour before automatic quarantine.

**ORCHARD-REC2:** Rung 8 (per-port power toggle) is the highest-value automated rung and the reason
ORCHARD-H3 prohibits consumer hubs.

**ORCHARD-REC3:** For `managed_supervised` devices, MDM provides a parallel destructive channel —
restart, shutdown, lock, erase, and Return to Service — used for wedged devices and for periodic
clean-slate reprovisioning. [V] MDM is **not** used for high-frequency UI execution.

Research-tier additions to the ladder:

```text
JB-1. SSH probe + frida-server health probe
JB-2. Re-run the jailbreak (semi-untethered: relaunch app; semi-tethered: re-tether)
JB-3. Verify boot build still equals verified_boot_build  -> mismatch = P1 incident
JB-4. Re-image from the pinned restore image + re-apply the freeze record
JB-5. Quarantine and escalate
```

### 6.7 Capacity controller

| Function | Behaviour |
|---|---|
| Admission | Per-worker `max_concurrent_sessions` by workload profile (measured, §11.3.1). A `trace` profile session counts as 3 `ui` sessions. |
| Draining | Mark worker `draining`; existing leases run to completion; new grants blocked. |
| Maintenance windows | Per-cell, calendared; devices leave the pool cleanly rather than failing mid-lease. |
| Spare pool | Phase 3+: maintain ≥ 10% spare devices per capability class so a quarantine does not break a matrix. |
| Capacity reservations | Phase 4: a release gate can reserve matrix capacity ahead of time. |
| Cell awareness | Phase 3+: anti-affinity spreads a matrix across cells; a cell outage degrades rather than fails a run. |

### 6.8 Policy & RBAC

```mermaid
graph TD
  subgraph Roles
    R1["viewer<br/>read registry, read evidence"]
    R2["developer<br/>+ reserve, app.*, ui.*, logs.*, crashes.*"]
    R3["debugger<br/>+ debug.* on OWN bundle IDs"]
    R4["security_researcher<br/>+ process.*, memory.*, instrument.*,<br/>shell.exec on APPROVED research devices"]
    R5["security_researcher_expert<br/>+ raw Frida scripts"]
    R6["lab_admin<br/>+ lifecycle, quarantine, maintenance, UDID"]
  end
  R1 --> R2 --> R3 --> R4 --> R5
  R6 -.-> R1

  subgraph Gates
    G1["role grant"]
    G2["device class match"]
    G3["target scope<br/>(bundle IDs, per engagement)"]
    G4["budget<br/>(steps, tokens, wall clock, cost)"]
    G5["time window<br/>(engagement validity)"]
  end

  R4 --> G1 --> G2 --> G3 --> G4 --> G5 --> ALLOW["execute + audit"]

  style R4 fill:#6b2d2d,color:#fff
  style G3 fill:#6b3d2d,color:#fff
```

**ORCHARD-POL1:** Deny by default. A capability absent from the contract is unreachable, not merely
discouraged.

**ORCHARD-POL2:** Privileged capabilities (`ios.shell.exec`, `ios.memory.*`, `ios.process.kill`,
`ios.instrument.attach` with raw scripts) require **all five gates**, and every invocation is written
to the immutable audit log with the engagement reference.

**ORCHARD-POL3:** No content rendered on an iPhone, present in a log, or returned by a tool may
change the caller's privileges. Policy decisions are made from the identity and the engagement
record only — never from model output. See §14.4.

---

## §7. The Mac Worker

### 7.1 Why the worker is bare metal

Apple tooling lives directly on macOS. **Containerising Xcode, CoreDevice and physical USB ownership
is the wrong abstraction.** Containers are correct for the Linux control-plane services and wrong for
the worker. A worker is provisioned by configuration management (§12.6), not by an image.

**ORCHARD-W1:** Do not replace Apple's host MobileDevice/usbmux plumbing with a third-party daemon on
macOS. The adapter selects the appropriate tool per operation; it does not fight the platform.

### 7.2 Worker components

```mermaid
graph TB
  subgraph Worker["orchard-worker (macOS, launchd)"]
    DM["device-monitor<br/>reconcile devicectl + go-ios views<br/>USB attach/detach events"]
    TM["tunnel-manager<br/>RSD/RemoteXPC lifecycle<br/>one tunnel per device"]
    PM["port-manager<br/>deterministic allocation of<br/>wdaLocalPort / mjpegServerPort"]
    SM["session-manager<br/>lease binding, fence check,<br/>Appium session lifecycle"]
    WL["wda-lifecycle<br/>install / verify / launch / probe / restart"]
    HP["health-prober<br/>battery, thermal, disk, WDA, tunnel"]
    CO["collectors<br/>syslog, crash, sysdiagnose, PCAP, xctrace"]
    AD["adapter layer<br/>typed, plane-aware"]
    EV["evidence-shipper<br/>content-addressed -> S3"]
  end

  NATS["NATS JetStream"] <--> SM
  DM --> REG["registry reconcile"]
  SM --> AD
  WL --> AD
  CO --> EV
  HP --> REG
  AD --> DEV["attached iPhones"]

  style AD fill:#2d4a6b,color:#fff
```

| Component | Responsibility | Failure behaviour |
|---|---|---|
| `device-monitor` | Continuous reconciliation of discovery views; USB attach/detach; topology mapping to hub+port | Emits `USB_FAILURE`; never trusts a boot-time inventory |
| `tunnel-manager` | Establishes and repairs the iOS 17+ RSD tunnel per device; runs as a privileged launchd daemon | Emits `DEVICE_SERVICE_FAILURE`; ladder rung 6 |
| `port-manager` | Deterministic, collision-free `wdaLocalPort` / `mjpegServerPort` / `derivedDataPath` per device | Port collision is a config bug, never a runtime race |
| `session-manager` | Validates the fencing token on **every** command; owns Appium session state | Rejects stale generations with `STALE_FENCE` |
| `wda-lifecycle` | WDA state machine (§7.5), build-hash and provisioning-expiry tracking | Ladder rungs 3–5 |
| `health-prober` | Periodic probes feeding the capability engine's TTL'd cache | Degrades capabilities before a job discovers the failure |
| `collectors` | Log/crash/sysdiagnose/PCAP/trace capture, streamed not buffered | Backpressure-aware; never fills the worker disk |
| `adapter layer` | The only code that touches external tools | Records which adapter served each call |
| `evidence-shipper` | Content-addressed upload with local spooling | Survives control-plane outage; never loses evidence |

### 7.3 The adapter layer

**ORCHARD-W2:** No business logic calls `devicectl`, `go-ios`, `pymobiledevice3`, Appium or Frida
directly. All access is through a typed interface with a declared preference order per operation.

```go
// adapters/iface.go  (illustrative)
type DeviceServices interface {
    List(ctx context.Context) ([]DeviceRef, error)
    InstallApp(ctx context.Context, d DeviceRef, ipa ArtifactRef) (InstallResult, error)
    LaunchApp(ctx context.Context, d DeviceRef, bundleID string, opts LaunchOpts) (ProcRef, error)
    StreamSyslog(ctx context.Context, d DeviceRef, sink EventSink) (Closer, error)
    CollectCrashes(ctx context.Context, d DeviceRef, since time.Time) ([]ArtifactRef, error)
    CapturePackets(ctx context.Context, d DeviceRef, sink EventSink) (Closer, error)
    Reboot(ctx context.Context, d DeviceRef) error
}

// Every result records provenance.
type InstallResult struct {
    OK           bool
    AdapterUsed  string        // "devicectl" | "go-ios" | "libimobiledevice" | "pymobiledevice3"
    Grade        string        // "V" | "E" | "C"
    Duration     time.Duration
    RawLogRef    ArtifactRef
}
```

**Preference order per operation** (ADR-003). The adapter tries in order, records which path served
the call, and emits a metric on every fallback so that adapter drift is visible **before** it becomes
an outage:

| Operation | 1st | 2nd | 3rd | 4th |
|---|---|---|---|---|
| Discover | `devicectl` [V] | `go-ios` [C] | `idevice_id` [V] | — |
| Install / uninstall | `devicectl` [V] | `go-ios` [C] | `ideviceinstaller` [V] | — |
| Launch / terminate | `devicectl` [V] | WDA/XCTest [V] | `go-ios` [C] | — |
| RSD tunnel | `devicectl` (native) [V] | `go-ios tunnel` [C] | `pymobiledevice3 tunneld` [E] | — |
| Syslog / OSLog | `idevicesyslog` [V] | `go-ios` [C] | `pymobiledevice3` [E] | — |
| Crash reports | `idevicecrashreport` [V] | `go-ios` [C] | `pymobiledevice3` [E] | — |
| sysdiagnose | `pymobiledevice3` [E] | `idevicediagnostics` [V] | — | — |
| PCAP | `pymobiledevice3` [E] | RVI + `tcpdump` [V] | — | — |
| Profiling | `xctrace` [V] | `pymobiledevice3` DVT [E] | — | — |
| Reboot / shutdown | MDM [V] | `idevicediagnostics` [V] | `go-ios` [C] | shell (research) |
| UI actions | Appium XCUITest → WDA [V] | — | — | — |
| Instrumentation | `frida-server` (research) [V] | Frida Gadget (jailed, own app) [V] | LLDB [V] | — |

**ORCHARD-W3:** `pymobiledevice3` runs **only** as a subprocess in its own virtualenv, never as an
imported library, for both licence isolation (§14.5) and protocol-churn blast-radius containment.

### 7.4 Worker bootstrap

```bash
#!/bin/zsh
# orchard/deployment/macos/bootstrap.sh
# NOTE: every version below is PINNED in deployment/macos/versions.lock.
set -euo pipefail

# --- Preconditions: Apple toolchain installed and selected by config management.
xcode-select -p
xcodebuild -version
xcrun devicectl --help >/dev/null
xcrun xctrace version

# --- Open-source supporting tools (pinned via a private Homebrew tap).
brew install \
  orchard/tap/libimobiledevice \
  orchard/tap/libusbmuxd \
  orchard/tap/go-ios \
  orchard/tap/node \
  orchard/tap/python

# --- Appium 3 + XCUITest driver, pinned.
npm install -g "appium@${APPIUM_VERSION}"
appium driver install --source=npm "appium-xcuitest-driver@${XCUITEST_DRIVER_VERSION}"

# --- pymobiledevice3 isolated: separate venv, subprocess-only (ORCHARD-W3 / §14.5).
python3 -m venv /opt/orchard/venv-pmd3
/opt/orchard/venv-pmd3/bin/pip install \
  "pymobiledevice3==${PMD3_VERSION}"

# --- Frida tooling: research workers ONLY.
if [[ "${ORCHARD_WORKER_CLASS}" == "research" ]]; then
  python3 -m venv /opt/orchard/venv-frida
  /opt/orchard/venv-frida/bin/pip install "frida-tools==${FRIDA_TOOLS_VERSION}"
fi

# --- Worker daemon + privileged tunnel daemon.
install -m 0755 ./orchard-worker /usr/local/bin/orchard-worker
sudo cp com.orchard.worker.plist       /Library/LaunchDaemons/
sudo cp com.orchard.tunneld.plist      /Library/LaunchDaemons/
sudo launchctl bootstrap system /Library/LaunchDaemons/com.orchard.tunneld.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.orchard.worker.plist

/usr/local/bin/orchard-worker selftest --strict
```

**ORCHARD-W4:** `versions.lock` pins Xcode, Appium, the XCUITest driver, go-ios, libimobiledevice,
pymobiledevice3, Frida and the WDA commit. An unpinned worker is not a worker; it is a variable.

### 7.5 WDA lifecycle state machine

```mermaid
stateDiagram-v2
  [*] --> NO_WDA
  NO_WDA --> INSTALLING: install signed prebuilt WDA
  INSTALLING --> INSTALLED: bundle present
  INSTALLED --> DDI_READY: mount / verify developer services
  DDI_READY --> TUNNEL_READY: establish RemoteXPC if required
  TUNNEL_READY --> LAUNCHING: launch runner
  LAUNCHING --> PROBING: HTTP /status on wdaLocalPort
  PROBING --> READY: 200 + expected build hash
  READY --> IN_SESSION: lease bound
  IN_SESSION --> READY: session closed, state cleared

  PROBING --> REPAIR: probe fail
  IN_SESSION --> REPAIR: request timeout / crash
  READY --> REPAIR: scheduled restart (leak mitigation)

  REPAIR --> LAUNCHING: relaunch runner
  REPAIR --> INSTALLING: build hash or signature mismatch
  REPAIR --> TUNNEL_READY: tunnel refresh
  REPAIR --> QUARANTINE: repeated failure budget exhausted

  READY --> EXPIRING: provisioning_expires_at < 14 days
  EXPIRING --> INSTALLING: signing service re-provisions
  QUARANTINE --> [*]

  note right of EXPIRING
    Expiry is a PREDICTED maintenance
    event, never a surprise CI outage.
  end note
```

**ORCHARD-W5:** Prefer **preinstalled / prebuilt WDA** over per-session `xcodebuild`. Rebuilding per
session costs seconds of startup and a persistent resident footprint per live instance. [C]

**ORCHARD-W6:** WDA is restarted on a schedule (default every 4 h of cumulative session time, tunable
per measured data) to mitigate long-session memory growth. [C] The scheduled restart happens between
leases, never inside one.

**ORCHARD-W7:** The worker tracks `wda_build_hash` and `provisioning_expires_at` in a local durable
store and reports both to the registry on every health probe. Expiry within 14 days degrades the
`ios.ui.*` capabilities in the contract with an explicit `degraded` entry (§3.4.1) so that schedulers
and agents can route around it.

### 7.6 Session configuration

```json
{
  "platformName": "iOS",
  "appium:automationName": "XCUITest",
  "appium:udid": "<from vault, never logged>",
  "appium:bundleId": "com.example.internalapp",

  "appium:usePreinstalledWDA": true,
  "appium:updatedWDABundleId": "com.example.lab.WebDriverAgentRunner",
  "appium:prebuiltWDAPath": "/opt/orchard/wda/WebDriverAgentRunner-Runner.app",

  "appium:wdaLocalPort": 8117,
  "appium:mjpegServerPort": 9117,
  "appium:derivedDataPath": "/var/lib/orchard/sessions/lease-abc123",

  "appium:newCommandTimeout": 120,
  "appium:wdaLaunchTimeout": 90,
  "appium:shouldTerminateApp": true,
  "appium:eventTimings": true
}
```

**ORCHARD-W8:** `wdaLocalPort`, `mjpegServerPort` and `derivedDataPath` are allocated deterministically
by `port-manager` from the device's stable slot index — `8100 + idx` and `9100 + idx`. Sharing MJPEG
ports causes video cross-talk between sessions. [V]

### 7.7 Instrumentation adapter

```bash
# Research device baseline probes (research workers only).
frida-ls-devices
frida-ps -U
frida-ps -Uai

# Reviewed trace template, never a raw script from an agent.
frida-trace -U -f com.example.internalapp -i 'CCCrypt*'
```

**ORCHARD-W9:** Raw Frida JavaScript is a privileged expert feature
(`security_researcher_expert`). Autonomous tasks invoke **reviewed, versioned trace templates** from
`workflows/security/templates/`, which are code-reviewed like any other source.

Frida output is normalised into the evidence event schema:

```json
{
  "type": "frida.function",
  "schema_version": 1,
  "task_id": "tsk_01J...",
  "device_id": "lab-ios-0042",
  "template": "crypto-primitives@v3",
  "pid": 1234,
  "module": "ExampleFramework",
  "symbol": "CCCrypt",
  "timestamp": "2026-09-17T09:31:02.118Z",
  "arguments": [{"index": 0, "representation": "kCCEncrypt"}]
}
```

**Jailed-device reality check [V]:** on a non-jailbroken device, Frida works only via a Gadget
embedded in an application you can re-sign, it instruments **only that app**, and the jailed
code-signing mode restricts `Interceptor` unless an appropriate debugger/debuggable state was
established first. Gadget-patched apps crashing on launch on recent jailed iOS is a reported
community failure mode. [C] The capability contract advertises this as
`scope: "eligible-app-gadget-or-debugger"` and **never** as general instrumentation.

### 7.8 Research-worker connection policy

```mermaid
graph LR
  AG["AI / MCP"] --> GW["MCP gateway<br/>control plane VLAN"]
  GW --> BR["Research broker<br/>outbound-initiated only"]
  BR --> WR["Research worker<br/>disposable, reimageable"]
  WR -->|key-only SSH<br/>research VLAN| JB["Jailbroken iPhone"]
  JB -.->|NO inbound route| GW

  style JB fill:#6b2d2d,color:#fff
  style WR fill:#6b2d2d,color:#fff
```

**ORCHARD-W10:** Research workers hold **no** signing credentials, share **no** hub with the stock
tier, initiate all control-plane connections outbound, and have disposable filesystems that are
re-imaged after any security run. A jailbroken iPhone is potentially hostile infrastructure and is
modelled as such.

---

## §8. API, CLI & MCP Surface

### 8.1 One semantic API, three bindings

```mermaid
graph TD
  SRC["api/openapi/orchard.yaml<br/>+ api/protobuf/*.proto<br/>+ api/capability-model/*.json<br/><b>SINGLE SOURCE OF TRUTH</b>"]
  SRC -->|codegen| REST["REST / gRPC server"]
  SRC -->|codegen| CLI["labctl"]
  SRC -->|codegen| MCP["MCP tool definitions"]
  SRC -->|codegen| SDK["Go / Python / TS clients"]
  SRC -->|codegen| DOC["Reference docs"]

  MCP --> CC["Claude Code"]
  MCP --> OC["OpenCode"]
  CLI --> CI["CI systems"]
  REST --> OTHER["Internal services"]

  style SRC fill:#2d4a6b,color:#fff
```

**ORCHARD-API1:** MCP tools, CLI verbs and REST routes are **generated** from one schema. A
hand-written MCP tool that does not exist in the API is a defect. This is what keeps three consumers
identical and prevents the MCP surface from silently becoming a second, weaker API.

### 8.2 The semantic API

```text
# Fleet & leases
devices.list                devices.query               devices.get
devices.reserve             devices.renew               devices.release
devices.health              devices.quarantine          devices.maintenance
devices.capabilities        # -> the capability contract (§3.4)

# Application lifecycle
ios.app.install             ios.app.uninstall           ios.app.launch
ios.app.stop                ios.app.restart             ios.app.list
ios.app.container.list      ios.app.container.read      ios.app.container.write

# UI plane
ios.ui.inspect              ios.ui.screenshot           ios.ui.record
ios.ui.tap                  ios.ui.type                 ios.ui.swipe
ios.ui.long_press           ios.ui.orientation          ios.ui.stream

# Diagnostics plane
ios.logs.start              ios.logs.stop               ios.logs.search
ios.crashes.collect         ios.diagnostics.collect     ios.metrics.collect
ios.network.capture

# Debug & profile plane
ios.debug.attach            ios.debug.command           ios.debug.detach
ios.trace.record            ios.trace.templates

# Privileged research plane  (contract-gated, RBAC-gated, scope-gated)
ios.process.list            ios.process.inspect         ios.process.kill
ios.memory.read             ios.instrument.attach       ios.instrument.trace
ios.shell.exec

# Management plane
ios.mdm.restart             ios.mdm.shutdown            ios.mdm.lock
ios.mdm.erase               ios.mdm.return_to_service   ios.mdm.profile.apply

# Execution & evidence
test.run                    test.matrix                 investigate.start
evidence.get                evidence.list               runs.get
```

**ORCHARD-API2:** The surface is intentionally ADB-*shaped* for ergonomics. Every verb that stock iOS
cannot honour returns `CAPABILITY_UNAVAILABLE` with remediation (§3.5) — never a workaround, never a
silent no-op, never a partial success.

### 8.3 `labctl` — the deterministic interface

```bash
# Discovery
labctl devices list --where 'platform=ios AND ios>=27' --output table
labctl devices capabilities lab-ios-0042 --output json

# Lease lifecycle (fencing token is carried in the lease file/env)
LEASE=$(labctl devices reserve \
          --where 'platform=ios AND ios>=27 AND class=stock_developer' \
          --ttl 45m --priority ci --output lease-id)

labctl ios app install  --lease "$LEASE" --artifact build/MyApp.ipa
labctl ios app launch   --lease "$LEASE" --bundle com.example.internalapp
labctl ios logs start   --lease "$LEASE" --predicate 'subsystem == "com.example"'
labctl test run         --lease "$LEASE" --suite auth-regression \
                        --collect logs,crashes,screenshots,traces
labctl investigate      --lease "$LEASE" --on-failure --model-class MID
labctl evidence get     --run "$RUN" --output ./evidence
labctl devices release  "$LEASE"

# Admin
labctl admin worker drain mac-worker-a1
labctl admin device quarantine lab-ios-0042 --reason "cable CBL-0413 suspect"
labctl admin capacity show --cell rack-a
```

**The canonical CI job** — vendor-neutral, safe under any failure:

```bash
#!/usr/bin/env bash
set -euo pipefail

LEASE=""
cleanup() { [[ -n "${LEASE}" ]] && labctl devices release "${LEASE}" || true; }
trap cleanup EXIT

LEASE="$(labctl devices reserve \
  --where 'platform=ios AND ios>=27 AND developer_mode=true' \
  --ttl 45m --priority ci --output lease-id)"

labctl ios app install --lease "${LEASE}" --artifact build/MyApp.ipa

labctl test run --lease "${LEASE}" \
  --suite auth-regression \
  --collect logs,crashes,screenshots

labctl investigate --lease "${LEASE}" --on-failure --model-class MID
```

**ORCHARD-API3:** `labctl` auto-renews the lease in the background for the life of the process and
aborts the job immediately on `STALE_FENCE`. A CI job must never be able to keep driving a device it
no longer owns.

### 8.4 MCP gateway

Transport: **Streamable HTTP** — required, because stdio is per-user and local and cannot serve a
shared multi-user lab.

```mermaid
sequenceDiagram
  participant H as Harness Claude Code or OpenCode
  participant G as MCP Gateway
  participant P as Policy
  participant C as Capability Engine
  participant A as REST API

  H->>G: initialize
  G->>P: authenticate bearer token -> principal
  P-->>G: role=developer, engagements=[...]
  H->>G: tools/list
  G->>C: contracts for all leased devices of this principal
  C-->>G: per-device capability contracts
  G-->>H: tool list = intersection(API surface, contract, role)
  Note over G,H: Unsupported tools are ABSENT,<br/>not present-and-failing.

  H->>G: tools/call ios.ui.tap{lease, x, y}
  G->>P: authorise(principal, capability, device, scope)
  P-->>G: allow
  G->>A: POST /v1/leases/{id}/ui/tap
  A-->>G: result + evidence refs
  G-->>H: content + structured result
  Note over G: Tool OUTPUT is fenced as untrusted (§14.4)
```

#### 8.4.1 MCP server decomposition

| Server | Tools | Minimum role |
|---|---|---|
| `orchard-devices` | `devices.*` | viewer / developer |
| `orchard-ui` | `ios.ui.*`, `ios.app.*` | developer |
| `orchard-diagnostics` | `ios.logs.*`, `ios.crashes.*`, `ios.diagnostics.*`, `ios.metrics.*`, `ios.network.capture` | developer |
| `orchard-debug` | `ios.debug.*`, `ios.trace.*` | debugger |
| `orchard-instrumentation` | `ios.process.*`, `ios.memory.*`, `ios.instrument.*`, `ios.shell.exec` | security_researcher |
| `orchard-management` | `ios.mdm.*` | lab_admin |

Separate servers exist so a principal's client never even *negotiates* a server it cannot use.

#### 8.4.2 Claude Code configuration

```json
{
  "mcpServers": {
    "orchard-devices": {
      "type": "http",
      "url": "https://orchard.internal/mcp/devices",
      "headers": { "Authorization": "Bearer ${ORCHARD_TOKEN}" }
    },
    "orchard-ui": {
      "type": "http",
      "url": "https://orchard.internal/mcp/ui",
      "headers": { "Authorization": "Bearer ${ORCHARD_TOKEN}" }
    },
    "orchard-diagnostics": {
      "type": "http",
      "url": "https://orchard.internal/mcp/diagnostics",
      "headers": { "Authorization": "Bearer ${ORCHARD_TOKEN}" }
    },
    "orchard-debug": {
      "type": "http",
      "url": "https://orchard.internal/mcp/debug",
      "headers": { "Authorization": "Bearer ${ORCHARD_TOKEN}" }
    }
  }
}
```

#### 8.4.3 OpenCode configuration

OpenCode uses a **different schema**. Do not paste Claude Code blocks unchanged: top-level `mcp` (not
`mcpServers`), `local`/`remote` types, `command` as an array, `environment` (not `env`).

```json
{
  "mcp": {
    "orchard-devices": {
      "type": "remote",
      "url": "https://orchard.internal/mcp/devices",
      "enabled": true,
      "headers": { "Authorization": "Bearer {env:ORCHARD_TOKEN}" }
    },
    "orchard-ui": {
      "type": "remote",
      "url": "https://orchard.internal/mcp/ui",
      "enabled": true
    }
  }
}
```

**ORCHARD-API4:** Client configuration schemas evolve independently of the MCP protocol. Both
configurations are **Phase-0 validated** and pinned in `docs/compatibility/`, and a conformance test
(§11.5) asserts both clients can list and call tools on every release.

### 8.5 Tool design rules for agent efficiency

| Rule | Rationale |
|---|---|
| **Accessibility tree first, screenshots as fallback.** | A11y snapshots are cheap, structured and diffable; images cost tokens and latency. Both research passes independently identified this as the correct default. |
| **Return stable element references, not raw coordinates.** | Coordinates break on layout change; a11y identifiers survive. |
| **Once an element has a stable identifier, subsequent actions skip vision entirely.** | Not every tool call needs a vision model. |
| **Paginate and cap.** | `ios.ui.inspect` returns a bounded subtree, never an unbounded dump. |
| **Every tool returns evidence refs, not blobs.** | Agents get `artifact://sha256:...`; humans and the report renderer resolve them. |
| **Every tool result carries `failure_domain`.** | Prevents an agent from reporting a `WDA_FAILURE` as a product bug. |
| **Idempotency keys on mutating calls.** | Retries are safe by construction. |

### 8.6 Model gateway integration

All inference goes through **LiteLLM**, addressed by **capability class**, never by model brand.

```yaml
# deployment/litellm/model-classes.yaml
model_classes:
  LOW:
    alias: orchard-low
    purposes: [log_classification, device_selection, simple_planning, known_error_triage]
  MID:
    alias: orchard-mid
    purposes: [ui_exploration, test_generation, screenshot_reasoning, ordinary_investigation]
  HIGH:
    alias: orchard-high
    purposes: [cross_device_root_cause, complex_debugging, trace_analysis, security_hypothesis]
```

**ORCHARD-API5:** The orchestrator records **both** the logical class and the **resolved model
identifier returned by the gateway** on every call. Aliases are remapped over time; without the
resolved identifier, historic runs become unauditable.

---

## §9. AI Orchestration

### 9.1 The governing principle

> **AI explores and investigates. Deterministic engines gate releases.**

Contemporary mobile-agent research is nowhere near deterministic-test reliability, particularly for
complex multi-application tasks; agent architecture matters as much as the underlying model. [R]
Independently, the economics say the same thing: a stable login regression must not consume 200
vision-model turns on every CI run.

**ORCHARD-AI1:** No release gate may depend on a non-deterministic agent decision. An agent may
*discover* or *repair* a test; a deterministic engine then *owns* it.

### 9.2 Four execution modes

```mermaid
flowchart LR
  subgraph Gate["Release gate — deterministic only"]
    M1["Mode 1: Deterministic regression<br/>XCUITest / Appium / DSL<br/>AI: none, or failure summarisation"]
  end
  subgraph Explore["Discovery — AI-assisted"]
    M2["Mode 2: Property / fuzz<br/>AI proposes invariants + seeds<br/>engine executes"]
    M3["Mode 3: AI exploratory testing<br/>unknown paths, state discovery"]
  end
  subgraph Diagnose["Diagnosis — AI-led"]
    M4["Mode 4: AI failure investigation<br/>cross-device, logs, traces, hypotheses"]
  end

  M3 -->|persist discovered flow| M1
  M2 -->|persist counterexample| M1
  M4 -->|persist regression test| M1

  style Gate fill:#2d6b3d,color:#fff
  style M4 fill:#2d4a6b,color:#fff
```

**The ratchet (ORCHARD-AI2):** every mode-2/3/4 discovery that proves real **must** be persisted as a
deterministic artifact — an XCUITest, an Appium test, a workflow-DSL flow, a generated property test,
or a Maestro flow *once* physical-iOS support clears its Phase-0 gate. "AI discovers, the
deterministic system remembers" is the pattern that keeps inference cost bounded as coverage grows.

### 9.3 Agent roles and the investigation loop

```mermaid
flowchart TD
  G["GOAL or CI FAILURE"] --> PL["Planner<br/>decompose, pick modes,<br/>build device predicate"]
  PL --> SQ["Scheduler query<br/>+ capability negotiation"]
  SQ --> DB["Deterministic baseline<br/>run known suites first"]
  DB --> EX["Explorer<br/>a11y tree first,<br/>screenshot fallback,<br/>build coverage/state map"]
  EX --> INV["Investigator"]

  INV --> I1["logs + crash reports"]
  INV --> I2["xctrace / Instruments"]
  INV --> I3["LLDB on eligible target"]
  INV --> I4["Frida on authorised research target"]
  INV --> I5["comparison device<br/>different iOS / model"]

  I1 & I2 & I3 & I4 & I5 --> HY["Hypothesis engine"]
  HY --> RP["Targeted reproduction<br/>+ counterexample on control device"]
  RP --> VF["Verifier<br/>INDEPENDENT confirmation"]
  VF -->|confirmed| CL["Classify:<br/>APP / OS-version / DEVICE / INFRA"]
  VF -->|refuted| HY
  CL --> EV["Evidence bundle + report"]
  EV --> RT["Ratchet: emit deterministic<br/>regression test"]
  RT --> REL["Release device"]

  style VF fill:#6b3d2d,color:#fff
  style RT fill:#2d6b3d,color:#fff
```

| Role | Mandate | Hard limit |
|---|---|---|
| **Planner** | Decompose the goal, choose execution modes, compile the device predicate, set budgets. | Cannot execute device actions. |
| **Explorer** | Map UI and state. A11y tree first; screenshots only when the tree is insufficient. | Read-mostly; destructive actions require explicit allowance. |
| **Investigator** | Collect logs, crashes, traces; attach debugger/instrumentation within scope; form hypotheses; reproduce across devices and OS versions. | Privileged tools only where the contract and RBAC allow. |
| **Security** | Drive Frida/LLDB/PCAP on authorised targets on research devices. | Reviewed templates only unless `security_researcher_expert`. |
| **Verifier** | Independently confirm or refute a hypothesis and produce auditable evidence. | **Must not be the same agent instance that formed the hypothesis.** |

**ORCHARD-AI3:** The verifier is structurally separate. An exploratory agent may **not** declare its
own hypothesis proven because one action produced an expected screenshot. Confirmation requires an
independent run, ideally on a control device.

**ORCHARD-AI4:** Root-cause classification must always choose between **app / OS-version / device /
infrastructure**, and an `INFRA` classification is cross-checked against the failure-domain taxonomy
(§6.5) before it can be reported as anything else.

### 9.4 Model escalation

```mermaid
stateDiagram-v2
  [*] --> LOW
  LOW --> MID: UI reasoning or ambiguity required
  MID --> HIGH: repeated hypotheses fail
  MID --> HIGH: cross-version behaviour conflicts
  MID --> HIGH: LLDB / Frida traces need interpretation
  MID --> HIGH: security analysis requested
  MID --> HIGH: confidence below threshold
  HIGH --> [*]: conclusion + evidence
  LOW --> [*]: trivially classified
  MID --> [*]: resolved

  note right of HIGH
    Escalation is EVIDENCE-DRIVEN,
    never a default. Every transition
    is logged with its trigger.
  end note
```

**ORCHARD-AI5:** Escalation is logged with its trigger, its cost and its outcome, so escalation
policy can be tuned from data rather than intuition.

### 9.5 Budgets and kill switches

| Budget | Default | Enforced at |
|---|---|---|
| Steps per task | 120 | Orchestrator |
| Wall clock per task | 30 min | Orchestrator + lease TTL |
| Tokens per task | class-dependent | LiteLLM key |
| Cost per task | configurable | LiteLLM key |
| Tool calls per device per minute | 60 | MCP gateway |
| Privileged tool calls per engagement | explicit | Policy |
| Global kill switch | — | Control plane; terminates all agent loops and releases leases |

**ORCHARD-AI6:** A budget breach is `POLICY_BUDGET_EXCEEDED`, which **aborts the loop, captures full
state, releases the device and escalates**. It never silently truncates the task, because a
half-finished autonomous run that reports success is worse than one that fails.

### 9.6 Result caching

Cache agent conclusions keyed on `(normalised UI tree hash, goal hash, app artifact sha256, iOS
build)`. An identical screen with an identical goal on an identical build **must not** re-invoke
inference. This is the single largest cost lever in the system and is a Phase-2 deliverable.

### 9.7 Replay and determinism honesty

**ORCHARD-AI7:** "Replayable" means **evidence-complete and reconstructable** — not that an LLM will
emit byte-identical decisions. The evidence bundle captures the full action/observation sequence, all
inputs, all tool results and all model metadata, so a human or another agent can follow exactly what
happened and why. Claiming bitwise determinism for an LLM-driven run would violate ORCHARD-P1 just as
surely as claiming a shell on stock iOS.

### 9.8 Prompt-injection defence

Screenshots, UI text, log lines, crash strings, web content and tool output are **adversarial
inputs**. A malicious or merely unlucky application can render text that reads like an instruction.

```mermaid
flowchart LR
  APP["App UI text / logs /<br/>web content / tool output"] --> FENCE["Untrusted-content fence<br/>explicit delimiters +<br/>provenance labels"]
  FENCE --> LLM["Model context"]
  LLM --> PROP["Proposed tool call"]
  PROP --> POL["Policy engine<br/>identity + engagement only"]
  POL -->|allow| EXEC["Execute"]
  POL -->|deny| DENY["403 NOT_AUTHORISED<br/>logged as injection candidate"]

  X["Model output"] -.->|MUST NOT influence| POL

  style FENCE fill:#6b3d2d,color:#fff
  style POL fill:#2d4a6b,color:#fff
```

**ORCHARD-AI8:** Privilege is derived exclusively from the authenticated principal and the engagement
record. **No content observed on a device may alter it.** Denials that correlate with unusual
on-screen text are logged as injection candidates and reviewed.

### 9.9 Worked example — autonomous cross-device investigation

```mermaid
sequenceDiagram
  autonumber
  participant CI
  participant O as Orchestrator
  participant S as Scheduler
  participant D1 as D1 iPhone 15 Pro iOS 27.0
  participant D2 as D2 iPhone 13 iOS 26.4
  participant V as Verifier
  participant E as Evidence

  CI->>O: auth-regression failed on D1, investigate (MID)
  O->>D1: collect crash reports + OSLog window
  D1-->>O: no crash — OSLog shows keychain error -34018
  O->>O: hypothesis H1 = entitlement/provisioning regression
  O->>O: escalate MID -> HIGH (trace interpretation required)
  O->>D1: xctrace record (template: app-launch)
  D1-->>O: trace artifact
  O->>S: reserve comparison device, ios < 27, same app build
  S-->>O: lease D2 gen=412
  O->>D2: install same artifact sha256, run same suite
  D2-->>O: PASSES
  O->>O: refine H1 -> OS-version-specific regression on iOS 27
  O->>V: verify H1 independently
  V->>D1: fresh install, minimal repro flow
  D1-->>V: reproduces deterministically (3/3)
  V->>D2: same minimal flow
  D2-->>V: does not reproduce (0/3)
  V-->>O: H1 CONFIRMED, classification = OS_VERSION
  O->>E: evidence bundle + generated XCUITest minimal repro
  O->>S: release both leases
  O-->>CI: report + artifact://sha256:... + regression test PR
```

Note what the platform did *not* do: it did not attempt a shell, it did not guess, and it did not let
the agent that formed the hypothesis also certify it.

---

## §10. Repository Structure & Engineering Standards

### 10.1 Repository strategy — one monorepo, three satellites

```mermaid
graph TB
  MONO["<b>orchard</b> — monorepo<br/>API, control plane, worker, adapters,<br/>MCP, CLI, agents, deployment, docs"]
  R1["<b>orchard-wda</b><br/>pinned WDA fork + build/sign pipeline<br/>separate release cadence"]
  R2["<b>orchard-research</b><br/>PRIVATE. jailbreak runbooks,<br/>Frida templates, engagement records"]
  R3["<b>orchard-tap</b><br/>Homebrew tap: pinned third-party builds"]

  MONO -->|consumes signed artifact| R1
  MONO -->|consumes reviewed templates| R2
  MONO -->|provisions workers from| R3

  style MONO fill:#2d4a6b,color:#fff
  style R2 fill:#6b2d2d,color:#fff
```

**Why a monorepo for the core:** the API schema is the source of truth for the server, the CLI, the
MCP gateway and every SDK (§8.1). Splitting them guarantees version skew between an MCP tool and the
endpoint behind it — the exact failure this architecture exists to prevent.

**Why the three satellites are separate:**

| Repo | Reason for separation |
|---|---|
| `orchard-wda` | Tracks upstream WebDriverAgent on its own cadence; the build produces a **signed** artifact with its own provenance chain and its own signing identity, which must not be reachable from the main build. |
| `orchard-research` | **Private, restricted access.** Contains jailbreak procedures, Frida templates, target scopes and engagement records. Different audience, different retention, different legal posture (§14.5). |
| `orchard-tap` | Pinned third-party binaries for worker provisioning; changes on a supply-chain cadence, not a product cadence. |

### 10.2 Monorepo layout

```text
orchard/
├── api/                              # SOURCE OF TRUTH — everything else is generated
│   ├── openapi/orchard.yaml
│   ├── protobuf/orchard/v1/*.proto
│   ├── capability-model/
│   │   ├── capabilities.json         # canonical capability registry
│   │   ├── device-classes.json
│   │   └── contract.schema.json
│   ├── errors/errors.yaml            # §3.5 taxonomy, single definition
│   └── gen/                          # checked-in generated code (reviewable diffs)
│
├── control-plane/
│   ├── cmd/                          # orchard-api, -scheduler, -registry, -recovery,
│   │                                 # -capacity, -policy, -runner, -signing
│   ├── internal/
│   │   ├── registry/                 # inventory, topology, component asset history
│   │   ├── capability/               # the capability engine (§3.4)
│   │   ├── scheduler/                # predicates, ranking, leases, FENCING
│   │   ├── recovery/                 # ladder + failure-domain classifier
│   │   ├── capacity/                 # admission, draining, maintenance, spares
│   │   ├── policy/                   # RBAC, target scope, budgets
│   │   ├── evidence/                 # bundle assembly, content addressing
│   │   └── transport/                # NATS, gRPC, HTTP
│   └── migrations/                   # versioned SQL
│
├── worker-macos/
│   ├── cmd/orchard-worker/
│   ├── internal/
│   │   ├── devicemonitor/  tunnelmanager/  portmanager/
│   │   ├── sessionmanager/ wdalifecycle/   healthprober/
│   │   ├── collectors/     evidenceshipper/
│   │   └── fence/                    # generation validation — security-critical
│   └── testdata/
│
├── adapters/                         # THE ONLY code that shells out to external tools
│   ├── iface/                        # typed interfaces + provenance types
│   ├── appledevice/                  # devicectl, simctl, xcodebuild, xctrace, xcresult, lldb
│   ├── goios/
│   ├── libimobiledevice/
│   ├── pymobiledevice3/              # SUBPROCESS ONLY — see §14.5
│   ├── appiumwda/
│   ├── frida/
│   ├── jailbreakssh/
│   ├── mdm/
│   ├── corellium/
│   └── xcodebuildmcp/                # integrated, never promoted to control plane
│
├── mcp/
│   ├── gateway/                      # auth, contract-driven tool advertisement, fencing
│   ├── servers/{devices,ui,diagnostics,debug,instrumentation,management}/
│   └── conformance/                  # Claude Code + OpenCode client tests (§11.5)
│
├── cli/labctl/
│
├── agents/
│   ├── planner/  explorer/  investigator/  security/  verifier/
│   ├── prompts/                      # versioned; revision recorded in every bundle
│   ├── fencing/                      # untrusted-content delimiters (§9.8)
│   └── cache/                        # result cache (§9.6)
│
├── workflows/
│   ├── deterministic/                # XCUITest + Appium suites
│   ├── exploratory/
│   ├── fuzz/
│   └── security/templates/           # REVIEWED Frida templates only
│
├── schemas/                          # device, capability, lease, task, evidence, events
│
├── ci/
│   ├── github/  gitlab/  jenkins/  buildkite/  generic/
│   └── selftest/                     # the lab tests itself (§11.6)
│
├── observability/
│   ├── otel/  dashboards/  alerts/  slo/
│
├── security/
│   ├── rbac/  policies/  signing/  threat-model/  egress-allowlist/
│
├── deployment/
│   ├── control-plane/                # Helm / compose
│   ├── macos/                        # bootstrap.sh, launchd plists, versions.lock
│   ├── networking/                   # VLAN + firewall definitions as code
│   ├── litellm/
│   └── mdm/
│
├── tools/                            # codegen, lint, evidence inspector, capability differ
│
└── docs/
    ├── architecture/                 # this spec, ADRs
    ├── compatibility/                # PER-IOS-VERSION certification results
    ├── jailbreak-matrix/
    ├── runbooks/
    ├── capacity/                     # Phase-0 measurements, per workload profile
    └── api/
```

### 10.3 Module dependency rules

```mermaid
graph TD
  API["api/"] --> CP["control-plane/"]
  API --> WK["worker-macos/"]
  API --> MCP["mcp/"]
  API --> CLI["cli/"]
  API --> AG["agents/"]
  WK --> AD["adapters/"]
  CP -.->|FORBIDDEN| AD
  AG -.->|FORBIDDEN| AD
  MCP -.->|FORBIDDEN| AD
  MCP --> CLIENT["generated API client"]
  CLIENT --> CP

  style AD fill:#2d4a6b,color:#fff
  linkStyle 6,7,8 stroke:#b33,stroke-width:2px,stroke-dasharray: 5 5
```

Enforced by a CI import-boundary linter:

| Rule | Enforcement |
|---|---|
| Only `worker-macos/` may import `adapters/`. | `tools/lint/import-boundaries` |
| Nothing may import `adapters/pymobiledevice3` as a library; it is subprocess-only. | Linter + licence scan (§14.5) |
| `mcp/` and `cli/` reach the control plane only through the generated client. | Linter |
| `api/gen/` is generated; hand edits fail CI. | `make verify-codegen` diff check |
| `agents/` may not call adapters or the database directly. | Linter |

### 10.4 Language and toolchain standards

| Area | Standard |
|---|---|
| Control plane, worker, CLI, adapters | Go, latest stable minus one. `golangci-lint` with `errcheck`, `govet`, `staticcheck`, `gosec`. |
| MCP gateway | TypeScript strict; generated tool definitions. |
| Agents / orchestrator | Python; `ruff` + `mypy --strict`. |
| Schemas | JSON Schema 2020-12 + Protobuf. Backwards compatibility enforced by `buf breaking`. |
| SQL | Versioned, forward-only migrations. Every migration has a tested rollback plan. |
| Shell | `set -euo pipefail`; `shellcheck` clean. |
| Formatting | Enforced in CI; no style discussion in review. |
| Commits | Conventional Commits; the ADR number is referenced when a decision changes. |
| Branching | Trunk-based, short-lived branches, required review, no direct pushes to the default branch. |

### 10.5 Evidence-grading in code review

**ORCHARD-ENG1:** Any code or documentation asserting a device capability, a version behaviour or a
third-party guarantee **must** carry a grade and a source.

```go
// InstallApp installs a signed IPA.
//
// Capability: ios.app.install
// Grade: V — Apple documents devicectl as the supported host-side install path.
// Fallback: go-ios [C], ideviceinstaller [V].
// Certified: docs/compatibility/ios-27.0-25A331.md#install
func (a *AppleDeviceAdapter) InstallApp(...) { ... }
```

A capability claim without `Grade:` and `Certified:` fails review. This is how ADR-009 becomes
process rather than aspiration.

### 10.6 Versioning and compatibility

| Artifact | Scheme | Compatibility promise |
|---|---|---|
| API (REST/gRPC) | SemVer, `/v1` path | No breaking change within a major. `buf breaking` gates every PR. |
| Capability registry | Monotonic; capabilities are **added**, never silently re-scoped | Removing or narrowing a capability is a **major** change. |
| MCP tool surface | Tracks the API | A tool name never changes meaning. |
| `labctl` | SemVer; server negotiates minimum version | Server rejects clients below `min_client_version`. |
| Worker | Must be within one minor of the control plane | Capacity controller refuses to admit out-of-range workers. |
| Evidence bundle | `schema_version` on every record | Old bundles remain readable forever. Retention outlives code. |
| `versions.lock` | Pinned third-party toolchain | Changed only by an explicit, tested PR. |

### 10.7 Documentation requirements

Merging is blocked unless:

1. A new capability appears in `api/capability-model/capabilities.json` **and** in the §3.3 matrix.
2. A version-dependent behaviour has a `docs/compatibility/<ios-version>.md` entry.
3. An architectural change has an ADR in `docs/architecture/adr/`.
4. A new recovery action appears in the ladder (§6.6) **and** in a runbook.
5. A new privileged capability has a threat-model entry (§14.1) and an RBAC rule.

---

## §11. Testing Strategy

ORCHARD tests **two different things** and must never confuse them:

1. **The platform** — does ORCHARD itself work?
2. **The fleet** — does this physical device still behave as its capability contract claims?

### 11.1 The test pyramid

```mermaid
graph TB
  T6["<b>L6 — Chaos & fault injection</b><br/>pull cables, kill WDA, revoke leases, sever tunnels<br/>nightly, on real hardware"]
  T5["<b>L5 — Fleet conformance</b><br/>per-device capability certification<br/>continuous, per device, per iOS build"]
  T4["<b>L4 — Client conformance</b><br/>Claude Code + OpenCode + CI drive identical tool surfaces<br/>per release"]
  T3["<b>L3 — End-to-end on hardware</b><br/>reserve -> install -> test -> investigate -> release<br/>per merge to main"]
  T2["<b>L2 — Integration with device simulacra</b><br/>fake adapters + simulators, real scheduler/registry/worker<br/>per PR"]
  T1["<b>L1 — Unit</b><br/>fencing, predicates, ranking, classifiers, contract computation<br/>per commit"]

  T1 --> T2 --> T3 --> T4 --> T5 --> T6

  style T1 fill:#2d6b3d,color:#fff
  style T5 fill:#2d4a6b,color:#fff
  style T6 fill:#6b3d2d,color:#fff
```

### 11.2 L1–L2: platform correctness

**Highest-priority unit tests** — these encode the invariants that protect real hardware:

| Area | Must-have tests |
|---|---|
| **Fencing** | Stale generation rejected at worker; generation is strictly monotonic; concurrent grants never issue the same generation; a revoked lease cannot renew. Property-based with a fuzzed interleaving schedule. |
| **Scheduler** | Predicate compilation, ranking determinism, anti-affinity spread, starvation freedom under an aged queue, no double-booking under concurrent reserves. |
| **Capability engine** | Contract computed per `(device, principal)`; degraded entries appear on profile expiry; a `research` contract never leaks to a `developer` principal. |
| **Failure classifier** | Every adapter error maps to exactly one domain; unknown errors default to `ADAPTER_FAILURE`, never to `TEST_FAILURE`. |
| **Recovery ladder** | Rung budgets honoured; never skips to rung 9 on a single timeout; quarantine writes component history. |
| **Policy** | Deny-by-default; all five gates evaluated; model output cannot influence a decision (§9.8). |
| **Evidence** | Bundles are content-addressed, complete and schema-valid; a missing required field fails the build. |

**L2 uses device simulacra** — a `FakeDeviceServices` adapter plus real simulators — so the full
control plane, worker and scheduler run in CI **without a physical iPhone**. This is what makes the
platform testable at PR speed.

**ORCHARD-T1:** Every bug fixed in fencing, scheduling, recovery or policy ships with a regression
test. No exceptions: these subsystems fail silently and expensively.

### 11.3 Phase-0 certification — the measurement gate

This is not a test suite; it is **the gate that turns grade-C assumptions into grade-V facts**
(ORCHARD-E1). Architecture is not frozen and fleet procurement does not proceed until it passes.

#### 11.3.1 Concurrency matrix (settles ADR-001)

Run at **1, 2, 4, 8** devices, then higher only if the data justifies it, across four workload
profiles:

| Profile | Workload |
|---|---|
| `P1-ui` | WDA UI actions only |
| `P2-ui-video` | UI + MJPEG stream |
| `P3-ui-video-logs` | UI + MJPEG + continuous OSLog |
| `P4-full` | P3 + `xctrace` trace + PCAP |

Measured at each point:

```text
CPU p50/p95                      WDA request latency p50/p95/p99
memory pressure                  screenshot latency
swap usage                       MJPEG bandwidth
USB disconnect/reconnect count   log throughput
RemoteXPC tunnel failures        xcodebuild / WDA cold-start time
trace loss                       storage write rate
thermal condition (host+device)  session failure rate
```

**Output:** `docs/capacity/worker-profile-<hw>.md` → `worker.max_concurrent_sessions` per profile,
consumed directly by the capacity controller (§6.7). **This measured number, not any published
estimate, is what the scheduler enforces.**

#### 11.3.2 Capability certification per device class

Every cell in the §3.3 matrix is either **demonstrated** or **demonstrated to fail** on real
hardware, per iOS build. Results land in `docs/compatibility/ios-<version>-<build>.md` and feed the
capability engine's static priors.

#### 11.3.3 Tooling assumptions

| Assumption | Test |
|---|---|
| WDA on the current iOS generation | Preinstall signed WDA, establish RemoteXPC, run repeated sessions across reboots |
| Adapter agreement | Compare devicectl vs go-ios vs libimobiledevice vs pymobiledevice3 for discovery, install, logs; record divergences |
| `devicectl` install/launch/console | Verify stdout capture and `--terminate-existing` |
| PCAP | Validate RVI / pymobiledevice3 capture per intended iOS version |
| `xctrace` | Programmatic record + parse for each template used in production |
| Frida Gadget | Own debug-signed app: ObjC + native interception; record jailed `Interceptor` constraints |
| Dopamine device | Reboot → re-jailbreak → SSH → frida-server reliability over 50 cycles |
| palera1n device | Reboot recovery; confirm A11 passcode constraint behaviour |
| MDM recovery | Restart, shutdown, lock, erase, Return to Service |
| Wireless | Pair and reconnect after both worker and device restarts |
| MCP clients | Claude Code + OpenCode: auth, tool schema, concurrency, error surfaces |
| **Maestro physical iOS** | **Gate for ADR/§4.6 conditional adoption. If it fails, Maestro is simulator-only.** |
| AI reliability | Deterministic baseline vs agent exploration on the same flows; measure agreement |

#### 11.3.4 Offline-survival measurement (settles ADR-008)

Disconnect Apple egress and **measure** exactly which operations continue and for how long:

```text
t=0     sever Apple egress at the firewall
        -> record: install, launch, WDA session start, signing validation,
           MDM command delivery, device activation, tunnel establishment
t=1h, 6h, 24h, 72h, 7d ... until first failure
        -> record which operation fails first and why
```

**Output:** a documented offline-survival envelope in `docs/compatibility/offline-envelope.md` and
the egress allowlist in `security/egress-allowlist/`. This replaces the untested assumption that the
lab is air-gappable.

#### 11.3.5 USB fault isolation

Pull cables, reset ports, fail a hub, fail a worker. Confirm: correct failure-domain classification,
correct ladder rung selection, correct blast radius (one cell), correct component-history write.

### 11.4 L5: continuous fleet conformance

Every device runs a **conformance suite** on a schedule and after every recovery:

```mermaid
flowchart LR
  TRIG["Trigger:<br/>onboarding | post-recovery |<br/>nightly | post-iOS-change"] --> SUITE["Conformance suite"]
  SUITE --> C1["assert every claimed capability"]
  SUITE --> C2["assert every UNSUPPORTED capability<br/>returns CAPABILITY_UNAVAILABLE"]
  SUITE --> C3["WDA health + build hash"]
  SUITE --> C4["tunnel establish/repair"]
  SUITE --> C5["evidence bundle completeness"]
  C1 & C2 & C3 & C4 & C5 --> RES{"Pass?"}
  RES -->|yes| OK["available + contract refreshed"]
  RES -->|no| Q["quarantine + SRE ticket<br/>+ contract degraded"]

  style C2 fill:#6b3d2d,color:#fff
```

**ORCHARD-T2:** The negative assertions in C2 matter as much as the positive ones. A device that
*starts* answering `ios.shell.exec` has been jailbroken, compromised or misclassified — all of which
are **P1 security incidents**, not conveniences.

### 11.5 L4: client conformance

Per release, an automated suite drives the MCP gateway from **Claude Code**, **OpenCode** and the
**CI client** and asserts:

- identical tool surfaces for identical principals,
- identical structured errors,
- correct tool *absence* for unsupported capabilities,
- correct behaviour under concurrent sessions,
- configuration schemas in `docs/compatibility/` still valid for both clients (ORCHARD-API4).

### 11.6 L6: chaos engineering

Nightly, against a dedicated chaos cell, never against the production pool:

| Injection | Expected behaviour |
|---|---|
| Physically pull a USB cable mid-session | `USB_FAILURE`; ladder → port reset → recover or quarantine; job sees `CAPABILITY_DEGRADED`, not a test failure |
| `kill -9` the WDA runner | `WDA_FAILURE`; rung 3–4; session resumes or fails cleanly |
| Sever the RemoteXPC tunnel | `DEVICE_SERVICE_FAILURE`; rung 6 |
| Revoke a lease mid-command | Worker returns `STALE_FENCE`; job aborts; **no cross-contamination** |
| Kill the scheduler | Workers continue current leases; new reserves queue; no device is orphaned |
| Fill the worker disk | Collectors apply backpressure; evidence spools; no silent loss |
| Partition NATS | Workers buffer; evidence ships on reconnect; leases expire safely |
| Expire a provisioning profile | Contract degrades **before** a job takes the lease |
| Exhaust an agent budget | `POLICY_BUDGET_EXCEEDED`; loop aborts; state captured; device released |
| Feed injection text through app UI | Policy unaffected; denial logged as an injection candidate |

**ORCHARD-T3:** The chaos suite gates releases. A recovery ladder that has never been exercised is a
document, not a mechanism.

### 11.7 Testing the tests: flake governance

| Control | Rule |
|---|---|
| Flake attribution | Every retry records its `failure_domain`. Platform-domain flakes are **platform bugs**, tracked against ORCHARD's SLOs, never charged to the app team. |
| Quarantine budget | A suite exceeding 2% platform-domain flake rate blocks the release of the *platform*, not the app. |
| Device attribution | Flakes are cross-tabulated against `device_id`, `hub_id`, `cable_asset`. A cable with a flake cluster is replaced. |
| Agent non-determinism | Mode 3/4 runs are **never** counted as flakes; they are not gates (ORCHARD-AI1). |

### 11.8 Test data and app artifacts

- Every run records the app artifact **SHA-256**. A test result without it is void.
- Test apps are built by the signing service (§12.5) and stored immutably.
- Security-test applications run **only** on quarantined research devices, on the isolated VLAN, and
  the device is **re-imaged afterwards** before returning to any pool (§14.3).

---

## §12. CI/CD

Three distinct pipelines that are routinely and incorrectly conflated:

1. **Pipeline A** — building and releasing **ORCHARD itself**.
2. **Pipeline B** — provisioning and updating **the fleet**.
3. **Pipeline C** — customer teams running **their** iOS tests *on* ORCHARD.

### 12.1 Pipeline A — building ORCHARD

```mermaid
flowchart TD
  PR["Pull request"] --> L["Lint + format<br/>golangci-lint, ruff, mypy, shellcheck, tsc"]
  L --> CG["verify-codegen<br/>api/gen matches api/ source"]
  CG --> BC["buf breaking<br/>+ capability-registry compat check"]
  BC --> IB["import-boundary linter<br/>(§10.3)"]
  IB --> LIC["licence scan<br/>(GPL linkage = hard fail, §14.5)"]
  LIC --> U["L1 unit tests<br/>incl. fencing property tests"]
  U --> I["L2 integration<br/>fake adapters + simulators"]
  I --> SEC["SAST + secret scan + dep audit"]
  SEC --> GRADE["evidence-grade linter<br/>(ORCHARD-ENG1)"]
  GRADE --> M{"Merge to main"}

  M --> BLD["Build: Go binaries (linux+darwin),<br/>TS gateway, Python orchestrator,<br/>container images"]
  BLD --> SIGN["Sign artifacts + generate SBOM<br/>+ provenance attestation"]
  SIGN --> E2E["L3 end-to-end on the<br/>STAGING CELL (real hardware)"]
  E2E --> CONF["L4 client conformance<br/>Claude Code + OpenCode + CI"]
  CONF --> CHAOS["L6 chaos suite (nightly gate)"]
  CHAOS --> REL["Release candidate"]
  REL --> CANARY["Canary: 1 cell"]
  CANARY --> PROG["Progressive rollout by cell"]
  PROG --> DONE["Released"]

  CANARY -->|SLO regression| RB["Automatic rollback"]

  style M fill:#2d6b3d,color:#fff
  style RB fill:#6b2d2d,color:#fff
```

**ORCHARD-CD1:** A control-plane release **MUST NOT** interrupt an in-flight lease. Deploys drain
cells one at a time; leases run to completion; new grants route elsewhere.

**ORCHARD-CD2:** The staging cell is **real hardware** with at least one device of each class the
production fleet contains, including one research device. A control plane validated only against
simulators has not been validated.

### 12.2 Pipeline A — release gates

| Gate | Blocking condition |
|---|---|
| Codegen drift | `api/gen` differs from regenerated output |
| API compatibility | `buf breaking` failure, or a capability narrowed without a major bump |
| Import boundaries | Any violation of §10.3 |
| Licence | Any GPL library **linked** into a binary (subprocess use is permitted) |
| Evidence grading | Any capability claim without `Grade:` + `Certified:` |
| Unit + integration | Any failure; coverage below threshold on fencing/scheduler/policy packages |
| E2E on hardware | Any failure in the staging-cell suite |
| Client conformance | Any divergence between Claude Code, OpenCode and CI surfaces |
| Chaos | Any recovery-ladder regression |
| SLO canary | Session success rate or recovery MTTR regression during canary |

### 12.3 Pipeline B — fleet provisioning

Workers and devices are managed as code, never by hand.

```mermaid
flowchart LR
  subgraph AsCode["Declared in git"]
    V["deployment/macos/versions.lock"]
    N["deployment/networking/*.yaml"]
    M["deployment/mdm/profiles/*"]
    T["orchard-tap formulae"]
  end
  V & N & M & T --> PLAN["labctl admin fleet plan<br/>(dry run, shows diff)"]
  PLAN --> APPROVE["Human approval<br/>required for OS/toolchain changes"]
  APPROVE --> APPLY["Rolling apply, cell by cell"]
  APPLY --> DRAIN["drain cell"]
  DRAIN --> UPD["update worker toolchain"]
  UPD --> CERT["re-run fleet conformance (§11.4)"]
  CERT -->|pass| REJOIN["rejoin pool"]
  CERT -->|fail| HOLD["hold cell + SRE ticket"]

  style APPROVE fill:#6b3d2d,color:#fff
```

**ORCHARD-CD3:** An **iOS or Xcode version change is a fleet migration**, never a background update.
It requires: a pinned-build plan, a staging-cell certification run, a compatibility document, and
per-cell rollout. This is the operational expression of "iOS churn is a standing cost" (S12).

**ORCHARD-CD4:** Research devices are **excluded from every update path by construction**
(ORCHARD-R2). Pipeline B refuses to plan changes for devices labelled `frozen`, and an attempt is a
P1 incident.

### 12.4 Pipeline C — customer test execution

```mermaid
flowchart TD
  P["git push (app repo)"] --> B["Build + sign IPA<br/>on the signing service"]
  B --> A["Publish immutable artifact<br/>+ SHA-256"]
  A --> MX["Create test matrix"]
  MX --> SQ["labctl devices reserve<br/>(parallel leases, anti-affinity across cells)"]
  SQ --> INS["Install"]
  INS --> DT["Deterministic XCTest / Appium suites"]
  DT --> PF["Property / fuzz suites"]
  PF --> AX["AI exploratory gap coverage<br/>(non-gating)"]
  AX --> SS["Authorised security suite<br/>(research devices only)"]
  SS --> F{"Failure?"}
  F -->|no| RPT["Evidence bundle + report"]
  F -->|yes| DOM{"failure_domain"}
  DOM -->|platform domain| RETRY["Recovery ladder + retry<br/>NOT a product bug"]
  DOM -->|TEST/APP| INV["AI investigator (§9.3)"]
  INV --> XD["Cross-device comparison"]
  XD --> VER["Verifier"]
  VER --> CLS["Classify app / OS / device / infra"]
  CLS --> RPT
  RPT --> RATCHET["Persist discovered flows<br/>as deterministic tests"]
  RPT --> REL["Release leases (trap EXIT)"]

  style DOM fill:#2d4a6b,color:#fff
  style RETRY fill:#6b3d2d,color:#fff
```

**ORCHARD-CD5:** The release gate is the deterministic suite. Modes 2–4 (§9.2) annotate the report;
they never block or unblock it.

### 12.5 The signing service

Signing is the most common source of surprise CI outages in iOS labs, so it is a **service**, not a
step.

```mermaid
flowchart LR
  V["Vault<br/>certs + keys, never on worker disk"] --> SS["orchard-signing"]
  UDID["UDID registry"] --> SS
  SS --> PROF["Provisioning profiles"]
  PROF --> WDA["WDA signing identity<br/>SEPARATE from distribution identity"]
  PROF --> APP["Test app signing"]
  SS --> PRED["Expiry prediction<br/>-> capability 'degraded' at T-14d"]
  PRED --> MAINT["Scheduled maintenance event<br/>NOT a CI outage"]

  style V fill:#2d4a6b,color:#fff
  style WDA fill:#6b3d2d,color:#fff
```

| Rule | Detail |
|---|---|
| ORCHARD-SIGN1 | Signing credentials live in a vault and are **never** distributed to device workers. Build/sign happens on a controlled service. |
| ORCHARD-SIGN2 | The **WDA signing identity is separate** from the high-value distribution identity. Compromise of a lab worker must not yield distribution capability. |
| ORCHARD-SIGN3 | Profile expiry is predicted and surfaced as a degraded capability at T-14 days, then auto-renewed and WDA reinstalled during a maintenance window. |
| ORCHARD-SIGN4 | Research workers hold **no** signing material at all (ORCHARD-W10). |
| ORCHARD-SIGN5 | Offline/air-gapped operation uses offline provisioning profiles plus a local re-signing pipeline, bounded by the measured offline envelope (§11.3.4). |

### 12.6 Environments

| Environment | Purpose | Fleet |
|---|---|---|
| `dev` | Developer laptops; fake adapters + simulators | None |
| `ci` | Pipeline A L1/L2 | None (simulacra) |
| `staging` | Pipeline A L3/L4/L6 | 1 real cell: ≥ 1 stock, 1 supervised, 1 research, simulators |
| `chaos` | Nightly L6 | Dedicated cell, expendable |
| `prod` | Everything else | Full fleet |

### 12.7 Deployment topology

| Component | Runs on | Strategy |
|---|---|---|
| Control-plane services | Linux containers (on-prem k8s or compose) | Rolling; HA from Phase 3 |
| PostgreSQL | On-prem, HA + PITR backups from Phase 3 | Blue/green migrations, forward-only |
| NATS JetStream | On-prem cluster | Rolling |
| Artifact store | On-prem S3-compatible | N/A |
| OTel backend | On-prem | Rolling |
| LiteLLM | On-prem | Rolling |
| Mac workers | Bare metal macOS | **Drain → update → certify → rejoin**, one cell at a time |
| MCP gateway | Linux containers behind internal TLS | Rolling; sessions drain |

### 12.8 Rollback

| Failure | Rollback |
|---|---|
| Control-plane regression | Automatic on canary SLO breach; previous image redeployed; DB migrations are forward-only and backwards-compatible for one minor |
| Worker toolchain regression | `versions.lock` revert + cell re-provision + re-certify |
| WDA regression | Previous signed WDA artifact is retained and reinstallable by build hash |
| iOS version regression | Devices are pinned; affected cell is held; matrix routes to other builds |
| Agent prompt/policy regression | Prompt revisions are versioned; the orchestrator pins a revision per release and can roll back independently of code |

---

## §13. Observability & SRE

### 13.1 Trace model

OpenTelemetry is the common model. One trace spans the entire causal chain, from CI job to USB byte.

```mermaid
graph TD
  A["pipeline span<br/>pipeline_id"] --> B["reservation span<br/>predicate, queue wait, ranking"]
  B --> C["device-session span<br/>device_id, lease_generation"]
  C --> D["action span<br/>capability, params hash"]
  D --> E["adapter span<br/>which adapter served it, fallbacks"]
  E --> F["process span<br/>WDA / devicectl / go-ios / Frida / xctrace"]
  C --> G["agent span<br/>role, model_class, resolved_model"]
  G --> H["llm call span<br/>tokens, latency, cost"]

  style C fill:#2d4a6b,color:#fff
```

### 13.2 Required action record fields

Every device action emits a record carrying **all** of:

```text
task_id                pipeline_id            agent_id
model_class            resolved_model         prompt_revision
device_id              device_model           ios_version        ios_build
device_class           jailbreak_state        fidelity_caveat
host_id                cell_id                hub_id  hub_port  cable_asset
lease_id               lease_generation       wda_session
capability             action_parameters_hash adapter_used       adapter_grade
screenshot_artifact    ui_tree_artifact       log_refs           crash_refs
trace_ids              frida_event_stream_ref pcap_ref
llm_request_id         llm_response_hash      input_tokens  output_tokens
latency_ms             tool_calls             errors        retries
failure_domain         outcome
```

**ORCHARD-OBS1:** `device_id` — never the UDID — appears in telemetry. UDIDs are vault-referenced and
visible only to `lab_admin`.

### 13.3 Golden signals

| Signal | Metric | Alert |
|---|---|---|
| Availability | `orchard_devices_available / total` by class and cell | < 90% of class capacity for 10 min |
| Saturation | Queue depth, p95 reservation wait | p95 wait > 5 min |
| Errors | Rate by `failure_domain` | Platform-domain rate > 2% of sessions |
| Latency | WDA request p99, screenshot latency | p99 > 3× 7-day baseline |
| Recovery | Ladder rung distribution, MTTR | Rung ≥ 8 invoked > 3×/hour in a cell |
| Fleet health | Quarantine rate, battery band, thermal | Any cell with ≥ 2 quarantines in 24 h |
| Signing | Days to nearest profile expiry | < 21 days |
| Agent | Steps/task, escalation rate, cost/task, budget breaches | Cost per task > 2× 7-day median |
| Supply chain | Adapter fallback rate | Any adapter falling back > 10% — early warning of iOS drift |

**ORCHARD-OBS2:** Adapter fallback rate is the fleet's canary for iOS churn. A rising fallback rate
from `devicectl` to `go-ios` means an Apple behaviour changed, usually days before it becomes an
outage.

### 13.4 Evidence bundles

An evidence bundle is immutable, content-addressed and **self-sufficient** — readable years later
without the code that produced it.

```text
evidence/<run_id>/
├── manifest.json             # schema_version, all hashes, signed
├── inputs/
│   ├── app_artifact.sha256
│   ├── test_source_commit
│   ├── test_seed
│   └── capability_contract.json
├── environment/
│   ├── tool_versions.json    # Xcode, WDA commit+hash, Appium, driver, go-ios,
│   │                         # libimobiledevice, pymobiledevice3, Frida
│   ├── device_snapshot.json  # model, chip, build, jailbreak state, battery, thermal
│   ├── worker_snapshot.json
│   └── agent.json            # prompt revision, agent code revision, model alias,
│                             # RESOLVED model id, sampling params
├── actions/                  # ordered action+observation sequence
├── artifacts/                # screenshots, UI trees, logs, crashes, traces, pcap, xcresult
├── llm/                      # request ids, response hashes, tokens, costs
└── conclusion/               # hypotheses, verifier result, classification, generated tests
```

**ORCHARD-OBS3:** A run without a complete bundle is a **platform defect**, not a test result. The
manifest is validated before a run is reported.

**ORCHARD-OBS4:** Replay means *evidence-complete and reconstructable*, never bitwise-identical LLM
output (ORCHARD-AI7).

### 13.5 Retention

| Data | Retention | Notes |
|---|---|---|
| Audit log (tool calls, leases, privileged ops) | 7 years, immutable, WORM | Legal/compliance |
| Evidence bundles — release gates | 2 years | Auditable release record |
| Evidence bundles — routine CI | 90 days | Tiered to cold storage at 30 days |
| Evidence bundles — security engagements | Per engagement, minimum 3 years | `orchard-research` governance |
| Screenshots / video | 30 days by default | Largest volume driver; may contain PII |
| Unified logs | Collect **promptly** — device-side retention is volatile | Hours to ~30 days on-device |
| Traces (OTel) | 30 days, sampled above volume threshold | |
| Metrics | 13 months | Capacity planning |

**ORCHARD-OBS5:** Screenshots and logs may contain PII or customer content. Retention is policy-driven
with redaction hooks, and scope is enforced at read time by RBAC.

### 13.6 Runbooks

`docs/runbooks/` is a release artifact, not documentation debt. Minimum set:

```text
device-quarantined.md              wda-unhealthy.md
tunnel-establish-failure.md        usb-enumeration-storm.md
worker-wedged.md                   scheduler-backlog.md
provisioning-expiry.md             signing-service-outage.md
ios-version-migration.md           cell-drain-and-return.md
rejailbreak-dopamine.md            rejailbreak-palera1n.md
research-device-reimage.md         suspected-device-compromise.md
agent-runaway-budget.md            evidence-store-full.md
corellium-appliance-degraded.md    mdm-return-to-service.md
```

**ORCHARD-OBS6:** Every automated recovery rung (§6.6) has a corresponding runbook describing what a
human does when that rung fails.

---

## §14. Security, Legal & Compliance

### 14.1 Threat model summary

| # | Threat | Control |
|---|---|---|
| T1 | Malicious test app escapes to the control plane | Research VLAN, outbound-only workers, no inbound route, re-image after security runs |
| T2 | Jailbroken device is compromised and used as a pivot | Treated as hostile by default; no secrets present; dedicated hubs and workers; disposable worker filesystems |
| T3 | Signing credential theft | Vault-held; never on workers; WDA identity separated from distribution identity |
| T4 | Prompt injection via device content escalates agent privilege | Privilege derives only from principal + engagement; content is fenced as untrusted; denials logged as injection candidates |
| T5 | Stale lease holder corrupts another job's device | Monotonic fencing tokens enforced at the worker |
| T6 | Privileged capability used outside an authorised target scope | Five policy gates; per-engagement target scope; immutable audit |
| T7 | Evidence tampering | Content-addressed artifacts; signed manifests; WORM audit store |
| T8 | Supply-chain compromise of a pinned tool | `versions.lock`, private Homebrew tap, SBOM + provenance, dependency audit in CI |
| T9 | UDID/PII leakage through telemetry or reports | Vault references; `device_id` in telemetry; RBAC at read time; redaction hooks |
| T10 | Unauthorised OS update destroys a research device | `frozen` label; excluded from all update paths; attempted update is a P1 |
| T11 | A stock device silently gains privileged capability | Conformance negative assertions (ORCHARD-T2) raise a P1 |
| T12 | Agent runaway cost or destructive loop | Budgets, step caps, global kill switch, non-destructive-by-default explorer |

### 14.2 Network segmentation

```mermaid
graph TB
  subgraph Trusted
    CP["Control Plane VLAN"]
    SEC["Signing / Secrets enclave"]
    ADM["Admin network"]
  end
  subgraph SemiTrusted
    SW["Stock Worker VLAN"]
    SD["Stock Device Wi-Fi VLAN"]
    OBS["Artifact / Observability VLAN"]
    MDL["Model / LiteLLM VLAN"]
  end
  subgraph Untrusted
    RW["Research Worker VLAN"]
    RD["Research Device VLAN"]
  end

  SW -->|outbound authenticated| CP
  RW -->|outbound via broker ONLY| CP
  CP --> OBS
  SW --> OBS
  RW --> OBS
  SEC --> SW
  SEC -.->|NEVER| RW
  CP --> MDL
  RD -.->|no route| CP
  SD -.->|no inbound| CP

  style Untrusted fill:#3b1f1f,color:#fff
  style SEC fill:#2d4a6b,color:#fff
```

**ORCHARD-SEC1:** Workers **initiate** connections to the control plane. Device networks never
initiate arbitrary inbound connections to central services.

**ORCHARD-SEC2:** The signing enclave has **no path at all** to the research VLAN. This is enforced in
`deployment/networking/` as code and asserted by a nightly reachability test.

### 14.3 Security-research workflow

```mermaid
flowchart TD
  A["Engagement record created<br/>target scope + validity window + approver"] --> B["Reserve research device"]
  B --> C["Verify device snapshot<br/>+ jailbreak health + verified_boot_build"]
  C --> D["Install exact app artifact (sha256)"]
  D --> E["Capture baseline<br/>process / log / network state"]
  E --> F["Deterministic security regression"]
  F --> G["Optional AI exploratory interaction"]
  G --> H["Attach Frida / LLDB UNDER POLICY<br/>reviewed templates by default"]
  H --> I["Collect method + native traces"]
  I --> J["Exercise suspicious behaviour"]
  J --> K["Capture crash / memory / network evidence"]
  K --> L["Reproduce on a CLEAN control device"]
  L --> M["Classify: app vs OS vs instrumentation artefact"]
  M --> N["Immutable report + evidence manifest"]
  N --> O["Sanitise + RE-IMAGE + release"]

  style A fill:#6b3d2d,color:#fff
  style O fill:#6b2d2d,color:#fff
```

**ORCHARD-SEC3:** "A research device is available" is **not** authorisation to attach to every
process. Target scope is a separate, explicit, time-bounded authorisation object (ORCHARD-C3).

**ORCHARD-SEC4:** After any malware or untrusted-app test, the device is treated as compromised and
**re-imaged before reuse**. It does not return to any pool until conformance passes.

**ORCHARD-SEC5:** Step M is mandatory. Instrumentation changes behaviour; a finding that has not been
separated from its instrumentation artefact is not a finding.

### 14.4 Untrusted content handling

All of the following are untrusted input: UI text, accessibility labels, log lines, crash strings,
web content rendered in-app, filenames, and every adapter's stdout. They are delimited and
provenance-labelled before entering model context, and they can never influence a policy decision
(§9.8).

### 14.5 Licensing and legal

| Item | Licence | Obligation | Control |
|---|---|---|---|
| `pymobiledevice3` | **GPL-3.0** | Distribution/derivative-work obligations | **Subprocess-only, separate venv, never linked** (ORCHARD-W3). CI licence scan hard-fails on linkage. |
| `libimobiledevice` | LGPL/GPL components | Component-dependent | Wrapped; dynamic use; documented per component |
| `go-ios` | MIT | Attribution | Standard |
| Appium / XCUITest driver | Apache-2.0 | Attribution, NOTICE | Standard |
| WebDriverAgent | BSD-family | Attribution | Standard |
| Frida | Component-specific | Review per component | Legal review before redistribution |
| **TrollStore** | **NOASSERTION upstream** | Unclear | **Legal review required before inclusion in any distributed artifact.** Use as an operator tool only until resolved. |
| palera1n / Dopamine | MIT | Attribution | Operator tooling; not redistributed |
| Corellium | Commercial | Contract terms | Procurement + legal |
| Apple SRD | Apple programme | Premises-bound; Apple's property; report findings to Apple; scope excludes Apple Pay and third-party apps | Separate device class, policy-gated, tracked by programme record |
| Xcode / Apple tooling | Apple licence | Licensing terms for automated use | Legal review of fleet-scale usage |

**ORCHARD-LEG1:** The SBOM is generated per release and includes worker toolchain components, not
just control-plane dependencies.

**ORCHARD-LEG2:** Security research is conducted **only** against organisation-owned or explicitly
authorised targets, recorded in an engagement record with a named approver and a validity window.

### 14.6 Secrets

| Secret | Storage | Rotation |
|---|---|---|
| Signing certs and keys | Vault, HSM-backed where available | Per policy; expiry predicted |
| Device pairing records | Vault | On re-pair |
| UDIDs / serials | Vault-referenced | N/A |
| SSH keys (research) | Vault; key-only auth; per-device | 90 days |
| MCP bearer tokens | Short-lived, per-principal | ≤ 24 h |
| Worker enrolment credentials | Short-lived join tokens | Per enrolment |
| LiteLLM keys | Per-team, budgeted | 90 days |
| MDM push credentials | Vault | Per Apple lifecycle |

**ORCHARD-SEC6:** No secret is ever written to a worker disk in plaintext, and no secret of any kind
exists on a research worker.

---

## §15. Development Roadmap

### 15.1 Phase overview

```mermaid
gantt
  title ORCHARD delivery roadmap
  dateFormat YYYY-MM-DD
  axisFormat %b %Y

  section Phase 0 — Validate
  Tooling + capability certification      :p0a, 2026-09-22, 42d
  Concurrency + USB fault matrix          :p0b, 2026-10-06, 28d
  Offline envelope + signing automation   :p0c, 2026-10-13, 21d
  Research device proving                 :p0d, 2026-10-06, 28d
  GATE 0 architecture freeze              :milestone, g0, 2026-11-03, 0d

  section Phase 1 — POC
  API schema + codegen + registry         :p1a, after g0, 28d
  Worker daemon + adapters + WDA          :p1b, after g0, 42d
  Scheduler + leases + FENCING            :p1c, 2026-11-17, 28d
  MCP gateway + labctl                    :p1d, 2026-12-01, 28d
  Agents: explorer + investigator + verifier :p1e, 2026-12-15, 35d
  GATE 1 autonomous run                   :milestone, g1, 2027-01-26, 0d

  section Phase 2 — Small lab
  Production scheduler + queues + health  :p2a, after g1, 35d
  Recovery ladder + quarantine            :p2b, after g1, 35d
  CI integration + evidence + OTel        :p2c, 2027-02-16, 35d
  Result caching + ratchet                :p2d, 2027-03-02, 28d
  GATE 2 10-20 devices in production CI   :milestone, g2, 2027-04-06, 0d

  section Phase 3 — Production
  HA control plane + DB HA                :p3a, after g2, 42d
  Signing service + worker pools by class :p3b, after g2, 42d
  Multi-rack + per-port power + RBAC      :p3c, 2027-05-18, 42d
  Chaos suite + DR runbooks               :p3d, 2027-06-01, 35d
  GATE 3 50-100 devices, SLOs published   :milestone, g3, 2027-07-27, 0d

  section Phase 4 — Scale
  Cell-aware sharded scheduler            :p4a, after g3, 56d
  Fleet inventory + component history     :p4b, after g3, 42d
  Capacity reservations + maintenance coordinator :p4c, 2027-09-21, 42d
  Corellium / SRD integration             :p4d, 2027-09-07, 56d
  GATE 4 100-500+ devices                 :milestone, g4, 2027-12-14, 0d
```

Dates are indicative and assume the staffing in §15.7. **Gates are not date-driven** — a gate that
has not met its exit criteria does not open.

### 15.2 Phase 0 — Research validation (mandatory, blocking)

> **Nothing is architected and nothing is procured until Phase 0 passes.** This is the phase that
> converts grade-C assumptions into grade-V facts, and it is the single most important lesson both
> research passes converged on.

**Scope:** 3–4 stock iPhones across two iOS generations, 1 palera1n-class device, 1 Dopamine-class
device, 1 Mac worker, 1 managed hub, simulator pool.

| Deliverable | Detail |
|---|---|
| D0.1 | Capability certification per class → `docs/compatibility/` (§11.3.2) |
| D0.2 | Concurrency matrix 1/2/4/8 × 4 workload profiles → `docs/capacity/` (§11.3.1) — **settles ADR-001** |
| D0.3 | Adapter agreement report: devicectl vs go-ios vs libimobiledevice vs pymobiledevice3 — **settles ADR-003** |
| D0.4 | Offline-survival envelope + egress allowlist (§11.3.4) — **settles ADR-008** |
| D0.5 | Research device proving: 50 reboot/re-jailbreak/SSH/frida cycles per device — **settles ORCHARD-R1** |
| D0.6 | Frida Gadget on an own debug-signed app; jailed `Interceptor` constraints documented |
| D0.7 | MDM validation: restart, shutdown, lock, erase, Return to Service — **settles ADR-004** |
| D0.8 | `xctrace` programmatic record + parse for every production template — **settles ADR-005** |
| D0.9 | Signing/provisioning renewal automation proven end to end |
| D0.10 | MCP client validation: Claude Code + OpenCode auth, schema, concurrency — pins ORCHARD-API4 |
| D0.11 | USB fault isolation results (cable pull, port reset, hub fail, worker fail) |
| D0.12 | **Maestro physical-iOS verdict** — adopt or restrict to simulator |
| D0.13 | SRD programme window + Dopamine 3.0 coverage **confirmed with the source** — closes the two grade-U items from ADR-009 |

**Gate 0 exit criteria (all required):**

1. Every §3.3 matrix cell is demonstrated or demonstrated-to-fail on real hardware.
2. `worker.max_concurrent_sessions` is a **measured** number per workload profile.
3. The offline envelope is measured, not asserted.
4. Both research devices survive 50 reboot/recovery cycles with documented MTTR.
5. Both MCP client configurations are validated and pinned.
6. No architectural assumption in §4 remains grade C or lower.

### 15.3 Phase 1 — POC

**Scope:** 1 Mac worker, 2 stock Developer-Mode iPhones, 1 pinned jailbroken device, simulator pool,
Claude Code + OpenCode, internal LiteLLM.

| Deliverable | Detail |
|---|---|
| D1.1 | `api/` schema + codegen for REST, CLI, MCP, SDKs |
| D1.2 | Registry + **capability engine** serving live contracts |
| D1.3 | Worker daemon: device-monitor, tunnel-manager, port-manager, session-manager, WDA lifecycle, health prober |
| D1.4 | Adapters: appledevice, goios, libimobiledevice, pymobiledevice3 (subprocess), appiumwda, frida |
| D1.5 | Scheduler with leases, TTL, heartbeat and **fencing tokens** |
| D1.6 | MCP gateway with contract-driven tool advertisement + RBAC |
| D1.7 | `labctl` with auto-renew and `STALE_FENCE` abort |
| D1.8 | Agents: explorer, investigator, verifier; LiteLLM LOW/MID/HIGH |
| D1.9 | Evidence bundles → artifact store; basic OTel |
| D1.10 | Recovery ladder rungs 1–9 |

**Gate 1 exit criteria:**

1. **100 consecutive** reserve → install → test → release cycles with zero manual intervention.
2. Automatic WDA restart and automatic USB reconnect both demonstrated under chaos injection.
3. One **end-to-end autonomous AI investigation** producing a complete, human-verifiable evidence
   bundle.
4. One authorised Frida investigation succeeds on the research device **and is refused with
   `CAPABILITY_UNAVAILABLE` on a stock device** — capability gating proven in both directions.
5. Claude Code and OpenCode both drive the gateway with identical tool surfaces.
6. Deterministic evidence IDs; bundles validate against the schema.

### 15.4 Phase 2 — Small lab (10–20 devices)

| Deliverable | Detail |
|---|---|
| D2.1 | Production scheduler: queues, priorities, aged fairness, affinity/anti-affinity |
| D2.2 | Health scoring, automatic quarantine, component asset history |
| D2.3 | Multiple workers; automated capability discovery on onboarding |
| D2.4 | CI integration (GitHub/GitLab/Jenkins/Buildkite via `labctl`) |
| D2.5 | Central artifacts, full OTel, dashboards, alerts |
| D2.6 | Full recovery ladder incl. per-port power control |
| D2.7 | MDM lifecycle integration incl. Return to Service |
| D2.8 | Agent result caching + the deterministic ratchet (§9.2) |
| D2.9 | Fleet conformance suite running continuously (§11.4) |

**Gate 2 exit criteria:** 10–20 devices serving real product CI; platform-domain flake rate < 2%;
recovery MTTR p90 ≤ 5 min; zero false product bugs attributable to misclassified platform failures
over 30 days; SLO baselines measured and ready to publish.

### 15.5 Phase 3 — Production (50–100 devices)

| Deliverable | Detail |
|---|---|
| D3.1 | HA control plane; PostgreSQL HA + PITR |
| D3.2 | Dedicated signing service with expiry prediction |
| D3.3 | Worker pools segmented by security class; research enclave fully isolated |
| D3.4 | Multiple racks; per-port power control everywhere; cell-aware anti-affinity |
| D3.5 | Strict RBAC, engagement records, immutable audit, retention + redaction |
| D3.6 | Chaos suite gating releases; DR runbooks; spare pool ≥ 10% |
| D3.7 | Capacity controller: draining, maintenance windows, admission by profile |

**Gate 3 exit criteria:** SLOs in §1.7 **published and met** for 30 days; DR exercise completed;
security review signed off; every runbook exercised at least once.

### 15.6 Phase 4 — Large scale (100–500+)

| Deliverable | Detail |
|---|---|
| D4.1 | Cell/rack-aware sharded scheduler; partitioned worker pools |
| D4.2 | Capacity reservations for release gates |
| D4.3 | Global + cell-local health; maintenance coordinator |
| D4.4 | Fleet inventory automation incl. cable/hub asset history and replacement workflow |
| D4.5 | Network QoS; artifact lifecycle tiers; high-volume OTel sampling |
| D4.6 | **Corellium appliance** integration as `corellium_virtual` (ADR-002) |
| D4.7 | **SRD pool** integration as `apple_srd` with programme-scope policy gates |
| D4.8 | Formal SRE on-call, error budgets, capacity forecasting |

**Gate 4 exit criteria:** 100+ devices at target SLOs; a single cell loss degrades rather than fails
a matrix run; modern-silicon research capability demonstrably available via Corellium and/or SRD.

### 15.7 Staffing

| Phase | Team | Focus |
|---|---|---|
| 0 | 2 engineers (1 iOS/device, 1 platform) + 0.25 security | Measurement, not construction |
| 1 | 4 (2 Go platform, 1 iOS/device, 1 AI/agents) + 0.25 SRE | POC |
| 2 | 6 (3 Go, 1 iOS/device, 1 AI, 1 SRE) + 0.5 security | Productionisation |
| 3 | 8 (3 Go, 2 iOS/device, 1 AI, 2 SRE) + 1 security | HA, scale, hardening |
| 4 | 9–10 + dedicated lab technician | Scale + physical fleet ops |

**Standing cost from Phase 1 onward:** ~1 FTE-equivalent of continuous maintenance against iOS and
Xcode releases. This is not a project line item; it is the permanent cost of operating on Apple's
platform (S12). Budget it explicitly or it will be paid in outages.

### 15.8 Cost model — the dimension neither research pass addressed

| Category | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|---|---|---|---|---|
| Devices | 3 + sims | 10–20 | 50–100 | 100–500+ |
| Mac workers | 1 | 2–3 | 6–10 | 15–40 |
| Managed hubs / PDUs / racks | 1 hub | 2–3 hubs | multi-rack | multi-rack |
| Apple Developer programme | 1 | 1 | 1 | 1 |
| Corellium | — | — | evaluate | licence (see ADR-002 trigger) |
| SRD | — | apply | if granted | if granted |
| Engineering | 4 FTE | 6 FTE | 8 FTE | 9–10 FTE |
| Maintenance (standing) | 0.5 FTE | 1 FTE | 1 FTE | 1–1.5 FTE |
| Replacement inventory | — | 10% spares | 10% spares | 10% spares + cable/hub budget |

**Build-vs-buy honesty:** commercial device farms exist and are cheaper at low volume. ORCHARD is
justified by the three things they cannot provide: **on-premises control of proprietary artifacts**,
**privileged research capability**, and **an agent-native capability-negotiating API**. If those three
are not genuine requirements, buy a commercial farm instead. That is a real decision, and it should
be made deliberately at Gate 0 rather than discovered at Gate 3.

---

## §16. Risk Register & Open Questions

### 16.1 Risk register

| # | Risk | Likelihood | Impact | Grade | Mitigation | Owner |
|---|---|---|---|---|---|---|
| R1 | **iOS version churn breaks tunnels/WDA** | High | High | V | Adapter layer absorbs churn; pinned builds; staging-cell certification before fleet migration; adapter-fallback-rate alerting as early warning | Platform |
| R2 | **No durable modern-silicon jailbreak** | High | High | V | Two-tier fleet; pinned A11–A13 pool; Corellium escalation (ADR-002); SRD if obtainable | Research |
| R3 | **Signing / provisioning expiry causes CI outage** | High | Medium | V | Signing service, expiry prediction at T-14d, capability degradation, automated renewal | Platform |
| R4 | GPL-3.0 entanglement via pymobiledevice3 | Medium | High | V | Subprocess isolation; CI licence scan hard-fails on linkage; go-ios as MIT alternative (ADR-003) | Legal + Platform |
| R5 | WDA memory growth / `xcodebuild` overhead | High | Medium | C | Prebuilt WDA; scheduled restarts between leases; measured in Phase 0 | Platform |
| R6 | Frida on jailed modern iOS is fragile | High | Medium | V/C | Gadget scope is app-only and advertised as such; never plan system-wide instrumentation on stock | Research |
| R7 | SRD legal/operational constraints | Medium | Medium | V | Separate device class; premises-bound policy; programme record; excluded from general pool | Legal |
| R8 | Malicious test app compromises research infrastructure | Medium | High | V | Isolated VLAN, disposable workers, no secrets, mandatory re-image | Security |
| R9 | USB / cable / hub reliability dominates at scale | High | Medium | C | Component asset history; per-port power; auto replace-flag at 3 events/30d | SRE |
| R10 | AI non-determinism misreported as truth | Medium | High | R | ORCHARD-AI1/AI3: deterministic gates, independent verifier, evidence-complete replay | AI |
| R11 | Prompt injection from target app content | Medium | High | T | Content fencing; policy independent of model output; injection-candidate logging | Security |
| R12 | Commercial farm secrecy leaves density unknowable | High | Low | V | Local empirical certification replaces guessed ratios (ADR-001) | Platform |
| R13 | Control-plane engineering effort underestimated | Medium | High | T | Phased gates; every phase independently useful; buy-vs-build revisited at Gate 0 | Leadership |
| R14 | Research device accidentally OS-updated | Medium | High | V | `frozen` label; excluded from update paths; attempted update is a P1 | SRE |
| R15 | Corellium cost or contract terms block adoption | Medium | Medium | C | Evaluate at Phase 3; keep physical research tier viable independently | Procurement |
| R16 | Evidence volume outgrows storage budget | Medium | Medium | T | Tiered retention; screenshot/video 30d default; sampling above threshold | SRE |

### 16.2 Open questions — must be closed in Phase 0

These are carried forward from both research passes **ungraded or contradictory**, and this document
refuses to state them as facts.

| # | Question | Status | Closure action |
|---|---|---|---|
| Q1 | **Apple SRD application window.** Doc A found press coverage saying the window ended October 2025 and Apple's own page saying "through October 2026" — a direct contradiction. | **U — unresolved** | Confirm directly with Apple before any procurement assumption. D0.13. |
| Q2 | **Dopamine 3.0 coverage claims.** Reported PPL/SPTM bypasses expanding modern coverage; not independently verified. | **U — unresolved** | Verify against the upstream repository's documented matrix and test on actual hardware before buying devices. D0.13. |
| Q3 | **Maestro physical-iOS support.** Upstream README advertises physical Android; iOS appears in the simulator matrix. | **U — unresolved** | Phase-0 empirical test. D0.12. Adopt, restrict to simulator, or drop. |
| Q4 | "TestCat" as referenced in the original brief. | **U — no credible evidence found** | Remains excluded. Do not promote on name recognition. |
| Q5 | Actual `worker.max_concurrent_sessions` per workload profile. | **C — estimated only** | D0.2. Blocks Gate 0. |
| Q6 | Offline-survival envelope duration. | **T — asserted, never measured** | D0.4. Blocks Gate 0. |
| Q7 | Adapter divergence: do devicectl, go-ios, libimobiledevice and pymobiledevice3 agree on the current iOS generation? | **C — unknown** | D0.3. Determines preference order. |
| Q8 | Xcode licensing at fleet scale for automated use. | **Open — legal** | Legal review before Phase 3. |
| Q9 | TrollStore's upstream licence (NOASSERTION). | **Open — legal** | Legal review before any redistribution. Operator-tool-only until resolved. |
| Q10 | Whether commercial device-farm procurement is the better answer for this organisation. | **Open — strategic** | Decide explicitly at Gate 0 using §15.8. |

**ORCHARD-Q1:** An open question may not be silently resolved by an implementer's assumption. Closing
one requires a documented experiment or a vendor confirmation, recorded in
`docs/compatibility/` or `docs/architecture/adr/`, with the grade promoted accordingly.

### 16.3 What this platform explicitly cannot do

Stated plainly, because ORCHARD-P1 applies to the specification as much as to the API:

On an ordinary retail iPhone, ORCHARD provides excellent UI automation, app deployment and lifecycle
control, logs, crashes, diagnostics, network capture, supported profiling, and debugging of eligible
application processes.

It **cannot** provide arbitrary Unix shell access, root filesystem access, arbitrary system-process
memory access, arbitrary runtime hooking, or `frida-server`. These are not missing features awaiting
implementation. They are consequences of the iOS security model, and any tool claiming otherwise on
stock hardware is either wrong or describing a jailbroken device.

A deliberately frozen jailbroken pool fills much of that gap on older silicon. Corellium fills it for
modern iOS without hardware fidelity. An Apple Security Research Device fills it with Apple's
sanction and Apple's constraints. Choosing among those three, per target, is what the capability
model exists to make explicit.

---

## §17. Appendices

### 17.1 Quick-reference: capability decision tree

```mermaid
flowchart TD
  START["Agent or CI needs capability X"] --> Q1{"Is X in the device's<br/>capability contract?"}
  Q1 -->|No| Q2{"Is X supported on ANY<br/>device class?"}
  Q2 -->|No| E1["CAPABILITY_UNAVAILABLE<br/>permanent. Re-plan."]
  Q2 -->|Yes| E2["CAPABILITY_UNAVAILABLE<br/>+ remediation: reserve class Y<br/>+ eligible_device_count"]
  Q1 -->|"Yes, but degraded"| E3["CAPABILITY_DEGRADED<br/>retry after recovery,<br/>or request another device"]
  Q1 -->|Yes| Q3{"Does the principal's role<br/>grant X?"}
  Q3 -->|No| E4["Tool NOT ADVERTISED<br/>(agent never sees it)"]
  Q3 -->|Yes| Q4{"Is the target within<br/>the engagement scope?"}
  Q4 -->|No| E5["403 NOT_AUTHORISED<br/>escalate to a human"]
  Q4 -->|Yes| Q5{"Budget remaining?"}
  Q5 -->|No| E6["POLICY_BUDGET_EXCEEDED<br/>abort loop, capture, escalate"]
  Q5 -->|Yes| Q6{"Fencing token current?"}
  Q6 -->|No| E7["409 STALE_FENCE<br/>abort immediately"]
  Q6 -->|Yes| OK["Execute + audit + evidence"]

  style OK fill:#2d6b3d,color:#fff
  style E1 fill:#6b2d2d,color:#fff
  style E7 fill:#6b2d2d,color:#fff
```

### 17.2 Android → iOS translation table

For teams arriving from an ADB/ARTEMIS mental model. **This table is the fastest way to prevent wrong
assumptions.**

| Android | Closest iOS equivalent | Critical difference |
|---|---|---|
| ADB transport | usbmux + CoreDevice/RemoteXPC | Multiple protocols and services, not one universal interface |
| `adb devices` | `devicectl list devices`, `go-ios list`, `idevice_id -l` | Straightforward; reconcile multiple views |
| `adb install` | `devicectl device install app` / installation proxy / MDM | Signing and provisioning rules are substantially stronger |
| UIAutomator | XCTest / XCUITest / WDA | Good UI automation, but requires test-host + signing infrastructure |
| `logcat` | OSLog / syslog / crash services | No single identical universal stream; on-device retention is volatile |
| **`adb shell`** | **No equivalent on stock retail iOS** | **Fundamental capability gap** |
| `adb root` | Jailbreak / SRD / Corellium | Not a stock retail-device option |
| `adb forward` | usbmux / `iproxy` / RemoteXPC | Achievable |
| `adb pull` (app data) | AFC / House Arrest | Container-scoped, dev-signed apps only |
| Root filesystem | None on stock | Jailbreak / SRD / Corellium only |
| Arbitrary process attach | None on stock | Debug-entitled target only |
| `frida-server` | Jailbreak / SRD / Corellium | Stock uses Gadget in a re-signable app, app-scoped |
| `scrcpy` | WDA MJPEG stream | Not raw framebuffer access |
| Fastboot / recovery | CoreDevice recovery / DFU tooling | Strong, different API model |
| Google's ARTEMIS | ORCHARD | ARTEMIS builds on a stock shell + root-optional Frida. **An iPhone ARTEMIS is necessarily two-tier**: a broad stock tier (UI, lifecycle, logs, crashes, screenshots, profiling) and a narrow privileged tier. |

### 17.3 Requirement index

| ID | Requirement | Section |
|---|---|---|
| ORCHARD-P1 | The Honesty Principle — ergonomics without claimed parity | §1.3 |
| ORCHARD-E1 | Grade-C numbers never become guarantees | §0.3 |
| ORCHARD-C1 | Contract computed per `(device, principal)` | §3.4 |
| ORCHARD-C2 | MCP advertises only contracted tools | §3.4 |
| ORCHARD-C3 | Device availability ≠ target authorisation | §3.4.1 |
| ORCHARD-C4 | Every error carries a failure domain | §3.5 |
| ORCHARD-A1 | Control plane never touches USB | §4.3 |
| ORCHARD-A2 | No direct adapter imports outside the worker | §4.3 |
| ORCHARD-A3 | Fencing enforced at the worker, not just the scheduler | §4.3 |
| ORCHARD-H1 | A cell is the smallest fault domain | §5.1 |
| ORCHARD-H2 | The worker owns its devices entirely | §5.1 |
| ORCHARD-H3 | No consumer USB hubs in production | §5.6 |
| ORCHARD-H4 | No flat 500-device topology; cells are schedulable | §5.8 |
| ORCHARD-R1 | Buy and freeze known-good research combinations | §5.4 |
| ORCHARD-R2 | Research devices are excluded from all update paths | §5.4 |
| ORCHARD-R3 | SRD is its own class, never pooled | §5.5 |
| ORCHARD-REG1 | UDIDs are vault-referenced | §6.2 |
| ORCHARD-REG2 | Continuous discovery reconciliation | §6.2 |
| ORCHARD-SCH1 | Monotonic fencing tokens are mandatory | §6.3.3 |
| ORCHARD-SCH2 | Only TEST/APP failures are product signals | §6.5 |
| ORCHARD-REC1 | Graduated ladder with rung budgets | §6.6 |
| ORCHARD-REC2 | Per-port power is the key automated rung | §6.6 |
| ORCHARD-REC3 | MDM is the destructive channel, not the UI channel | §6.6 |
| ORCHARD-POL1 | Deny by default | §6.8 |
| ORCHARD-POL2 | Privileged capabilities require all five gates | §6.8 |
| ORCHARD-POL3 | Device content never changes privileges | §6.8 |
| ORCHARD-W1 | Do not fight Apple's host plumbing | §7.1 |
| ORCHARD-W2 | Typed adapter layer with declared preference order | §7.3 |
| ORCHARD-W3 | pymobiledevice3 is subprocess-only | §7.3 |
| ORCHARD-W4 | Pinned `versions.lock` | §7.4 |
| ORCHARD-W5 | Prebuilt WDA over per-session xcodebuild | §7.5 |
| ORCHARD-W6 | Scheduled WDA restarts between leases | §7.5 |
| ORCHARD-W7 | Track WDA build hash and provisioning expiry | §7.5 |
| ORCHARD-W8 | Deterministic port and derived-data allocation | §7.6 |
| ORCHARD-W9 | Reviewed Frida templates, not raw agent scripts | §7.7 |
| ORCHARD-W10 | Research workers hold no secrets | §7.8 |
| ORCHARD-API1 | One schema generates REST, CLI, MCP, SDKs | §8.1 |
| ORCHARD-API2 | ADB-shaped surface, honest errors | §8.2 |
| ORCHARD-API3 | `labctl` aborts on STALE_FENCE | §8.3 |
| ORCHARD-API4 | Client configs are Phase-0 validated and pinned | §8.4.3 |
| ORCHARD-API5 | Record both model class and resolved model | §8.6 |
| ORCHARD-AI1 | No release gate depends on an agent decision | §9.1 |
| ORCHARD-AI2 | The ratchet: discoveries become deterministic tests | §9.2 |
| ORCHARD-AI3 | The verifier is structurally independent | §9.3 |
| ORCHARD-AI4 | Classification: app / OS / device / infra | §9.3 |
| ORCHARD-AI5 | Escalation is evidence-driven and logged | §9.4 |
| ORCHARD-AI6 | Budget breach aborts and escalates | §9.5 |
| ORCHARD-AI7 | Replay = evidence-complete, not bitwise | §9.7 |
| ORCHARD-AI8 | Privilege derives only from principal + engagement | §9.8 |
| ORCHARD-ENG1 | Capability claims carry Grade + Certified | §10.5 |
| ORCHARD-T1 | Regression tests for fencing/scheduling/recovery/policy | §11.2 |
| ORCHARD-T2 | Negative conformance assertions are P1 signals | §11.4 |
| ORCHARD-T3 | Chaos suite gates releases | §11.6 |
| ORCHARD-CD1 | Deploys never interrupt in-flight leases | §12.1 |
| ORCHARD-CD2 | Staging is real hardware, all classes | §12.1 |
| ORCHARD-CD3 | iOS/Xcode change = fleet migration | §12.3 |
| ORCHARD-CD4 | Frozen devices excluded from Pipeline B | §12.3 |
| ORCHARD-CD5 | Deterministic suite is the gate | §12.4 |
| ORCHARD-SIGN1-5 | Signing service rules | §12.5 |
| ORCHARD-OBS1-6 | Telemetry, evidence, retention, runbooks | §13 |
| ORCHARD-SEC1-6 | Segmentation, research workflow, secrets | §14 |
| ORCHARD-LEG1-2 | SBOM scope; authorised targets only | §14.5 |
| ORCHARD-Q1 | Open questions close by experiment, not assumption | §16.2 |

### 17.4 Anti-patterns — things that look reasonable and are not

| Anti-pattern | Why it fails |
|---|---|
| "Just SSH from Claude Code to the Mac mini." | No leases, no fencing, no capability model, no audit, no recovery. It works for two devices and collapses at ten. |
| Making Appium the control plane. | Appium is a UI adapter. It has no concept of inventory, fault domains, signing state, or privilege. |
| Making an MCP server the platform. | MCP is a protocol for exposing tools. It says nothing about scheduling, USB ownership, health or safety. |
| One `jailbroken: true/false` flag. | TrollStore, rootless, rootful and SRD are four different capability sets. |
| Publishing "N iPhones per Mac". | Workload-dependent. Publishing it guarantees it will be wrong for someone. |
| Reboot-first recovery. | A single element timeout costs 90 seconds of reboot and loses all session state. |
| Storing a passcode to unlock devices. | Unattended unlock is deliberately restricted; it fails precisely after a reboot, when recovery needs it. |
| Sharing one MJPEG port across sessions. | Causes silent video cross-talk between devices. |
| Letting the agent that formed a hypothesis confirm it. | Produces confident, wrong conclusions with a screenshot attached. |
| Treating a `WDA_FAILURE` as a test failure. | Manufactures false product bugs and destroys trust in the lab. |
| Importing pymobiledevice3 as a library. | GPL-3.0 linkage plus maximal blast radius from private-protocol churn. |
| Assuming a current iPhone can be jailbroken. | There is no public durable jailbreak for current silicon on current iOS. |
| Planning system-wide Frida on stock devices. | Gadget is app-scoped and fragile on jailed modern iOS. |
| Air-gapping and assuming signing keeps working. | Signing validation and activation retain Apple-service dependencies. |
| Skipping Phase 0 to "start building". | Every architectural assumption in this document is grade-C until measured. This is the most expensive mistake available. |

### 17.5 Compliance matrix template

Tracked per release in `docs/architecture/compliance.md`:

| Requirement | Implemented in | Tested by | Status | Evidence |
|---|---|---|---|---|
| ORCHARD-SCH1 | `control-plane/internal/scheduler/fence.go` | `fence_property_test.go`, chaos `revoke-mid-command` | ✅ | run `wf_...` |
| ORCHARD-C2 | `mcp/gateway/tools.go` | `mcp/conformance/absence_test.go` | ✅ | run `wf_...` |
| ... | ... | ... | ... | ... |

### 17.6 Source bibliography

**Apple primary:** Developer Mode (iOS 16+); `devicectl` / CoreDevice; `simctl`; Instruments and
`xctrace`; MetricKit; XCTest attachments; MDM commands, supervision, Return to Service, declarative
device management and device health; Security Research Device programme (shell access, arbitrary
entitlements, custom kernel caches, programme scope exclusions).

**Automation:** Appium XCUITest driver (Apache-2.0, Appium 3 generation; parallel-session isolation
via `wdaLocalPort` / `mjpegServerPort` / `derivedDataPath`; preinstalled-WDA flows; RemoteXPC
handling); WebDriverAgent (Appium fork); real-device code-signing and provisioning requirements
including online-validation considerations.

**Device services:** libimobiledevice (usbmuxd, `idevice_id`, `ideviceinfo`, `ideviceinstaller`,
`idevicesyslog`, `idevicecrashreport`, `idevicescreenshot`, `idevicediagnostics`, `ifuse`, `iproxy`);
pymobiledevice3 (GPL-3.0; RemoteXPC/DVT, PCAP, WebInspector, recovery, `tunneld`); go-ios (MIT; CLI +
REST, `tunnel start`, `runwda`, `image auto`, `devicestate`, JSON output).

**Instrumentation:** Frida iOS documentation — jailbroken `frida-server` vs jailed Gadget modes, and
the jailed code-signing restriction on `Interceptor`; Objection; OWASP MASTG; community reports of
Gadget-patched apps crashing on recent jailed iOS.

**Research devices:** palera1n (checkm8, A8–A11, iOS 15+, A11 passcode constraint); Dopamine (opa334,
rootless semi-untethered, arm64e ranges with extended A12/A13 coverage; v3.0 claims **unconfirmed**);
TrollStore (CoreTrust-based permasigning, documented version windows, explicitly not system-process
tweak injection, NOASSERTION upstream licence metadata).

**Virtualisation:** Corellium (ARM-native virtualized iOS, on-prem/air-gappable appliance, instant
root, snapshots, REST API; commercial).

**Agent/MCP ecosystem (references and seeds, not the platform):** mobile-next/mobile-mcp
(accessibility-first, no vision model required); UgeeCodes/iOS-agent-bridge (iOS 17 tunnel + WDA +
MCP); blitzdotdev/iPhone-mcp; srmorete/mobile-device-mcp; getsentry/XcodeBuildMCP (MIT; dev-agent
helper); minitap/runablehq mobile-use (Android-first); droidrun; takahirom/arbigent (result caching);
witchan/ios-mcp (jailbroken-only tool surface); Lakr233/iphone-mcp; Maestro (Apache-2.0, MCP,
**physical-iOS support unverified**); AppiumTestDistribution/appium-device-farm;
DeviceFarmer/stf_ios_support (legacy video-path limitation); google/artemis.

**Benchmarks:** iOSWorld (2026 native iOS agent benchmark — substantial remaining difficulty on
complex multi-application tasks; combined visual + structured UI information improves performance);
SWE-Bench Mobile (low end-to-end success rates relative to CI requirements; agent architecture
matters as much as the model).

**Infrastructure:** Cambrionix SuperSync / ThunderSync and USB endpoint technical notes; Acroname
USBHub3c / USBHub3+; Apple Developer Forums `cfgutil` ceiling reports; AWS Device Farm host model;
Agoda "200 Mac minis" (**simulators on virtualized macOS — not physical-device evidence**);
ElcomSoft on unified-log retention volatility.

**Platform:** Model Context Protocol; Claude Code MCP configuration; OpenCode MCP configuration
(distinct schema); LiteLLM; OpenTelemetry; NATS JetStream; PostgreSQL.

---

## Closing statement

ORCHARD is not "Appium at scale". It is an **iOS research operating layer**: a capability-negotiating
control plane that tells the truth about what each piece of hardware can actually do, schedules that
hardware safely, recovers it automatically, gives autonomous agents meaningful but policy-limited
investigative power, keeps deterministic tests as the release gate, and produces evidence a human can
audit years later.

Two independent research passes converged on that architecture. They disagreed about numbers, about
vendors, and about which risks deserved the most weight — and every one of those disagreements is
recorded in §2 with a ruling and a reason. What neither could settle from documentation alone is
recorded in §16.2 as an open question with an experiment attached.

The single most important instruction in this document is the one both passes reached independently
and from opposite directions:

> **Measure before you build, and never claim a capability the hardware does not have.**
