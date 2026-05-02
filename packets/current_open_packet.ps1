$ErrorActionPreference = "Stop"

$Schema = "nodex.continuity_sync.state_record.v1"
$Seam = "ContinuitySyncStateRecord v1"

$RepoRoot = "C:\Users\Zak\OneDrive\Desktop\Nodex System\Node"
$LiveContextRoot = "C:\Users\Zak\OneDrive\Desktop\nodex-live-context"
$EvidenceRoot = "C:\Users\Zak\OneDrive\Desktop\Nodex Evidence"

$ExpectedNodexHead = "9aa487b Add success signal boundary manifest validator"
$PreviousNodexHead = "062b834 Add model output approval boundary manifest"
$ExpectedLiveContextHeadBeforeCommit = "20b654a Update continuity after model output approval boundary"

$PriorSeam = "ContinuitySyncExecution v1"
$PriorDecision = "continuity_sync_executed"
$PlannedNextSeam = "ContinuitySyncCommitGate v1"

$ContinuityTargets = @(
  "current_handoff.md",
  "evidence_latest/latest.json",
  "evidence_latest/latest_summary.txt",
  "packets/current_open_packet.ps1"
)

$BlockedAuthorities = @(
  "file_move_execution",
  "broad_filesystem_capability",
  "source_mutation",
  "implementation",
  "commit",
  "staging",
  "generated_code_approval",
  "model_output_approval",
  "prompt_output_authority",
  "self_approval_authority",
  "authority_self_expansion",
  "reward_authority",
  "autonomous_priority_authority",
  "success_signal_authority",
  "graph_expansion"
)

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

function Format-CommandArgument {
  param([string]$Value)
  if ($Value -match '\s') { return '"' + $Value + '"' }
  return $Value
}

function Invoke-Git {
  param([string]$Label, [string]$WorkingDirectory, [string[]]$Arguments)
  if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { throw "$Label missing working directory" }
  if ($null -eq $Arguments -or $Arguments.Count -eq 0) { throw "$Label missing git arguments" }

  $FullArgs = @("-C", $WorkingDirectory) + $Arguments
  $CommandText = "git " + (($FullArgs | ForEach-Object { Format-CommandArgument $_ }) -join " ")

  $OutputText = ""
  $ExitCode = 0
  try {
    $OutputText = (& git @FullArgs 2>&1 | Out-String).TrimEnd()
    $ExitCode = [int]$LASTEXITCODE
  } catch {
    $OutputText = ($_ | Out-String).TrimEnd()
    $ExitCode = 1
  }

  [void]$script:Commands.Add([ordered]@{ label = $Label; command = $CommandText; exitCode = $ExitCode; output = $OutputText })
  if ($ExitCode -ne 0) { throw "$Label failed with exit code ${ExitCode}: $OutputText" }
  return $OutputText
}

function Find-LatestEvidence {
  param([string]$Filter, [string]$ExpectedSeam, [string]$ExpectedDecision, [string]$ExpectedNextSeam, [string]$ExpectedAuditedCommit)
  $Candidates = Get-ChildItem -LiteralPath $EvidenceRoot -Filter $Filter | Sort-Object LastWriteTime -Descending
  foreach ($Candidate in $Candidates) {
    try {
      $Json = Get-Content -LiteralPath $Candidate.FullName -Raw | ConvertFrom-Json
      if (
        $Json.status -eq "pass" -and
        $Json.seam -eq $ExpectedSeam -and
        $Json.decision -eq $ExpectedDecision -and
        $Json.nextAllowedSeam -eq $ExpectedNextSeam -and
        $Json.auditedCommit -eq $ExpectedAuditedCommit
      ) {
        return [ordered]@{ file = $Candidate; json = $Json }
      }
    } catch {
      continue
    }
  }
  throw "No matching evidence found for $ExpectedSeam"
}

function Normalize-StatusPath {
  param([string]$Line)
  if ($Line.Length -lt 4) { return $Line }
  return $Line.Substring(3)
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
    previousAuditedCommit = $PreviousNodexHead
    liveContextHeadBeforeCommit = $ExpectedLiveContextHeadBeforeCommit
    priorSeam = $PriorSeam
    priorDecision = $PriorDecision
    continuityTargets = $ContinuityTargets
    continuityTargetsStateRecorded = ($Status -eq "pass")
    rewardAuthorityGranted = $false
    rewardAuthorityAllowedNow = $false
    successSignalAuthorityGranted = $false
    successSignalAuthorityAllowedNow = $false
    graphExpansionAllowedNow = $false
    modelOutputApprovalGranted = $false
    modelOutputApprovalAllowedNow = $false
    generatedCodeApprovalGranted = $false
    generatedCodeApprovalAllowedNow = $false
    promptOutputAuthorityGranted = $false
    selfApprovalAuthorityGranted = $false
    authoritySelfExpansionGranted = $false
    fileMoveExecutionAllowedNow = $false
    broadFilesystemCapabilityGranted = $false
    sourceMutationPerformed = $false
    implementationPerformed = $false
    commitPerformed = $false
    stagingPerformed = $false
    liveContextWritePerformed = $false
    liveContextCommitPerformed = $false
    liveContextStagingPerformed = $false
    fileMovePerformed = $false
    recommendedAfterContinuity = "OperatorDirectionRequired v1 should select PacketGenerationReliabilityHardeningPlan v1 before further feature expansion"
    blocked = $BlockedAuthorities
    validation = [ordered]@{
      priorContinuitySyncExecutionVerified = ($Status -eq "pass")
      nodexHeadVerified = ($Status -eq "pass")
      liveContextHeadVerified = ($Status -eq "pass")
      liveContextDirtyStateVerified = ($Status -eq "pass")
      stagedPathsEmpty = ($Status -eq "pass")
      stateRecorded = ($Status -eq "pass")
      authorityBlocksPreserved = ($Status -eq "pass")
    }
    checks = $Checks
    commands = $Commands
    nextAllowedSeam = $(if ($Status -eq "pass") { $PlannedNextSeam } else { $Seam })
    failureMessage = $FailureMessage
  }

  $Payload | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $EvidenceJson -Encoding UTF8

  $Summary = @(
    "CONTINUITY SYNC STATE RECORD V1 " + $(if ($Status -eq "pass") { "COMPLETE" } else { "FAILED" }),
    "",
    "status: $Status",
    "decision: $Decision",
    "state_record: true",
    "audited_commit: $ExpectedNodexHead",
    "previous_audited_commit: $PreviousNodexHead",
    "live_context_head_before_commit: $ExpectedLiveContextHeadBeforeCommit",
    "",
    "continuity_targets_state_recorded:",
    "- current_handoff.md",
    "- evidence_latest/latest.json",
    "- evidence_latest/latest_summary.txt",
    "- packets/current_open_packet.ps1",
    "",
    "recommended_after_continuity:",
    "- OperatorDirectionRequired v1 should select PacketGenerationReliabilityHardeningPlan v1 before further feature expansion",
    "",
    "next_allowed_seam: " + $(if ($Status -eq "pass") { $PlannedNextSeam } else { $Seam }),
    "evidence_json: $EvidenceJson",
    "evidence_summary: $EvidenceSummary"
  )
  if ($FailureMessage) { $Summary += ""; $Summary += "failure: $FailureMessage" }
  $Summary | Set-Content -LiteralPath $EvidenceSummary -Encoding UTF8

  if ($Status -eq "pass") {
    try { Set-Clipboard -Value (($Summary -join [Environment]::NewLine) + [Environment]::NewLine) } catch {}
  }
}

try {
  Add-Check "evidence root exists" (Test-Path -LiteralPath $EvidenceRoot) "evidence root must exist" $EvidenceRoot
  Add-Check "Nodex repo root exists" (Test-Path -LiteralPath $RepoRoot) "Nodex repo root must exist" $RepoRoot
  Add-Check "live context root exists" (Test-Path -LiteralPath $LiveContextRoot) "live context root must exist" $LiveContextRoot

  $Execution = Find-LatestEvidence `
    -Filter "continuity_sync_execution_v1_*.json" `
    -ExpectedSeam $PriorSeam `
    -ExpectedDecision $PriorDecision `
    -ExpectedNextSeam $Seam `
    -ExpectedAuditedCommit $ExpectedNodexHead

  Add-Check "prior continuity execution evidence exists" ($null -ne $Execution.file) "missing ContinuitySyncExecution v1 evidence" $Execution.file.FullName
  Add-Check "prior continuity execution wrote targets" ($Execution.json.continuityTargetsWritten -eq $true) "ContinuitySyncExecution v1 must write continuity targets" "continuityTargetsWritten=$($Execution.json.continuityTargetsWritten)"
  Add-Check "prior continuity execution live context write true" ($Execution.json.liveContextWritePerformed -eq $true) "ContinuitySyncExecution v1 must record live context write" "liveContextWritePerformed=$($Execution.json.liveContextWritePerformed)"
  Add-Check "prior continuity execution no commit" ($Execution.json.liveContextCommitPerformed -eq $false) "ContinuitySyncExecution v1 must not commit live context" "liveContextCommitPerformed=$($Execution.json.liveContextCommitPerformed)"
  Add-Check "prior continuity execution no staging" ($Execution.json.liveContextStagingPerformed -eq $false) "ContinuitySyncExecution v1 must not stage live context" "liveContextStagingPerformed=$($Execution.json.liveContextStagingPerformed)"
  Add-Check "prior reward authority false" ($Execution.json.rewardAuthorityGranted -eq $false) "reward authority must remain false" "rewardAuthorityGranted=$($Execution.json.rewardAuthorityGranted)"
  Add-Check "prior success signal authority false" ($Execution.json.successSignalAuthorityGranted -eq $false) "success signal authority must remain false" "successSignalAuthorityGranted=$($Execution.json.successSignalAuthorityGranted)"
  Add-Check "prior graph expansion false" ($Execution.json.graphExpansionAllowedNow -eq $false) "graph expansion must remain false" "graphExpansionAllowedNow=$($Execution.json.graphExpansionAllowedNow)"

  $NodexHead = Invoke-Git "VERIFY NODEX HEAD CONTINUITY STATE RECORD" $RepoRoot @("log", "-1", "--oneline")
  Add-Check "Nodex head exact" ($NodexHead -eq $ExpectedNodexHead) "Nodex head mismatch" "actual=$NodexHead; expected=$ExpectedNodexHead"

  $LiveContextHead = Invoke-Git "VERIFY LIVE CONTEXT HEAD CONTINUITY STATE RECORD" $LiveContextRoot @("log", "-1", "--oneline")
  Add-Check "live context head exact" ($LiveContextHead -eq $ExpectedLiveContextHeadBeforeCommit) "live context head mismatch" "actual=$LiveContextHead; expected=$ExpectedLiveContextHeadBeforeCommit"

  $LiveStatus = Invoke-Git "LIVE CONTEXT STATUS CONTINUITY STATE RECORD" $LiveContextRoot @("status", "--porcelain=v1")
  Add-Check "live context dirty after sync execution" (-not [string]::IsNullOrWhiteSpace($LiveStatus)) "live context must have continuity sync changes" $LiveStatus

  $DirtyPaths = @()
  if (-not [string]::IsNullOrWhiteSpace($LiveStatus)) {
    $DirtyPaths = @($LiveStatus -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Normalize-StatusPath $_ })
  }

  foreach ($Target in $ContinuityTargets) {
    Add-Check "continuity target dirty: $Target" ($DirtyPaths -contains $Target) "expected continuity target to be dirty: $Target" ($DirtyPaths -join "; ")
  }

  $Unexpected = @($DirtyPaths | Where-Object { $ContinuityTargets -notcontains $_ })
  Add-Check "no unexpected live context dirty paths" ($Unexpected.Count -eq 0) "unexpected live context dirty paths" ($Unexpected -join "; ")

  $NodexStatus = Invoke-Git "NODEX STATUS CONTINUITY STATE RECORD" $RepoRoot @("status", "--porcelain=v1")
  Add-Check "Nodex working tree clean" ([string]::IsNullOrWhiteSpace($NodexStatus)) "Nodex working tree must remain clean" $NodexStatus

  $NodexStaged = Invoke-Git "NODEX STAGED PATHS CONTINUITY STATE RECORD" $RepoRoot @("diff", "--cached", "--name-only")
  Add-Check "Nodex staged paths empty" ([string]::IsNullOrWhiteSpace($NodexStaged)) "Nodex staged paths must be empty" $NodexStaged

  $LiveStaged = Invoke-Git "LIVE CONTEXT STAGED PATHS CONTINUITY STATE RECORD" $LiveContextRoot @("diff", "--cached", "--name-only")
  Add-Check "live context staged paths empty" ([string]::IsNullOrWhiteSpace($LiveStaged)) "live context staged paths must be empty before commit gate" $LiveStaged

  Write-Evidence -Status "pass" -Decision "continuity_sync_state_recorded"

  Write-Host "SUMMARY COPIED TO CLIPBOARD:"
  Write-Host "- $EvidenceSummary"
  Write-Host "CONTINUITY SYNC STATE RECORD V1 COMPLETE"
  Write-Host ""
  Write-Host "status: pass"
  Write-Host "decision: continuity_sync_state_recorded"
  Write-Host "next_allowed_seam: $PlannedNextSeam"
  Write-Host "evidence_json: $EvidenceJson"
  Write-Host "evidence_summary: $EvidenceSummary"
} catch {
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
