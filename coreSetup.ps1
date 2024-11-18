﻿<#
.SYNOPSIS
A script to handle the common tasks with client computers

.DESCRIPTION
It will install the base applications we always want and will also uninstall the normal set as well as letting us do optional installed for Ops and Dev computers.

.PARAMETER -o
Install common applications for Ops.

.PARAMETER -d
Install common applications for Dev.

.PARAMETER --uninstall
Uninstall common applications.

.PARAMETER --updates
Update installed applications.

.PARAMETER --nobase
If set we will not install the base apps (like firefox).

.PARAMETER --power
Apply the power changes for hibernate etc.

.EXAMPLE
coreSetup -o

.EXAMPLE
coreSetup --noauto --nobase

.NOTES
Requires winget. Also you might need to run "Set-ExecutionPolicy Unrestricted" to use powershell scripts.

#>
# Check if we are running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # orginal: Start-Process -FilePath "powershell" -ArgumentList "-File .\coreSetup.ps1" -Verb RunAs
    # We are not running as administrator, so start a new process with 'RunAs'
    Start-Process powershell.exe "-File", ($myinvocation.MyCommand.Definition) -Verb RunAs
    exit
}
#Patrick Moon - 2024
# Written by Patrick Moon
# Tested and co-developed by Gabriel
# Get the latest version at https://github.com/mrdatawolf/CoreSetup
# List of applications ids to install. Note: install we use id to be specific, uninstall uses name
$apps = @("Mozilla.Firefox")
$appsScopeRequired = @("Google.Chrome")
$appThatNeedWingetSourceDeclared = @("Adobe Acrobat Reader DC")
# Optional installs
$optionalApps = @("SonicWALL.NetExtender", "Microsoft.Powershell", "tightvnc")
$optionalAppsWithComplications = @("Microsoft 365")
#dev installs
$devApps = @("git.git", "vscode", "github desktop", "JanDeDobbeleer.OhMyPosh", "nvm-windows")

# List of applications names to install. Note: uninstall uses name because the id cane change, install uses id
# Uninstall applications
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
    "Dell Core Services", 
    "Dell Customer Connect"
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
    "HP System Event Utility"
)

$lenovoAppsToRemove = @(
    "Lenovo Vantage",
    "Lenovo System Update",
    "Lenovo Utility",
    "Lenovo Service Bridge",
    "Lenovo Quick Clean",
    "Lenovo Migration Assistant"
)

# Define the progress title
$progressTitle = "Created by Patrick Moon. Version: $versionNumber"

#show progress
function outputProgress {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Status,
        [Parameter(Mandatory = $true, Position = 1)]
        [int] $Progress
    )
    Write-Progress -Activity $progressTitle -Status $Status -PercentComplete $Progress
}
function Invoke-Sanity-Checks {
    # Check if the script is running in PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Output "This script must be run in PowerShell. Please open PowerShell ISE and run the script again."
        exit
    }

    # Check if winget is installed
    try {
        $wingetCheck = Get-Command winget -ErrorAction Stop
        Write-Host "Winget is installed so we can continue."  -ForegroundColor Green
    }
    catch {
        Write-Host "Winget is either not installed or had an error. This is complicated. Good luck! Hint: check if App Installer is updated in the windows store" -ForegroundColor Red
        exit
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
        winget install $app -s $source --scope $scope --silent 
    }
    elseif ($source) { 
        winget install $app -s $source --silent 
    }
    else { 
        winget install $app --silent 
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
        Write-Progress -Activity "Installing applications - $app" -Status "$([Math]::Floor((($i + 1) / $totalApps) * 100))% Complete:" -PercentComplete ([Math]::Floor((($i + 1) / $totalApps) * 100))
        $wingetList = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            Write-Host " $app already installed"  -ForegroundColor Cyan
        }
        else {
            Install-App -app $app -source $source -scope $scope
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$app installed" -ForegroundColor Green
            }
            else {
                Write-Host "$app failed to install" -ForegroundColor Red
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
    $percentComplete = 0
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        Write-Progress -Activity "Uninstalling applications - $app" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        # Check if the application is installed
        $wingetList = winget list --name $app
        if ($LASTEXITCODE -eq 0) {
            $wingetUninstall = winget uninstall $app --silent
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$app uninstalled" -ForegroundColor Green
            }
            else {
                Write-Host "$app failed to uninstall" -ForegroundColor Cyan
            }
        }
        else {
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            Write-Host "$app not installed" -ForegroundColor Cyan
        }
    }
}
function runUpdates {
    Write-Progress -Activity "Getting the most current source list"
    winget source update
    Write-Progress -Activity "Updating the applications"
    winget update --all --silent
}

function powerSetup {
    powercfg.exe -x -monitor-timeout-ac 0
    powercfg.exe -x -monitor-timeout-dc 0
    powercfg.exe -x -disk-timeout-ac 0
    powercfg.exe -x -disk-timeout-dc 0
    powercfg.exe -x -standby-timeout-ac 0
    powercfg.exe -x -standby-timeout-dc 0
    powercfg.exe -x -hibernate-timeout-ac 0
    powercfg.exe -x -hibernate-timeout-dc 0
    powercfg.exe -h off
}

#check that we have current winget sources
Write-Host "updating winget sources"
winget source update

# Display title line
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Core Setup Script" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Invoke-Sanity-Checks
if ($args -contains "--noauto") {
    Write-Host "Skipping base installs" -ForegroundColor Cyan
}

#see what the user wants to run
#Check if they want to do the main apps
$appsInstall = $true
$optionalInstall = $false
$optionalExtendedInstall = $false
if ($args -contains "--basic") {
    $appsInstall = $true
}
else {
    Write-Host "Do you want to install the following programs?"
    for ($i = 0; $i -lt $apps.Length; $i++) {
        Write-Host "$i. $($apps[$i])"
    }
    for ($i = 0; $i -lt $appThatNeedWingetSourceDeclared.Length; $i++) {
        Write-Host "$i. $($appThatNeedWingetSourceDeclared[$i])"
    }
    for ($i = 0; $i -lt $appsScopeRequired.Length; $i++) {
        Write-Host "$i. $($appsScopeRequired[$i])"
    }
    $userInput = Read-Host " (Y/n)" 
    if ($userInput -eq "n") {
        $appsInstall = $false
    }
}
# Check for optional argument
if ($args -contains "-o") {
    $optionalInstall = $true
}
else {
    Write-Host "Do you want to install the following optional programs?"
    for ($i = 0; $i -lt $optionalApps.Length; $i++) {
        Write-Host "$i. $($optionalApps[$i])"
    }
    $userInput = Read-Host " (y/N)" 
    if ($userInput -eq "y") {
        $optionalInstall = $true

        $userInput = Read-Host "Do you want to install programs that might take a long time to download (office365)? (y/N)"
        if ($userInput -eq "y") {
            $optionalExtendedInstall = $true
        }
    }
}
# Check for dev argument
$devInstall = $false
if ($args -contains "-d") {
    $devInstall = $true
}
else {
    Write-Host "Do you want to install the following developer programs?"
    for ($i = 0; $i -lt $devApps.Length; $i++) {
        Write-Host "$i. $($devApps[$i])"
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $devInstall = $true
    }
}

# Check for uninstall argument
$uninstall = $false
if ($args -contains "--uninstalls") {
    $uninstall = $true
    $uninstallCommonApps = $true
    $uninstallLenovoApps = $true
    $uninstallDellApps = $true
    $uninstallHpApps = $true
}
else {
    Write-Host "Do you want to uninstall common Windows applications?"
    for ($i = 0; $i -lt $appsToRemove.Length; $i++) {
        Write-Host "$i. $($appsToRemove[$i])" -ForegroundColor Red
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
        $uninstallCommonApps = $true
    }

    Write-Host "Do you want to uninstall Dell applications?"
    for ($i = 0; $i -lt $dellAppsToRemove.Length; $i++) {
        Write-Host "$i. $($dellAppsToRemove[$i])" -ForegroundColor Red
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
        $uninstallDellApps = $true
    }

    Write-Host "Do you want to uninstall HP applications?"
    for ($i = 0; $i -lt $hpAppsToRemove.Length; $i++) {
        Write-Host "$i. $($hpAppsToRemove[$i])" -ForegroundColor Red
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
        $uninstallHpApps = $true
    }

    Write-Host "Do you want to uninstall Lenovo applications?"
    for ($i = 0; $i -lt $lenovoAppsToRemove.Length; $i++) {
        Write-Host "$i. $($lenovoAppsToRemove[$i])" -ForegroundColor Red
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
        $uninstallLenovoApps = $true
    }
}



#Check if we should also just run updates for applications still on the system
$updates = $false
if ($args -contains "--updates") {
    $updates = $true
}
else {
    $userInput = Read-Host "Do you want to run updates for installed programs? (y/N)"
    if ($userInput -eq "y") {
        $updates = $true
    }
}

# Check for power argument
$powerAdjust = $false
if ($args -contains "--power") {
    $powerAdjust = $true
}
else {
    Write-Host "Do you want to power settings for maximum performance?"
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $powerAdjust = $true
    }
}

# Install applications
if ($appsInstall) {
    Write-Host "Installing base applications... (if it pauses for a long time press y and then enter)"
    Install-Apps -apps $apps
    Write-Host "Done Installing base applications!"
    Write-Host "Installing base applications with special needs."
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "winget"
    Write-Host "Done installing base applications with special needs."
    Write-Host "Installing base applications that require scope declaration."
    Install-Apps -apps $appsScopeRequired -source "winget" -scope "machine"
    Write-Host "Done installing base applications that require scope declaration."
}
else {
    Write-Host "Skipping base applications" -ForegroundColor Cyan
}
    
# Install optional applications
if ($optionalInstall) {
    Write-Output "Installing optional applications..."
    Install-Apps -apps $optionalApps
    Write-Output "Done installing optional applications!"
}
if ($optionalExtendedInstall) {
    Write-Output "Installing other optional applications..."
    Install-Apps -apps $optionalAppsWithComplications
    Write-Output "Done installing other optional applications!"
}
# Install dev applications
if ($devInstall) {
    Write-Output "Installing Developer Applications..."
    Install-Apps -apps $devApps -source "winget"
    Write-Output "Done installing developer applications!"
}

# Ask questions and uninstall apps based on user input
if ($uninstall) {
    if ($uninstallCommonApps) {
        Write-Output "Uninstalling general applications..."
        Uninstall-Apps -apps $appsToRemove
        Write-Output "Done uninstalling general applications!"
    }
    if ($uninstallDellApps) {
        Write-Output "Uninstalling Dell specific applications..."
        Uninstall-Apps -apps $dellAppsToRemove
        Write-Output "Done uninstalling Dell applications!"
    }
    if ($uninstallHpApps) {
        Write-Output "Uninstalling HP specific applications..."
        Uninstall-Apps -apps $hpAppsToRemove
        Write-Output "Done uninstalling HP applications!"
    }
    if ($uninstallLenovoApps) {
        Write-Output "Uninstalling Lenovo specific applications..."
        Uninstall-Apps -apps $lenovoAppsToRemove
        Write-Output "Done uninstalling Lenovo applications!"
    }
}
if ($updates) {
    Write-Output "Updating installed applications..."
    runUpdates
    Write-Output "Done updating installed applications!"
}

# update power settings
if ($powerAdjust) {
    Write-Output "Updating power settings..."
    powercfg.exe -x -monitor-timeout-ac 60
    powercfg.exe -x -monitor-timeout-dc 60
    powercfg.exe -x -disk-timeout-ac 0
    powercfg.exe -x -disk-timeout-dc 0
    powercfg.exe -x -standby-timeout-ac 0
    powercfg.exe -x -standby-timeout-dc 0
    powercfg.exe -x -hibernate-timeout-ac 0
    powercfg.exe -x -hibernate-timeout-dc 0
    powercfg.exe -h off
    Write-Output "Done updating power settings!"
}

Write-Host "Completed." -ForegroundColor Cyan