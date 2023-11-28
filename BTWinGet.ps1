<#
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

.EXAMPLE
btWinGet -o

.NOTES
Requires winget. Also you might need to run "Set-ExecutionPolicy Unrestricted" to use powershell scripts.

#>
#Biztech Consulting - 2023
#Version 1.1.0
# Written by MrDataWolf
# Tested and co-developed by Gabriel
# Get the latest version at https://github.com/mrdatawolf/BTWinGet

# List of applications ids to install. Note: install we use id to be specific, uninstall uses name
 $apps = @("Mozilla.Firefox", "Google.Chrome")
 $appThatNeedWingetSourceDeclared = @("Adobe Acrobat Reader DC", "Adobe Acrobat Reader DC.32bit")
# Optional installs
 $optionalApps = @("SonicWALL.NetExtender", "Microsoft.Powershell", "tightvnc")
 $optionalAppsWithComplications = @("Microsoft 365")
#dev installs
 $devApps = @("git.git","vscode", "github desktop", "JanDeDobbeleer.OhMyPosh")

# List of applications names to install. Note: uninstall uses name because the id cane change, install uses id
# Uninstall applications
 $appsToRemove = @("Mail and Calendar", "Spotify Music", "Movies & TV", "Phone Link", "Your Phone", "Game Bar", "LinkedIn", "Skype", "News", "MSN Weather", "Microsoft Family", "xbox", "Xbox Game Speech Window", "Xbox Identity Provider", "Xbox Game Bar Plugin", "Xbox TCUI")
 $dellAppsToRemove = @("Dell SupportAssist", "Dell Digital Delivery Services","Dell Core Services","Dell SupportAssist for Dell Update", "Dell Core Services", "Dell Command | Update for Windows Universal", "Dell Optimizer Core", "Dell SupportAssist Remediation", "Dell SupportAssist for Home PCs", "Dell Digital Delivery", "Dell SupportAssist OS Recovery Plugin for Dell Update")

function Sanity-Checks {
    # Check if the script is running in PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Output "This script must be run in PowerShell. Please open PowerShell ISE and run the script again."
        exit
    }

    # Check if winget is installed
    try {
        $winget = Get-Command winget -ErrorAction Stop
        Write-Output "Winget is already installed."
    } catch {
        Write-Output "Winget is not installed. This is complicated. Good luck!"
        exit
    }
}
function Install-Apps {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$apps
    )

    $totalApps = $apps.Count
    $percentComplete = 0
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        Write-Progress -Activity "Installing applications - $app" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        $installedApp = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            $result = "$app already installed"
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
        } else {
            $output = winget install $app --silent
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            if ($LASTEXITCODE -eq 0) {
                $result = "$app installed"
            } else {
                $result = "$app failed to install"
            }
        }
        Write-Host " $result"
    }
}
function Install-Apps-Source-Winget {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$apps
    )

    $totalApps = $apps.Count
    $percentComplete = 0
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        Write-Progress -Activity "Installing applications - $app" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        $installedApp = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            $result = "$app already installed"
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
        } else {
            $output = winget install $app -s winget
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            if ($LASTEXITCODE -eq 0) {
                $result = "$app installed"
            } else {
                $result = "$app failed to install"
            }
        }
        Write-Host " $result"
    }
}
function Uninstall-Apps {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$apps
    )

    $totalApps = $apps.Count
    $percentComplete = 0
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        Write-Progress -Activity "Uninstalling applications - $app" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        # Check if the application is installed
        $installedApp = winget list --name $app
        if ($LASTEXITCODE -eq 0) {
            $output = winget uninstall $app --silent
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            if ($LASTEXITCODE -eq 0) {
                $result = "$app uninstalled"
            } else {
                $result = "$app failed to uninstall"
            }
        } else {
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            $result = "$app not installed"
        }
        Write-Host " $result"
    }
}
function runUpdates {
    Write-Progress -Activity "Getting the most current source list"
    winget source update
    Write-Progress -Activity "Updating the applications"
    winget update --all --silent
}

# Display title line
Write-Host "=============================="
Write-Host "Biztech Application Script"
Write-Host "=============================="

Sanity-Checks
# Check for optional argument
Write-Host "*****"
Write-Host "If this is the first time you have ran this on a system:"
Write-Host "*!*! Fully run the Windows and Dell updates before this!!!!! It needs the Windows updates and Dell apps will be removed. *!*!"
Write-Host " Before you continue go into the MS store and search for winget.  You want to update 'App Installer' there then continue here"
Write-Host " Open a powershell prompt and type winget list.  Answer yes."
Write-Host "*****"

#see what the user wants to run
$optionalInstall = $false
$optionalExtendedInstall = $false
if ($args -contains "-o") {
    $optionalInstall = $true
} else {
    $userInput = Read-Host "Do you want to install optional programs (netextender etc)? (y/N)"
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
} else {
    $userInput = Read-Host "Do you want to install dev programs (vscode etc)? (y/N)"
    if ($userInput -eq "y") {
        $devInstall = $true
    }
}
# Check for uninstall argument
$uninstall = $false
if ($args -contains "--uninstalls") {
    $uninstall = $true
} else {
    $userInput = Read-Host "Do you want to remove programs BT does not want in systems (spotify etc)? (y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
    }
}
#Check if we should also just run updates for applications still on the system
$updates = $false
if ($args -contains "--updates") {
    $updates = $true
} else {
    $userInput = Read-Host "Do you want to run updates for installed programs? (y/N)"
    if ($userInput -eq "y") {
        $updates = $true
    }
}

# Install applications
Write-Output "Installing Base Applications..."
 Install-Apps -apps $apps
Write-Output "Done Installing Base Applications!"
Write-Output "Installing Base Applications with special needs"
 Install-Apps -apps $appThatNeedWingetSourceDeclared
Write-Output "Done installing Base Applications with special needs"
# Install optional applications
if ($optionalInstall) {
    Write-Output "Installing optional applications..."
     Install-Apps -apps $optionalApps
    Write-Output "Done Installing optional applications!"
}
if ($optionalExtendedInstall) {
    Write-Output "Installing other optional applications..."
     Install-Apps -apps $optionalAppsWithComplications
    Write-Output "Done installing other optional applications!"
}
# Install dev applications
if ($devInstall) {
    Write-Output "Installing Developer Applications..."
     Install-Apps-Source-Winget -apps $devApps
    Write-Output "Done installing developer applications!"
}

# Remove apps
if ($uninstall) {
    Write-Output "Uninstalling General Applications..."
     Uninstall-Apps -apps $appsToRemove
    Write-Output "Done Uninstalling Applications!"
    Write-Output "Uninstalling Dell Specific Applications..."
     Uninstall-Apps -apps $dellAppsToRemove
    Write-Output "Done uninstalling upplications!"
}
if ($updates) {
    Write-Output "Updating Installed Applications..."
     runUpdates
    Write-Output "Done Updating Installed Applications!"
}