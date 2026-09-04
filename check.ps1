$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skills Environment Check"
Write-Host "========================================"
Write-Host ""

$manifestPath = Join-Path $PSScriptRoot "skills.json"

if (-not (Test-Path $manifestPath)) {
    Write-Host "ERROR: skills.json not found." -ForegroundColor Red
    exit 1
}

try {
    $config = Get-Content $manifestPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: skills.json is invalid JSON." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

$coreSkills = @($config.skills | Where-Object {
    $_.enabled -eq $true -and $_.tier -eq "core"
})

if ($coreSkills.Count -eq 0) {
    Write-Host "ERROR: no enabled core skills found in skills.json." `
        -ForegroundColor Red
    exit 1
}

function Get-CommandVersionText {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Args = @("--version")
    )

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue

    if ($null -eq $cmd) {
        return "NOT FOUND"
    }

    try {
        $result = & $Command @Args 2>$null | Select-Object -First 1

        if ($null -eq $result -or "$result".Trim() -eq "") {
            return "FOUND"
        }

        return "$result".Trim()
    }
    catch {
        return "FOUND"
    }
}

function Test-AgentInstalled {
    param([Parameter(Mandatory = $true)]$Agent)

    foreach ($command in @($Agent.Commands)) {
        if ($command -and (Get-Command $command -ErrorAction SilentlyContinue)) {
            return $true
        }
    }

    foreach ($path in @($Agent.DetectPaths)) {
        if ($path -and (Test-Path $path)) {
            return $true
        }
    }

    return $false
}

function Get-AgentSkillStatus {
    param(
        [Parameter(Mandatory = $true)]$Agent,
        [Parameter(Mandatory = $true)]$Skills
    )

    $missing = @()

    foreach ($skill in $Skills) {
        $skillFile = Join-Path $Agent.SkillRoot "$($skill.name)\SKILL.md"

        if (-not (Test-Path $skillFile)) {
            $missing += $skill.name
        }
    }

    return [PSCustomObject]@{
        Ready   = ($missing.Count -eq 0)
        Missing = $missing
        Count   = $Skills.Count - $missing.Count
    }
}

Write-Host "Node:"
Write-Host (Get-CommandVersionText -Command "node" -Args @("-v"))
Write-Host ""
Write-Host "NPM:"
Write-Host (Get-CommandVersionText -Command "npm.cmd" -Args @("-v"))
Write-Host ""
Write-Host "NPX:"
Write-Host (Get-CommandVersionText -Command "npx.cmd" -Args @("-v"))
Write-Host ""

# ============================================================
# Global Skills
# ============================================================

$globalSkillRoot = Join-Path $HOME ".agents\skills"
$globalReady = 0

Write-Host "========================================"
Write-Host " Global Skills"
Write-Host "========================================"
Write-Host ""

foreach ($skill in $coreSkills) {
    $skillFile = Join-Path $globalSkillRoot "$($skill.name)\SKILL.md"

    if (Test-Path $skillFile) {
        $globalReady++
        Write-Host ("  OK  {0}" -f $skill.name) -ForegroundColor Green
    }
    else {
        Write-Host ("  MISSING  {0}" -f $skill.name) -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# Agent definitions
# ============================================================

$codexHome = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
}
else {
    Join-Path $HOME ".codex"
}

$claudeHome = if ($env:CLAUDE_CONFIG_DIR) {
    $env:CLAUDE_CONFIG_DIR
}
else {
    Join-Path $HOME ".claude"
}

$npmGlobalRoot = $null

try {
    $npmGlobalRoot = (& npm.cmd root -g 2>$null | Select-Object -First 1)

    if ($null -ne $npmGlobalRoot) {
        $npmGlobalRoot = "$npmGlobalRoot".Trim()
    }
}
catch {
    $npmGlobalRoot = $null
}

$geminiNpmPath = $null

if ($npmGlobalRoot) {
    $geminiNpmPath = Join-Path $npmGlobalRoot "@google\gemini-cli"
}

$agentDefinitions = @{
    "codex" = [PSCustomObject]@{
        Id          = "codex"
        Name        = "Codex"
        Commands    = @("codex", "codex.exe")
        DetectPaths = @($codexHome)
        SkillRoot   = Join-Path $codexHome "skills"
    }

    "claude-code" = [PSCustomObject]@{
        Id          = "claude-code"
        Name        = "Claude Code"
        Commands    = @("claude", "claude.cmd", "claude.exe")
        DetectPaths = @($claudeHome)
        SkillRoot   = Join-Path $claudeHome "skills"
    }

    "cursor" = [PSCustomObject]@{
        Id          = "cursor"
        Name        = "Cursor"
        Commands    = @("cursor", "cursor.cmd", "cursor.exe")
        DetectPaths = @((Join-Path $HOME ".cursor"))
        SkillRoot   = Join-Path $HOME ".cursor\skills"
    }

    "gemini-cli" = [PSCustomObject]@{
        Id          = "gemini-cli"
        Name        = "Gemini CLI"
        Commands    = @("gemini", "gemini.cmd", "gemini.ps1")
        DetectPaths = @($geminiNpmPath)
        SkillRoot   = Join-Path $HOME ".gemini\skills"
    }

    "antigravity-cli" = [PSCustomObject]@{
        Id          = "antigravity-cli"
        Name        = "Antigravity CLI"
        Commands    = @("agy", "agy.exe")
        DetectPaths = @((Join-Path $HOME ".gemini\antigravity"))
        SkillRoot   = Join-Path $HOME ".gemini\config\skills"
    }
}

# ============================================================
# Agent Skill Check
# ============================================================

Write-Host "========================================"
Write-Host " Agent Skill Check"
Write-Host "========================================"
Write-Host ""

$results = @()

foreach ($agentId in @($config.agents)) {

    if (-not $agentDefinitions.ContainsKey($agentId)) {
        Write-Host "Checking $agentId..."
        Write-Host "$agentId`: SKIP (no checker definition)" `
            -ForegroundColor Yellow
        Write-Host ""

        $results += [PSCustomObject]@{
            Id      = $agentId
            Name    = $agentId
            Status  = "SKIP"
            Ready   = 0
            Total   = $coreSkills.Count
            Missing = @()
            Root    = ""
        }

        continue
    }

    $agent = $agentDefinitions[$agentId]

    Write-Host "Checking $($agent.Name)..."

    if (-not (Test-AgentInstalled -Agent $agent)) {
        Write-Host "$($agent.Name): SKIP" -ForegroundColor Yellow
        Write-Host ""

        $results += [PSCustomObject]@{
            Id      = $agent.Id
            Name    = $agent.Name
            Status  = "SKIP"
            Ready   = 0
            Total   = $coreSkills.Count
            Missing = @()
            Root    = $agent.SkillRoot
        }

        continue
    }

    $status = Get-AgentSkillStatus `
        -Agent $agent `
        -Skills $coreSkills

    if ($status.Ready) {
        Write-Host "$($agent.Name): PASS" -ForegroundColor Green
        $state = "PASS"
    }
    else {
        Write-Host "$($agent.Name): FAIL" -ForegroundColor Red
        Write-Host "  Skill root: $($agent.SkillRoot)"
        Write-Host "  Missing   : $($status.Missing -join ', ')" `
            -ForegroundColor Red
        $state = "FAIL"
    }

    Write-Host ""

    $results += [PSCustomObject]@{
        Id      = $agent.Id
        Name    = $agent.Name
        Status  = $state
        Ready   = $status.Count
        Total   = $coreSkills.Count
        Missing = $status.Missing
        Root    = $agent.SkillRoot
    }
}

# ============================================================
# Summary
# ============================================================

Write-Host "========================================"
Write-Host " Summary"
Write-Host "========================================"
Write-Host ""

foreach ($result in $results) {

    $detail =
        if ($result.Status -eq "PASS") {
            "$($result.Ready)/$($result.Total) core skills ready"
        }
        elseif ($result.Status -eq "FAIL") {
            "$($result.Ready)/$($result.Total) core skills ready"
        }
        else {
            "agent not installed"
        }

    $line = "{0,-19} {1,-6} {2}" -f `
        $result.Name, `
        $result.Status, `
        $detail

    switch ($result.Status) {
        "PASS" {
            Write-Host $line -ForegroundColor Green
        }
        "FAIL" {
            Write-Host $line -ForegroundColor Red
        }
        default {
            Write-Host $line -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " Core Skills"
Write-Host "========================================"
Write-Host ""
Write-Host "Core skills: $globalReady/$($coreSkills.Count)"

foreach ($skill in $coreSkills) {
    $skillFile = Join-Path $globalSkillRoot "$($skill.name)\SKILL.md"

    if (Test-Path $skillFile) {
        Write-Host ("  OK       {0}" -f $skill.name) -ForegroundColor Green
    }
    else {
        Write-Host ("  MISSING  {0}" -f $skill.name) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " Final Result"
Write-Host "========================================"
Write-Host ""

$agentFailures = @($results | Where-Object {
    $_.Status -eq "FAIL"
})

$environmentReady = (
    $globalReady -eq $coreSkills.Count -and
    $agentFailures.Count -eq 0
)

if ($environmentReady) {
    Write-Host "ENVIRONMENT READY" -ForegroundColor Green
    Write-Host ""
    Write-Host "All installed agents are ready."
    Write-Host "Agents that are not installed were skipped."
    exit 0
}
else {
    Write-Host "ENVIRONMENT NOT READY" -ForegroundColor Red

    if ($globalReady -ne $coreSkills.Count) {
        Write-Host "Global core skills are incomplete." `
            -ForegroundColor Red
    }

    if ($agentFailures.Count -gt 0) {
        Write-Host "One or more installed agents are missing core skills." `
            -ForegroundColor Red
    }

    exit 1
}
