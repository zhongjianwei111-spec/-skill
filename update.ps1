$ErrorActionPreference = "Stop"

Write-Host "Updating global skills..."

& npx.cmd --yes --package=skills@latest skills update -g -y

if ($LASTEXITCODE -ne 0) {
    Write-Host "Update failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Update completed." -ForegroundColor Green
Write-Host "Restart your agents."