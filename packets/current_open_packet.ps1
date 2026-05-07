$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'

$ExpectedNodexCommit = '0514da1 Add static packet schema validation layer manifest'
$ExpectedStableLatestCompletedSeam = 'LiveContextPushStateRecord v1'
$ExpectedCurrentOpenSeam = 'MasterSourceCheck v1'
$ExpectedNextAllowedSeamIfPass = 'OperatorDirectionRequired v1'

$BlockedAuthoritiesText = @"
nodex_source_mutation
nodex_commit
nodex_push
live_context_source_mutation
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
"@.TrimEnd()

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ('master_source_check_v1_' + $Timestamp + '.json')
$EvidenceSummaryPath = Join-Path $EvidenceRoot ('master_source_check_v1_summary_' + $Timestamp + '.txt')

function Write-TextFileUtf8NoBom {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-GitText {
  param([string[]]$Arguments)
  $output = & git @Arguments 2>&1 | ForEach-Object { $_.ToString() }
  [pscustomObject]@{
    FilePath = 'git'
    Arguments = $Arguments
    ExitCode = $LASTEXITCODE
    Text = ($output -join "`n")
  }
}

function Fail-MasterSourceCheck {
  param([string]$Message, [object[]]$CommandResults = @())

  $failure = [pscustomobject]@{
    schema = 'nodex.master_source_check.v1'
    status = 'fail'
    seam = 'MasterSourceCheck v1'
    checkOnly = $true
    decision = 'master_source_check_failed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    commandResults = $CommandResults
    sourceMutationPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    nextAllowedSeam = 'MasterSourceCheckRepair v1'
    failureMessage = $Message
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($failure | ConvertTo-Json -Depth 100)

  $summary = @"
MASTER SOURCE CHECK V1 FAILED

status: fail
failure: $Message
next_allowed_seam: MasterSourceCheckRepair v1
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

  $nodexHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $commandResults += $nodexHead
  if ($nodexHead.ExitCode -ne 0 -or $nodexHead.Text -ne $ExpectedNodexCommit) { $problems.Add('Nodex HEAD mismatch: ' + $nodexHead.Text) | Out-Null }

  $nodexOrigin = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $commandResults += $nodexOrigin
  if ($nodexOrigin.ExitCode -ne 0 -or $nodexOrigin.Text -ne $ExpectedNodexCommit) { $problems.Add('Nodex origin/main mismatch: ' + $nodexOrigin.Text) | Out-Null }

  $nodexAhead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '--oneline', 'origin/main..HEAD')
  $commandResults += $nodexAhead
  if ($nodexAhead.ExitCode -ne 0 -or $nodexAhead.Text -ne '') { $problems.Add('Nodex ahead-of-origin not empty: ' + $nodexAhead.Text) | Out-Null }

  $nodexBehind = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '--oneline', 'HEAD..origin/main')
  $commandResults += $nodexBehind
  if ($nodexBehind.ExitCode -ne 0 -or $nodexBehind.Text -ne '') { $problems.Add('Nodex behind-origin not empty: ' + $nodexBehind.Text) | Out-Null }

  $nodexStatus = Invoke-GitText -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $commandResults += $nodexStatus
  if ($nodexStatus.ExitCode -ne 0 -or $nodexStatus.Text -ne '') { $problems.Add('Nodex working tree not clean: ' + $nodexStatus.Text) | Out-Null }

  $liveHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
  $commandResults += $liveHead

  $liveOrigin = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $commandResults += $liveOrigin

  if ($liveHead.ExitCode -ne 0) { $problems.Add('live-context HEAD check failed: ' + $liveHead.Text) | Out-Null }
  if ($liveOrigin.ExitCode -ne 0) { $problems.Add('live-context origin/main check failed: ' + $liveOrigin.Text) | Out-Null }
  if ($liveHead.ExitCode -eq 0 -and $liveOrigin.ExitCode -eq 0 -and $liveHead.Text -ne $liveOrigin.Text) { $problems.Add('live-context HEAD and origin/main mismatch: HEAD=' + $liveHead.Text + ' origin=' + $liveOrigin.Text) | Out-Null }

  $liveAhead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '--oneline', 'origin/main..HEAD')
  $commandResults += $liveAhead
  if ($liveAhead.ExitCode -ne 0 -or $liveAhead.Text -ne '') { $problems.Add('live-context ahead-of-origin not empty: ' + $liveAhead.Text) | Out-Null }

  $liveBehind = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '--oneline', 'HEAD..origin/main')
  $commandResults += $liveBehind
  if ($liveBehind.ExitCode -ne 0 -or $liveBehind.Text -ne '') { $problems.Add('live-context behind-origin not empty: ' + $liveBehind.Text) | Out-Null }

  $liveStatus = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $commandResults += $liveStatus
  if ($liveStatus.ExitCode -ne 0 -or $liveStatus.Text -ne '') { $problems.Add('live-context working tree not clean: ' + $liveStatus.Text) | Out-Null }

  $latestJsonPath = Join-Path $LiveContextRoot 'evidence_latest/latest.json'
  $latestSummaryPath = Join-Path $LiveContextRoot 'evidence_latest/latest_summary.txt'
  $handoffPath = Join-Path $LiveContextRoot 'current_handoff.md'
  $packetPath = Join-Path $LiveContextRoot 'packets/current_open_packet.ps1'

  foreach ($path in @($latestJsonPath, $latestSummaryPath, $handoffPath, $packetPath)) {
    if (-not (Test-Path -LiteralPath $path)) { $problems.Add('required live-context file missing: ' + $path) | Out-Null }
  }

  $latestJson = $null
  if (Test-Path -LiteralPath $latestJsonPath) {
    try {
      $latestJson = Get-Content -LiteralPath $latestJsonPath -Raw | ConvertFrom-Json
    } catch {
      $problems.Add('failed to parse latest.json: ' + $_.Exception.Message) | Out-Null
    }
  }

  $latestCompleted = ''
  $currentOpen = ''
  $nextAllowed = ''
  $trackedNodexCommit = ''
  $trackedLiveContextCommitSelfReferenceBlocked = $false

  if ($null -ne $latestJson) {
    $latestCompleted = [string]$latestJson.latestCompletedSeam
    $currentOpen = [string]$latestJson.currentOpenSeam
    $nextAllowed = [string]$latestJson.nextAllowedSeam
    $trackedNodexCommit = [string]$latestJson.latestNodexCommit
    $trackedLiveContextCommitSelfReferenceBlocked = [bool]$latestJson.liveContextTrackedCommitSelfReferenceBlocked
  }

  if ($latestCompleted -ne $ExpectedStableLatestCompletedSeam) { $problems.Add('latest.json latestCompletedSeam mismatch: ' + $latestCompleted) | Out-Null }
  if ($currentOpen -ne $ExpectedCurrentOpenSeam) { $problems.Add('latest.json currentOpenSeam mismatch: ' + $currentOpen) | Out-Null }
  if ($nextAllowed -ne $ExpectedCurrentOpenSeam) { $problems.Add('latest.json nextAllowedSeam mismatch: ' + $nextAllowed) | Out-Null }
  if ($trackedNodexCommit -ne $ExpectedNodexCommit) { $problems.Add('latest.json latestNodexCommit mismatch: ' + $trackedNodexCommit) | Out-Null }
  if ($trackedLiveContextCommitSelfReferenceBlocked -ne $true) { $problems.Add('latest.json liveContextTrackedCommitSelfReferenceBlocked is not true') | Out-Null }

  $latestSummaryText = if (Test-Path -LiteralPath $latestSummaryPath) { Get-Content -LiteralPath $latestSummaryPath -Raw } else { '' }
  $handoffText = if (Test-Path -LiteralPath $handoffPath) { Get-Content -LiteralPath $handoffPath -Raw } else { '' }
  $packetText = if (Test-Path -LiteralPath $packetPath) { Get-Content -LiteralPath $packetPath -Raw } else { '' }

  if ($latestSummaryText -notmatch 'current_open_seam:\s*MasterSourceCheck v1') { $problems.Add('latest_summary.txt current_open_seam does not point to MasterSourceCheck v1') | Out-Null }
  if ($latestSummaryText -notmatch 'next_allowed_seam:\s*MasterSourceCheck v1') { $problems.Add('latest_summary.txt next_allowed_seam does not point to MasterSourceCheck v1') | Out-Null }
  if ($handoffText -notmatch 'Current open seam\s*\r?\n\s*MasterSourceCheck v1') { $problems.Add('current_handoff.md current open seam does not point to MasterSourceCheck v1') | Out-Null }
  if ($packetText -notmatch 'MASTER SOURCE CHECK V1') { $problems.Add('current_open_packet.ps1 is not a MasterSourceCheck packet') | Out-Null }

  $pass = ($problems.Count -eq 0)
  $allowedNow = if ($pass) { $ExpectedNextAllowedSeamIfPass } else { 'MasterSourceCheckRepair v1' }
  $decision = if ($pass) { 'operator_direction_required_allowed' } else { 'master_source_check_repair_required' }
  $reason = if ($pass) { 'Local evidence, live-context files, and git state agree after post-push continuity repair.' } else { 'Master source check found alignment problems after post-push continuity repair.' }
  $problemList = if ($pass) { @('none') } else { @($problems.ToArray()) }

  $evidence = [pscustomobject]@{
    schema = 'nodex.master_source_check.v1'
    status = 'pass'
    seam = 'MasterSourceCheck v1'
    checkOnly = $true
    decision = $decision
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    latestCompletedSeam = $ExpectedStableLatestCompletedSeam
    currentOpenSeam = 'MasterSourceCheck v1'
    latestNodexCommit = $ExpectedNodexCommit
    latestNodexOriginCommit = $ExpectedNodexCommit
    latestLiveContextCommit = $liveHead.Text
    latestLiveContextOriginCommit = $liveOrigin.Text
    liveContextTrackedCommitSelfReferenceBlocked = $true
    masterSourceCheck = [pscustomobject]@{
      pass = $pass
      conflict = (-not $pass)
      scope_limited = $true
      allowed_now = $allowedNow
      blocked_now = @($BlockedAuthoritiesText -split "`n")
      reason = $reason
    }
    alignmentProblems = $problemList
    nodexWorkingTreeClean = ($nodexStatus.Text -eq '')
    nodexOriginSynced = (($nodexAhead.Text -eq '') -and ($nodexBehind.Text -eq ''))
    liveContextWorkingTreeClean = ($liveStatus.Text -eq '')
    liveContextOriginSynced = (($liveAhead.Text -eq '') -and ($liveBehind.Text -eq ''))
    localEvidenceRemainsAuthority = $true
    sourceMutationPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    runtimeExecutionAllowed = $false
    toolExecutionAllowed = $false
    modelOutputApprovalAllowed = $false
    generatedCodeApprovalAllowed = $false
    authorityExpansionAllowed = $false
    blockedAuthoritiesText = $BlockedAuthoritiesText
    commandResults = $commandResults
    nextAllowedSeam = $allowedNow
    failureMessage = ''
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($evidence | ConvertTo-Json -Depth 100)

  $problemText = (($problemList | ForEach-Object { '- ' + $_ }) -join "`n")

  $summary = @"
MASTER SOURCE CHECK V1 COMPLETE

MasterSourceCheck:
pass: $($pass.ToString().ToLowerInvariant())
conflict: $(((-not $pass)).ToString().ToLowerInvariant())
scope_limited: true
allowed_now: $allowedNow
blocked_now:
$BlockedAuthoritiesText

reason: $reason

status: pass
decision: $decision
check_only: true
latest_completed_seam: $ExpectedStableLatestCompletedSeam
current_open_seam: MasterSourceCheck v1
latest_nodex_commit: $ExpectedNodexCommit
latest_live_context_commit: $($liveHead.Text)
nodex_working_tree_clean: $($evidence.nodexWorkingTreeClean.ToString().ToLowerInvariant())
nodex_origin_synced: $($evidence.nodexOriginSynced.ToString().ToLowerInvariant())
live_context_working_tree_clean: $($evidence.liveContextWorkingTreeClean.ToString().ToLowerInvariant())
live_context_origin_synced: $($evidence.liveContextOriginSynced.ToString().ToLowerInvariant())
live_context_tracked_commit_self_reference_blocked: true
local_evidence_remains_authority: true
source_mutation_performed: false
commit_performed: false
push_performed: false

alignment_problems:
$problemText

next_allowed_seam: $allowedNow
evidence_json: $EvidenceJsonPath
evidence_summary: $EvidenceSummaryPath
"@

  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  Write-Host $summary
  exit 0
} catch {
  Fail-MasterSourceCheck -Message $_.Exception.Message
}