# NODEX PACKET GENERATION RULES v1

Stable packet-generation constraints for Nodex PowerShell packets.

This file is stable guidance only.
It is NOT live evidence.
It is NOT authority state.
It does NOT mark any seam passed.

Live state must come from:
- current_handoff.md
- evidence_latest/latest_summary.txt
- evidence_latest/latest.json

Local Nodex evidence remains authority.

## Post-result continuity sync

All future Nodex packets should include post-result continuity sync.

The Nodex seam result and continuity sync result must be separate.

Required result fields:
- status: pass|fail
- continuity_sync: pass|fail|skipped

Do not convert a passed Nodex seam into failed because GitHub continuity push failed.
Do not convert a failed Nodex seam into passed because GitHub continuity push succeeded.

Continuity sync may update and push only:
C:\Users\Zak\OneDrive\Desktop\nodex-live-context

Continuity sync must never stage, commit, push, mutate, or delete anything inside:
C:\Users\Zak\OneDrive\Desktop\Nodex System\Node

Continuity sync may touch only these paths inside nodex-live-context:
- current_handoff.md
- evidence_latest/latest_summary.txt
- evidence_latest/latest.json
- architecture/nodex_exact_continuity_source_v1.md
- architecture/nodex_boundary_pushing_master_architecture.md
- packets/current_open_packet.ps1
- README.md
- packet_generation_rules.md

Continuity sync must:
- copy latest relevant evidence JSON/TXT into evidence_latest/
- update current_handoff.md to the new completed/current seam boundary
- update packets/current_open_packet.ps1 with the next generated packet or a non-runnable placeholder
- commit and push only inside nodex-live-context
- report continuity_sync separately from the Nodex seam result

Sync triggers:
- Decision pass
- StateRecord pass
- Spine Audit pass
- Implementation pass
- CommitGate pass
- failure evidence write

## PowerShell hardening rules

For all future packets:
- no inline conditional subexpressions like $(if (...)) inside hashtable values
- precompute booleans or use direct comparisons
- boolean parameters must receive real booleans only
- avoid here-strings in interactive user-run commands
- generated .ps1 files may contain here-strings only when complete and syntactically closed inside the file
- prefer arrays plus [System.IO.File]::WriteAllLines(...) for generated Markdown/text
- include guarded success and failure summary clipboard copy
- failure evidence writing must be minimal and separately guarded
- validate evidence fields, not just file existence
- use exact seam-specific evidence filters
- verify JSON readback after writing evidence
- assert the git root before any git command
- never concatenate packet run commands
- avoid backtick continuations in user-run commands
- do not use broad filename-only cleanup such as *_FULL_PACKET.ps1 as proof of staleness
- downloaded artifact path must be verified before execution
- if no next packet exists, write a non-runnable placeholder to packets/current_open_packet.ps1

Required clipboard markers:
- Copy-SummaryToClipboard
- Set-Clipboard
- SUMMARY COPIED TO CLIPBOARD:
- FAILED_TO_COPY_SUMMARY_TO_CLIPBOARD:

Every packet header must state:
- what repo it may touch
- what repo it must not touch
- what authority it may grant
- what authority it must not grant
- that continuity sync is non-authoritative

## Git root assertions

Nodex repo root:
C:\Users\Zak\OneDrive\Desktop\Nodex System\Node

Continuity repo root:
C:\Users\Zak\OneDrive\Desktop\nodex-live-context

Before git commands, assert the active git root matches the intended repo.

## Evidence validation rule

Do not treat file existence as pass.

Required evidence checks must verify:
- status
- decision
- nextAllowedSeam
- authority grant fields
- blocked fields
- continuity_sync

Use exact seam-specific filters.

Good:
- agent_handoff_runtime_wiring_plan_v1_*.json
- agent_handoff_runtime_wiring_plan_v1_summary_*.txt

Bad:
- *_plan_*.json
- latest*.json

## Current open packet placeholder rule

If no next packet exists yet, packets/current_open_packet.ps1 must be non-runnable and throw.

Final rule:
Models propose.
Local evidence decides.
Continuity sync informs future chats.
Continuity sync is not Nodex authority.
