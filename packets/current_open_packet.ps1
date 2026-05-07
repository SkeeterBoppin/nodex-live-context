$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# LiveContextPostPushContinuityRepairExecution v1
# Boundary:
# - Repair execution seam.
# - Mutates exactly four live-context continuity marker files:
#   - current_handoff.md
#   - evidence_latest/latest.json
#   - evidence_latest/latest_summary.txt
#   - packets/current_open_packet.ps1
# - Does not mutate Nodex.
# - Does not stage.
# - Does not commit.
# - Does not push.
# - Does not execute runtime/tools.
# - Does not grant authority.

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'

$ThisSeam = 'LiveContextPostPushContinuityRepairExecution v1'
$PriorSeam = 'LiveContextPostPushContinuityRepairPreflight v1'
$ExpectedPriorDecision = 'live_context_post_push_continuity_repair_execution_allowed'
$ExpectedNodexCommit = '0514da1 Add static packet schema validation layer manifest'
$ExpectedLiveContextCommit = '7bdb15c Update continuity after post-recovery static schema validation'

$ExpectedStaleLatestCompleted = 'StaticPacketSchemaValidationLayerPostRecoveryReadinessDecisionRepair v1'
$ExpectedStaleCurrentOpen = 'LiveContextUpdateExecution v1'
$ExpectedStaleNextAllowed = 'LiveContextUpdateCommitPlan v1'

$UpdatedLatestCompleted = 'LiveContextUpdatePushStateRecord v1'
$UpdatedCurrentOpen = 'LiveContextPostPushContinuityRepairExecution v1'
$UpdatedNextAllowed = 'LiveContextPostPushContinuityRepairCommitPlan v1'
$NextAllowedSeam = 'LiveContextPostPushContinuityRepairCommitPlan v1'

$RepairFilesText = @"
current_handoff.md
evidence_latest/latest.json
evidence_latest/latest_summary.txt
packets/current_open_packet.ps1
"@.Trim()

$ExpectedDirtyStatusText = @"
 M current_handoff.md
 M evidence_latest/latest.json
 M evidence_latest/latest_summary.txt
 M packets/current_open_packet.ps1
"@.Trim()

$BlockedAuthoritiesText = @"
nodex_source_mutation
nodex_commit
nodex_push
live_context_commit
live_context_push
runtime_execution
tool_execution
packet_execution_by_nodex
packet_commit_by_nodex
packet_push_by_nodex
generated_code_approval
model_output_approval
prompt_output_authority
self_approval_authority
authority_self_expansion
reward_authority
autonomous_priority_authority
success_signal_authority
graph_expansion
deep_research_authority
external_review_authority
advisory_output_authority
direct_finding_adoption
"@.Trim()

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ("live_context_post_push_continuity_repair_execution_v1_$Timestamp.json")
$EvidenceSummaryPath = Join-Path $EvidenceRoot ("live_context_post_push_continuity_repair_execution_v1_summary_$Timestamp.txt")

function Write-TextFileUtf8NoBom {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-ProcessText {
  param([string]$FilePath, [object]$Arguments)
  $output = & $FilePath @Arguments 2>&1 | ForEach-Object { $_.ToString() }
  [pscustomobject]@{
    FilePath = $FilePath
    Arguments = $Arguments
    ExitCode = $LASTEXITCODE
    Text = ($output -join "`n")
  }
}

function Read-JsonFile {
  param([string]$Path)
  Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-FieldText {
  param([object]$Object, [string]$Name)
  if ($null -eq $Object) {
    return ''
  }
  if ($Object.PSObject.Properties.Name -contains $Name) {
    return [string]$Object.PSObject.Properties[$Name].Value
  }
  return ''
}

function Normalize-TextLines {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ''
  }
  return (($Text -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object) -join "`n")
}

function Add-Problem {
  param([string]$Message)
  if ($script:ProblemText -eq '') {
    $script:ProblemText = '- ' + $Message
  } else {
    $script:ProblemText = $script:ProblemText + "`n- " + $Message
  }
  $script:HasProblem = $true
}

function Fail-Seam {
  param([string]$Message)

  $failure = [pscustomobject]@{
    schema = 'nodex.live_context.post_push_continuity_repair_execution.v1'
    status = 'fail'
    seam = $ThisSeam
    executionOnly = $true
    decision = 'live_context_post_push_continuity_repair_execution_failed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    problemText = $script:ProblemText
    commandResults = $script:CommandResults
    sourceMutationPerformed = $false
    liveContextMutationPerformed = $script:MarkerMutationAttempted
    liveContextMutationScope = $script:MutationScope
    stagingPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    runtimeExecutionAllowed = $false
    toolExecutionAllowed = $false
    packetExecutionByNodexAllowed = $false
    modelOutputApprovalAllowed = $false
    generatedCodeApprovalAllowed = $false
    authorityExpansionAllowed = $false
    blockedAuthoritiesText = $BlockedAuthoritiesText
    nextAllowedSeam = 'LiveContextPostPushContinuityRepairExecutionRepair v1'
    failureMessage = $Message
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($failure | ConvertTo-Json -Depth 50)

  $problemBlock = $script:ProblemText
  if ($problemBlock -eq '') {
    $problemBlock = '- ' + $Message
  }

  $summary = @"
LIVE CONTEXT POST PUSH CONTINUITY REPAIR EXECUTION V1 FAILED

status: fail
failure: $Message

execution_problems:
$problemBlock

marker_mutation_attempted: $($script:MarkerMutationAttempted)
mutation_scope: $($script:MutationScope)

next_allowed_seam: LiveContextPostPushContinuityRepairExecutionRepair v1
evidence_json: $EvidenceJsonPath
evidence_summary: $EvidenceSummaryPath
"@

  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  Write-Host $summary
  exit 1
}

try {
  $script:HasProblem = $false
  $script:ProblemText = ''
  $script:CommandResults = @()
  $script:MarkerMutationAttempted = $false
  $script:MutationScope = 'none'

  if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or -not (Test-Path -LiteralPath $PSCommandPath)) {
    Add-Problem 'PSCommandPath unavailable; run this packet from a .ps1 file'
  }

  if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Add-Problem "Nodex repo path missing: $RepoRoot"
  }

  if (-not (Test-Path -LiteralPath $LiveContextRoot)) {
    Add-Problem "live-context repo path missing: $LiveContextRoot"
  }

  if (-not (Test-Path -LiteralPath $EvidenceRoot)) {
    New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
  }

  $priorEvidencePath = ''
  $priorEvidence = Get-ChildItem -LiteralPath $EvidenceRoot -Filter 'live_context_post_push_continuity_repair_preflight_v1_*.json' -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($null -eq $priorEvidence) {
    Add-Problem 'prior pass evidence not found: LiveContextPostPushContinuityRepairPreflight v1'
  } else {
    $priorEvidencePath = $priorEvidence.FullName
    try {
      $priorJson = Read-JsonFile -Path $priorEvidencePath
      $priorStatus = Get-FieldText -Object $priorJson -Name 'status'
      $priorSeam = Get-FieldText -Object $priorJson -Name 'seam'
      $priorDecision = Get-FieldText -Object $priorJson -Name 'decision'
      $priorNext = Get-FieldText -Object $priorJson -Name 'nextAllowedSeam'
      $priorNodex = Get-FieldText -Object $priorJson -Name 'latestNodexCommit'
      $priorLive = Get-FieldText -Object $priorJson -Name 'latestLiveContextCommit'
      $priorLiveOrigin = Get-FieldText -Object $priorJson -Name 'latestLiveContextOriginCommit'
      $priorStaleCompleted = Get-FieldText -Object $priorJson -Name 'currentStaleLatestCompletedSeam'
      $priorStaleOpen = Get-FieldText -Object $priorJson -Name 'currentStaleOpenSeam'
      $priorStaleNext = Get-FieldText -Object $priorJson -Name 'currentStaleNextAllowedSeam'

      if ($priorStatus -ne 'pass') {
        Add-Problem "prior evidence status mismatch: $priorStatus"
      }
      if ($priorSeam -ne $PriorSeam) {
        Add-Problem "prior evidence seam mismatch: $priorSeam"
      }
      if ($priorDecision -ne $ExpectedPriorDecision) {
        Add-Problem "prior evidence decision mismatch: $priorDecision"
      }
      if ($priorNext -ne $ThisSeam) {
        Add-Problem "prior evidence nextAllowedSeam mismatch: $priorNext"
      }
      if ($priorNodex -ne $ExpectedNodexCommit) {
        Add-Problem "prior evidence latestNodexCommit mismatch: $priorNodex"
      }
      if ($priorLive -ne $ExpectedLiveContextCommit) {
        Add-Problem "prior evidence latestLiveContextCommit mismatch: $priorLive"
      }
      if ($priorLiveOrigin -ne $ExpectedLiveContextCommit) {
        Add-Problem "prior evidence latestLiveContextOriginCommit mismatch: $priorLiveOrigin"
      }
      if ($priorStaleCompleted -ne $ExpectedStaleLatestCompleted) {
        Add-Problem "prior stale latestCompletedSeam mismatch: $priorStaleCompleted"
      }
      if ($priorStaleOpen -ne $ExpectedStaleCurrentOpen) {
        Add-Problem "prior stale currentOpenSeam mismatch: $priorStaleOpen"
      }
      if ($priorStaleNext -ne $ExpectedStaleNextAllowed) {
        Add-Problem "prior stale nextAllowedSeam mismatch: $priorStaleNext"
      }
    } catch {
      Add-Problem "prior evidence parse error: $($_.Exception.Message)"
    }
  }

  $nodexHead = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $script:CommandResults += $nodexHead
  if ($nodexHead.ExitCode -ne 0 -or $nodexHead.Text -ne $ExpectedNodexCommit) {
    Add-Problem "Nodex HEAD mismatch: $($nodexHead.Text)"
  }

  $nodexOrigin = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $script:CommandResults += $nodexOrigin
  if ($nodexOrigin.ExitCode -ne 0 -or $nodexOrigin.Text -ne $ExpectedNodexCommit) {
    Add-Problem "Nodex origin/main mismatch: $($nodexOrigin.Text)"
  }

  $nodexStatus = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $script:CommandResults += $nodexStatus
  if ($nodexStatus.ExitCode -ne 0 -or $nodexStatus.Text -ne '') {
    Add-Problem "Nodex working tree not clean before repair execution: $($nodexStatus.Text)"
  }

  $liveHead = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
  $script:CommandResults += $liveHead
  if ($liveHead.ExitCode -ne 0 -or $liveHead.Text -ne $ExpectedLiveContextCommit) {
    Add-Problem "live-context HEAD mismatch before repair execution: $($liveHead.Text)"
  }

  $liveOrigin = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $script:CommandResults += $liveOrigin
  if ($liveOrigin.ExitCode -ne 0 -or $liveOrigin.Text -ne $ExpectedLiveContextCommit) {
    Add-Problem "live-context origin/main mismatch before repair execution: $($liveOrigin.Text)"
  }

  $liveStatusBefore = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $script:CommandResults += $liveStatusBefore
  if ($liveStatusBefore.ExitCode -ne 0 -or $liveStatusBefore.Text -ne '') {
    Add-Problem "live-context working tree not clean before repair execution: $($liveStatusBefore.Text)"
  }

  $stagedBefore = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'diff', '--cached', '--name-only', '--')
  $script:CommandResults += $stagedBefore
  if ($stagedBefore.ExitCode -ne 0 -or $stagedBefore.Text -ne '') {
    Add-Problem "live-context staged files not empty before repair execution: $($stagedBefore.Text)"
  }

  $liveAhead = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '--oneline', 'origin/main..HEAD')
  $script:CommandResults += $liveAhead
  if ($liveAhead.ExitCode -ne 0 -or $liveAhead.Text -ne '') {
    Add-Problem "live-context ahead-of-origin not empty before repair execution: $($liveAhead.Text)"
  }

  $liveBehind = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '--oneline', 'HEAD..origin/main')
  $script:CommandResults += $liveBehind
  if ($liveBehind.ExitCode -ne 0 -or $liveBehind.Text -ne '') {
    Add-Problem "live-context behind-origin not empty before repair execution: $($liveBehind.Text)"
  }

  $handoffPath = Join-Path $LiveContextRoot 'current_handoff.md'
  $latestJsonPath = Join-Path $LiveContextRoot 'evidence_latest/latest.json'
  $latestSummaryPath = Join-Path $LiveContextRoot 'evidence_latest/latest_summary.txt'
  $packetPath = Join-Path $LiveContextRoot 'packets/current_open_packet.ps1'

  if (-not (Test-Path -LiteralPath $handoffPath)) {
    Add-Problem "current_handoff.md missing: $handoffPath"
  }
  if (-not (Test-Path -LiteralPath $latestJsonPath)) {
    Add-Problem "latest.json missing: $latestJsonPath"
  }
  if (-not (Test-Path -LiteralPath $latestSummaryPath)) {
    Add-Problem "latest_summary.txt missing: $latestSummaryPath"
  }
  if (-not (Test-Path -LiteralPath $packetPath)) {
    Add-Problem "current_open_packet.ps1 missing: $packetPath"
  }

  if (Test-Path -LiteralPath $latestJsonPath) {
    try {
      $latestJson = Read-JsonFile -Path $latestJsonPath
      $latestCompleted = Get-FieldText -Object $latestJson -Name 'latestCompletedSeam'
      $currentOpen = Get-FieldText -Object $latestJson -Name 'currentOpenSeam'
      $nextAllowed = Get-FieldText -Object $latestJson -Name 'nextAllowedSeam'
      $latestNodex = Get-FieldText -Object $latestJson -Name 'latestNodexCommit'
      $selfReference = Get-FieldText -Object $latestJson -Name 'liveContextTrackedCommitSelfReferenceBlocked'

      if ($latestCompleted -ne $ExpectedStaleLatestCompleted) {
        Add-Problem "latest.json latestCompletedSeam was not expected stale marker: $latestCompleted"
      }
      if ($currentOpen -ne $ExpectedStaleCurrentOpen) {
        Add-Problem "latest.json currentOpenSeam was not expected stale marker: $currentOpen"
      }
      if ($nextAllowed -ne $ExpectedStaleNextAllowed) {
        Add-Problem "latest.json nextAllowedSeam was not expected stale marker: $nextAllowed"
      }
      if ($latestNodex -ne $ExpectedNodexCommit) {
        Add-Problem "latest.json latestNodexCommit mismatch: $latestNodex"
      }
      if ($selfReference -ne 'True') {
        Add-Problem "latest.json self-reference marker mismatch: $selfReference"
      }
    } catch {
      Add-Problem "latest.json parse error before repair execution: $($_.Exception.Message)"
    }
  }

  if ($script:HasProblem) {
    Fail-Seam -Message 'live-context post-push continuity repair execution pre-mutation validation failed'
  }

  $script:MarkerMutationAttempted = $true
  $script:MutationScope = 'planned_live_context_continuity_files_only'

  $latestJsonObject = [ordered]@{
    schema = 'nodex.live_context.latest.v1'
    status = 'pass'
    latestCompletedSeam = $UpdatedLatestCompleted
    currentOpenSeam = $UpdatedCurrentOpen
    updatedAt = (Get-Date).ToString('o')
    sourceAuthority = 'local_evidence_only'
    latestNodexCommit = $ExpectedNodexCommit
    latestNodexOriginCommit = $ExpectedNodexCommit
    latestLiveContextCommit = $ExpectedLiveContextCommit
    latestLiveContextOriginCommit = $ExpectedLiveContextCommit
    latestEvidenceJson = ''
    previousEvidenceJson = $priorEvidencePath
    selfReferenceBoundary = 'do_not_require_live_context_files_to_name_the_commit_that_contains_their_own_update'
    liveContextTrackedCommitSelfReferenceBlocked = $true
    localEvidenceRemainsAuthority = $true
    nextAllowedSeam = $UpdatedNextAllowed
    blockedAuthoritiesText = $BlockedAuthoritiesText
  }

  $latestSummary = @"
LIVE CONTEXT LATEST SUMMARY

status: pass
latest_completed_seam: $UpdatedLatestCompleted
current_open_seam: $UpdatedCurrentOpen
source_authority: local_evidence_only

latest_nodex_commit: $ExpectedNodexCommit
latest_nodex_origin_commit: $ExpectedNodexCommit
latest_live_context_commit: $ExpectedLiveContextCommit
latest_live_context_origin_commit: $ExpectedLiveContextCommit

latest_evidence_json: pending_post_push_continuity_repair_execution_evidence
previous_evidence_json: $priorEvidencePath

self_reference_boundary: do_not_require_live_context_files_to_name_the_commit_that_contains_their_own_update
live_context_tracked_commit_self_reference_blocked: true

current_open_packet: packets/current_open_packet.ps1
exact_run_command: & "`$env:USERPROFILE\OneDrive\Desktop\nodex-live-context\packets\current_open_packet.ps1"

blocked_authorities:
$BlockedAuthoritiesText

next_allowed_seam: $UpdatedNextAllowed
"@

  $handoff = @"
# Nodex Current Handoff

## Authority

Local evidence is authority.
Model output is not authority.
Generated code is not approval.
Deep Research output is not authority.
External review output is not authority.

## Latest completed seam

$UpdatedLatestCompleted

## Current open seam

$UpdatedCurrentOpen

## Latest commits

- Nodex: $ExpectedNodexCommit
- Nodex origin/main: $ExpectedNodexCommit
- live-context: $ExpectedLiveContextCommit
- live-context origin/main: $ExpectedLiveContextCommit

## Continuity repair note

This continuity repair follows LiveContextUpdatePushStateRecord v1.

The prior live-context marker files were stale relative to local evidence after the 7bdb15c push. This repair updates marker files only; it does not claim the future commit that will contain this repair.

Self-reference boundary:
do_not_require_live_context_files_to_name_the_commit_that_contains_their_own_update

## Latest evidence

- Previous evidence JSON: $priorEvidencePath
- Current repair execution evidence JSON: pending until this packet completes

## Current open packet

Run:

````powershell
& "`$env:USERPROFILE\OneDrive\Desktop\nodex-live-context\packets\current_open_packet.ps1"
````

## Blocked authorities

````text
$BlockedAuthoritiesText
````

## Next allowed seam

$UpdatedNextAllowed
"@

  Write-TextFileUtf8NoBom -Path $latestJsonPath -Text (($latestJsonObject | ConvertTo-Json -Depth 50))
  Write-TextFileUtf8NoBom -Path $latestSummaryPath -Text $latestSummary
  Write-TextFileUtf8NoBom -Path $handoffPath -Text $handoff

  $packetContent = Get-Content -LiteralPath $PSCommandPath -Raw
  Write-TextFileUtf8NoBom -Path $packetPath -Text $packetContent

  $liveStatusAfter = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $script:CommandResults += $liveStatusAfter
  if ($liveStatusAfter.ExitCode -ne 0) {
    Add-Problem "live-context status failed after repair execution: $($liveStatusAfter.Text)"
  }

  $actualDirtyNormalized = Normalize-TextLines -Text $liveStatusAfter.Text
  $expectedDirtyNormalized = Normalize-TextLines -Text $ExpectedDirtyStatusText
  if ($actualDirtyNormalized -ne $expectedDirtyNormalized) {
    Add-Problem "live-context dirty scope mismatch after repair execution. actual=[$actualDirtyNormalized] expected=[$expectedDirtyNormalized]"
  }

  $nodexStatusAfter = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $script:CommandResults += $nodexStatusAfter
  if ($nodexStatusAfter.ExitCode -ne 0 -or $nodexStatusAfter.Text -ne '') {
    Add-Problem "Nodex working tree not clean after repair execution: $($nodexStatusAfter.Text)"
  }

  $stagedAfter = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'diff', '--cached', '--name-only', '--')
  $script:CommandResults += $stagedAfter
  if ($stagedAfter.ExitCode -ne 0 -or $stagedAfter.Text -ne '') {
    Add-Problem "live-context staged files not empty after repair execution: $($stagedAfter.Text)"
  }

  if (Test-Path -LiteralPath $latestJsonPath) {
    try {
      $updatedJson = Read-JsonFile -Path $latestJsonPath
      $updatedLatestCompletedObserved = Get-FieldText -Object $updatedJson -Name 'latestCompletedSeam'
      $updatedCurrentOpenObserved = Get-FieldText -Object $updatedJson -Name 'currentOpenSeam'
      $updatedNextAllowedObserved = Get-FieldText -Object $updatedJson -Name 'nextAllowedSeam'
      $updatedNodexObserved = Get-FieldText -Object $updatedJson -Name 'latestNodexCommit'
      $updatedLiveObserved = Get-FieldText -Object $updatedJson -Name 'latestLiveContextCommit'
      $updatedSelfReference = Get-FieldText -Object $updatedJson -Name 'liveContextTrackedCommitSelfReferenceBlocked'

      if ($updatedLatestCompletedObserved -ne $UpdatedLatestCompleted) {
        Add-Problem "updated latest.json latestCompletedSeam mismatch: $updatedLatestCompletedObserved"
      }
      if ($updatedCurrentOpenObserved -ne $UpdatedCurrentOpen) {
        Add-Problem "updated latest.json currentOpenSeam mismatch: $updatedCurrentOpenObserved"
      }
      if ($updatedNextAllowedObserved -ne $UpdatedNextAllowed) {
        Add-Problem "updated latest.json nextAllowedSeam mismatch: $updatedNextAllowedObserved"
      }
      if ($updatedNodexObserved -ne $ExpectedNodexCommit) {
        Add-Problem "updated latest.json latestNodexCommit mismatch: $updatedNodexObserved"
      }
      if ($updatedLiveObserved -ne $ExpectedLiveContextCommit) {
        Add-Problem "updated latest.json latestLiveContextCommit mismatch: $updatedLiveObserved"
      }
      if ($updatedSelfReference -ne 'True') {
        Add-Problem "updated latest.json self-reference marker mismatch: $updatedSelfReference"
      }
    } catch {
      Add-Problem "updated latest.json parse error: $($_.Exception.Message)"
    }
  }

  if ($script:HasProblem) {
    Fail-Seam -Message 'live-context post-push continuity repair execution post-mutation validation failed'
  }

  $ExecutionFindings = @(
    [pscustomobject]@{
      id = 'preflight_verified'
      status = 'pass'
      reason = 'LiveContextPostPushContinuityRepairPreflight v1 passed and allowed repair execution.'
    },
    [pscustomobject]@{
      id = 'marker_repair_applied'
      status = 'pass'
      reason = 'Continuity markers were updated from stale post-push state to LiveContextUpdatePushStateRecord v1 / LiveContextPostPushContinuityRepairExecution v1.'
    },
    [pscustomobject]@{
      id = 'dirty_scope_exact'
      status = 'pass'
      reason = 'Only the four planned live-context marker files are dirty after repair execution.'
    },
    [pscustomobject]@{
      id = 'nodex_preserved'
      status = 'pass'
      reason = 'Nodex working tree remains clean and synced at 0514da1.'
    },
    [pscustomobject]@{
      id = 'commit_plan_next_only'
      status = 'pass'
      reason = 'Repair execution performed no staging, commit, push, runtime execution, tool execution, model-output approval, generated-code approval, or authority expansion.'
    }
  )

  $evidence = [pscustomobject]@{
    schema = 'nodex.live_context.post_push_continuity_repair_execution.v1'
    status = 'pass'
    seam = $ThisSeam
    executionOnly = $true
    decision = 'live_context_post_push_continuity_repair_commit_plan_allowed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    priorSeam = $PriorSeam
    priorEvidence = $priorEvidencePath
    latestNodexCommit = $ExpectedNodexCommit
    latestNodexOriginCommit = $ExpectedNodexCommit
    latestLiveContextCommit = $ExpectedLiveContextCommit
    latestLiveContextOriginCommit = $ExpectedLiveContextCommit
    repairedFromLatestCompletedSeam = $ExpectedStaleLatestCompleted
    repairedFromCurrentOpenSeam = $ExpectedStaleCurrentOpen
    repairedFromNextAllowedSeam = $ExpectedStaleNextAllowed
    updatedLatestCompletedSeam = $UpdatedLatestCompleted
    updatedCurrentOpenSeam = $UpdatedCurrentOpen
    updatedNextAllowedSeam = $UpdatedNextAllowed
    repairFilesText = $RepairFilesText
    actualDirtyStatusText = $liveStatusAfter.Text
    executionFindings = $ExecutionFindings
    nodexWorkingTreeClean = $true
    liveContextDirtyScopeExact = $true
    liveContextStagedPathsEmpty = $true
    sourceMutationPerformed = $false
    liveContextMutationPerformed = $true
    liveContextMutationScope = 'planned_live_context_continuity_marker_files_only'
    stagingPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    runtimeExecutionAllowed = $false
    toolExecutionAllowed = $false
    packetExecutionByNodexAllowed = $false
    modelOutputApprovalAllowed = $false
    generatedCodeApprovalAllowed = $false
    authorityExpansionAllowed = $false
    blockedAuthoritiesText = $BlockedAuthoritiesText
    commandResults = $script:CommandResults
    nextAllowedSeam = $NextAllowedSeam
    failureMessage = ''
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($evidence | ConvertTo-Json -Depth 50)

  $readback = Read-JsonFile -Path $EvidenceJsonPath
  if ((Get-FieldText -Object $readback -Name 'status') -ne 'pass') {
    Fail-Seam -Message 'evidence JSON readback status mismatch after write'
  }

  $findingsText = (($ExecutionFindings | ForEach-Object { "- $($_.id): $($_.status) — $($_.reason)" }) -join "`n")

  $summary = @"
LIVE CONTEXT POST PUSH CONTINUITY REPAIR EXECUTION V1 COMPLETE

status: pass
decision: live_context_post_push_continuity_repair_commit_plan_allowed
execution_only: true

prior_seam: $PriorSeam
latest_nodex_commit: $ExpectedNodexCommit
latest_nodex_origin_commit: $ExpectedNodexCommit
latest_live_context_commit: $ExpectedLiveContextCommit
latest_live_context_origin_commit: $ExpectedLiveContextCommit

repaired_from_latest_completed_seam: $ExpectedStaleLatestCompleted
repaired_from_current_open_seam: $ExpectedStaleCurrentOpen
repaired_from_next_allowed_seam: $ExpectedStaleNextAllowed

updated_latest_completed_seam: $UpdatedLatestCompleted
updated_current_open_seam: $UpdatedCurrentOpen
updated_next_allowed_seam: $UpdatedNextAllowed

repair_files:
$RepairFilesText

actual_dirty_status:
$($liveStatusAfter.Text)

execution_findings:
$findingsText

nodex_working_tree_clean: true
live_context_dirty_scope_exact: true
live_context_staged_paths_empty: true

source_mutation_performed: false
live_context_mutation_performed: true
live_context_mutation_scope: planned_live_context_continuity_marker_files_only
staging_performed: false
commit_performed: false
push_performed: false
runtime_execution_allowed: false
tool_execution_allowed: false
packet_execution_by_nodex_allowed: false
model_output_approval_allowed: false
generated_code_approval_allowed: false
authority_expansion_allowed: false

blocked_authorities:
$BlockedAuthoritiesText

next_allowed_seam: $NextAllowedSeam
evidence_json: $EvidenceJsonPath
evidence_summary: $EvidenceSummaryPath
"@

  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary

  try {
    Set-Clipboard -Value $summary
    $summary = $summary + "`n`nSUMMARY COPIED TO CLIPBOARD:`n- $EvidenceSummaryPath"
    Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  } catch {
    $summary = $summary + "`n`nSUMMARY COPY TO CLIPBOARD FAILED:`n- $($_.Exception.Message)"
    Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  }

  Write-Host $summary
  exit 0
} catch {
  Fail-Seam -Message $_.Exception.Message
}
