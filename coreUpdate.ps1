<#
.SYNOPSIS
A script to handle the common tasks with a new user on a computer

.DESCRIPTION
This will assume coreSetup was ran before and only removes apps that get added back on a user and set user specific system settings.

.EXAMPLE
coreUpdate 

.NOTES
Requires winget. Also you might need to run "Set-ExecutionPolicy Unrestricted" to use powershell scripts.

#>
#Patrick Moon - 2024
# Written by Patrick Moon
# Get the latest version at https://github.com/mrdatawolf/CoreSetup
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
Write-Host "Core Update Script" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Invoke-Sanity-Checks
$uninstall = $true
$updates = $true
$powerAdjust = $true
# Remove apps
if ($uninstall) {
    Write-Output "Uninstalling general applications..."
    Uninstall-Apps -apps $appsToRemove
    Write-Output "Done Uninstalling general applications!"
    Write-Output "Uninstalling Dell specific applications..."
    Uninstall-Apps -apps $dellAppsToRemove
    Write-Output "Done uninstalling applications!"
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