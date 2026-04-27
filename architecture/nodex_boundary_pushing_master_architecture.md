# Nodex Boundary-Pushing Master Architecture

## Core thesis

> Intelligence, however super it is, is useless without the correct context.

Nodex is not being built as a bigger chatbot, a prompt stack, or a generic agent wrapper.

Nodex is being built as a proof-governed local cognition substrate: a system where models, tools, code, memory, context, evidence, and humans interact through typed contracts and validated state transitions.

The system goal is not to make AI output more persuasive.

The system goal is to make unreliable intelligence usable by forcing every action through context, constraint, proof, authority ranking, provenance, and rollback.

The central rule:

```text
Do not trust agent output.
Do not trust memory.
Do not trust retrieval.
Do not trust tool calls.
Do not trust summaries.
Do not trust commits.

Only trust validated state transitions.
```

That rule is the foundation.

---

# 1. Direction

Current AI systems are mostly advancing along this path:

```text
more context
more tools
more agents
more automation
more memory
more integration
```

That direction is useful, but incomplete.

More intelligence without correct context causes drift.

More tools without capability contracts causes unsafe execution.

More memory without provenance stores hallucinated history.

More agents without authority ranking creates conflict.

More autonomy without rollback risks system damage.

Nodex should take a different path:

```text
models propose
tools act
graphs constrain
evidence proves
validators decide
memory records
repair improves
humans authorize boundary expansion
```

This turns intelligence into a component, not an authority.

---

# 2. Current validated architecture direction

The active Nodex proof loop is:

```text
intent
  -> TaskGraph
  -> bounded agent task packet
  -> Codex/model/tool execution
  -> raw transcript
  -> TranscriptParser
  -> TranscriptEvidenceAdapter
  -> EvidenceGate
  -> MemoryCapsule
  -> ContextLedger
  -> ValidityGraph
  -> next task / rollback / repair
```

Near-term staged sequence:

```text
1. TaskGraph
2. AgentHandoffPacket
3. AgentHandoffBridge
4. AgentHandoffRunner
5. TranscriptParser
6. TranscriptEvidenceAdapter
7. EvidenceGate
8. CommitGate
9. MemoryCapsule
10. ContextLedger
11. ValidityGraph
12. RepairGraph
13. CapabilityGraph
14. PolicyGraph
15. ProvenanceGraph
16. Multi-agent proof loop
17. Local UI / operator console
```

The high-level destination:

```text
A local proof-bearing intelligence substrate where no model is trusted and only validated state transitions affect durable system state.
```

---

# 3. Master tier stack

## Foundation tiers

### Tier 0 — Boundary Constitution

Purpose:

Define the non-negotiable laws of Nodex.

Artifacts:

```text
AGENTS.md
project instructions
phase rules
trust hierarchy
allowed behavior
forbidden behavior
approval rules
```

Question answered:

```text
What is Nodex never allowed to become?
```

Prevents:

```text
scope drift
prompt drift
accidental autonomy
unbounded execution
unsafe tool use
```

Rule:

```text
The constitution constrains every later tier.
No downstream module may weaken it.
```

---

### Tier 1 — Execution Graph

Current module:

```text
TaskGraph
```

Purpose:

Control ordered execution.

Question answered:

```text
What is the next valid action?
```

Responsibilities:

```text
define task steps
enforce ordering
track pending / in_progress / passed / failed states
prevent step skipping
require evidence for gated transitions
```

Prevents:

```text
out-of-order execution
multiple active steps
validating the wrong thing
moving forward after failure
```

---

### Tier 2 — Handoff Graph

Current / near modules:

```text
AgentHandoffPacket
AgentHandoffBridge
AgentHandoffRunner
```

Purpose:

Convert a valid task step into a bounded agent work packet.

Question answered:

```text
What exactly may an agent do, touch, and prove?
```

Responsibilities:

```text
define allowed files
define forbidden files
define expected dirty state
define required validation gates
bind packet to TaskGraph step
prevent agent scope expansion
```

Prevents:

```text
Codex wandering
wrong-file edits
hidden assumptions
task expansion
unbounded implementation
```

---

### Tier 3 — Evidence Graph

Current modules:

```text
TranscriptParser
TranscriptEvidenceAdapter
EvidenceGate
```

Purpose:

Convert raw terminal or Codex output into admissible evidence.

Question answered:

```text
What proof is acceptable?
```

Responsibilities:

```text
parse raw transcript
extract candidate evidence
adapt evidence into strict schema
reject unsupported evidence
block claimed success without proof
```

Prevents:

```text
trusting fluent output
trusting stale logs
trusting unverified Codex summaries
treating git status as validation evidence
accepting fake success markers
```

---

### Tier 4 — Memory Capsule Layer

Current module:

```text
MemoryCapsule
```

Purpose:

Store completed seam facts only after validation.

Question answered:

```text
What completed work is safe to remember?
```

Responsibilities:

```text
record seam
record phase
record commit
record files
record accepted evidence
record summary
preserve validated completion state
```

Prevents:

```text
remembering uncommitted work
storing hallucinated progress
mixing stale output with live state
```

---

### Tier 5 — Context Ledger

Active seam:

```text
ContextLedger v1
```

Correct boundary:

```text
validated MemoryCapsule facts
  -> append-only in-memory ContextLedger record
```

Purpose:

Append validated memory capsules into ordered context records.

Question answered:

```text
What happened, in what order, with what proof?
```

Responsibilities:

```text
record ordered system history
validate sequence numbers
reject duplicate record IDs
preserve immutable record snapshots
prevent context reordering
```

Important constraint:

```text
ContextLedger v1 is not persistence.
ContextLedger v1 is not filesystem storage.
ContextLedger v1 is not contextExporter.
ContextLedger v1 is an in-memory deterministic schema/runtime layer.
```

Prevents:

```text
context collapse
stale uploads overriding live repo state
repeating completed work
losing validated seam order
```

---

## Truth and authority tiers

### Tier 6 — Validity Graph

Purpose:

Rank and relate claims by authority.

Question answered:

```text
What is true, stale, contradicted, superseded, or active?
```

Example:

```text
Claim:
  Agent Handoff Packet v1 is committed

Supported by:
  commit hash 4745541
  clean post-commit status
  passing post-commit tests

Supersedes:
  stale uploaded transcript showing packet as uncommitted

Blocks:
  rerunning Agent Handoff Packet implementation

Enables:
  Agent Handoff Bridge v1
```

Responsibilities:

```text
represent claims
rank evidence
track supersession
track contradiction
mark active state
mark stale state
mark blocked actions
```

Prevents:

```text
old evidence looking current
uploaded stale files overriding live repo
repeating already completed seams
trusting summaries over commit proof
```

This is the next-tier text graph.

Text is no longer stored as content only. Text becomes:

```text
typed claims
constraints
decisions
evidence
contradictions
supersessions
authority-ranked state transitions
```

---

### Tier 7 — Provenance Graph

Purpose:

Track origin, transformation, actor, and proof path for every state object.

Question answered:

```text
Where did this fact come from, who or what produced it, and what transformed it?
```

Node types:

```text
Entity
Activity
Agent
Artifact
Transcript
Commit
ValidationResult
MemoryRecord
```

Edge types:

```text
produced_by
derived_from
validated_by
generated_during
committed_as
superseded_by
rejected_by
```

Responsibilities:

```text
preserve source lineage
bind outputs to producers
bind commits to evidence
bind memory to validation
bind repairs to failure causes
```

Prevents:

```text
orphaned facts
untraceable memory
ambiguous source authority
confusing Codex output with accepted proof
```

---

### Tier 8 — Repair Graph

Purpose:

Convert failures into reusable repair knowledge.

Question answered:

```text
How does the system recover without guessing?
```

Shape:

```text
failure
  -> boundary
  -> cause
  -> repair candidate
  -> validation result
  -> reusable rule
```

Failure node examples:

```text
wrong_seam
missing_marker
dirty_state_mismatch
forbidden_file_modified
syntax_failure
test_failure
stale_evidence
prompt_drift
```

Responsibilities:

```text
classify failure
locate boundary
separate symptom from cause
record successful repair
prevent repeat failure
```

Prevents:

```text
manual repeated troubleshooting
guessing from symptoms
losing lessons across sessions
repairing the wrong layer
```

---

### Tier 9 — Capability Graph

Purpose:

Represent every model, tool, local service, hardware function, and API as a contract.

Question answered:

```text
What can Nodex safely use right now?
```

Capability fields:

```text
capabilityId
provider
type
input contract
output contract
allowed side effects
forbidden side effects
required validation gates
cost
latency
risk
current health
last verified timestamp
```

Examples:

```text
codex_cli
ollama_local
lm_studio_server
python_sandbox
git
node_test_harness
filesystem_read
filesystem_write
image_generation
video_generation
audio_transcription
hardware_sensor
```

Prevents:

```text
tool sprawl
unsafe routing
assuming a model/tool can do something because it exists
calling unavailable services
using high-risk tools without gates
```

---

### Tier 10 — Policy / Constraint Graph

Purpose:

Make rules executable instead of advisory.

Question answered:

```text
What is forbidden, allowed, conditional, or requires human approval?
```

Constraint examples:

```text
no repo writes outside allowed files
no persistence unless seam explicitly allows it
no model calls inside pure validators
no commit without clean post-test state
no generated evidence inside repo unless ignored
no broad refactor during stabilization
human approval required for destructive commands
```

Responsibilities:

```text
normalize policy
evaluate proposed action
block invalid action
explain violated constraint
require approval when needed
```

Prevents:

```text
Codex ignoring task contract
silent file modification
unapproved persistence
unsafe automation
policy existing only in prompts
```

---

### Tier 11 — Epistemic Graph

Purpose:

Represent knowledge claims by domain, method, confidence, evidence type, and validation standard.

Question answered:

```text
What does Nodex know, how does it know it, and under which rules is it valid?
```

Fields:

```text
claim
domain
source type
evidence type
validation method
confidence
uncertainty
contradiction links
supersession links
scope
limits
```

Domain examples:

```text
software engineering
mathematics
physics
electronics
vehicle systems
linguistics
history
theology
philosophy
neuroscience
biophysics
symbolic systems
```

Prevents:

```text
mixing empirical claims with textual claims
mixing speculation with proof
flattening all domains into one validation standard
treating confidence as truth
```

---

## Improvement tiers

### Tier 12 — Evaluation Graph

Purpose:

Make improvement measurable and hard to game.

Question answered:

```text
Did the system actually improve?
```

Fields:

```text
benchmark task
baseline result
candidate result
metric
regression check
acceptance threshold
adversarial counter-test
result
```

Responsibilities:

```text
compare before/after
detect regressions
score improvements
prevent metric gaming
record accepted improvement
```

Prevents:

```text
self-congratulatory improvement claims
worse code passing because one example worked
optimizing one test while breaking another
```

---

### Tier 13 — Multi-Strategy Competition Graph

Purpose:

Force multiple approaches to compete under objective scoring.

Question answered:

```text
Which solution survives comparison?
```

Flow:

```text
task
  -> candidate A
  -> candidate B
  -> candidate C
  -> isolated execution
  -> scoring
  -> winner
  -> memory capsule
```

Candidate dimensions:

```text
correctness
minimality
risk
complexity
performance
test coverage
reversibility
constraint compliance
```

Prevents:

```text
single-attempt tunnel vision
model self-justification
accepting first plausible solution
```

---

### Tier 14 — Multi-Agent Proof Market

Purpose:

Let multiple models/tools propose, critique, verify, refute, compress, and repair, but only proof-bearing outputs affect state.

Question answered:

```text
Which agent contribution survives adversarial validation?
```

Agent roles:

```text
proposer
implementer
critic
verifier
reducer
repair planner
regression tester
security reviewer
domain specialist
```

Rule:

```text
Agents may compete.
Validators decide.
Memory records only accepted proof.
```

Prevents:

```text
one model dominating state
unchecked agent consensus
agent debate without validation
multi-agent hallucination amplification
```

---

### Tier 15 — Simulation / Sandbox World Graph

Purpose:

Test actions in simulated or isolated environments before touching real state.

Question answered:

```text
What happens if this action is attempted?
```

Examples:

```text
temp repo clone
candidate worktree
mock filesystem
dry-run command graph
fake API response
sandboxed code execution
synthetic hardware state
```

Responsibilities:

```text
simulate risky action
capture expected effects
compare with actual result
block unexpected side effects
```

Prevents:

```text
real-state corruption
accidental commits
dependency breakage
unsafe tool calls
```

---

### Tier 16 — Formal Contract Layer

Purpose:

Move critical boundaries from tested behavior toward mechanically checkable invariants.

Question answered:

```text
Can this state transition be proven invalid before execution?
```

Possible later tools:

```text
JSON Schema
property-based tests
state-machine tests
type contracts
SAT checks
SMT checks
model checking for small state machines
```

Responsibilities:

```text
define invariants
generate counterexamples
prove impossible states invalid
harden critical modules
```

Prevents:

```text
bugs hidden by narrow examples
state-machine edge failures
invalid transitions reaching runtime
```

---

### Tier 17 — Secure Execution / Isolation Layer

Purpose:

Make unsafe code execution and tool invocation bounded by containment.

Question answered:

```text
Can this run without escaping its authority?
```

Includes:

```text
sandbox root enforcement
symlink protection
import blocking
timeout enforcement
subprocess policy
environment control
artifact limits
network policy
secret isolation
```

Responsibilities:

```text
contain execution
limit resources
block escape paths
capture outputs
classify failures
```

Prevents:

```text
filesystem escape
runaway process
unsafe import
secret leak
unbounded artifact generation
```

---

## Control and autonomy tiers

### Tier 18 — Human Intent / Approval Graph

Purpose:

Represent which decisions require Zak, which can be automated, and which are never allowed.

Question answered:

```text
Who has authority over this transition?
```

Decision classes:

```text
auto-allowed
auto-blocked
requires human approval
requires external evidence
requires clean repo
requires rollback plan
requires manual inspection
```

Examples requiring approval:

```text
delete files
rewrite architecture
modify forbidden directories
run destructive git commands
change persistent memory policy
connect new external service
enable autonomous loop
```

Prevents:

```text
unsafe autonomy
hidden escalation
destructive action without consent
confusing suggestion with authorization
```

---

### Tier 19 — Agent Runtime Integration Layer

Purpose:

Connect Codex, local models, LM Studio, Ollama, tools, and future services through adapters.

Question answered:

```text
How does Nodex invoke external intelligence without trusting it?
```

Adapters:

```text
Codex CLI adapter
Codex app-server adapter
OpenAI API adapter
Ollama adapter
LM Studio adapter
MCP adapter
local tool adapter
hardware adapter
```

Critical rule:

```text
Transport is not trust.
Connection is not validation.
Agent output must still pass evidence gates.
```

Prevents:

```text
confusing connected with safe
letting model output bypass validators
trusting SDK responses as system truth
```

---

### Tier 20 — Autonomous Proof Loop

Purpose:

Allow Nodex to propose, execute, validate, commit, repair, and continue within hard constraints.

Question answered:

```text
Can Nodex safely advance itself one bounded seam at a time?
```

Required preconditions:

```text
ContextLedger active
ValidityGraph active
RepairGraph active
CapabilityGraph active
PolicyGraph active
CommitGate active
rollback path active
human approval graph active
```

Loop:

```text
validated state
  -> propose next bounded task
  -> generate TaskGraph
  -> create AgentHandoffPacket
  -> execute through runner
  -> parse transcript
  -> adapt evidence
  -> gate evidence
  -> commit or rollback
  -> write memory capsule
  -> append context ledger
  -> update validity graph
  -> repair or advance
```

Prevents:

```text
reckless autonomy
unbounded self-modification
silent failure accumulation
drift disguised as progress
```

---

## Frontier expansion tiers

### Tier 21 — Research / Hypothesis Graph

Purpose:

Let Nodex explore unknown domains without confusing speculation with fact.

Question answered:

```text
What hypotheses are worth testing, and what would falsify them?
```

Fields:

```text
hypothesis
domain
prior evidence
test design
falsification criteria
result
status
uncertainty
next experiment
```

Applies later to:

```text
physics
bioelectricity
neuroscience
electromagnetic phenomena
symbolic systems
ancient texts
language roots
hardware experiments
software architecture
```

Prevents:

```text
turning speculation into memory
claim inflation
unfalsifiable system beliefs
```

---

### Tier 22 — Self-Model / System Introspection Graph

Purpose:

Let Nodex model its own components, constraints, weaknesses, and upgrade paths.

Question answered:

```text
What is Nodex, what can it do, what can it not do, and what is unstable?
```

Includes:

```text
component inventory
seam maturity
known failure modes
validation coverage
risk map
current bottlenecks
next safe upgrade
```

Prevents:

```text
hallucinated capabilities
repeating old mistakes
acting as if incomplete systems are complete
```

---

### Tier 23 — UI / Operator Console

Purpose:

Expose the proof loop clearly to Zak.

Question answered:

```text
What is happening, what changed, what evidence supports it, and what needs approval?
```

Views:

```text
current seam
repo state
task graph
handoff packet
Codex output
evidence graph
validation result
commit/rollback control
context ledger
validity graph
repair suggestions
```

Do not build early.

Rule:

```text
UI before proof hides chaos.
Proof before UI makes the UI meaningful.
```

---

### Tier 24 — Distributed / Multi-Device Local Mesh

Purpose:

Allow Nodex to use multiple local machines/services while preserving contracts.

Question answered:

```text
Which machine/tool performed which action under what authority?
```

Examples:

```text
desktop GPU machine
laptop controller
car/nav hardware experiments
media generation box
local model server
storage node
sensor node
```

Requires first:

```text
CapabilityGraph
ProvenanceGraph
PolicyGraph
Secure Execution Layer
Human Approval Graph
```

Prevents:

```text
distributed confusion
unsafe hardware actions
untraceable multi-device state
```

---

### Tier 25 — Domain Expert Modules

Purpose:

Add validated reasoning modules for specific domains.

Question answered:

```text
How does Nodex reason correctly inside this domain?
```

Examples:

```text
math checker
geometry module
trig module
unit conversion module
physics module
chemistry module
electronics module
vehicle wiring module
code safety analyzer
philology module
textual source module
scientific claim validator
hardware diagnostic module
```

Rule:

```text
Domain modules must inherit the proof substrate.
They do not bypass it.
```

Prevents:

```text
domain hallucination
unsafe technical advice
unverified calculations
mixing expert output with proof
```

---

# 4. Correct hierarchy

```text
FOUNDATION
0  Boundary Constitution
1  Execution Graph
2  Handoff Graph
3  Evidence Graph
4  Memory Capsule Layer
5  Context Ledger

TRUTH / AUTHORITY
6  Validity Graph
7  Provenance Graph
8  Repair Graph
9  Capability Graph
10 Policy / Constraint Graph
11 Epistemic Graph

IMPROVEMENT
12 Evaluation Graph
13 Multi-Strategy Competition Graph
14 Multi-Agent Proof Market
15 Simulation / Sandbox World Graph
16 Formal Contract Layer
17 Secure Execution / Isolation Layer

CONTROL / AUTONOMY
18 Human Intent / Approval Graph
19 Agent Runtime Integration Layer
20 Autonomous Proof Loop

FRONTIER EXPANSION
21 Research / Hypothesis Graph
22 Self-Model / System Introspection Graph
23 UI / Operator Console
24 Distributed / Multi-Device Local Mesh
25 Domain Expert Modules
```

---

# 5. Correct build order

Immediate:

```text
1. Recover wrong ContextLedger seam
2. Implement pure ContextLedger v1
3. Validate and commit ContextLedger v1
```

Then:

```text
4. ValidityGraph v1
5. CommitGate automation
6. AgentHandoffRunner v1
7. RepairGraph v1
8. CapabilityGraph v1
9. PolicyGraph v1
10. ProvenanceGraph v1
```

Then:

```text
11. Codex App Server / SDK integration
12. MCP-style tool adapters
13. multi-agent critique loop
14. autonomous proof loop
15. UI / operator console
16. domain expert modules
17. distributed local mesh
```

Why this order:

```text
If we connect agents before validity exists:
faster drift.

If we build memory before evidence exists:
stored hallucination.

If we build UI before contracts exist:
pretty chaos.

If we build autonomy before rollback exists:
system damage.

If we build graph validity first:
every later capability becomes safer.
```

---

# 6. Hard rule for pushing boundaries

The farther Nodex goes, the stricter it must become.

```text
more capability requires stricter validation
more agents require stronger authority ranking
more memory requires stronger provenance
more tools require stronger capability contracts
more autonomy requires stronger rollback
more intelligence requires better context
```

The core operating thesis:

```text
Intelligence is not enough.

Correct context is not enough.

The winning structure is:
intelligence + correct context + constraint + evidence + authority + repair.
```

Or shorter:

```text
Intelligence proposes.
Context orients.
Constraints bound.
Evidence proves.
Authority ranks.
Repair improves.
```

That is Nodex.
