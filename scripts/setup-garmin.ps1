$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$setupFile = Join-Path $repositoryRoot "build\setup.js"

if (-not (Test-Path $setupFile)) {
    throw "Garmin setup file not found: $setupFile. Run the build first."
}

$garminEmail = Read-Host "Garmin email"
$securePassword = Read-Host "Garmin password" -AsSecureString
$credential = [PSCredential]::new("garmin", $securePassword)
$plainPassword = $credential.GetNetworkCredential().Password

try {
    # Persist credentials for future VS Code and Codex processes.
    [Environment]::SetEnvironmentVariable(
        "GARMIN_EMAIL",
        $garminEmail,
        "User"
    )

    [Environment]::SetEnvironmentVariable(
        "GARMIN_PASSWORD",
        $plainPassword,
        "User"
    )

    # Make credentials available to the Node process started below.
    $env:GARMIN_EMAIL = $garminEmail
    $env:GARMIN_PASSWORD = $plainPassword

    Write-Host ""
    Write-Host "Garmin credentials configured."
    Write-Host "Starting Garmin authentication..."
    Write-Host ""

    # Trust certificates installed in the Windows certificate store.
    & node --use-system-ca $setupFile

    if ($LASTEXITCODE -ne 0) {
        throw "Garmin authentication failed with exit code $LASTEXITCODE."
    }

    Write-Host ""
    Write-Host "Garmin MCP setup completed successfully."
    Write-Host "Restart VS Code before using the MCP from Codex."
}
finally {
    # Remove credentials from the current temporary process.
    Remove-Item Env:GARMIN_EMAIL -ErrorAction SilentlyContinue
    Remove-Item Env:GARMIN_PASSWORD -ErrorAction SilentlyContinue

    Remove-Variable garminEmail -ErrorAction SilentlyContinue
    Remove-Variable securePassword -ErrorAction SilentlyContinue
    Remove-Variable credential -ErrorAction SilentlyContinue
    Remove-Variable plainPassword -ErrorAction SilentlyContinue
}