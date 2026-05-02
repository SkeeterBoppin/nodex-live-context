$ErrorActionPreference = "Stop"

$Schema = "nodex.continuity_sync.state_record.v1"
$Seam = "ContinuitySyncStateRecord v1"

$RepoRoot = "C:\Users\Zak\OneDrive\Desktop\Nodex System\Node"
$LiveContextRoot = "C:\Users\Zak\OneDrive\Desktop\nodex-live-context"
$EvidenceRoot = "C:\Users\Zak\OneDrive\Desktop\Nodex Evidence"

$ExpectedNodexHead = "062b834 Add model output approval boundary manifest"
$ExpectedLiveContextHeadBeforeCommit = "09ec3c6 Update continuity after generated code approval boundary"
$PriorSeam = "ContinuitySyncExecution v1"
$PriorDecision = "continuity_sync_executed"
$PlannedNextSeam = "ContinuitySyncCommitGate v1"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$EvidenceJson = Join-Path $EvidenceRoot ("continuity_sync_state_record_v1_" + $Timestamp + ".json")
$EvidenceSummary = Join-Path $EvidenceRoot ("continuity_sync_state_record_v1_summary_" + $Timestamp + ".txt")

$Checks = New-Object System.Collections.ArrayList
$Commands = New-Object System.Collections.ArrayList

function Add-Check {
  param([string]$Name, [bool]$Pass, [string]$Reason, [string]$DataText = "")
  [void]$script:Checks.Add([ordered]@{ name = $Name; pass = $Pass; reason = $Reason; dataText = $DataText })
  if (-not $Pass) { throw $Reason }
}

function Invoke-Captured {
  param([string]$Label, [scriptblock]$ScriptBlock, [string]$CommandText)
  $OutputText = ""
  $ExitCode = 0
  try {
    $OutputText = (& $ScriptBlock 2>&1 | Out-String).TrimEnd()
    if ($null -ne $LASTEXITCODE) { $ExitCode = [int]$LASTEXITCODE }
  } catch {
    $OutputText = ($_ | Out-String).TrimEnd()
    $ExitCode = 1
  }
  [void]$script:Commands.Add([ordered]@{ label = $Label; command = $CommandText; exitCode = $ExitCode; output = $OutputText })
  if ($ExitCode -ne 0) { throw "$Label failed with exit code ${ExitCode}: $OutputText" }
  return $OutputText
}

function Invoke-Git {
  param([string]$Label, [string]$WorkingDirectory, [string[]]$Arguments)
  $Rendered = @($Arguments | ForEach-Object { if ($_ -match ''\s'') { ''"'' + $_ + ''"'' } else { $_ } })
  return Invoke-Captured -Label $Label -CommandText ("git -C `"$WorkingDirectory`" " + ($Rendered -join " ")) -ScriptBlock {
    & git -C $WorkingDirectory @Arguments
  }
}

function Write-Evidence {
  param([string]$Status, [string]$Decision, [string]$FailureMessage = "")
  if (-not (Test-Path -LiteralPath $EvidenceRoot)) {
    New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
  }

  $Payload = [ordered]@{
    schema = $Schema
    status = $Status
    seam = $Seam
    stateRecord = $true
    decision = $Decision
    createdAt = (Get-Date).ToString("o")
    repoRoot = $RepoRoot
    liveContextRoot = $LiveContextRoot
    evidenceRoot = $EvidenceRoot
    auditedCommit = $ExpectedNodexHead
    liveContextHeadBeforeCommit = $ExpectedLiveContextHeadBeforeCommit
    priorSeam = $PriorSeam
    priorDecision = $PriorDecision
    continuityTargetsStateRecorded = ($Status -eq "pass")
    modelOutputApprovalGranted = $false
    modelOutputApprovalAllowedNow = $false
    generatedCodeApprovalGranted = $false
    generatedCodeApprovalAllowedNow = $false
    promptOutputAuthorityGranted = $false
    selfApprovalAuthorityGranted = $false
    authoritySelfExpansionGranted = $false
    sourceMutationPerformed = $false
    implementationPerformed = $false
    commitPerformed = $false
    stagingPerformed = $false
    liveContextCommitPerformed = $false
    liveContextStagingPerformed = $false
    validation = [ordered]@{
      priorContinuityExecutionVerified = ($Status -eq "pass")
      nodexHeadVerified = ($Status -eq "pass")
      liveContextDirtyStateVerified = ($Status -eq "pass")
      stateRecordWritten = ($Status -eq "pass")
    }
    checks = $Checks
    commands = $Commands
    nextAllowedSeam = $(if ($Status -eq "pass") { $PlannedNextSeam } else { $Seam })
    failureMessage = $FailureMessage
  }

  $Payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $EvidenceJson -Encoding UTF8

  $Summary = @(
    "CONTINUITY SYNC STATE RECORD V1 " + $(if ($Status -eq "pass") { "COMPLETE" } else { "FAILED" }),
    "",
    "status: $Status",
    "decision: $Decision",
    "audited_commit: $ExpectedNodexHead",
    "live_context_head_before_commit: $ExpectedLiveContextHeadBeforeCommit",
    "next_allowed_seam: " + $(if ($Status -eq "pass") { $PlannedNextSeam } else { $Seam }),
    "evidence_json: $EvidenceJson",
    "evidence_summary: $EvidenceSummary"
  )
  if ($FailureMessage) { $Summary += ""; $Summary += "failure: $FailureMessage" }
  $Summary | Set-Content -LiteralPath $EvidenceSummary -Encoding UTF8
}

try {
  $NodexHead = Invoke-Git "VERIFY NODEX HEAD CONTINUITY STATE RECORD" $RepoRoot @("log", "-1", "--oneline")
  Add-Check "Nodex head exact" ($NodexHead -eq $ExpectedNodexHead) "Nodex head mismatch" "actual=$NodexHead; expected=$ExpectedNodexHead"

  $ExecutionEvidence = Get-ChildItem -LiteralPath $EvidenceRoot -Filter "continuity_sync_execution_v1_*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  Add-Check "continuity execution evidence exists" ($null -ne $ExecutionEvidence) "missing ContinuitySyncExecution v1 evidence" "continuity_sync_execution_v1_*.json"

  $ExecutionJson = Get-Content -LiteralPath $ExecutionEvidence.FullName -Raw | ConvertFrom-Json
  Add-Check "continuity execution status pass" ($ExecutionJson.status -eq "pass") "ContinuitySyncExecution v1 must be pass" "status=$($ExecutionJson.status)"
  Add-Check "continuity execution decision exact" ($ExecutionJson.decision -eq $PriorDecision) "ContinuitySyncExecution v1 decision mismatch" "actual=$($ExecutionJson.decision); expected=$PriorDecision"
  Add-Check "continuity execution routes to state record" ($ExecutionJson.nextAllowedSeam -eq $Seam) "ContinuitySyncExecution v1 next seam mismatch" "actual=$($ExecutionJson.nextAllowedSeam); expected=$Seam"
  Add-Check "model output approval remains false" ($ExecutionJson.modelOutputApprovalGranted -eq $false) "model-output approval must remain false" "modelOutputApprovalGranted=$($ExecutionJson.modelOutputApprovalGranted)"
  Add-Check "generated code approval remains false" ($ExecutionJson.generatedCodeApprovalGranted -eq $false) "generated-code approval must remain false" "generatedCodeApprovalGranted=$($ExecutionJson.generatedCodeApprovalGranted)"

  $LiveStatus = Invoke-Git "LIVE CONTEXT STATUS BEFORE STATE RECORD" $LiveContextRoot @("status", "--porcelain=v1")
  Add-Check "live context has continuity changes" (-not [string]::IsNullOrWhiteSpace($LiveStatus)) "live context must have uncommitted continuity sync changes" $LiveStatus

  Write-Evidence -Status "pass" -Decision "continuity_sync_state_recorded"

  Write-Host "CONTINUITY SYNC STATE RECORD V1 COMPLETE"
  Write-Host ""
  Write-Host "status: pass"
  Write-Host "decision: continuity_sync_state_recorded"
  Write-Host "next_allowed_seam: $PlannedNextSeam"
  Write-Host "evidence_json: $EvidenceJson"
  Write-Host "evidence_summary: $EvidenceSummary"
}
catch {
  $Failure = $_.Exception.Message
  try {
    Write-Evidence -Status "fail" -Decision "continuity_sync_state_record_failed" -FailureMessage $Failure
  } catch {
    Write-Host "FAILED TO WRITE FAILURE ARTIFACTS:"
    Write-Host $_.Exception.Message
  }
  Write-Host "CONTINUITY SYNC STATE RECORD V1 FAILED"
  Write-Host $Failure
  exit 1
}

