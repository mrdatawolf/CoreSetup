<#
.SYNOPSIS
A script to handle the common tasks with client computers

.DESCRIPTION
It will install the base applications we always want and will also uninstall the normal set as well as letting us do optional installed for Ops and Dev computers.

.PARAMETER InstallBaseApps
Install base applications (Firefox, Chrome, Adobe Reader)

.PARAMETER InstallOptionalApps
Install optional applications (SonicWall NetExtender, PowerShell)

.PARAMETER InstallOffice365
Install Microsoft 365 (long download time)

.PARAMETER InstallDevApps
Install developer applications (Git, VSCode, GitHub Desktop, OhMyPosh, NVM)

.PARAMETER UninstallWindowsApps
Uninstall common bloatware Windows applications

.PARAMETER UninstallDellApps
Uninstall Dell-specific applications

.PARAMETER UninstallHPApps
Uninstall HP-specific applications

.PARAMETER UninstallLenovoApps
Uninstall Lenovo-specific applications

.PARAMETER RunUpdates
Update all installed applications

.PARAMETER AdjustPowerSettings
Configure power settings for maximum performance (disable hibernation, sleep, etc.)

.PARAMETER EnablePublicDiscovery
Enable network discovery and file sharing on public networks

.PARAMETER EnableRemoteDesktop
Enable Remote Desktop and install TightVNC

.PARAMETER RemoveNewOutlook
Remove and block the new Outlook app

.PARAMETER DisableWiFiAndBluetooth
Disable WiFi and Bluetooth network adapters

.EXAMPLE
coreSetup.ps1 -InstallBaseApps -InstallOptionalApps

.EXAMPLE
coreSetup.ps1 -InstallDevApps -UninstallWindowsApps

.NOTES
Requires winget and administrator privileges. Run from Biztech Tools GUI or with elevated PowerShell.
Patrick Moon - 2024
Get the latest version at https://github.com/mrdatawolf/CoreSetup
#>

param(
    [switch]$InstallBaseApps,
    [switch]$InstallOptionalApps,
    [switch]$InstallOffice365,
    [switch]$InstallDevApps,
    [switch]$UninstallWindowsApps,
    [switch]$UninstallDellApps,
    [switch]$UninstallHPApps,
    [switch]$UninstallLenovoApps,
    [switch]$RunUpdates,
    [switch]$AdjustPowerSettings,
    [switch]$EnablePublicDiscovery,
    [switch]$EnableRemoteDesktop,
    [switch]$RemoveNewOutlook,
    [switch]$DisableWiFiAndBluetooth
)

# Detect if running in GUI mode (any parameters provided)
$guiMode = $InstallBaseApps -or $InstallOptionalApps -or $InstallOffice365 -or $InstallDevApps -or
           $UninstallWindowsApps -or $UninstallDellApps -or $UninstallHPApps -or $UninstallLenovoApps -or
           $RunUpdates -or $AdjustPowerSettings -or $EnablePublicDiscovery -or $EnableRemoteDesktop -or $RemoveNewOutlook -or
           $DisableWiFiAndBluetooth

# Check if we are running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if ($guiMode) {
        Write-Error "This script must be run with administrator privileges. Please run the GUI as administrator."
        exit 1
    } else {
        # CLI mode - relaunch with elevation
        Start-Process powershell.exe "-File", ($myinvocation.MyCommand.Definition) -Verb RunAs
        exit
    }
}

# List of applications ids to install
$apps = @("Mozilla.Firefox")
$appsScopeRequired = @("Google.Chrome")
$appThatNeedWingetSourceDeclared = @("Adobe Acrobat Reader DC")
$optionalApps = @("SonicWALL.NetExtender", "Microsoft.Powershell")
$optionalAppsWithComplications = @("Microsoft 365")
$devApps = @("git.git", "vscode", "github desktop", "JanDeDobbeleer.OhMyPosh", "nvm-windows")
$remoteAccessApps = @("tightvnc")

# List of applications names to uninstall
$appsToRemove = @(
    "Game Bar",
    "LinkedIn",
    "McAfee Personal Security",
    "Mail and Calendar",
    "Microsoft Family",
    "Movies & TV",
    "MSN Weather",
    "News",
    "Phone Link",
    "Skype",
    "Spotify Music",
    "xbox",
    "Xbox Game Speech Window",
    "Xbox Game Bar Plugin",
    "Xbox Identity Provider",
    "Your Phone",
    "Xbox TCUI"
)
$dellAppsToRemove = @(
    "Dell Command | Update for Windows Universal",
    "Dell Core Services",
    "Dell Customer Connect",
    "Dell Digital Delivery",
    "Dell Digital Delivery Services",
    "Dell Display Manager",
    "Dell Display Manager 2.1",
    "Dell Display Manager 2.2",
    "Dell Display Manager 2.3",
    "Dell Mobile Connect",
    "Dell Optimizer Core",
    "Dell PremierColor",
    "{389E5E66-84BC-4CCF-B0D2-3887E9E2E271}",
    "{16AE9E0C-0E0C-4AD6-82B4-D0F8AB94082F}",
    "Dell Peripheral Manager",
    "Dell SupportAssist",
    "Dell SupportAssist for Dell Update",
    "Dell SupportAssist for Home PCs",
    "Dell SupportAssist OS Recovery Plugin for Dell Update",
    "Dell SupportAssist Remediation",
    "Dell Trusted Device Agent",
    "{2F3E37A4-8F48-465A-813B-1F2964DBEB6A}",
    "Dell Watchdog Timer",
    "Power2Go for Dell",
    "PowerDirector for Dell",
    "DellTypeCStatus",
    "DB6EA5DB.MediaSuiteEssentialsforDell_mcezb6ze687jp",
    "DB6EA5DB.Power2GoforDell_mcezb6ze687jp",
    "DB6EA5DB.PowerDirectorforDell_mcezb6ze687jp",
    "DB6EA5DB.PowerMediaPlayerforDell_mcezb6ze687jp"
)
$hpAppsToRemove = @(
    "HP Audio Switch",
    "HP Documentation",
    "HP JumpStart Bridge",
    "HP JumpStart Launch",
    "HP Support Assistant",
    "HP System Event Utility",
    "HP Sure Run Module",
    "HP One Agent",
    "HP Sure Recover",
    "HP Wolf Security",
    "HP Wolf Security - Console",
    "HP Security Update Service",
    "HP Notifications",
    "HP Insights",
    "HP Connection Optimizer",
    "HP Desktop Support Utilities",
    "HP Easy Clean",
    "HP PC Hardware Diagnostics Windows",
    "HP Privacy Settings",
    "myHP",
    "Poly Lens"
)
$lenovoAppsToRemove = @(
    "Lenovo Vantage",
    "Lenovo System Update",
    "Lenovo Utility",
    "Lenovo Service Bridge",
    "Lenovo Quick Clean",
    "Lenovo Migration Assistant"
)

# Functions
function Invoke-Sanity-Checks {
    # Check if the script is running in PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Output "✗ ERROR: This script must be run in PowerShell 5 or later."
        exit 1
    }

    # Check if winget is installed
    try {
        $wingetCheck = Get-Command winget -ErrorAction Stop
        Write-Output "✓ Winget is installed"
    }
    catch {
        Write-Output "✗ ERROR: Winget is not installed or had an error."
        Write-Output "  Please update 'App Installer' from the Microsoft Store"
        exit 1
    }
}

function Install-App {
    param (
        [Parameter(Mandatory = $true)]
        [string]$app,
        [string]$source,
        [string]$scope
    )

    if ($source -and $scope) {
        winget install $app -s $source --scope $scope --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    elseif ($source) {
        winget install $app -s $source --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    else {
        winget install $app --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
}

function Install-Apps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$apps,
        [string]$source,
        [string]$scope
    )

    $totalApps = $apps.Count
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
        Write-Output "[$percentComplete%] Checking $app..."

        $wingetList = winget list --id $app --disable-interactivity 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "  ✓ $app already installed (skipping)"
        }
        else {
            Write-Output "  → Installing $app..."
            Install-App -app $app -source $source -scope $scope
            if ($LASTEXITCODE -eq 0) {
                Write-Output "  ✓ $app installed successfully"
            }
            else {
                Write-Output "  ✗ $app failed to install (continuing anyway)"
            }
        }
    }
}

function Uninstall-Apps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$apps
    )

    $totalApps = $apps.Count
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
        Write-Output "[$percentComplete%] Checking $app..."

        # Check if the application is installed
        $wingetList = winget list --name $app --disable-interactivity 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "  → Uninstalling $app..."
            winget uninstall $app --silent --disable-interactivity 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "  ✓ $app uninstalled"
            }
            else {
                Write-Output "  ~ $app uninstall attempted (may require manual removal)"
            }
        }
        else {
            Write-Output "  - $app not installed (skipping)"
        }
    }
}

function RunUpdates {
    Write-Output "→ Updating winget sources..."
    winget source update --disable-interactivity 2>&1 | Out-Null
    Write-Output "→ Updating all installed applications (this may take a while)..."
    winget update --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    Write-Output "✓ Updates completed"
}

function PowerSetup {
    Write-Output "→ Configuring power settings for maximum performance..."
    Write-Output "  - Disabling monitor timeout..."
    powercfg.exe -x -monitor-timeout-ac 0
    powercfg.exe -x -monitor-timeout-dc 0
    Write-Output "  - Disabling disk timeout..."
    powercfg.exe -x -disk-timeout-ac 0
    powercfg.exe -x -disk-timeout-dc 0
    Write-Output "  - Disabling standby..."
    powercfg.exe -x -standby-timeout-ac 0
    powercfg.exe -x -standby-timeout-dc 0
    Write-Output "  - Disabling hibernation..."
    powercfg.exe -x -hibernate-timeout-ac 0
    powercfg.exe -x -hibernate-timeout-dc 0
    powercfg.exe -h off
    Write-Output "✓ Power settings configured"
}

function DoPublicDiscovery {
    Write-Output "→ Enabling network discovery on public networks..."
    Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True -Profile Public 2>&1 | Out-Null
    Write-Output "→ Enabling file and printer sharing..."
    Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled True -Profile Public 2>&1 | Out-Null
    Write-Output "✓ Public network discovery enabled"
}

function DoRemoteDesktop {
    Write-Output "→ Enabling Remote Desktop..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" 2>&1 | Out-Null
    Write-Output "✓ Remote Desktop enabled"
    Write-Output "→ Installing remote access tools..."
    Install-Apps -apps $remoteAccessApps
}

function RemoveAndBlockNewOutlook {
    Write-Output "→ Removing and blocking new Outlook..."

    # Path to the registry key
    $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe"

    # Create the registry key if it doesn't exist
    if (-not (Test-Path $regPath)) {
        Write-Output "  - Creating registry key..."
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set the registry value to block new Outlook
    $propertyName = "BlockedOobeUpdaters"
    $propertyValue = "MS_Outlook"

    Write-Output "  - Setting block registry value..."
    try {
        Set-ItemProperty -Path $regPath -Name $propertyName -Value $propertyValue
    } catch {
        New-ItemProperty -Path $regPath -Name $propertyName -Value $propertyValue -PropertyType String -Force | Out-Null
    }

    # Remove the new Outlook app if it's already installed
    Write-Output "  - Checking for new Outlook installation..."
    $outlookPackage = Get-AppxPackage -Name "Microsoft.OutlookForWindows"
    if ($outlookPackage) {
        Write-Output "  - Removing new Outlook..."
        Remove-AppxProvisionedPackage -AllUsers -Online -PackageName $outlookPackage.PackageFullName 2>&1 | Out-Null
        Write-Output "✓ New Outlook removed and blocked"
    } else {
        Write-Output "✓ New Outlook blocked (was not installed)"
    }
}

function DisableWiFiAndBluetooth {
    Write-Output "→ Disabling WiFi and Bluetooth adapters..."

    # Disable WiFi adapters
    Write-Output "  - Searching for WiFi adapters..."
    $wifiAdapters = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match "wireless|wi-fi|802.11"}
    if ($wifiAdapters) {
        foreach ($adapter in $wifiAdapters) {
            Write-Output "  - Disabling $($adapter.Name) ($($adapter.InterfaceDescription))..."
            try {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                Write-Output "    ✓ WiFi adapter disabled"
            } catch {
                Write-Output "    ✗ Failed to disable WiFi adapter: $_"
            }
        }
    } else {
        Write-Output "  - No WiFi adapters found"
    }

    # Disable Bluetooth adapters
    Write-Output "  - Searching for Bluetooth adapters..."
    $bluetoothAdapters = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match "bluetooth"}
    if ($bluetoothAdapters) {
        foreach ($adapter in $bluetoothAdapters) {
            Write-Output "  - Disabling $($adapter.Name) ($($adapter.InterfaceDescription))..."
            try {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                Write-Output "    ✓ Bluetooth adapter disabled"
            } catch {
                Write-Output "    ✗ Failed to disable Bluetooth adapter: $_"
            }
        }
    } else {
        Write-Output "  - No Bluetooth adapters found"
    }

    Write-Output "✓ WiFi and Bluetooth disable operation completed"
}

# ============================================
# Main Execution
# ============================================

Write-Output "=============================="
Write-Output "  Core Setup Script"
Write-Output "=============================="
Write-Output ""

# Run sanity checks
Invoke-Sanity-Checks

# Update winget sources
Write-Output "→ Updating winget sources..."
winget source update --disable-interactivity 2>&1 | Out-Null
Write-Output "✓ Winget sources updated"
Write-Output ""

# Track if anything was selected
$operationsRun = 0

# Install base applications
if ($InstallBaseApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "INSTALLING BASE APPLICATIONS"
    Write-Output "========================================"
    Install-Apps -apps $apps
    Write-Output ""
    Write-Output "→ Installing apps requiring MS Store source..."
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "msstore"
    Write-Output ""
    Write-Output "→ Installing apps requiring machine scope..."
    Install-Apps -apps $appsScopeRequired -source "winget" -scope "machine"
    Write-Output ""
}

# Install optional applications
if ($InstallOptionalApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "INSTALLING OPTIONAL APPLICATIONS"
    Write-Output "========================================"
    Install-Apps -apps $optionalApps
    Write-Output ""
}

# Install Office 365
if ($InstallOffice365) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "INSTALLING MICROSOFT 365"
    Write-Output "========================================"
    Write-Output "⚠️  WARNING: This may take a long time to download"
    Install-Apps -apps $optionalAppsWithComplications
    Write-Output ""
}

# Install developer applications
if ($InstallDevApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "INSTALLING DEVELOPER APPLICATIONS"
    Write-Output "========================================"
    Install-Apps -apps $devApps -source "winget"
    Write-Output ""
}

# Uninstall Windows bloatware
if ($UninstallWindowsApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "UNINSTALLING WINDOWS BLOATWARE"
    Write-Output "========================================"
    Uninstall-Apps -apps $appsToRemove
    Write-Output ""
}

# Uninstall Dell apps
if ($UninstallDellApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "UNINSTALLING DELL APPLICATIONS"
    Write-Output "========================================"
    Uninstall-Apps -apps $dellAppsToRemove
    Write-Output ""
}

# Uninstall HP apps
if ($UninstallHPApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "UNINSTALLING HP APPLICATIONS"
    Write-Output "========================================"
    Uninstall-Apps -apps $hpAppsToRemove
    Write-Output ""
}

# Uninstall Lenovo apps
if ($UninstallLenovoApps) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "UNINSTALLING LENOVO APPLICATIONS"
    Write-Output "========================================"
    Uninstall-Apps -apps $lenovoAppsToRemove
    Write-Output ""
}

# Run updates
if ($RunUpdates) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "UPDATING INSTALLED APPLICATIONS"
    Write-Output "========================================"
    RunUpdates
    Write-Output ""
}

# Adjust power settings
if ($AdjustPowerSettings) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "ADJUSTING POWER SETTINGS"
    Write-Output "========================================"
    PowerSetup
    Write-Output ""
}

# Enable public discovery
if ($EnablePublicDiscovery) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "ENABLING PUBLIC NETWORK DISCOVERY"
    Write-Output "========================================"
    DoPublicDiscovery
    Write-Output ""
}

# Enable remote desktop
if ($EnableRemoteDesktop) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "ENABLING REMOTE DESKTOP"
    Write-Output "========================================"
    DoRemoteDesktop
    Write-Output ""
}

# Remove and block new Outlook
if ($RemoveNewOutlook) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "REMOVING AND BLOCKING NEW OUTLOOK"
    Write-Output "========================================"
    RemoveAndBlockNewOutlook
    Write-Output ""
}

# Disable WiFi and Bluetooth
if ($DisableWiFiAndBluetooth) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "DISABLING WIFI AND BLUETOOTH"
    Write-Output "========================================"
    DisableWiFiAndBluetooth
    Write-Output ""
}

# Summary
Write-Output "=============================="
if ($operationsRun -gt 0) {
    Write-Output "✓ COMPLETED $operationsRun OPERATION(S)"
} else {
    Write-Output "⚠️  NO OPERATIONS SELECTED"
}
Write-Output "=============================="

# Exit cleanly (no pause in GUI mode)
if (-not $guiMode) {
    Pause
}

exit 0
