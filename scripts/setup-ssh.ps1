[CmdletBinding()]
param(
    [string]$PublicKey,
    [string]$Username = $env:USERNAME
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Administrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Run PowerShell as Administrator before executing this script."
    }
}

function Ensure-OpenSSHServer {
    $capabilityName = "OpenSSH.Server~~~~0.0.1.0"
    $state = (Get-WindowsCapability -Online -Name $capabilityName).State
    if ($state -ne "Installed") {
        Write-Host "Installing OpenSSH Server feature (this may take a minute)..."
        Add-WindowsCapability -Online -Name $capabilityName | Out-Null
    } else {
        Write-Host "OpenSSH Server is already installed."
    }
}

function Configure-Service {
    Write-Host "Configuring sshd service startup..."
    Set-Service -Name sshd -StartupType Automatic
    $service = Get-Service -Name sshd
    if ($service.Status -ne "Running") {
        Start-Service -Name sshd
    }
    Write-Host "sshd service is running."
}

function Configure-Firewall {
    $ruleName = "OpenSSH-Server-In-TCP"
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if (-not $rule) {
        Write-Host "Creating firewall rule for inbound SSH..."
        New-NetFirewallRule -Name $ruleName -DisplayName "OpenSSH Server (TCP-In)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    } else {
        Write-Host "Firewall rule already present."
    }
}

function Configure-AuthorizedKeys {
    param(
        [string]$UserName,
        [string]$Key
    )

    if (-not $Key) {
        Write-Host "No public key provided. Skipping authorized_keys update."
        return
    }

    $profiles = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { $_.LocalPath -like "*\\$UserName" }
    if ($profiles -and $profiles[0].LocalPath) {
        $userProfile = $profiles[0].LocalPath
    }

    if (-not $userProfile) {
        $userProfile = Join-Path $env:SystemDrive "Users"
        $userProfile = Join-Path $userProfile $UserName
    }

    if (-not (Test-Path $userProfile)) {
        throw "User profile directory '$userProfile' was not found."
    }

    $sshDir = Join-Path $userProfile ".ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    icacls "$sshDir" /inheritance:r | Out-Null
    icacls "$sshDir" /grant "${UserName}:(F)" | Out-Null
    icacls "$sshDir" /grant "Administrators:(F)" | Out-Null
    icacls "$sshDir" /grant "SYSTEM:(F)" | Out-Null

    $authFile = Join-Path $sshDir "authorized_keys"
    if (-not (Test-Path $authFile)) {
        New-Item -ItemType File -Path $authFile -Force | Out-Null
    }

    $existing = Get-Content $authFile -ErrorAction SilentlyContinue
    if ($existing -notcontains $Key) {
        Add-Content -Path $authFile -Value $Key
        Write-Host "Public key appended to authorized_keys."
    } else {
        Write-Host "Public key already present in authorized_keys."
    }

    icacls "$authFile" /inheritance:r | Out-Null
    icacls "$authFile" /grant "${UserName}:(F)" | Out-Null
    icacls "$authFile" /grant "Administrators:(F)" | Out-Null
    icacls "$authFile" /grant "SYSTEM:(F)" | Out-Null
}

function Show-ConnectionInfo {
    $hostname = hostname
    $addresses = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1" -and $_.ValidLifetime -gt 0 }
    Write-Host "Host: $hostname"
    if ($addresses) {
        Write-Host "IPv4 addresses:" 
        $addresses | ForEach-Object { Write-Host " - $($_.IPAddress) ($($_.InterfaceAlias))" }
    } else {
        Write-Warning "No IPv4 addresses were detected. Run ipconfig manually."
    }
}

Assert-Administrator
Ensure-OpenSSHServer
Configure-Service
Configure-Firewall
Configure-AuthorizedKeys -UserName $Username -Key $PublicKey
Show-ConnectionInfo
Write-Host "SSH server is ready. Use 'ssh $Username@<ip>' from another machine on the VPN."
