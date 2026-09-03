param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Source,

    [string]$Selector = "",

    [ValidateSet(
        "development",
        "browser",
        "github",
        "writing",
        "research",
        "knowledge",
        "other"
    )]
    [string]$Category = "other",

    [ValidateSet(
        "core",
        "optional"
    )]
    [string]$Tier = "optional"
)

$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PSScriptRoot "skills.json"

if (-not (Test-Path $manifestPath)) {
    Write-Host "skills.json not found." -ForegroundColor Red
    exit 1
}

$config = Get-Content $manifestPath -Raw | ConvertFrom-Json

$exists = $config.skills |
    Where-Object {
        $_.name -eq $Name
    }

if ($exists) {
    Write-Host "Skill already exists: $Name" `
        -ForegroundColor Yellow

    exit 1
}

$newSkill = [PSCustomObject]@{
    name     = $Name
    tier     = $Tier
    category = $Category
    source   = $Source
    selector = $Selector
    enabled  = $true
}

$config.skills += $newSkill

$config |
    ConvertTo-Json -Depth 10 |
    Set-Content $manifestPath -Encoding UTF8

Write-Host ""
Write-Host "Skill added:" -ForegroundColor Green
Write-Host "  Name     : $Name"
Write-Host "  Tier     : $Tier"
Write-Host "  Category : $Category"
Write-Host "  Source   : $Source"

if ($Selector -ne "") {
    Write-Host "  Selector : $Selector"
}

Write-Host ""
Write-Host "Install it with:"
Write-Host "  .\install.ps1 -Skill $Name"