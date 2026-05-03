$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'
$AuthoritativeLocalEvidencePath = Join-Path $EvidenceRoot 'live_context_push_state_record_v1_20260502_233525.json'
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ('master_source_check_v1_' + $Timestamp + '.json')
$EvidenceSummaryPath = Join-Path $EvidenceRoot ('master_source_check_v1_summary_' + $Timestamp + '.txt')

$ExpectedLatestCompletedSeam = 'LiveContextPushStateRecord v1'
$ExpectedCurrentOpenSeam = 'MasterSourceCheck v1'
$ExpectedNodexCommit = '5f062d6 Add packet generation reliability hardening manifests'
$ExpectedLiveContextCommit = '2c6a21f Update continuity after packet generation reliability hardening'
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
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Invoke-GitText {
  param([string[]]$Arguments)
  $lines = & git @Arguments 2>&1 | ForEach-Object { $_.ToString() }
  if ($LASTEXITCODE -ne 0) {
    throw ('git command failed: git ' + ($Arguments -join ' ') + "`n" + (($lines | ForEach-Object { [string]$_ }) -join "`n"))
  }
  return (($lines | ForEach-Object { [string]$_ }) -join "`n")
}

try {
  if (-not (Test-Path -LiteralPath $AuthoritativeLocalEvidencePath)) {
    throw ('authoritative local evidence missing: ' + $AuthoritativeLocalEvidencePath)
  }

  $localEvidence = Get-Content -LiteralPath $AuthoritativeLocalEvidencePath -Raw | ConvertFrom-Json
  $latestJsonPath = Join-Path $LiveContextRoot 'evidence_latest\latest.json'
  $latestJson = Get-Content -LiteralPath $latestJsonPath -Raw | ConvertFrom-Json

  $nodexHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $nodexOriginHead = Invoke-GitText -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $nodexStatus = Invoke-GitText -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $liveHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s')
  $liveOriginHead = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'log', '-1', '--pretty=format:%h %s', 'origin/main')
  $liveStatus = Invoke-GitText -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')

  $failures = @()
  if ($localEvidence.status -ne 'pass') { $failures += 'local evidence status not pass' }
  if ($localEvidence.seam -ne $ExpectedLatestCompletedSeam) { $failures += 'local evidence seam mismatch' }
  if ($localEvidence.nextAllowedSeam -ne $ExpectedCurrentOpenSeam) { $failures += 'local evidence next seam mismatch' }
  if ($latestJson.latestCompletedSeam -ne $ExpectedLatestCompletedSeam) { $failures += 'latest.json latestCompletedSeam mismatch' }
  if ($latestJson.currentOpenSeam -ne $ExpectedCurrentOpenSeam) { $failures += 'latest.json currentOpenSeam mismatch' }
  if ($latestJson.nextAllowedSeam -ne $ExpectedCurrentOpenSeam) { $failures += 'latest.json nextAllowedSeam mismatch' }
  if ($nodexHead -ne $ExpectedNodexCommit) { $failures += 'Nodex HEAD mismatch' }
  if ($nodexOriginHead -ne $ExpectedNodexCommit) { $failures += 'Nodex origin/main mismatch' }
  if ($nodexStatus -ne '') { $failures += 'Nodex working tree not clean' }
  if ($liveHead -ne $ExpectedLiveContextCommit) { $failures += 'live-context HEAD mismatch' }
  if ($liveOriginHead -ne $ExpectedLiveContextCommit) { $failures += 'live-context origin/main mismatch' }
  if ($liveStatus -ne '') { $failures += 'live-context working tree not clean' }

  if (($failures -join '; ') -ne '') {
    $decision = 'master_source_check_conflict_operator_direction_blocked'
    $conflict = $true
    $nextAllowedSeam = 'MasterSourceCheckRepair v1'
    $reason = 'one or more master sources disagree: ' + ($failures -join '; ')
  } else {
    $decision = 'master_source_check_passed_operator_direction_required'
    $conflict = $false
    $nextAllowedSeam = $ExpectedNextSeam
    $reason = 'local evidence, live-context latest files, repo heads, and working trees agree'
  }

  $evidence = [pscustomobject]@{
    schema = 'nodex.master_source_check.v1'
    status = if ($conflict) { 'fail' } else { 'pass' }
    seam = 'MasterSourceCheck v1'
    readOnly = $true
    decision = $decision
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    authoritativeLocalEvidence = $AuthoritativeLocalEvidencePath
    pass = (-not $conflict)
    conflict = $conflict
    scope_limited = $true
    allowed_now = $nextAllowedSeam
    blocked_now = $BlockedAuthorities
    reason = $reason
    latestCompletedSeam = $ExpectedLatestCompletedSeam
    latestNodexCommit = $ExpectedNodexCommit
    latestLiveContextCommit = $ExpectedLiveContextCommit
    currentOpenSeam = $ExpectedCurrentOpenSeam
    observed = [pscustomobject]@{
      nodexHead = $nodexHead
      nodexOriginHead = $nodexOriginHead
      nodexStatus = $nodexStatus
      liveContextHead = $liveHead
      liveContextOriginHead = $liveOriginHead
      liveContextStatus = $liveStatus
      latestJsonLatestCompletedSeam = $latestJson.latestCompletedSeam
      latestJsonCurrentOpenSeam = $latestJson.currentOpenSeam
      latestJsonNextAllowedSeam = $latestJson.nextAllowedSeam
    }
    failures = $failures
    nextAllowedSeam = $nextAllowedSeam
  }

  $json = $evidence | ConvertTo-Json -Depth 20
  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text $json

  $summary = @(
    'MASTER SOURCE CHECK V1 COMPLETE',
    '',
    'status: ' + $evidence.status,
    'pass: ' + ([string](-not $conflict)).ToLowerInvariant(),
    'conflict: ' + ([string]$conflict).ToLowerInvariant(),
    'scope_limited: true',
    'allowed_now: ' + $nextAllowedSeam,
    'reason: ' + $reason,
    '',
    'latest_completed_seam: ' + $ExpectedLatestCompletedSeam,
    'latest_nodex_commit: ' + $ExpectedNodexCommit,
    'latest_live_context_commit: ' + $ExpectedLiveContextCommit,
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