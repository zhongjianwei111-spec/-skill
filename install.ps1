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

$config = Get-Content $manifestPath -Raw | ConvertFrom-Json

$skills = @($config.skills | Where-Object {
    $_.enabled -eq $true
})

# ============================================================
# 筛选 Skill
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
# Agent 参数
# ============================================================

$agentArgs = @()

foreach ($agent in $config.agents) {
    $agentArgs += "-a"
    $agentArgs += $agent
}

# ============================================================
# 安装
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

Write-Host ""
Write-Host "========================================"
Write-Host " Installation completed."
Write-Host "========================================"
Write-Host ""
Write-Host "Installed $($skills.Count) skill(s)." `
    -ForegroundColor Green

Write-Host ""
Write-Host "Run:"
Write-Host "  .\check.ps1"
Write-Host ""