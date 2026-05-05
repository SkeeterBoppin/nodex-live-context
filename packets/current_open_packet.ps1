$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'

$ExpectedNodexCommit = '0514da1 Add static packet schema validation layer manifest'
$ExpectedLiveContextPreUpdateCommit = '4c6e1c0 Repair live-context post-push continuity markers'
$ExpectedCurrentSeam = 'LiveContextCommitPlan v1'
$ExpectedNextSeam = 'LiveContextCommitPreflight v1'

$ExpectedDirtyStatus = @(
  ' M current_handoff.md',
  ' M evidence_latest/latest.json',
  ' M evidence_latest/latest_summary.txt',
  ' M packets/current_open_packet.ps1'
)

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ('live_context_commit_plan_v1_' + $Timestamp + '.json')
$EvidenceSummaryPath = Join-Path $EvidenceRoot ('live_context_commit_plan_v1_summary_' + $Timestamp + '.txt')

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
  [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n"); Arguments = $Arguments }
}

function Fail-CommitPlan {
  param([string]$Message, [object[]]$CommandResults = @())
  $failure = [pscustomobject]@{
    schema = 'nodex.live_context_commit.plan.v1'
    status = 'fail'
    seam = $ExpectedCurrentSeam
    planOnly = $true
    decision = 'live_context_commit_plan_failed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    commandResults = $CommandResults
    sourceMutationPerformed = $false
    commitPerformed = $false
    pushPerformed = $false
    nextAllowedSeam = 'LiveContextCommitPlanRepair v1'
    failureMessage = $Message
  }
  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($failure | ConvertTo-Json -Depth 80)
  $summary = "LIVE CONTEXT COMMIT PLAN V1 FAILED`n`nstatus: fail`nfailure: $Message`nnext_allowed_seam: LiveContextCommitPlanRepair v1`nevidence_json: $EvidenceJsonPath`nevidence_summary: $EvidenceSummaryPath"
  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  Write-Host $summary
  exit 1
}

$commandResults = @()

$nodexHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
$commandResults += $nodexHead
if ($nodexHead.ExitCode -ne 0 -or $nodexHead.Text -ne $ExpectedNodexCommit) {
  Fail-CommitPlan -Message ('Nodex HEAD mismatch: ' + $nodexHead.Text) -CommandResults $commandResults
}

$nodexOrigin = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
$commandResults += $nodexOrigin
if ($nodexOrigin.ExitCode -ne 0 -or $nodexOrigin.Text -ne $ExpectedNodexCommit) {
  Fail-CommitPlan -Message ('Nodex origin/main mismatch: ' + $nodexOrigin.Text) -CommandResults $commandResults
}

$liveHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
$commandResults += $liveHead
if ($liveHead.ExitCode -ne 0 -or $liveHead.Text -ne $ExpectedLiveContextPreUpdateCommit) {
  Fail-CommitPlan -Message ('live-context HEAD mismatch: ' + $liveHead.Text) -CommandResults $commandResults
}

$liveOrigin = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
$commandResults += $liveOrigin
if ($liveOrigin.ExitCode -ne 0 -or $liveOrigin.Text -ne $ExpectedLiveContextPreUpdateCommit) {
  Fail-CommitPlan -Message ('live-context origin/main mismatch: ' + $liveOrigin.Text) -CommandResults $commandResults
}

$status = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
$commandResults += $status
if ($status.ExitCode -ne 0) {
  Fail-CommitPlan -Message ('live-context status failed: ' + $status.Text) -CommandResults $commandResults
}

$actual = @($status.Text -split "`n" | Where-Object { $_ -ne '' } | Sort-Object)
$expected = @($ExpectedDirtyStatus | Sort-Object)
if (($actual -join "`n") -ne ($expected -join "`n")) {
  Fail-CommitPlan -Message ("live-context dirty scope mismatch:`nactual:`n" + ($actual -join "`n") + "`nexpected:`n" + ($expected -join "`n")) -CommandResults $commandResults
}

$evidence = [pscustomobject]@{
  schema = 'nodex.live_context_commit.plan.v1'
  status = 'pass'
  seam = $ExpectedCurrentSeam
  planOnly = $true
  decision = 'live_context_commit_preflight_planned'
  createdAt = (Get-Date).ToString('o')
  repoRoot = $RepoRoot
  liveContextRoot = $LiveContextRoot
  evidenceRoot = $EvidenceRoot
  latestNodexCommit = $ExpectedNodexCommit
  latestLiveContextCommitBeforeCommit = $ExpectedLiveContextPreUpdateCommit
  expectedDirtyStatus = $ExpectedDirtyStatus
  liveContextCommitPreflightAllowed = $true
  liveContextCommitAllowedNow = $false
  liveContextPushAllowedNow = $false
  sourceMutationPerformed = $false
  commitPerformed = $false
  pushPerformed = $false
  commandResults = $commandResults
  nextAllowedSeam = $ExpectedNextSeam
  failureMessage = ''
}

Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($evidence | ConvertTo-Json -Depth 80)

$summary = @"
LIVE CONTEXT COMMIT PLAN V1 COMPLETE

status: pass
decision: live_context_commit_preflight_planned
plan_only: true

latest_nodex_commit: $ExpectedNodexCommit
latest_live_context_commit_before_commit: $ExpectedLiveContextPreUpdateCommit

expected_dirty_status:
-  M current_handoff.md
-  M evidence_latest/latest.json
-  M evidence_latest/latest_summary.txt
-  M packets/current_open_packet.ps1

live_context_commit_preflight_allowed: true
live_context_commit_allowed_now: false
live_context_push_allowed_now: false

source_mutation_performed: false
commit_performed: false
push_performed: false

next_allowed_seam: $ExpectedNextSeam
evidence_json: $EvidenceJsonPath
evidence_summary: $EvidenceSummaryPath
"@

Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
Write-Host $summary
exit 0