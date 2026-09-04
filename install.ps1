param(
    [ValidateSet("core", "optional", "all")]
    [string]$Profile = "core",

    [string]$Category = "",

    [string[]]$Skill = @()
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skills Portable Installer"
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

$skills = @($config.skills | Where-Object {
    $_.enabled -eq $true
})

# ============================================================
# Skill filter
# ============================================================

if ($Skill.Count -gt 0) {

    $skills = @($skills | Where-Object {
        $Skill -contains $_.name
    })

}
elseif ($Category -ne "") {

    $skills = @($skills | Where-Object {
        $_.category -eq $Category
    })

}
elseif ($Profile -ne "all") {

    $skills = @($skills | Where-Object {
        $_.tier -eq $Profile
    })
}

if ($skills.Count -eq 0) {
    Write-Host "No matching skills found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Profile  : $Profile"

if ($Category -ne "") {
    Write-Host "Category : $Category"
}

Write-Host "Skills   : $($skills.Count)"
Write-Host ""

foreach ($item in $skills) {
    Write-Host "  - $($item.name)"
}

Write-Host ""

# ============================================================
# Agent args
# ============================================================

$agentArgs = @()

foreach ($agent in $config.agents) {
    $agentArgs += "-a"
    $agentArgs += $agent
}

# ============================================================
# Install from upstream
# ============================================================

$current = 0

foreach ($item in $skills) {

    $current++

    Write-Host ""
    Write-Host "[$current/$($skills.Count)] Installing $($item.name)..." `
        -ForegroundColor Cyan

    $cmdArgs = @(
        "--yes",
        "--package=skills@latest",
        "skills",
        "add",
        $item.source
    )

    if (
        $null -ne $item.selector -and
        $item.selector.Trim() -ne ""
    ) {
        $cmdArgs += "--skill"
        $cmdArgs += $item.selector
    }

    $cmdArgs += "-g"

    foreach ($arg in $agentArgs) {
        $cmdArgs += $arg
    }

    $cmdArgs += "--copy"
    $cmdArgs += "-y"

    & npx.cmd @cmdArgs

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "ERROR: $($item.name) installation failed." `
            -ForegroundColor Red

        Write-Host "Exit code: $LASTEXITCODE" `
            -ForegroundColor Red

        exit $LASTEXITCODE
    }

    Write-Host "OK: $($item.name) installed." `
        -ForegroundColor Green
}

# ============================================================
# Windows/global compatibility sync
#
# skills CLI currently uses ~/.agents/skills as the canonical
# global directory for several universal agents. Some versions
# may not create the agent-specific global link/directory.
#
# The actual CLIs may read:
#   Codex            ~/.codex/skills
#   Claude Code      ~/.claude/skills
#   Cursor           ~/.cursor/skills
#   Gemini CLI       ~/.gemini/skills
#   Antigravity CLI  ~/.gemini/antigravity-cli/skills
#
# This block keeps ~/.agents/skills as the single source and
# creates Junctions into each installed agent's real directory.
# ============================================================

function Test-AgentInstalled {
    param(
        [string[]]$Commands = @(),
        [string[]]$DetectPaths = @()
    )

    foreach ($command in $Commands) {
        if ($command -and (Get-Command $command -ErrorAction SilentlyContinue)) {
            return $true
        }
    }

    foreach ($path in $DetectPaths) {
        if ($path -and (Test-Path $path)) {
            return $true
        }
    }

    return $false
}

function Ensure-SkillLink {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $sourceSkillFile = Join-Path $SourcePath "SKILL.md"
    $targetSkillFile = Join-Path $TargetPath "SKILL.md"

    if (-not (Test-Path $sourceSkillFile)) {
        return $false
    }

    if (Test-Path $targetSkillFile) {
        return $true
    }

    if (Test-Path $TargetPath) {
        try {
            $targetItem = Get-Item $TargetPath -Force

            if (
                ($targetItem.Attributes -band [IO.FileAttributes]::ReparsePoint) `
                -eq [IO.FileAttributes]::ReparsePoint
            ) {
                Remove-Item $TargetPath -Force
            }
            else {
                Copy-Item `
                    -Path (Join-Path $SourcePath "*") `
                    -Destination $TargetPath `
                    -Recurse `
                    -Force

                return (Test-Path $targetSkillFile)
            }
        }
        catch {
            return $false
        }
    }

    try {
        New-Item `
            -ItemType Junction `
            -Path $TargetPath `
            -Target $SourcePath `
            -ErrorAction Stop | Out-Null

        return (Test-Path $targetSkillFile)
    }
    catch {
        try {
            New-Item `
                -ItemType Directory `
                -Path $TargetPath `
                -Force | Out-Null

            Copy-Item `
                -Path (Join-Path $SourcePath "*") `
                -Destination $TargetPath `
                -Recurse `
                -Force

            return (Test-Path $targetSkillFile)
        }
        catch {
            return $false
        }
    }
}

$canonicalSkillRoot = Join-Path $HOME ".agents\skills"
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
        Name        = "Codex"
        Commands    = @("codex", "codex.exe")
        DetectPaths = @($codexHome)
        SkillRoot   = Join-Path $codexHome "skills"
    }

    "claude-code" = [PSCustomObject]@{
        Name        = "Claude Code"
        Commands    = @("claude", "claude.cmd", "claude.exe")
        DetectPaths = @($claudeHome)
        SkillRoot   = Join-Path $claudeHome "skills"
    }

    "cursor" = [PSCustomObject]@{
        Name        = "Cursor"
        Commands    = @("cursor", "cursor.cmd", "cursor.exe")
        DetectPaths = @((Join-Path $HOME ".cursor"))
        SkillRoot   = Join-Path $HOME ".cursor\skills"
    }

    "gemini-cli" = [PSCustomObject]@{
        Name        = "Gemini CLI"
        Commands    = @("gemini", "gemini.cmd", "gemini.ps1")
        DetectPaths = @($geminiNpmPath)
        SkillRoot   = Join-Path $HOME ".gemini\skills"
    }

    "antigravity-cli" = [PSCustomObject]@{
        Name        = "Antigravity CLI"
        Commands    = @("agy", "agy.exe")
        DetectPaths = @((Join-Path $HOME ".gemini\antigravity"))
        SkillRoot   = Join-Path $HOME ".gemini\config\skills"
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skill Sync"
Write-Host "========================================"
Write-Host ""

$syncFailures = @()

foreach ($agentId in @($config.agents)) {

    if (-not $agentDefinitions.ContainsKey($agentId)) {
        Write-Host ("  SKIP {0} - no sync definition" -f $agentId) `
            -ForegroundColor DarkYellow
        continue
    }

    $agent = $agentDefinitions[$agentId]

    $installed = Test-AgentInstalled `
        -Commands @($agent.Commands) `
        -DetectPaths @($agent.DetectPaths)

    if (-not $installed) {
        Write-Host ("  SKIP {0} - agent not installed" -f $agent.Name) `
            -ForegroundColor DarkYellow
        continue
    }

    if (-not (Test-Path $agent.SkillRoot)) {
        New-Item `
            -ItemType Directory `
            -Path $agent.SkillRoot `
            -Force | Out-Null
    }

    $agentFailed = @()

    foreach ($item in $skills) {

        $sourcePath = Join-Path $canonicalSkillRoot $item.name
        $targetPath = Join-Path $agent.SkillRoot $item.name

        $ok = Ensure-SkillLink `
            -SourcePath $sourcePath `
            -TargetPath $targetPath

        if (-not $ok) {
            $agentFailed += $item.name
        }
    }

    if ($agentFailed.Count -eq 0) {
        Write-Host ("  OK   {0}" -f $agent.Name) -ForegroundColor Green
    }
    else {
        Write-Host ("  FAIL {0}: {1}" -f $agent.Name, ($agentFailed -join ", ")) `
            -ForegroundColor Red

        $syncFailures += $agent.Name
    }
}

Write-Host ""

# ============================================================
# Done
# ============================================================

Write-Host "========================================"
Write-Host " Installation completed."
Write-Host "========================================"
Write-Host ""
Write-Host "Installed $($skills.Count) skill(s)." `
    -ForegroundColor Green

if ($syncFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Agent sync failed for:" -ForegroundColor Yellow
    Write-Host "  $($syncFailures -join ', ')" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Run:"
Write-Host "  .\check.ps1"
Write-Host ""
