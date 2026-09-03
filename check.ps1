$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skills Environment Check"
Write-Host "========================================"
Write-Host ""

# ============================================================
# 基础环境
# ============================================================

Write-Host "Node:"
node -v

Write-Host ""
Write-Host "NPM:"
npm -v

Write-Host ""
Write-Host "NPX:"
npx --version


# ============================================================
# 核心 Skills
# ============================================================

$coreSkills = @(
    "create-plan",
    "grill-me",
    "diagnosing-bugs",
    "tdd",
    "playwright"
)

$globalSkillRoot = "$HOME\.agents\skills"


# ============================================================
# Agent 安装检测
# ============================================================

function Test-AgentInstalled {

    param(
        [string]$AgentId
    )

    switch ($AgentId) {

        "codex" {

            # Codex CLI
            if (Get-Command codex -ErrorAction SilentlyContinue) {
                return $true
            }

            # Codex 配置/数据目录
            if (Test-Path "$HOME\.codex") {
                return $true
            }

            return $false
        }


        "claude-code" {

            # Claude Code CLI
            if (Get-Command claude -ErrorAction SilentlyContinue) {
                return $true
            }

            # Claude 配置目录
            if (Test-Path "$HOME\.claude") {
                return $true
            }

            return $false
        }


        "cursor" {

            # Cursor CLI
            if (Get-Command cursor -ErrorAction SilentlyContinue) {
                return $true
            }

            # Cursor 常见安装目录
            $cursorPaths = @(
                "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
                "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
                "$env:LOCALAPPDATA\Cursor\Cursor.exe"
            )

            foreach ($path in $cursorPaths) {
                if (Test-Path $path) {
                    return $true
                }
            }

            # Cursor 用户目录
            if (Test-Path "$HOME\.cursor") {
                return $true
            }

            return $false
        }


        "gemini-cli" {

            # Gemini CLI
            if (Get-Command gemini -ErrorAction SilentlyContinue) {
                return $true
            }

            # Gemini CLI 配置目录
            if (Test-Path "$HOME\.gemini") {
                return $true
            }

            return $false
        }
    }

    return $false
}


# ============================================================
# 检查公共 Skill 是否完整
# ============================================================

function Get-MissingSkills {

    $missing = @()

    foreach ($skill in $coreSkills) {

        $skillPath = Join-Path $globalSkillRoot $skill

        if (-not (Test-Path $skillPath)) {
            $missing += $skill
            continue
        }

        # 进一步确认 SKILL.md 存在
        $skillFile = Join-Path $skillPath "SKILL.md"

        if (-not (Test-Path $skillFile)) {
            $missing += $skill
        }
    }

    return $missing
}


# ============================================================
# Agent 定义
# ============================================================

$agents = @(
    @{
        Name = "Codex"
        Id   = "codex"
    },
    @{
        Name = "Claude Code"
        Id   = "claude-code"
    },
    @{
        Name = "Cursor"
        Id   = "cursor"
    },
    @{
        Name = "Gemini CLI"
        Id   = "gemini-cli"
    }
)


# ============================================================
# 显示全局 Skill
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Global Skills"
Write-Host "========================================"
Write-Host ""

if (Test-Path $globalSkillRoot) {

    foreach ($skill in $coreSkills) {

        $skillPath = Join-Path $globalSkillRoot $skill
        $skillFile = Join-Path $skillPath "SKILL.md"

        if ((Test-Path $skillPath) -and (Test-Path $skillFile)) {
            Write-Host ("  OK  {0}" -f $skill) -ForegroundColor Green
        }
        else {
            Write-Host ("  MISSING  {0}" -f $skill) -ForegroundColor Red
        }
    }

}
else {

    Write-Host "Global skills directory not found:" -ForegroundColor Red
    Write-Host $globalSkillRoot
}


# ============================================================
# Agent 检查
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skill Check"
Write-Host "========================================"
Write-Host ""

$results = @()

$hasFailure = $false

foreach ($agent in $agents) {

    Write-Host "Checking $($agent.Name)..." -ForegroundColor Cyan

    $installed = Test-AgentInstalled $agent.Id

    # --------------------------------------------------------
    # Agent 未安装
    # --------------------------------------------------------

    if (-not $installed) {

        Write-Host "$($agent.Name): SKIP (Agent not installed)" -ForegroundColor Yellow

        $results += [PSCustomObject]@{
            Name   = $agent.Name
            Status = "SKIP"
            Detail = "Agent not installed"
        }

        Write-Host ""
        continue
    }


    # --------------------------------------------------------
    # Agent 已安装，检查 Skill
    # --------------------------------------------------------

    $missingSkills = @(Get-MissingSkills)

    if ($missingSkills.Count -eq 0) {

        Write-Host "$($agent.Name): PASS" -ForegroundColor Green

        $results += [PSCustomObject]@{
            Name   = $agent.Name
            Status = "PASS"
            Detail = "5/5 core skills ready"
        }

    }
    else {

        Write-Host "$($agent.Name): FAIL" -ForegroundColor Red

        Write-Host "Missing skills:" -ForegroundColor Yellow

        foreach ($skill in $missingSkills) {
            Write-Host "  - $skill"
        }

        $results += [PSCustomObject]@{
            Name   = $agent.Name
            Status = "FAIL"
            Detail = "$($missingSkills.Count) skill(s) missing"
        }

        $hasFailure = $true
    }

    Write-Host ""
}


# ============================================================
# 汇总
# ============================================================

Write-Host "========================================"
Write-Host " Summary"
Write-Host "========================================"
Write-Host ""

foreach ($result in $results) {

    switch ($result.Status) {

        "PASS" {
            Write-Host (
                "{0,-15} {1,-6} {2}" -f `
                $result.Name,
                $result.Status,
                $result.Detail
            ) -ForegroundColor Green
        }

        "SKIP" {
            Write-Host (
                "{0,-15} {1,-6} {2}" -f `
                $result.Name,
                $result.Status,
                $result.Detail
            ) -ForegroundColor Yellow
        }

        "FAIL" {
            Write-Host (
                "{0,-15} {1,-6} {2}" -f `
                $result.Name,
                $result.Status,
                $result.Detail
            ) -ForegroundColor Red
        }
    }
}


# ============================================================
# Core Skills 汇总
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Core Skills"
Write-Host "========================================"
Write-Host ""

$missingGlobalSkills = @(Get-MissingSkills)

$installedCount = $coreSkills.Count - $missingGlobalSkills.Count

Write-Host "Core skills: $installedCount/$($coreSkills.Count)"

foreach ($skill in $coreSkills) {

    if ($missingGlobalSkills -contains $skill) {

        Write-Host "  MISSING  $skill" -ForegroundColor Red

    }
    else {

        Write-Host "  OK       $skill" -ForegroundColor Green
    }
}


# ============================================================
# 最终结果
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host " Final Result"
Write-Host "========================================"
Write-Host ""

if ($missingGlobalSkills.Count -gt 0) {

    Write-Host "CORE SKILLS INCOMPLETE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run:"
    Write-Host "  .\install.ps1"

    exit 1
}

if ($hasFailure) {

    Write-Host "ENVIRONMENT HAS FAILURES" -ForegroundColor Red
    Write-Host ""
    Write-Host "One or more installed agents cannot access all core skills."

    exit 1
}


Write-Host "ENVIRONMENT READY" -ForegroundColor Green
Write-Host ""
Write-Host "All installed agents are ready."
Write-Host "Agents that are not installed were skipped."

exit 0