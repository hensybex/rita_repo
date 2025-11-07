[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Administrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Run PowerShell as Administrator and execute the script again."
    }
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is not available. Install App Installer from the Microsoft Store and retry."
    }
}

function Get-NodeInfo {
    try {
        $nodeCmd = Get-Command node -ErrorAction Stop
        $nodeVersion = & $nodeCmd.Source -v
        return [pscustomobject]@{
            Version = $nodeVersion
            Path    = $nodeCmd.Source
        }
    } catch {
        return $null
    }
}

function Install-Node {
    $arguments = @(
        "install",
        "--id", "OpenJS.NodeJS.LTS",
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    if ($Force) {
        $arguments += "--force"
    }

    Write-Host "Installing or updating Node.js LTS via winget..."
    winget @arguments
}

function Show-NodeVersion {
    $nodeExecutable = "$env:ProgramFiles\nodejs\node.exe"
    $npmExecutable = "$env:ProgramFiles\nodejs\npm.cmd"

    if (Test-Path $nodeExecutable) {
        $nodeVersion = & $nodeExecutable -v
        Write-Host "Node.js: $nodeVersion"
    } else {
        Write-Warning "node.exe was not found at $nodeExecutable. Open a new PowerShell window and run node -v."
    }

    if (Test-Path $npmExecutable) {
        $npmVersion = & $npmExecutable -v
        Write-Host "npm: $npmVersion"
    } else {
        Write-Warning "npm.cmd was not found at $npmExecutable. Open a new PowerShell window and run npm -v."
    }
}

Assert-Administrator
Ensure-Winget

$currentNode = Get-NodeInfo

if ($currentNode -and -not $Force) {
    Write-Host "Node.js is already installed ($($currentNode.Version)). Use -Force to reinstall."
    return
}

Install-Node

Show-NodeVersion
Write-Host "Done. You can now run npm install -g @google/gemini-cli."
