$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# LiveContextUpdateExecution v1
# Boundary:
# - Execution seam for live-context continuity files only.
# - Mutates exactly:
#   - current_handoff.md
#   - evidence_latest/latest.json
#   - evidence_latest/latest_summary.txt
#   - packets/current_open_packet.ps1
# - Does not mutate Nodex source.
# - Does not stage.
# - Does not commit.
# - Does not push.
# - Does not execute runtime/tools by Nodex.
# - Does not grant authority.

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'

$ThisSeam = 'LiveContextUpdateExecution v1'
$PriorSeam = 'LiveContextUpdatePreflight v1'
$ExpectedPriorDecision = 'live_context_update_execution_allowed'
$ExpectedNodexCommit = '0514da1 Add static packet schema validation layer manifest'
$ExpectedLiveContextCommitBeforeUpdate = 'dabfc82 Repair live-context recovery markers after static packet schema validation'

$PlannedLatestCompletedSeamAfterUpdate = 'StaticPacketSchemaValidationLayerPostRecoveryReadinessDecisionRepair v1'
$PlannedCurrentOpenSeamAfterUpdate = 'LiveContextUpdateExecution v1'
$PlannedNextAllowedSeamAfterUpdate = 'LiveContextUpdateCommitPlan v1'

$NextAllowedSeam = 'LiveContextUpdateCommitPlan v1'

$LiveContextFilesToUpdate = @(
  'current_handoff.md',
  'evidence_latest/latest.json',
  'evidence_latest/latest_summary.txt',
  'packets/current_open_packet.ps1'
)

$ExpectedDirtyStatusAfterExecution = @(
  ' M current_handoff.md',
  ' M evidence_latest/latest.json',
  ' M evidence_latest/latest_summary.txt',
  ' M packets/current_open_packet.ps1'
)

$BlockedAuthorities = @(
  'nodex_source_mutation',
  'nodex_commit',
  'nodex_push',
  'live_context_commit',
  'live_context_push',
  'runtime_execution',
  'tool_execution',
  'packet_execution_by_nodex',
  'packet_commit_by_nodex',
  'packet_push_by_nodex',
  'generated_code_approval',
  'model_output_approval',
  'prompt_output_authority',
  'self_approval_authority',
  'authority_self_expansion',
  'reward_authority',
  'autonomous_priority_authority',
  'success_signal_authority',
  'graph_expansion',
  'deep_research_authority',
  'external_review_authority',
  'advisory_output_authority',
  'direct_finding_adoption'
)

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ("live_context_update_execution_v1_$Timestamp.json")
$EvidenceSummaryPath = Join-Path $EvidenceRoot ("live_context_update_execution_v1_summary_$Timestamp.txt")

function Write-TextFileUtf8NoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Text
  )

  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-ProcessText {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  $output = & $FilePath @Arguments 2>&1 | ForEach-Object { $_.ToString() }

  [pscustomobject]@{
    FilePath = $FilePath
    Arguments = $Arguments
    ExitCode = $LASTEXITCODE
    Text = ($output -join "`n")
  }
}

function Read-JsonFile {
  param([Parameter(Mandatory = $true)][string]$Path)
  Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-JsonField {
  param(
    [Parameter(Mandatory = $true)][object]$Object,
    [Parameter(Mandatory = $true)][string[]]$Names
  )

  foreach ($name in $Names) {
    if ($null -ne $Object -and ($Object.PSObject.Properties.Name -contains $name)) {
      return $Object.PSObject.Properties[$name].Value
    }
  }

  return $null
}

function Find-LatestJsonByStatus {
  param(
    [Parameter(Mandatory = $true)][string]$Filter,
    [Parameter(Mandatory = $true)][string]$Status
  )

  $items = Get-ChildItem -LiteralPath $EvidenceRoot -Filter $Filter -File |
    Sort-Object LastWriteTime -Descending

  foreach ($item in $items) {
    try {
      $json = Read-JsonFile -Path $item.FullName
      $observedStatus = [string](Get-JsonField -Object $json -Names @('status'))
      if ($observedStatus -eq $Status) {
        return [pscustomobject]@{
          Path = $item.FullName
          Json = $json
        }
      }
    } catch {
      # Ignore unreadable/nonmatching files.
    }
  }

  return $null
}

function Normalize-ArrayText {
  param([object]$Value)

  if ($null -eq $Value) {
    return @()
  }

  if ($Value -is [System.Array]) {
    return @($Value | ForEach-Object { [string]$_ })
  }

  return @([string]$Value)
}

function Same-StringSet {
  param(
    [Parameter(Mandatory = $true)][string[]]$Actual,
    [Parameter(Mandatory = $true)][string[]]$Expected
  )

  $a = @($Actual | Sort-Object)
  $e = @($Expected | Sort-Object)
  if ($a.Count -ne $e.Count) {
    return $false
  }

  for ($i = 0; $i -lt $a.Count; $i++) {
    if ($a[$i] -ne $e[$i]) {
      return $false
    }
  }

  return $true
}

function Fail-Seam {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [object[]]$CommandResults = @(),
    [string[]]$Problems = @()
  )

  $failure = [pscustomobject]@{
    schema = 'nodex.live_context.update_execution.v1'
    status = 'fail'
    seam = $ThisSeam
    executionOnly = $true
    decision = 'live_context_update_execution_failed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    problems = @($Problems)
    commandResults = @($CommandResults)
    sourceMutationPerformed = $false
    liveContextMutationPerformed = $false
    stagingPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    runtimeExecutionAllowed = $false
    toolExecutionAllowed = $false
    packetExecutionByNodexAllowed = $false
    modelOutputApprovalAllowed = $false
    generatedCodeApprovalAllowed = $false
    authorityExpansionAllowed = $false
    blockedAuthorities = @($BlockedAuthorities)
    nextAllowedSeam = 'LiveContextUpdateExecutionRepair v1'
    failureMessage = $Message
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($failure | ConvertTo-Json -Depth 100)

  $problemText = if ($Problems.Count -gt 0) {
    (($Problems | ForEach-Object { '- ' + $_ }) -join "`n")
  } else {
    '- ' + $Message
  }

  $summary = @"
LIVE CONTEXT UPDATE EXECUTION V1 FAILED

status: fail
failure: $Message

execution_problems:
$problemText

next_allowed_seam: LiveContextUpdateExecutionRepair v1
evidence_json: $EvidenceJsonPath
evidence_summary: $EvidenceSummaryPath
"@

  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  Write-Host $summary
  exit 1
}

try {
  $commandResults = @()
  $problems = [System.Collections.Generic.List[string]]::new()

  if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Fail-Seam -Message "Nodex repo path missing: $RepoRoot"
  }

  if (-not (Test-Path -LiteralPath $LiveContextRoot)) {
    Fail-Seam -Message "live-context repo path missing: $LiveContextRoot"
  }

  if (-not (Test-Path -LiteralPath $EvidenceRoot)) {
    New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
  }

  if ([string]::IsNullOrWhiteSpace($PSCommandPath) -or -not (Test-Path -LiteralPath $PSCommandPath)) {
    Fail-Seam -Message 'PSCommandPath is unavailable; run this packet from a .ps1 file.'
  }

  $priorEvidence = Find-LatestJsonByStatus -Filter 'live_context_update_preflight_v1_*.json' -Status 'pass'
  if ($null -eq $priorEvidence) {
    $problems.Add('prior pass evidence not found: LiveContextUpdatePreflight v1') | Out-Null
  } else {
    $priorSeamObserved = [string](Get-JsonField -Object $priorEvidence.Json -Names @('seam'))
    $priorDecisionObserved = [string](Get-JsonField -Object $priorEvidence.Json -Names @('decision'))
    $priorNextObserved = [string](Get-JsonField -Object $priorEvidence.Json -Names @('nextAllowedSeam', 'next_allowed_seam'))

    if ($priorSeamObserved -ne $PriorSeam) {
      $problems.Add("prior seam mismatch: $priorSeamObserved") | Out-Null
    }

    if ($priorDecisionObserved -ne $ExpectedPriorDecision) {
      $problems.Add("prior decision mismatch: $priorDecisionObserved") | Out-Null
    }

    if ($priorNextObserved -ne $ThisSeam) {
      $problems.Add("prior nextAllowedSeam mismatch: $priorNextObserved") | Out-Null
    }

    $plannedLatestCompleted = [string](Get-JsonField -Object $priorEvidence.Json -Names @('plannedLatestCompletedSeamAfterUpdate', 'planned_latest_completed_seam_after_update'))
    $plannedCurrentOpen = [string](Get-JsonField -Object $priorEvidence.Json -Names @('plannedCurrentOpenSeamAfterUpdate', 'planned_current_open_seam_after_update'))
    $plannedNextAllowed = [string](Get-JsonField -Object $priorEvidence.Json -Names @('plannedNextAllowedSeamAfterUpdate', 'planned_next_allowed_seam_after_update'))
    $plannedFiles = Normalize-ArrayText -Value (Get-JsonField -Object $priorEvidence.Json -Names @('updateFiles', 'update_files'))

    if ($plannedLatestCompleted -ne $PlannedLatestCompletedSeamAfterUpdate) {
      $problems.Add("prior planned latestCompletedSeam mismatch: $plannedLatestCompleted") | Out-Null
    }

    if ($plannedCurrentOpen -ne $PlannedCurrentOpenSeamAfterUpdate) {
      $problems.Add("prior planned currentOpenSeam mismatch: $plannedCurrentOpen") | Out-Null
    }

    if ($plannedNextAllowed -ne $PlannedNextAllowedSeamAfterUpdate) {
      $problems.Add("prior planned nextAllowedSeam mismatch: $plannedNextAllowed") | Out-Null
    }

    if (-not (Same-StringSet -Actual $plannedFiles -Expected $LiveContextFilesToUpdate)) {
      $problems.Add("prior planned update file set mismatch: $($plannedFiles -join ', ')") | Out-Null
    }
  }

  $nodexHead = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $commandResults += $nodexHead
  if ($nodexHead.ExitCode -ne 0 -or $nodexHead.Text -ne $ExpectedNodexCommit) {
    $problems.Add("Nodex HEAD mismatch: $($nodexHead.Text)") | Out-Null
  }

  $nodexOrigin = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $commandResults += $nodexOrigin
  if ($nodexOrigin.ExitCode -ne 0 -or $nodexOrigin.Text -ne $ExpectedNodexCommit) {
    $problems.Add("Nodex origin/main mismatch: $($nodexOrigin.Text)") | Out-Null
  }

  $nodexStatusBefore = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $commandResults += $nodexStatusBefore
  if ($nodexStatusBefore.ExitCode -ne 0 -or $nodexStatusBefore.Text -ne '') {
    $problems.Add("Nodex working tree not clean before execution: $($nodexStatusBefore.Text)") | Out-Null
  }

  $liveHead = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
  $commandResults += $liveHead
  if ($liveHead.ExitCode -ne 0 -or $liveHead.Text -ne $ExpectedLiveContextCommitBeforeUpdate) {
    $problems.Add("live-context HEAD mismatch before update: $($liveHead.Text)") | Out-Null
  }

  $liveOrigin = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $commandResults += $liveOrigin
  if ($liveOrigin.ExitCode -ne 0 -or $liveOrigin.Text -ne $ExpectedLiveContextCommitBeforeUpdate) {
    $problems.Add("live-context origin/main mismatch before update: $($liveOrigin.Text)") | Out-Null
  }

  $liveStatusBefore = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $commandResults += $liveStatusBefore
  if ($liveStatusBefore.ExitCode -ne 0 -or $liveStatusBefore.Text -ne '') {
    $problems.Add("live-context working tree not clean before update: $($liveStatusBefore.Text)") | Out-Null
  }

  foreach ($relative in $LiveContextFilesToUpdate) {
    $path = Join-Path $LiveContextRoot $relative
    if (-not (Test-Path -LiteralPath $path)) {
      $problems.Add("planned live-context update file missing before update: $relative") | Out-Null
    }
  }

  if ($problems.Count -gt 0) {
    Fail-Seam -Message 'live-context update execution pre-mutation validation failed' -CommandResults $commandResults -Problems $problems.ToArray()
  }

  $handoffPath = Join-Path $LiveContextRoot 'current_handoff.md'
  $latestJsonPath = Join-Path $LiveContextRoot 'evidence_latest/latest.json'
  $latestSummaryPath = Join-Path $LiveContextRoot 'evidence_latest/latest_summary.txt'
  $packetPath = Join-Path $LiveContextRoot 'packets/current_open_packet.ps1'

  $latestJsonObject = [ordered]@{
    schema = 'nodex.live_context.latest.v1'
    status = 'pass'
    latestCompletedSeam = $PlannedLatestCompletedSeamAfterUpdate
    currentOpenSeam = $PlannedCurrentOpenSeamAfterUpdate
    updatedAt = (Get-Date).ToString('o')
    sourceAuthority = 'local_evidence_only'
    latestNodexCommit = $ExpectedNodexCommit
    latestNodexOriginCommit = $ExpectedNodexCommit
    latestLiveContextCommitBeforeSelfReferenceRepair = $ExpectedLiveContextCommitBeforeUpdate
    latestEvidenceJson = ''
    previousEvidenceJson = if ($null -ne $priorEvidence) { $priorEvidence.Path } else { '' }
    selfReferenceBoundary = 'do_not_require_live_context_files_to_name_the_commit_that_contains_their_own_update'
    liveContextTrackedCommitSelfReferenceBlocked = $true
    localEvidenceRemainsAuthority = $true
    nextAllowedSeam = $PlannedNextAllowedSeamAfterUpdate
    blockedAuthorities = @($BlockedAuthorities)
  }

  $latestSummary = @"
LIVE CONTEXT LATEST SUMMARY

status: pass
latest_completed_seam: $PlannedLatestCompletedSeamAfterUpdate
current_open_seam: $PlannedCurrentOpenSeamAfterUpdate
source_authority: local_evidence_only

latest_nodex_commit: $ExpectedNodexCommit
latest_nodex_origin_commit: $ExpectedNodexCommit
latest_live_context_commit_before_self_reference_repair: $ExpectedLiveContextCommitBeforeUpdate
live_context_tracked_commit_self_reference_blocked: true

latest_evidence_json: pending_update_execution_evidence
previous_evidence_json: $(if ($null -ne $priorEvidence) { $priorEvidence.Path } else { '' })

current_open_packet: packets/current_open_packet.ps1
exact_run_command: & "`$env:USERPROFILE\OneDrive\Desktop\nodex-live-context\packets\current_open_packet.ps1"

blocked_authorities:
$($BlockedAuthorities -join "`n")

next_allowed_seam: $PlannedNextAllowedSeamAfterUpdate
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

$PlannedLatestCompletedSeamAfterUpdate

## Current open seam

$PlannedCurrentOpenSeamAfterUpdate

## Latest commits

- Nodex: $ExpectedNodexCommit
- Nodex origin/main: $ExpectedNodexCommit
- live-context before self-reference repair: $ExpectedLiveContextCommitBeforeUpdate

## Continuity update note

Live-context was updated after post-recovery static packet schema validation readiness repair.

The live-context file content does not claim the future commit that will contain this update. This preserves the self-reference boundary:
do_not_require_live_context_files_to_name_the_commit_that_contains_their_own_update

## Latest evidence

- Previous evidence JSON: $(if ($null -ne $priorEvidence) { $priorEvidence.Path } else { '' })
- Current update execution evidence JSON: pending until this packet completes

## Current open packet

Run:

````powershell
& "`$env:USERPROFILE\OneDrive\Desktop\nodex-live-context\packets\current_open_packet.ps1"
````

## Blocked authorities

````text
$($BlockedAuthorities -join "`n")
````

## Next allowed seam

$PlannedNextAllowedSeamAfterUpdate
"@

  Write-TextFileUtf8NoBom -Path $latestJsonPath -Text (($latestJsonObject | ConvertTo-Json -Depth 100))
  Write-TextFileUtf8NoBom -Path $latestSummaryPath -Text $latestSummary
  Write-TextFileUtf8NoBom -Path $handoffPath -Text $handoff

  $packetContent = Get-Content -LiteralPath $PSCommandPath -Raw
  Write-TextFileUtf8NoBom -Path $packetPath -Text $packetContent

  $liveStatusAfter = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $commandResults += $liveStatusAfter
  if ($liveStatusAfter.ExitCode -ne 0) {
    Fail-Seam -Message "live-context status failed after update: $($liveStatusAfter.Text)" -CommandResults $commandResults
  }

  $actualDirtyStatus = @($liveStatusAfter.Text -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

  if (-not (Same-StringSet -Actual $actualDirtyStatus -Expected $ExpectedDirtyStatusAfterExecution)) {
    $problems.Add("live-context dirty status mismatch after update. actual=[$($actualDirtyStatus -join '; ')] expected=[$($ExpectedDirtyStatusAfterExecution -join '; ')]") | Out-Null
  }

  $nodexStatusAfter = Invoke-ProcessText -FilePath 'git' -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $commandResults += $nodexStatusAfter
  if ($nodexStatusAfter.ExitCode -ne 0 -or $nodexStatusAfter.Text -ne '') {
    $problems.Add("Nodex working tree not clean after live-context update: $($nodexStatusAfter.Text)") | Out-Null
  }

  if ($problems.Count -gt 0) {
    Fail-Seam -Message 'live-context update execution post-mutation validation failed' -CommandResults $commandResults -Problems $problems.ToArray()
  }

  $findings = @(
    [pscustomobject]@{
      id = 'preflight_verified'
      status = 'pass'
      reason = 'LiveContextUpdatePreflight v1 passed and allowed update execution.'
    },
    [pscustomobject]@{
      id = 'exact_live_context_scope_mutated'
      status = 'pass'
      reason = 'Only the four planned live-context continuity files are dirty after update execution.'
    },
    [pscustomobject]@{
      id = 'nodex_source_preserved'
      status = 'pass'
      reason = 'Nodex repo remains clean and synced; no Nodex source mutation occurred.'
    },
    [pscustomobject]@{
      id = 'self_reference_boundary_preserved'
      status = 'pass'
      reason = 'Updated live-context files do not claim the future commit that will contain their own update.'
    },
    [pscustomobject]@{
      id = 'commit_plan_next_only'
      status = 'pass'
      reason = 'Update execution performed no staging, commit, push, runtime execution, tool execution, model-output approval, generated-code approval, or authority expansion.'
    }
  )

  $evidence = [pscustomobject]@{
    schema = 'nodex.live_context.update_execution.v1'
    status = 'pass'
    seam = $ThisSeam
    executionOnly = $true
    decision = 'live_context_update_commit_plan_allowed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    priorSeam = $PriorSeam
    priorEvidence = if ($null -ne $priorEvidence) { $priorEvidence.Path } else { '' }
    latestNodexCommit = $ExpectedNodexCommit
    latestNodexOriginCommit = $ExpectedNodexCommit
    latestLiveContextCommitBeforeUpdate = $ExpectedLiveContextCommitBeforeUpdate
    latestLiveContextOriginCommitBeforeUpdate = $ExpectedLiveContextCommitBeforeUpdate
    updatedLatestCompletedSeam = $PlannedLatestCompletedSeamAfterUpdate
    updatedCurrentOpenSeam = $PlannedCurrentOpenSeamAfterUpdate
    updatedNextAllowedSeam = $PlannedNextAllowedSeamAfterUpdate
    updatedFiles = @($LiveContextFilesToUpdate)
    expectedDirtyStatus = @($ExpectedDirtyStatusAfterExecution)
    actualDirtyStatus = @($actualDirtyStatus)
    updateFindings = @($findings)
    nodexWorkingTreeClean = $true
    liveContextDirtyScopeExact = $true
    sourceMutationPerformed = $false
    liveContextMutationPerformed = $true
    liveContextMutationScope = 'planned_live_context_continuity_files_only'
    stagingPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    runtimeExecutionAllowed = $false
    toolExecutionAllowed = $false
    packetExecutionByNodexAllowed = $false
    modelOutputApprovalAllowed = $false
    generatedCodeApprovalAllowed = $false
    authorityExpansionAllowed = $false
    blockedAuthorities = @($BlockedAuthorities)
    blockedAuthoritiesText = ($BlockedAuthorities -join "`n")
    commandResults = @($commandResults)
    nextAllowedSeam = $NextAllowedSeam
    failureMessage = ''
  }

  $evidenceJsonText = $evidence | ConvertTo-Json -Depth 100
  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text $evidenceJsonText

  try {
    $readback = Read-JsonFile -Path $EvidenceJsonPath
    if ([string](Get-JsonField -Object $readback -Names @('status')) -ne 'pass') {
      Fail-Seam -Message 'evidence JSON readback status mismatch after write' -CommandResults $commandResults
    }
  } catch {
    Fail-Seam -Message "evidence JSON readback failed: $($_.Exception.Message)" -CommandResults $commandResults
  }

  $findingsText = (($findings | ForEach-Object { "- $($_.id): $($_.status) — $($_.reason)" }) -join "`n")
  $filesText = (($LiveContextFilesToUpdate | ForEach-Object { "- $_" }) -join "`n")
  $dirtyText = (($actualDirtyStatus | ForEach-Object { "- $_" }) -join "`n")
  $blockedText = ($BlockedAuthorities -join "`n")

  $summary = @"
LIVE CONTEXT UPDATE EXECUTION V1 COMPLETE

status: pass
decision: live_context_update_commit_plan_allowed
execution_only: true

prior_seam: $PriorSeam
latest_nodex_commit: $ExpectedNodexCommit
latest_nodex_origin_commit: $ExpectedNodexCommit
latest_live_context_commit_before_update: $ExpectedLiveContextCommitBeforeUpdate
latest_live_context_origin_commit_before_update: $ExpectedLiveContextCommitBeforeUpdate

updated_latest_completed_seam: $PlannedLatestCompletedSeamAfterUpdate
updated_current_open_seam: $PlannedCurrentOpenSeamAfterUpdate
updated_next_allowed_seam: $PlannedNextAllowedSeamAfterUpdate

updated_files:
$filesText

actual_dirty_status:
$dirtyText

update_findings:
$findingsText

nodex_working_tree_clean: true
live_context_dirty_scope_exact: true

source_mutation_performed: false
live_context_mutation_performed: true
live_context_mutation_scope: planned_live_context_continuity_files_only
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
$blockedText

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
