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
        throw "Запусти PowerShell от имени администратора и повтори запуск скрипта."
    }
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "Утилита winget не найдена. Установи 'App Installer' из Microsoft Store и запусти скрипт ещё раз."
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

    Write-Host "⏳ Устанавливаю/обновляю Node.js LTS через winget..."
    winget @arguments | Write-Host
}

function Show-NodeVersion {
    $nodeExecutable = "$env:ProgramFiles\nodejs\node.exe"

    if (Test-Path $nodeExecutable) {
        $nodeVersion = & $nodeExecutable -v
        $npmVersion = & "$env:ProgramFiles\nodejs\npm.cmd" -v
        Write-Host "✅ Node.js установлен: $nodeVersion"
        Write-Host "✅ npm установлен: $npmVersion"
    } else {
        Write-Warning "Node.js установлен, но текущая сессия PowerShell ещё не видит новую версию. Открой новое окно и выполни 'node -v' и 'npm -v'."
    }
}

Assert-Administrator
Ensure-Winget

$currentNode = Get-NodeInfo

if ($currentNode -and -not $Force) {
    Write-Host "ℹ️ Node.js уже установлен ($($currentNode.Version)). Для переустановки запусти скрипт с параметром -Force."
    return
}

Install-Node
Show-NodeVersion
Write-Host "🚀 Готово. Теперь можно запускать 'npm install -g @google/gemini-cli'."
