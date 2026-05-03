$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ('master_source_check_v1_' + $Timestamp + '.json')
$EvidenceSummaryPath = Join-Path $EvidenceRoot ('master_source_check_v1_summary_' + $Timestamp + '.txt')

$ExpectedCurrentOpenSeam = 'MasterSourceCheck v1'
$ExpectedNodexCommit = '5f062d6 Add packet generation reliability hardening manifests'
$ExpectedNextSeam = 'OperatorDirectionRequired v1'

$BlockedAuthorities = @(
  'manual_commit',
  'manual_staging',
  'reset',
  'source_mutation',
  'implementation',
  'generated_code_approval',
  'model_output_approval',
  'prompt_output_authority',
  'self_approval_authority',
  'authority_self_expansion',
  'reward_authority',
  'autonomous_priority_authority',
  'success_signal_authority',
  'graph_expansion'
)

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
  $lines = & git @Arguments 2>&1 | ForEach-Object { $_.ToString() }
  if ($LASTEXITCODE -ne 0) {
    throw ('git command failed: git ' + ($Arguments -join ' ') + "`n" + ($lines -join "`n"))
  }
  return ($lines -join "`n")
}

try {
  $latestJsonPath = Join-Path $LiveContextRoot 'evidence_latest\latest.json'
  if (-not (Test-Path -LiteralPath $latestJsonPath)) {
    throw ('latest.json missing: ' + $latestJsonPath)
  }

  $latestJson = Get-Content -LiteralPath $latestJsonPath -Raw | ConvertFrom-Json

  $nodexHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $nodexOriginHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $nodexStatus = Invoke-GitText -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $liveHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
  $liveOriginHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $liveStatus = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')

  $failures = @()
  if ($latestJson.currentOpenSeam -ne $ExpectedCurrentOpenSeam) { $failures += 'latest.json currentOpenSeam mismatch' }
  if ($latestJson.nextAllowedSeam -ne $ExpectedCurrentOpenSeam) { $failures += 'latest.json nextAllowedSeam mismatch' }
  if ($latestJson.latestNodexCommit -ne $ExpectedNodexCommit) { $failures += 'latest.json latestNodexCommit mismatch' }
  if ($latestJson.liveContextCommitTracking -ne 'external_evidence_only') { $failures += 'latest.json liveContextCommitTracking invariant mismatch' }
  if ($latestJson.liveContextTrackedCommitSelfReferenceBlocked -ne $true) { $failures += 'latest.json self-reference block missing' }
  if ($nodexHead -ne $ExpectedNodexCommit) { $failures += 'Nodex HEAD mismatch' }
  if ($nodexOriginHead -ne $ExpectedNodexCommit) { $failures += 'Nodex origin/main mismatch' }
  if ($nodexStatus -ne '') { $failures += 'Nodex working tree not clean' }
  if ($liveHead -ne $liveOriginHead) { $failures += 'live-context HEAD does not match origin/main' }
  if ($liveStatus -ne '') { $failures += 'live-context working tree not clean' }

  if (($failures -join '; ') -ne '') {
    $status = 'fail'
    $pass = $false
    $conflict = $true
    $decision = 'master_source_check_conflict_operator_direction_blocked'
    $nextAllowedSeam = 'MasterSourceCheckRepair v1'
    $reason = 'one or more master sources disagree: ' + ($failures -join '; ')
  } else {
    $status = 'pass'
    $pass = $true
    $conflict = $false
    $decision = 'master_source_check_passed_operator_direction_required'
    $nextAllowedSeam = $ExpectedNextSeam
    $reason = 'local live-context latest file, repo heads, and working trees agree under external-evidence-only live-context commit invariant'
  }

  $evidence = [pscustomobject]@{
    schema = 'nodex.master_source_check.v1'
    status = $status
    seam = 'MasterSourceCheck v1'
    readOnly = $true
    decision = $decision
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    pass = $pass
    conflict = $conflict
    scope_limited = $true
    allowed_now = $nextAllowedSeam
    blocked_now = $BlockedAuthorities
    reason = $reason
    latestCompletedSeam = $latestJson.latestCompletedSeam
    latestNodexCommit = $ExpectedNodexCommit
    latestLiveContextCommitPolicy = 'external_evidence_only'
    liveContextHeadObserved = $liveHead
    liveContextOriginObserved = $liveOriginHead
    currentOpenSeam = $ExpectedCurrentOpenSeam
    nextAllowedSeam = $nextAllowedSeam
  }

  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text ($evidence | ConvertTo-Json -Depth 20)

  $summary = @(
    'MASTER SOURCE CHECK V1 COMPLETE',
    '',
    'status: ' + $status,
    'pass: ' + ([string]$pass).ToLowerInvariant(),
    'conflict: ' + ([string]$conflict).ToLowerInvariant(),
    'scope_limited: true',
    'allowed_now: ' + $nextAllowedSeam,
    'reason: ' + $reason,
    '',
    'latest_completed_seam: ' + $latestJson.latestCompletedSeam,
    'latest_nodex_commit: ' + $ExpectedNodexCommit,
    'latest_live_context_commit_policy: external_evidence_only',
    'live_context_head_observed: ' + $liveHead,
    'current_open_seam: ' + $ExpectedCurrentOpenSeam,
    '',
    'next_allowed_seam: ' + $nextAllowedSeam,
    'evidence_json: ' + $EvidenceJsonPath,
    'evidence_summary: ' + $EvidenceSummaryPath
  ) -join "`n"

  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  try { Set-Clipboard -Value $summary } catch {}
  Write-Host $summary
  if ($conflict) { exit 1 }
  exit 0
} catch {
  Write-Host 'MASTER SOURCE CHECK V1 FAILED'
  Write-Host ('failure: ' + $_.Exception.Message)
  exit 1
}