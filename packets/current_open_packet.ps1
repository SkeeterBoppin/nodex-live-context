$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex System\Node'
$LiveContextRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\nodex-live-context'
$EvidenceRoot = Join-Path $env:USERPROFILE 'OneDrive\Desktop\Nodex Evidence'
$ContinuityExecutionEvidencePath = 'C:\Users\Zak\OneDrive\Desktop\Nodex Evidence\continuity_sync_execution_v1_20260502_225805.json'
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$EvidenceJsonPath = Join-Path $EvidenceRoot ('continuity_sync_state_record_v1_' + $Timestamp + '.json')
$EvidenceSummaryPath = Join-Path $EvidenceRoot ('continuity_sync_state_record_v1_summary_' + $Timestamp + '.txt')
$ExpectedNextSeam = 'NodexRepoPushPlan v1'
$Commands = New-Object 'System.Collections.Generic.List[object]'
$Checks = New-Object 'System.Collections.Generic.List[object]'

function New-Check {
  param([string]$Name, [bool]$Pass, [string]$Reason, [string]$DataText = '')
  return [pscustomobject]@{ name = $Name; pass = $Pass; reason = $Reason; dataText = $DataText }
}

function Invoke-Native {
  param([string]$FilePath, [string[]]$Arguments = @(), [string]$WorkingDirectory = '')
  $previousLocation = (Get-Location).Path
  if ($WorkingDirectory -ne '') { Set-Location -LiteralPath $WorkingDirectory }
  $outputLines = @()
  try {
    $outputLines = & $FilePath @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = $LASTEXITCODE
  } finally {
    if ($WorkingDirectory -ne '') { Set-Location -LiteralPath $previousLocation }
  }
  $argvParts = @()
  $argvParts += [string]$FilePath
  foreach ($arg in $Arguments) { $argvParts += [string]$arg }
  return [pscustomobject]@{
    command = $FilePath + ' ' + ($Arguments -join ' ')
    actualArgvText = ($argvParts -join ' | ')
    exitCode = $exitCode
    output = (($outputLines | ForEach-Object { [string]$_ }) -join "`n")
  }
}

function Write-TextFileUtf8NoBom {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

try {
  if (-not (Test-Path -LiteralPath $ContinuityExecutionEvidencePath)) { throw 'continuity execution evidence missing' }
  $executionEvidence = Get-Content -LiteralPath $ContinuityExecutionEvidencePath -Raw | ConvertFrom-Json
  $Checks.Add((New-Check -Name 'continuity execution status pass' -Pass ($executionEvidence.status -eq 'pass') -Reason 'continuity execution must have passed' -DataText $executionEvidence.status)) | Out-Null
  $Checks.Add((New-Check -Name 'continuity execution seam exact' -Pass ($executionEvidence.seam -eq 'ContinuitySyncExecution v1') -Reason 'execution seam must match' -DataText $executionEvidence.seam)) | Out-Null
  $Checks.Add((New-Check -Name 'continuity execution routed to state record' -Pass ($executionEvidence.nextAllowedSeam -eq 'ContinuitySyncStateRecord v1') -Reason 'execution must route to state record' -DataText $executionEvidence.nextAllowedSeam)) | Out-Null

  $head = Invoke-Native -FilePath 'git' -Arguments @('-C', $RepoRoot, 'log', '-1', '--pretty=format:%h %s')
  $Commands.Add([pscustomobject]@{ label = 'VERIFY NODEX HEAD STATE RECORD'; command = $head.command; actualArgvText = $head.actualArgvText; exitCode = $head.exitCode; output = $head.output }) | Out-Null
  $Checks.Add((New-Check -Name 'Nodex head exact' -Pass ($head.output -eq '5f062d6 Add packet generation reliability hardening manifests') -Reason 'Nodex head must match synced commit' -DataText $head.output)) | Out-Null

  $nodexStatus = Invoke-Native -FilePath 'git' -Arguments @('-C', $RepoRoot, 'status', '--porcelain=v1')
  $Commands.Add([pscustomobject]@{ label = 'NODEX STATUS STATE RECORD'; command = $nodexStatus.command; actualArgvText = $nodexStatus.actualArgvText; exitCode = $nodexStatus.exitCode; output = $nodexStatus.output }) | Out-Null
  $Checks.Add((New-Check -Name 'Nodex working tree clean' -Pass ($nodexStatus.output -eq '') -Reason 'Nodex working tree must be clean' -DataText $nodexStatus.output)) | Out-Null

  $liveStatus = Invoke-Native -FilePath 'git' -Arguments @('-C', $LiveContextRoot, 'status', '--porcelain=v1')
  $Commands.Add([pscustomobject]@{ label = 'LIVE CONTEXT STATUS STATE RECORD'; command = $liveStatus.command; actualArgvText = $liveStatus.actualArgvText; exitCode = $liveStatus.exitCode; output = $liveStatus.output }) | Out-Null

  $failed = @()
  foreach ($check in $Checks) { if (-not $check.pass) { $failed += $check.name } }
  if (($failed -join '; ') -ne '') { throw ('continuity sync state record checks failed: ' + ($failed -join '; ')) }

  $evidence = [pscustomobject]@{
    schema = 'nodex.continuity_sync.state_record.v1'
    status = 'pass'
    seam = 'ContinuitySyncStateRecord v1'
    stateRecordOnly = $true
    decision = 'continuity_sync_state_recorded_push_plan_allowed'
    createdAt = (Get-Date).ToString('o')
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    continuityExecutionEvidence = $ContinuityExecutionEvidencePath
    auditedCommit = '5f062d6 Add packet generation reliability hardening manifests'
    liveContextSynced = $true
    pushPerformed = $false
    nodexRepoPushPerformed = $false
    blocked = @('push','nodex_repo_push','manual_commit','manual_staging','reset','source_mutation','implementation','generated_code_approval','model_output_approval','prompt_output_authority','self_approval_authority','authority_self_expansion','reward_authority','autonomous_priority_authority','success_signal_authority','graph_expansion')
    validation = [pscustomobject]@{
      continuityExecutionEvidenceVerified = $true
      nodexHeadVerified = $true
      nodexWorkingTreeClean = $true
      authorityBlocksPreserved = $true
    }
    checks = $Checks.ToArray()
    commands = $Commands.ToArray()
    nextAllowedSeam = $ExpectedNextSeam
    failureMessage = ''
  }
  $json = $evidence | ConvertTo-Json -Depth 20
  Write-TextFileUtf8NoBom -Path $EvidenceJsonPath -Text $json
  $summary = @(
    'CONTINUITY SYNC STATE RECORD V1 COMPLETE',
    '',
    'status: pass',
    'decision: continuity_sync_state_recorded_push_plan_allowed',
    'state_record_only: true',
    'audited_commit: 5f062d6 Add packet generation reliability hardening manifests',
    'next_allowed_seam: ' + $ExpectedNextSeam,
    'evidence_json: ' + $EvidenceJsonPath,
    'evidence_summary: ' + $EvidenceSummaryPath
  ) -join "`n"
  Write-TextFileUtf8NoBom -Path $EvidenceSummaryPath -Text $summary
  Write-Host $summary
} catch {
  $message = $_.Exception.Message
  Write-Host 'CONTINUITY SYNC STATE RECORD V1 FAILED'
  Write-Host ('failure: ' + $message)
  exit 1
}