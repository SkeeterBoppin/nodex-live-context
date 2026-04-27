# GIT EXECUTION AUTHORITY DECISION V1
# Boundary: decision only.
# This packet grants git execution by Nodex authority only if GitExecutionAuthorityPreflight v1 passed.
# It does NOT grant permission changes, AgentHandoffRunner runtime wiring, model-output authority, proof-claim promotion authority, external review authority, or Deep Research authority.
# It does NOT grant source mutation, evidence rewrite, evidence deletion, repo deletion, deletion, file move, staging, or commit authority outside explicit later seams.
# It does NOT mutate source, rewrite prior evidence, delete files, move files, wire adapters, run runtime workload, stage files, or commit.
# It writes new decision evidence and summary only.
# It copies the final summary to clipboard on success/failure where practical.

$ErrorActionPreference = "Stop"

$repoRoot = Join-Path $env:USERPROFILE "OneDrive\Desktop\Nodex System\Node"
$systemRoot = Join-Path $env:USERPROFILE "OneDrive\Desktop\Nodex System"
$downloadsRoot = Join-Path $env:USERPROFILE "Downloads"
$evidenceRoot = Join-Path $env:USERPROFILE "OneDrive\Desktop\Nodex Evidence"
$architectureRoot = Join-Path $systemRoot "Architecture"
$continuitySourcePath = Join-Path $architectureRoot "nodex_exact_continuity_source_v1.md"
$boundaryArchitectureSourcePath = Join-Path $architectureRoot "nodex_boundary_pushing_master_architecture.md"
$expectedHead = "c64ae68 Add proof claim layer manifest validator"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$decisionJson = Join-Path $evidenceRoot "git_execution_authority_decision_v1_$stamp.json"
$decisionSummary = Join-Path $evidenceRoot "git_execution_authority_decision_v1_summary_$stamp.txt"

$checks = @()
$commandResults = @()

$script:head = $null
$script:gitExecutionPreflightPath = $null
$script:gitExecutionPlanPath = $null
$script:priorAuditPath = $null
$script:processStatePath = $null
$script:processDecisionPath = $null
$script:runtimeFileWriteStatePath = $null
$script:runtimeFileWriteDecisionPath = $null
$script:toolStatePath = $null
$script:runtimeExecutionStatePath = $null
$script:runtimeIntegrationStatePath = $null
$script:activationStatePath = $null

$grantedBoundary = [ordered]@{
  activationAuthorityAllowed = $true
  activationAuthorityGranted = $true
  activationAuthorityScope = "activation_authority_only"

  runtimeIntegrationAuthorityAllowed = $true
  runtimeIntegrationAuthorityGranted = $true
  runtimeIntegrationAuthorityScope = "runtime_integration_authority_only"

  runtimeExecutionAuthorityAllowed = $true
  runtimeExecutionAuthorityGranted = $true
  runtimeExecutionAuthorityScope = "runtime_execution_authority_only"
  runtimeAuthorityGranted = $true

  toolExecutionAuthorityAllowed = $true
  toolExecutionAuthorityGranted = $true
  toolExecutionAuthorityScope = "tool_execution_authority_only"
  toolExecutionAllowed = $true

  runtimeFileWriteAuthorityAllowed = $true
  runtimeFileWriteAuthorityGranted = $true
  runtimeFileWriteAuthorityScope = "runtime_file_write_authority_only"
  runtimeFileWritesAllowed = $true
  runtimeFileWritesGranted = $true

  processExecutionAuthorityAllowed = $true
  processExecutionAuthorityGranted = $true
  processExecutionAuthorityScope = "process_execution_authority_only"
  processExecutionAllowed = $true
  processExecutionGranted = $true

  gitExecutionAuthorityAllowed = $true
  gitExecutionAuthorityGranted = $true
  gitExecutionAuthorityScope = "git_execution_authority_only"
  gitExecutionAllowedByNodex = $true
  gitExecutionByNodexGranted = $true

  permissionGrantsAllowed = $false
  permissionGrantsGranted = $false
  agentHandoffRuntimeWiringAllowed = $false
  modelOutputAuthorityAllowed = $false
  proofClaimPromotionAuthorityAllowed = $false
  replayAuthorityAllowed = $false
  externalReviewAuthorityAllowed = $false
  deepResearchAuthorityAllowed = $false
  packetHelperExecutionAuthorityAllowed = $false
  runtimeAdapterSideEffectAuthorityAllowed = $false

  sourceMutationAllowed = $false
  evidenceRewriteAllowed = $false
  evidenceDeletionAllowed = $false
  repoDeletionAllowed = $false
  deletionAllowed = $false
  fileMoveAllowed = $false
  stagingAllowed = $false
  commitAllowed = $false
}

$blocked = [ordered]@{
  permissionGrants = $true
  agentHandoffRuntimeWiring = $true
  modelOutputAuthority = $true
  proofClaimPromotionAuthority = $true
  externalReviewAuthority = $true
  deepResearchAuthority = $true
  sourceMutation = $true
  evidenceRewrite = $true
  evidenceDeletion = $true
  repoDeletion = $true
  deletion = $true
  fileMove = $true
  commit = $true
  staging = $true
  artifactQuarantine = $true
  packetQualityRepairImplementation = $true
  badCodeRepair = $true
  cleanupImplementation = $true
  additionalCleanupDeletion = $true
  additionalDownloadsCleanup = $true
}

function Add-Check {
  param(
    [string]$Name,
    [bool]$Pass,
    [string]$Reason,
    $Data = $null
  )

  $script:checks += [ordered]@{
    name = $Name
    pass = $Pass
    reason = $Reason
    data = $Data
  }

  if (-not $Pass) {
    throw $Reason
  }
}

function Invoke-Recorded {
  param(
    [string]$Label,
    [string]$FilePath,
    [string[]]$Arguments
  )

  $combined = ""
  $exitCode = 0

  try {
    $output = & $FilePath @Arguments 2>&1
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    if ($null -ne $output) {
      $combined = ($output | Out-String).TrimEnd()
    }
  } catch {
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 1 }
    $combined = $_.Exception.Message
  }

  $script:commandResults += [ordered]@{
    label = $Label
    filePath = $FilePath
    arguments = $Arguments
    exitCode = $exitCode
    stdoutStderr = $combined
  }

  return [ordered]@{
    exitCode = $exitCode
    stdoutStderr = $combined
  }
}

function Copy-SummaryToClipboard {
  param([string]$Path)

  try {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      Get-Content -LiteralPath $Path -Raw | Set-Clipboard
      Write-Host ""
      Write-Host "SUMMARY COPIED TO CLIPBOARD:"
      Write-Host "- $Path"
    } else {
      Write-Host ""
      Write-Host "FAILED_TO_COPY_SUMMARY_TO_CLIPBOARD:"
      Write-Host "- summary file missing: $Path"
    }
  } catch {
    Write-Host ""
    Write-Host "FAILED_TO_COPY_SUMMARY_TO_CLIPBOARD:"
    Write-Host "- $($_.Exception.Message)"
  }
}

function Get-LatestEvidence {
  param(
    [string]$Filter,
    [string]$Label
  )

  $file = Get-ChildItem -LiteralPath $evidenceRoot -Filter $Filter -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  Add-Check "$Label exists" ($null -ne $file) "missing $Filter evidence" ([ordered]@{
    pattern = $Filter
  })

  return $file.FullName
}

function Read-JsonFile {
  param(
    [string]$Path,
    [string]$Label
  )

  Add-Check "$Label path present" (-not [string]::IsNullOrWhiteSpace($Path)) "$Label path must be present" ([ordered]@{
    path = $Path
  })

  Add-Check "$Label file exists" (Test-Path -LiteralPath $Path -PathType Leaf) "$Label file must exist" ([ordered]@{
    path = $Path
  })

  return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Assert-True {
  param($Value, [string]$Name)
  Add-Check $Name ($Value -eq $true) "$Name must be true" ([ordered]@{
    actual = $Value
  })
}

function Assert-False {
  param($Value, [string]$Name)
  Add-Check $Name ($Value -eq $false) "$Name must be false" ([ordered]@{
    actual = $Value
  })
}

function Write-FailureEvidence {
  param([string]$Message)

  try {
    $failureBoundary = $grantedBoundary.Clone()
    $failureBoundary.gitExecutionAuthorityAllowed = $false
    $failureBoundary.gitExecutionAuthorityGranted = $false
    $failureBoundary.gitExecutionAuthorityScope = "blocked"
    $failureBoundary.gitExecutionAllowedByNodex = $false
    $failureBoundary.gitExecutionByNodexGranted = $false

    $failure = [ordered]@{
      schema = "nodex.git_execution_authority.decision.v1"
      status = "fail"
      createdAt = (Get-Date).ToString("o")
      repoRoot = $repoRoot
      systemRoot = $systemRoot
      downloadsRoot = $downloadsRoot
      evidenceRoot = $evidenceRoot
      architectureRoot = $architectureRoot
      seam = "GitExecutionAuthorityDecision v1"
      auditedCommit = [ordered]@{
        expected = $expectedHead
        head = $script:head
      }
      priorGitExecutionAuthorityPreflight = $script:gitExecutionPreflightPath
      priorGitExecutionAuthorityPlan = $script:gitExecutionPlanPath
      nextAllowedSeam = "GitExecutionAuthorityDecisionRepair v1"
      decisionOnly = $true
      decision = "git_execution_authority_decision_failed"
      gitExecutionAuthorityGranted = $false
      gitExecutionByNodexGranted = $false
      permissionGrantsGranted = $false
      agentHandoffRuntimeWiringAllowedNow = $false
      sourceMutationAllowedNow = $false
      evidenceRewriteAllowedNow = $false
      evidenceDeletionAllowedNow = $false
      repoDeletionAllowedNow = $false
      deletionAllowedNow = $false
      fileMoveAllowedNow = $false
      commitAllowedNow = $false
      stagingAllowedNow = $false
      boundary = $failureBoundary
      blocked = $blocked
      checks = $checks
      commandResults = $commandResults
      failure = [ordered]@{
        message = $Message
      }
    }

    $failure | ConvertTo-Json -Depth 45 | Set-Content -LiteralPath $decisionJson -Encoding UTF8

    Set-Content -LiteralPath $decisionSummary -Encoding UTF8 -Value @"
GIT EXECUTION AUTHORITY DECISION V1

status: fail
failure: $Message
git_execution_authority_granted: false
git_execution_by_nodex_granted: false
permission_grants_granted: false
agent_handoff_runtime_wiring_allowed_now: false

source_mutation_allowed_now: false
evidence_rewrite_allowed_now: false
evidence_deletion_allowed_now: false
repo_deletion_allowed_now: false
deletion_allowed_now: false
file_move_allowed_now: false
commit_allowed_now: false
staging_allowed_now: false

next_allowed_seam: GitExecutionAuthorityDecisionRepair v1

evidence_json: $decisionJson
evidence_summary: $decisionSummary
"@

    Copy-SummaryToClipboard $decisionSummary
  } catch {
    Write-Host "FAILED TO WRITE GIT EXECUTION AUTHORITY DECISION FAILURE EVIDENCE"
    Write-Host $_.Exception.Message
  }
}

try {
  Set-Location -LiteralPath $repoRoot

  $preStatusResult = Invoke-Recorded "GIT STATUS --SHORT PRE" "git" @("status", "--short")
  $preStatusShort = $preStatusResult.stdoutStderr.Trim()
  Add-Check "pre-decision working tree clean" ($preStatusShort -eq "") "GitExecutionAuthorityDecision v1 must start with clean working tree" ([ordered]@{
    statusShort = $preStatusShort
  })

  $headResult = Invoke-Recorded "VERIFY HEAD" "git" @("log", "-1", "--oneline")
  $script:head = $headResult.stdoutStderr.Trim()
  Add-Check "committed baseline verified" ($script:head -eq $expectedHead) "HEAD must match GitExecutionAuthorityDecision baseline" ([ordered]@{
    expected = $expectedHead
    actual = $script:head
  })

  $script:gitExecutionPreflightPath = Get-LatestEvidence "git_execution_authority_preflight_v1_*.json" "git execution authority preflight JSON"
  $script:gitExecutionPlanPath = Get-LatestEvidence "git_execution_authority_plan_v1_*.json" "git execution authority plan JSON"
  $script:priorAuditPath = Get-LatestEvidence "post_process_execution_authority_grant_spine_audit_v1_*.json" "post-process execution authority grant spine audit JSON"
  $script:processStatePath = Get-LatestEvidence "process_execution_authority_state_record_v1_*.json" "process execution authority state record JSON"
  $script:processDecisionPath = Get-LatestEvidence "process_execution_authority_decision_v1_*.json" "process execution authority decision JSON"
  $script:runtimeFileWriteStatePath = Get-LatestEvidence "runtime_file_write_authority_state_record_v1_*.json" "runtime file write authority state record JSON"
  $script:runtimeFileWriteDecisionPath = Get-LatestEvidence "runtime_file_write_authority_decision_v1_*.json" "runtime file write authority decision JSON"
  $script:toolStatePath = Get-LatestEvidence "tool_execution_authority_state_record_v1_*.json" "tool execution authority state record JSON"
  $script:runtimeExecutionStatePath = Get-LatestEvidence "runtime_execution_authority_state_record_v1_*.json" "runtime execution authority state record JSON"
  $script:runtimeIntegrationStatePath = Get-LatestEvidence "runtime_integration_authority_state_record_v1_*.json" "runtime integration authority state record JSON"
  $script:activationStatePath = Get-LatestEvidence "activation_authority_state_record_v1_*.json" "activation authority state record JSON"

  $gitPreflight = Read-JsonFile $script:gitExecutionPreflightPath "git execution authority preflight"
  $gitPlan = Read-JsonFile $script:gitExecutionPlanPath "git execution authority plan"
  $priorAudit = Read-JsonFile $script:priorAuditPath "post-process execution authority grant spine audit"
  $processState = Read-JsonFile $script:processStatePath "process execution authority state record"
  $processDecision = Read-JsonFile $script:processDecisionPath "process execution authority decision"
  $runtimeFileWriteState = Read-JsonFile $script:runtimeFileWriteStatePath "runtime file write authority state record"
  $runtimeFileWriteDecision = Read-JsonFile $script:runtimeFileWriteDecisionPath "runtime file write authority decision"
  $toolState = Read-JsonFile $script:toolStatePath "tool execution authority state record"
  $runtimeExecutionState = Read-JsonFile $script:runtimeExecutionStatePath "runtime execution authority state record"
  $runtimeIntegrationState = Read-JsonFile $script:runtimeIntegrationStatePath "runtime integration authority state record"
  $activationState = Read-JsonFile $script:activationStatePath "activation authority state record"

  Add-Check "git execution preflight status pass" ($gitPreflight.status -eq "pass") "git execution authority preflight must be pass" ([ordered]@{
    path = $script:gitExecutionPreflightPath
  })
  Add-Check "git execution preflight exact decision" ($gitPreflight.decision -eq "git_execution_authority_decision_ready") "git execution preflight must be decision ready" ([ordered]@{
    decision = $gitPreflight.decision
  })
  Add-Check "git execution preflight routes to decision" (($gitPreflight.nextAllowedSeam -eq "GitExecutionAuthorityDecision v1") -or ($gitPreflight.gitExecutionAuthorityDecisionAllowedNow -eq $true)) "git execution preflight must route to GitExecutionAuthorityDecision v1" ([ordered]@{
    nextAllowedSeam = $gitPreflight.nextAllowedSeam
    gitExecutionAuthorityDecisionAllowedNow = $gitPreflight.gitExecutionAuthorityDecisionAllowedNow
  })
  Assert-True $gitPreflight.gitExecutionAuthorityDecisionAllowedNow "git preflight gitExecutionAuthorityDecisionAllowedNow"
  Assert-False $gitPreflight.gitExecutionByNodexGranted "git preflight gitExecutionByNodexGranted"
  Assert-False $gitPreflight.permissionGrantsGranted "git preflight permissionGrantsGranted"
  Assert-False $gitPreflight.agentHandoffRuntimeWiringAllowedNow "git preflight agentHandoffRuntimeWiringAllowedNow"
  Assert-False $gitPreflight.modelOutputAuthorityGranted "git preflight modelOutputAuthorityGranted"
  Assert-False $gitPreflight.proofClaimPromotionAuthorityGranted "git preflight proofClaimPromotionAuthorityGranted"
  Assert-False $gitPreflight.externalReviewAuthorityGranted "git preflight externalReviewAuthorityGranted"
  Assert-False $gitPreflight.deepResearchAuthorityGranted "git preflight deepResearchAuthorityGranted"
  Assert-False $gitPreflight.sourceMutationAllowedNow "git preflight sourceMutationAllowedNow"
  Assert-False $gitPreflight.evidenceRewriteAllowedNow "git preflight evidenceRewriteAllowedNow"
  Assert-False $gitPreflight.evidenceDeletionAllowedNow "git preflight evidenceDeletionAllowedNow"
  Assert-False $gitPreflight.repoDeletionAllowedNow "git preflight repoDeletionAllowedNow"
  Assert-False $gitPreflight.deletionAllowedNow "git preflight deletionAllowedNow"
  Assert-False $gitPreflight.fileMoveAllowedNow "git preflight fileMoveAllowedNow"
  Assert-False $gitPreflight.commitAllowedNow "git preflight commitAllowedNow"
  Assert-False $gitPreflight.stagingAllowedNow "git preflight stagingAllowedNow"

  Add-Check "git execution plan status pass" ($gitPlan.status -eq "pass") "git execution authority plan must be pass" ([ordered]@{
    path = $script:gitExecutionPlanPath
  })
  Add-Check "git execution plan exact decision" ($gitPlan.decision -eq "git_execution_authority_preflight_planned") "git execution plan must have planned preflight" ([ordered]@{
    decision = $gitPlan.decision
  })
  Assert-False $gitPlan.gitExecutionAuthorityDecisionAllowedNow "git plan gitExecutionAuthorityDecisionAllowedNow"
  Assert-False $gitPlan.gitExecutionByNodexGranted "git plan gitExecutionByNodexGranted"
  Assert-False $gitPlan.permissionGrantsGranted "git plan permissionGrantsGranted"
  Assert-False $gitPlan.agentHandoffRuntimeWiringAllowedNow "git plan agentHandoffRuntimeWiringAllowedNow"
  Assert-False $gitPlan.commitAllowedNow "git plan commitAllowedNow"
  Assert-False $gitPlan.stagingAllowedNow "git plan stagingAllowedNow"

  Add-Check "prior spine audit status pass" ($priorAudit.status -eq "pass") "prior post-process execution authority grant spine audit must be pass" ([ordered]@{
    path = $script:priorAuditPath
  })
  Add-Check "prior spine audit decision exact" ($priorAudit.decision -eq "post_process_execution_authority_grant_spine_audit_complete") "prior spine audit decision must be complete" ([ordered]@{
    decision = $priorAudit.decision
  })
  Assert-True $priorAudit.processExecutionAuthorityGranted "prior audit processExecutionAuthorityGranted"
  Assert-True $priorAudit.processExecutionGranted "prior audit processExecutionGranted"
  Add-Check "prior audit process scope exact" ($priorAudit.processExecutionAuthorityScope -eq "process_execution_authority_only") "process execution scope must be process_execution_authority_only" ([ordered]@{
    actual = $priorAudit.processExecutionAuthorityScope
  })
  Assert-False $priorAudit.gitExecutionByNodexGranted "prior audit gitExecutionByNodexGranted"
  Assert-False $priorAudit.permissionGrantsGranted "prior audit permissionGrantsGranted"
  Assert-False $priorAudit.agentHandoffRuntimeWiringAllowedNow "prior audit agentHandoffRuntimeWiringAllowedNow"
  Assert-False $priorAudit.sourceMutationAllowedNow "prior audit sourceMutationAllowedNow"
  Assert-False $priorAudit.evidenceRewriteAllowedNow "prior audit evidenceRewriteAllowedNow"
  Assert-False $priorAudit.evidenceDeletionAllowedNow "prior audit evidenceDeletionAllowedNow"
  Assert-False $priorAudit.repoDeletionAllowedNow "prior audit repoDeletionAllowedNow"
  Assert-False $priorAudit.deletionAllowedNow "prior audit deletionAllowedNow"
  Assert-False $priorAudit.fileMoveAllowedNow "prior audit fileMoveAllowedNow"

  Add-Check "process execution state status pass" ($processState.status -eq "pass") "process execution state record must be pass" ([ordered]@{
    path = $script:processStatePath
  })
  Assert-True $processState.processExecutionAuthorityGranted "process state processExecutionAuthorityGranted"
  Assert-True $processState.processExecutionGranted "process state processExecutionGranted"
  Add-Check "process state scope exact" ($processState.processExecutionAuthorityScope -eq "process_execution_authority_only") "process execution scope must be process_execution_authority_only" ([ordered]@{
    actual = $processState.processExecutionAuthorityScope
  })
  Assert-False $processState.gitExecutionByNodexGranted "process state gitExecutionByNodexGranted"
  Assert-False $processState.permissionGrantsGranted "process state permissionGrantsGranted"

  Add-Check "process execution decision status pass" ($processDecision.status -eq "pass") "process execution decision must be pass" ([ordered]@{
    path = $script:processDecisionPath
  })
  Assert-True $processDecision.processExecutionAuthorityGranted "process decision processExecutionAuthorityGranted"
  Assert-True $processDecision.processExecutionGranted "process decision processExecutionGranted"
  Assert-False $processDecision.gitExecutionByNodexGranted "process decision gitExecutionByNodexGranted"
  Assert-False $processDecision.permissionGrantsGranted "process decision permissionGrantsGranted"

  Add-Check "runtime file write state status pass" ($runtimeFileWriteState.status -eq "pass") "runtime file write state record must be pass" ([ordered]@{
    path = $script:runtimeFileWriteStatePath
  })
  Assert-True $runtimeFileWriteState.runtimeFileWriteAuthorityGranted "runtime file write state runtimeFileWriteAuthorityGranted"
  Assert-True $runtimeFileWriteState.runtimeFileWritesGranted "runtime file write state runtimeFileWritesGranted"

  Add-Check "runtime file write decision status pass" ($runtimeFileWriteDecision.status -eq "pass") "runtime file write decision must be pass" ([ordered]@{
    path = $script:runtimeFileWriteDecisionPath
  })
  Assert-True $runtimeFileWriteDecision.runtimeFileWriteAuthorityGranted "runtime file write decision runtimeFileWriteAuthorityGranted"
  Assert-True $runtimeFileWriteDecision.runtimeFileWritesGranted "runtime file write decision runtimeFileWritesGranted"

  Add-Check "tool execution state status pass" ($toolState.status -eq "pass") "tool execution state record must be pass" ([ordered]@{
    path = $script:toolStatePath
  })
  Assert-True $toolState.toolExecutionAuthorityGranted "tool state toolExecutionAuthorityGranted"
  Add-Check "tool state scope exact" ($toolState.toolExecutionAuthorityScope -eq "tool_execution_authority_only") "tool execution scope must be tool_execution_authority_only" ([ordered]@{
    actual = $toolState.toolExecutionAuthorityScope
  })

  Add-Check "runtime execution state status pass" ($runtimeExecutionState.status -eq "pass") "runtime execution state record must be pass" ([ordered]@{
    path = $script:runtimeExecutionStatePath
  })
  Assert-True $runtimeExecutionState.runtimeExecutionAuthorityGranted "runtime execution state runtimeExecutionAuthorityGranted"
  Add-Check "runtime execution scope exact" ($runtimeExecutionState.runtimeExecutionAuthorityScope -eq "runtime_execution_authority_only") "runtime execution scope must be runtime_execution_authority_only" ([ordered]@{
    actual = $runtimeExecutionState.runtimeExecutionAuthorityScope
  })

  Add-Check "runtime integration state status pass" ($runtimeIntegrationState.status -eq "pass") "runtime integration state record must be pass" ([ordered]@{
    path = $script:runtimeIntegrationStatePath
  })
  Assert-True $runtimeIntegrationState.runtimeIntegrationAuthorityGranted "runtime integration state runtimeIntegrationAuthorityGranted"
  Add-Check "runtime integration scope exact" ($runtimeIntegrationState.runtimeIntegrationAuthorityScope -eq "runtime_integration_authority_only") "runtime integration scope must be runtime_integration_authority_only" ([ordered]@{
    actual = $runtimeIntegrationState.runtimeIntegrationAuthorityScope
  })

  Add-Check "activation state status pass" ($activationState.status -eq "pass") "activation authority state record must be pass" ([ordered]@{
    path = $script:activationStatePath
  })
  Assert-True $activationState.activationAuthorityGranted "activation state activationAuthorityGranted"
  Add-Check "activation scope exact" ($activationState.activationAuthorityScope -eq "activation_authority_only") "activation scope must be activation_authority_only" ([ordered]@{
    actual = $activationState.activationAuthorityScope
  })

  Add-Check "architecture root exists" (Test-Path -LiteralPath $architectureRoot -PathType Container) "architecture root must exist" ([ordered]@{
    path = $architectureRoot
  })
  Add-Check "continuity source exists" (Test-Path -LiteralPath $continuitySourcePath -PathType Leaf) "continuity source must exist" ([ordered]@{
    path = $continuitySourcePath
  })
  Add-Check "boundary architecture source exists" (Test-Path -LiteralPath $boundaryArchitectureSourcePath -PathType Leaf) "boundary architecture source must exist" ([ordered]@{
    path = $boundaryArchitectureSourcePath
  })
  Add-Check "package.json exists" (Test-Path -LiteralPath (Join-Path $repoRoot "package.json") -PathType Leaf) "package.json must exist" ([ordered]@{
    path = Join-Path $repoRoot "package.json"
  })
  Add-Check "tests/run.js exists" (Test-Path -LiteralPath (Join-Path $repoRoot "tests\run.js") -PathType Leaf) "tests/run.js must exist" ([ordered]@{
    path = Join-Path $repoRoot "tests\run.js"
  })

  $harness = Invoke-Recorded "FULL HARNESS DECISION" "node" @("tests/run.js")
  Add-Check "full harness passed during decision" ($harness.exitCode -eq 0 -and $harness.stdoutStderr -match "All Nodex tests passed") "node tests/run.js must pass during GitExecutionAuthorityDecision v1" ([ordered]@{
    output = $harness.stdoutStderr
  })

  $postStatusResult = Invoke-Recorded "GIT STATUS --SHORT POST" "git" @("status", "--short")
  $postStatusShort = $postStatusResult.stdoutStderr.Trim()
  Add-Check "post-decision working tree clean" ($postStatusShort -eq "") "GitExecutionAuthorityDecision v1 must leave repo working tree clean" ([ordered]@{
    statusShort = $postStatusShort
  })

  $decision = [ordered]@{
    schema = "nodex.git_execution_authority.decision.v1"
    status = "pass"
    createdAt = (Get-Date).ToString("o")
    repoRoot = $repoRoot
    systemRoot = $systemRoot
    downloadsRoot = $downloadsRoot
    evidenceRoot = $evidenceRoot
    architectureRoot = $architectureRoot
    seam = "GitExecutionAuthorityDecision v1"
    auditedCommit = [ordered]@{
      expected = $expectedHead
      head = $script:head
    }

    priorGitExecutionAuthorityPreflight = $script:gitExecutionPreflightPath
    priorGitExecutionAuthorityPlan = $script:gitExecutionPlanPath
    priorPostProcessExecutionAuthorityGrantSpineAudit = $script:priorAuditPath
    priorProcessExecutionAuthorityStateRecord = $script:processStatePath
    priorProcessExecutionAuthorityDecision = $script:processDecisionPath
    priorRuntimeFileWriteAuthorityStateRecord = $script:runtimeFileWriteStatePath
    priorRuntimeFileWriteAuthorityDecision = $script:runtimeFileWriteDecisionPath
    priorToolExecutionAuthorityStateRecord = $script:toolStatePath
    priorRuntimeExecutionAuthorityStateRecord = $script:runtimeExecutionStatePath
    priorRuntimeIntegrationAuthorityStateRecord = $script:runtimeIntegrationStatePath
    priorActivationAuthorityStateRecord = $script:activationStatePath

    decisionOnly = $true
    decision = "git_execution_authority_granted"

    activationAuthorityGranted = $true
    activationAuthorityScope = "activation_authority_only"

    runtimeIntegrationAuthorityGranted = $true
    runtimeIntegrationAuthorityScope = "runtime_integration_authority_only"

    runtimeAuthorityGranted = $true
    runtimeExecutionAuthorityGranted = $true
    runtimeExecutionAuthorityScope = "runtime_execution_authority_only"

    toolExecutionAuthorityGranted = $true
    toolExecutionAuthorityScope = "tool_execution_authority_only"

    runtimeFileWriteAuthorityGranted = $true
    runtimeFileWriteAuthorityScope = "runtime_file_write_authority_only"
    runtimeFileWritesGranted = $true

    processExecutionAuthorityGranted = $true
    processExecutionAuthorityScope = "process_execution_authority_only"
    processExecutionAuthorityStateRecorded = $true
    processExecutionGranted = $true

    gitExecutionAuthorityDecisionApplied = $true
    gitExecutionAuthorityGranted = $true
    gitExecutionAuthorityScope = "git_execution_authority_only"
    gitExecutionByNodexGranted = $true
    gitExecutionAuthorityStateRecordAllowedNow = $true

    permissionGrantsGranted = $false
    agentHandoffRuntimeWiringAllowedNow = $false
    modelOutputAuthorityGranted = $false
    proofClaimPromotionAuthorityGranted = $false
    externalReviewAuthorityGranted = $false
    deepResearchAuthorityGranted = $false

    sourceMutationAllowedNow = $false
    evidenceRewriteAllowedNow = $false
    evidenceDeletionAllowedNow = $false
    repoDeletionAllowedNow = $false
    deletionAllowedNow = $false
    fileMoveAllowedNow = $false
    commitAllowedNow = $false
    stagingAllowedNow = $false

    nextAllowedSeam = "GitExecutionAuthorityStateRecord v1"
    plannedFollowingSeams = @(
      "Post-GitExecutionAuthorityGrant Spine Audit v1",
      "PermissionGrantAuthorityPlan v1"
    )

    grantBasis = [ordered]@{
      activationAuthorityGranted = $true
      runtimeIntegrationAuthorityGranted = $true
      runtimeExecutionAuthorityGranted = $true
      toolExecutionAuthorityGranted = $true
      runtimeFileWriteAuthorityGranted = $true
      processExecutionAuthorityGranted = $true
      postProcessExecutionSpineAuditPassed = $true
      gitExecutionAuthorityPreflightPassed = $true
      fullHarnessPassed = $true
      workingTreeClean = $true
    }

    gitExecutionAuthorityAllowedEffects = @(
      "record git execution by Nodex authority as granted",
      "allow future planning/audit seams explicitly derived from git execution authority",
      "preserve permission/model-output/proof-promotion/external-review/Deep-Research authority blocks",
      "preserve AgentHandoffRunner runtime wiring block until explicit later seam",
      "preserve source mutation/evidence rewrite/evidence deletion/repo deletion/deletion/file move/staging/commit blocks until explicit later seams"
    )

    explicitNonGrants = @(
      "permission grants",
      "AgentHandoffRunner runtime wiring",
      "model-output authority",
      "proof-claim promotion authority",
      "external review authority",
      "Deep Research authority",
      "source mutation",
      "evidence rewrite",
      "evidence deletion",
      "repo deletion",
      "deletion",
      "file move",
      "staging",
      "commit authority outside explicit commit-gate seams"
    )

    boundary = $grantedBoundary
    blocked = $blocked

    validation = [ordered]@{
      gitExecutionAuthorityPreflightVerified = $true
      gitExecutionAuthorityPlanVerified = $true
      priorSpineAuditVerified = $true
      processExecutionStateRecordVerified = $true
      processExecutionDecisionVerified = $true
      runtimeFileWriteStateRecordVerified = $true
      runtimeFileWriteDecisionVerified = $true
      toolExecutionStateRecordVerified = $true
      runtimeExecutionStateRecordVerified = $true
      runtimeIntegrationStateRecordVerified = $true
      activationStateRecordVerified = $true
      expectedHeadVerified = $true
      architectureSourcesVerified = $true
      preDecisionWorkingTreeClean = $true
      fullHarnessPassed = $true
      postDecisionWorkingTreeClean = $true
      activationAuthorityGranted = $true
      runtimeIntegrationAuthorityGranted = $true
      runtimeAuthorityGranted = $true
      runtimeExecutionAuthorityGranted = $true
      toolExecutionAuthorityGranted = $true
      runtimeFileWriteAuthorityGranted = $true
      runtimeFileWritesGranted = $true
      processExecutionAuthorityGranted = $true
      processExecutionGranted = $true
      gitExecutionAuthorityGranted = $true
      gitExecutionByNodexGranted = $true
      permissionGrantsGranted = $false
      agentHandoffRuntimeWiringAllowed = $false
      modelOutputAuthorityGranted = $false
      proofClaimPromotionAuthorityGranted = $false
      externalReviewAuthorityGranted = $false
      deepResearchAuthorityGranted = $false
      sourceMutation = $false
      evidenceRewrite = $false
      evidenceDeletion = $false
      repoDeletion = $false
      deletion = $false
      fileMove = $false
      commit = $false
      staging = $false
    }

    checks = $checks
    commandResults = $commandResults
    failure = $null
  }

  $decision | ConvertTo-Json -Depth 45 | Set-Content -LiteralPath $decisionJson -Encoding UTF8

  $readback = Get-Content -LiteralPath $decisionJson -Raw | ConvertFrom-Json
  Add-Check "decision JSON readback status pass" ($readback.status -eq "pass") "decision JSON readback must be pass" ([ordered]@{
    path = $decisionJson
  })
  Add-Check "decision JSON readback next seam" ($readback.nextAllowedSeam -eq "GitExecutionAuthorityStateRecord v1") "decision JSON readback must route to GitExecutionAuthorityStateRecord v1" ([ordered]@{
    path = $decisionJson
    nextAllowedSeam = $readback.nextAllowedSeam
  })
  Add-Check "decision JSON readback git execution granted" ($readback.gitExecutionByNodexGranted -eq $true) "decision JSON readback must grant git execution by Nodex" ([ordered]@{
    path = $decisionJson
  })
  Add-Check "decision JSON readback permission still blocked" ($readback.permissionGrantsGranted -eq $false) "decision JSON readback must keep permission grants blocked" ([ordered]@{
    path = $decisionJson
  })
  Add-Check "decision JSON readback source mutation blocked" ($readback.sourceMutationAllowedNow -eq $false) "decision JSON readback must keep source mutation blocked" ([ordered]@{
    path = $decisionJson
  })
  Add-Check "decision JSON readback commit blocked" ($readback.commitAllowedNow -eq $false) "decision JSON readback must keep commit blocked" ([ordered]@{
    path = $decisionJson
  })
  Add-Check "decision JSON readback staging blocked" ($readback.stagingAllowedNow -eq $false) "decision JSON readback must keep staging blocked" ([ordered]@{
    path = $decisionJson
  })

  Set-Content -LiteralPath $decisionSummary -Encoding UTF8 -Value @"
GIT EXECUTION AUTHORITY DECISION V1

status: pass
audited_commit: $script:head
decision_only: true
decision: git_execution_authority_granted

activation_authority_granted: true
activation_authority_scope: activation_authority_only

runtime_integration_authority_granted: true
runtime_integration_authority_scope: runtime_integration_authority_only

runtime_authority_granted: true
runtime_execution_authority_granted: true
runtime_execution_authority_scope: runtime_execution_authority_only

tool_execution_authority_granted: true
tool_execution_authority_scope: tool_execution_authority_only

runtime_file_write_authority_granted: true
runtime_file_write_authority_scope: runtime_file_write_authority_only
runtime_file_writes_granted: true

process_execution_authority_granted: true
process_execution_authority_scope: process_execution_authority_only
process_execution_authority_state_recorded: true
process_execution_granted: true

git_execution_authority_decision_applied: true
git_execution_authority_granted: true
git_execution_authority_scope: git_execution_authority_only
git_execution_by_nodex_granted: true
git_execution_authority_state_record_allowed_now: true

permission_grants_granted: false
agent_handoff_runtime_wiring_allowed_now: false
model_output_authority_granted: false
proof_claim_promotion_authority_granted: false
external_review_authority_granted: false
deep_research_authority_granted: false

source_mutation_allowed_now: false
evidence_rewrite_allowed_now: false
evidence_deletion_allowed_now: false
repo_deletion_allowed_now: false
deletion_allowed_now: false
file_move_allowed_now: false
commit_allowed_now: false
staging_allowed_now: false

next_allowed_seam: GitExecutionAuthorityStateRecord v1

planned_following_seams:
- Post-GitExecutionAuthorityGrant Spine Audit v1
- PermissionGrantAuthorityPlan v1

evidence_json: $decisionJson
evidence_summary: $decisionSummary
"@

  Add-Check "decision summary exists" (Test-Path -LiteralPath $decisionSummary -PathType Leaf) "decision summary must exist" ([ordered]@{
    path = $decisionSummary
  })

  Copy-SummaryToClipboard $decisionSummary

  Write-Host "GIT EXECUTION AUTHORITY DECISION V1 COMPLETE"
  Write-Host ""
  Write-Host "Audited commit:"
  Write-Host "- $script:head"
  Write-Host ""
  Write-Host "Decision:"
  Write-Host "- git_execution_authority_granted"
  Write-Host ""
  Write-Host "Granted:"
  Write-Host "- git execution by Nodex authority only"
  Write-Host ""
  Write-Host "Not granted:"
  Write-Host "- permission grants"
  Write-Host "- AgentHandoffRunner runtime wiring"
  Write-Host "- model-output authority"
  Write-Host "- proof-claim promotion authority"
  Write-Host "- external review authority"
  Write-Host "- Deep Research authority"
  Write-Host "- source mutation"
  Write-Host "- evidence rewrite"
  Write-Host "- evidence deletion"
  Write-Host "- repo deletion"
  Write-Host "- deletion"
  Write-Host "- file move"
  Write-Host "- staging"
  Write-Host "- commit authority outside explicit commit-gate seams"
  Write-Host ""
  Write-Host "Next allowed seam:"
  Write-Host "- GitExecutionAuthorityStateRecord v1"
  Write-Host ""
  Write-Host "Evidence:"
  Write-Host "- $decisionJson"
  Write-Host "- $decisionSummary"
  Write-Host ""
  Write-Host "Working tree:"
  Write-Host "- clean"

} catch {
  $failure = $_.Exception.Message
  Write-FailureEvidence $failure

  Write-Host "GIT EXECUTION AUTHORITY DECISION V1 FAILED"
  Write-Host ""
  Write-Host "Failure:"
  Write-Host "- $failure"
  Write-Host ""
  Write-Host "Evidence:"
  Write-Host "- $decisionJson"
  Write-Host "- $decisionSummary"
  exit 1
}
