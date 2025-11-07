[CmdletBinding()]
param(
    [string]$ApiKey
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Administrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Run PowerShell as Administrator before executing this script."
    }
}

function Ensure-Npm {
    $nodeDir = Join-Path $env:ProgramFiles "nodejs"
    $npmPath = Join-Path $nodeDir "npm.cmd"

    if (-not (Test-Path $npmPath)) {
        throw "npm.cmd not found at $npmPath. Run scripts/install-node.ps1 first."
    }

    if (-not ($env:Path.Split([IO.Path]::PathSeparator) -contains $nodeDir)) {
        $env:Path = $nodeDir + [IO.Path]::PathSeparator + $env:Path
    }

    $npmBin = Join-Path $env:APPDATA "npm"
    if (-not ($env:Path.Split([IO.Path]::PathSeparator) -contains $npmBin)) {
        $env:Path = $npmBin + [IO.Path]::PathSeparator + $env:Path
        Write-Warning "$npmBin was temporarily added to PATH for this session. Add it permanently for convenience."
    }

    return $npmPath
}

function Install-GeminiCli {
    param(
        [string]$NpmPath
    )

    Write-Host "Installing @google/gemini-cli globally via npm..."
    & $NpmPath "install" "-g" "@google/gemini-cli"
}

function Verify-Gemini {
    try {
        $geminiCmd = Get-Command gemini -ErrorAction Stop
        $version = & $geminiCmd.Source "--version"
        Write-Host "gemini CLI: $version"
    } catch {
        Write-Warning "gemini command not found in PATH. Open a new PowerShell window and run gemini --version."
    }
}

function Configure-ApiKey {
    param(
        [string]$Value
    )

    if (-not $Value) {
        return
    }

    [Environment]::SetEnvironmentVariable("GEMINI_API_KEY", $Value, "User")
    $env:GEMINI_API_KEY = $Value
    Write-Host "Stored GEMINI_API_KEY for the current user."
}

Assert-Administrator
$npmPath = Ensure-Npm
Install-GeminiCli -NpmPath $npmPath
Verify-Gemini
Configure-ApiKey -Value $ApiKey
Write-Host "Done. Launch gemini and choose the preferred auth method."
