param(
    [ValidateSet("all", "core", "optional")]
    [string]$Profile = "all",

    [string]$Category = "",

    [switch]$InstalledOnly,

    [switch]$MissingOnly
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " Agent Skills List"
Write-Host "========================================"
Write-Host ""

$manifestPath = Join-Path $PSScriptRoot "skills.json"
$globalSkillRoot = "$HOME\.agents\skills"

if (-not (Test-Path $manifestPath)) {
    Write-Host "ERROR: skills.json not found:" -ForegroundColor Red
    Write-Host "  $manifestPath"
    exit 1
}

try {
    $config = Get-Content $manifestPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: skills.json is invalid JSON." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

$skills = @($config.skills)

# ------------------------------------------------------------
# Profile filter
# ------------------------------------------------------------

if ($Profile -ne "all") {
    $skills = @(
        $skills | Where-Object {
            $_.tier -eq $Profile
        }
    )
}

# ------------------------------------------------------------
# Category filter
# ------------------------------------------------------------

if ($Category -ne "") {
    $skills = @(
        $skills | Where-Object {
            $_.category -eq $Category
        }
    )
}

# ------------------------------------------------------------
# Build result
# ------------------------------------------------------------

$results = @()

foreach ($skill in $skills) {

    $skillPath = Join-Path $globalSkillRoot $skill.name
    $skillFile = Join-Path $skillPath "SKILL.md"

    $installed = (
        (Test-Path $skillPath) -and
        (Test-Path $skillFile)
    )

    $results += [PSCustomObject]@{
        Name      = $skill.name
        Tier      = $skill.tier
        Category  = $skill.category
        Enabled   = [bool]$skill.enabled
        Installed = $installed
        Source    = $skill.source
    }
}

# ------------------------------------------------------------
# Installed / missing filter
# ------------------------------------------------------------

if ($InstalledOnly) {
    $results = @(
        $results | Where-Object {
            $_.Installed -eq $true
        }
    )
}

if ($MissingOnly) {
    $results = @(
        $results | Where-Object {
            $_.Installed -eq $false
        }
    )
}

if ($results.Count -eq 0) {
    Write-Host "No matching skills found." -ForegroundColor Yellow
    exit 0
}

# ------------------------------------------------------------
# Display
# ------------------------------------------------------------

$display = $results | ForEach-Object {

    $status =
        if (-not $_.Enabled) {
            "DISABLED"
        }
        elseif ($_.Installed) {
            "INSTALLED"
        }
        else {
            "NOT INSTALLED"
        }

    [PSCustomObject]@{
        Name     = $_.Name
        Tier     = $_.Tier
        Category = $_.Category
        Status   = $status
        Source   = $_.Source
    }
}

$display | Format-Table -AutoSize

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

$total = $results.Count
$installedCount = @($results | Where-Object { $_.Installed }).Count
$missingCount = @($results | Where-Object { -not $_.Installed }).Count
$enabledCount = @($results | Where-Object { $_.Enabled }).Count
$disabledCount = @($results | Where-Object { -not $_.Enabled }).Count

$coreCount = @($results | Where-Object { $_.Tier -eq "core" }).Count
$optionalCount = @($results | Where-Object { $_.Tier -eq "optional" }).Count

Write-Host ""
Write-Host "========================================"
Write-Host " Summary"
Write-Host "========================================"
Write-Host ""

Write-Host ("Configured : {0}" -f $total)
Write-Host ("Installed  : {0}" -f $installedCount) -ForegroundColor Green

if ($missingCount -gt 0) {
    Write-Host ("Missing    : {0}" -f $missingCount) -ForegroundColor Yellow
}
else {
    Write-Host ("Missing    : {0}" -f $missingCount) -ForegroundColor Green
}

Write-Host ("Enabled    : {0}" -f $enabledCount)
Write-Host ("Disabled   : {0}" -f $disabledCount)
Write-Host ("Core       : {0}" -f $coreCount)
Write-Host ("Optional   : {0}" -f $optionalCount)

Write-Host ""
Write-Host "Skill root:"
Write-Host "  $globalSkillRoot"

Write-Host ""
Write-Host "Examples:"
Write-Host "  .\list.ps1"
Write-Host "  .\list.ps1 -Profile core"
Write-Host "  .\list.ps1 -Profile optional"
Write-Host "  .\list.ps1 -Category github"
Write-Host "  .\list.ps1 -InstalledOnly"
Write-Host "  .\list.ps1 -MissingOnly"
Write-Host ""
