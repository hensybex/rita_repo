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
        throw "Нужно запустить PowerShell от имени администратора."
    }
}

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "Команда winget не найдена. Установи App Installer из Microsoft Store и повтори запуск."
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

    Write-Host "Устанавливаю или обновляю Node.js LTS через winget..."
    winget @arguments
}

function Show-NodeVersion {
    $nodeExecutable = "$env:ProgramFiles\nodejs\node.exe"
    $npmExecutable = "$env:ProgramFiles\nodejs\npm.cmd"

    if (Test-Path $nodeExecutable) {
        $nodeVersion = & $nodeExecutable -v
        Write-Host "Node.js установлен: $nodeVersion"
    } else {
        Write-Warning "Не удалось найти node.exe по пути $nodeExecutable. Открой новое окно PowerShell и проверь node -v."
    }

    if (Test-Path $npmExecutable) {
        $npmVersion = & $npmExecutable -v
        Write-Host "npm установлен: $npmVersion"
    } else {
        Write-Warning "Не удалось найти npm.cmd по пути $npmExecutable. Открой новое окно PowerShell и проверь npm -v."
    }
}

Assert-Administrator
Ensure-Winget

$currentNode = Get-NodeInfo

if ($currentNode -and -not $Force) {
    Write-Host "Node.js уже установлен ($($currentNode.Version)). Запусти скрипт с параметром -Force, если нужна переустановка."
    return
}

Install-Node

Show-NodeVersion
Write-Host "Готово. Можно запускать npm install -g @google/gemini-cli."
