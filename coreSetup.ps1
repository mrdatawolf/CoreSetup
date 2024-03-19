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

.PARAMETER --noauto
If set the autogathering of info will be skipped.

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

# Define the list of possible clients
$clients = @("test")

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

function autogatherInfo {
    outputProgress "Getting Date..." 05
    # Get the current date and format it as yyyy-MM-dd
    $date = Get-Date -Format "yyyy-MM-dd"
    outputProgress "Getting OS version..." 10
    # Get the Windows version number
    $osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
    outputProgress "Getting HOSTNAME tag..." 15
    # Get the hostname for the computer
    $hostname = $env:computername
    outputProgress "Getting service tag..." 20
    # Get the Dell service tag
    $serviceTag = Invoke-Command -ScriptBlock {
        Get-CimInstance -ClassName win32_bios | Select-Object -ExpandProperty SerialNumber
    }
    outputProgress "Getting IP addresses..." 30
    # Get all network IP addresses
    $ipAddresses = Invoke-Command -ScriptBlock {
        Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object InterfaceAlias, IpAddress
    }
    outputProgress "Getting current user..." 40
    # Get the currently logged in user
    $currentUser = $env:USERNAME
    outputProgress "Getting shared drives..." 50
    # Get a list of shared drives and their locations
    $shares = Invoke-Command -ScriptBlock {
        (Get-SmbShare | Where-Object { $_.ScopeName -eq "Default" }).Name
    }
    outputProgress "Getting remote shares..." 60
    # Get a list of remote shares and their paths
    $remoteShares = Invoke-Command -ScriptBlock {
        (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*\*" }).DisplayRoot
    }
    outputProgress "Getting printers..." 70
    # Get a list of printers and their names
    $printers = Invoke-Command -ScriptBlock {
        Get-Printer | Select-Object Name
    }
    outputProgress "Getting drives..." 80
    # Get a list of all drives and their size and free space
    $drives = @(Invoke-Command -ScriptBlock {
            Get-PSDrive -PSProvider 'FileSystem' | Select-Object Name, @{Name = "Size(GB)"; Expression = { [math]::Round($_.Used / 1GB) } }, @{Name = "FreeSpace(GB)"; Expression = { [math]::Round($_.Free / 1GB) } }
        })
    outputProgress "Getting domain..." 90
    # Get the domain the computer is connected to
    $domain = $env:USERDOMAIN
    outputProgress "Finished gathering data!" 100
    # Create a custom object to store the service tag, IP addresses, machine name, logged in user, printers, shared drives, remote shares, and folders
    $serviceInfoObj = @{
        "Date Create"    = $date
        "Script Version" = $versionNumber
        "OS Version"     = $osVersion
        "ClientName"     = $client
        "Domain"         = $domain
        "ServiceTag"     = $serviceTag
        "IPAddresses"    = $ipAddresses
        "LoggedInUser"   = $currentUser
        "Printers"       = $printers
        "Shares"         = $shares
        "RemoteShares"   = $remoteShares
        "Drives"         = $drives
        "Hostname"       = $hostname
    }

    # Convert the object to a JSON string
    $serviceInfoJson = ConvertTo-Json $serviceInfoObj -Depth 4

    # Define the default file path and name to the user's desktop
    #$jsonFilePath = "$env:USERPROFILE\Desktop\SystemInfo_$hostname.json"
    $jsonFilePath = "~\Desktop\SystemInfo~$client~$domain~$hostname.json"


    # Write the service information to the CSV file
    $serviceInfoJson | Out-File -FilePath $jsonFilePath -Encoding ascii
    $serviceInfoObj | Select-Object * | Out-GridView -Title "Service information was saved to $jsonFilePath"
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
else {
    # Prompt user to select a client if no argument is provided
    Write-Host "Choose a client to gather information from:" -ForegroundColor Cyan
    Write-Host "Please select a client:"
    for ($i = 0; $i -lt $clients.Length; $i++) {
        Write-Host "$i. $($clients[$i])"
    }
    $clientIndex = Read-Host "Enter the number corresponding to the client you want to select"
    $client = $clients[$clientIndex]
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
}
else {
    Write-Host "Do you want to UNinstall the following programs?"
    for ($i = 0; $i -lt $appsToRemove.Length; $i++) {
        Write-Host "$i. $($appsToRemove[$i])" -ForegroundColor Red
    }
    for ($i = $i; $i -lt $dellAppsToRemove.Length; $i++) {
        Write-Host "$i. $($dellAppsToRemove[$i])" -ForegroundColor Red
    }
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $uninstall = $true
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

# Check for noauto argument
$json = $false
if ($args -contains "--json") {
    $json = $true
}
else {
    Write-Host "Do you want to save a json report of the system?"
    $userInput = Read-Host "(y/N)"
    if ($userInput -eq "y") {
        $json = $true
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

if ($json) {
    Write-Host "Gathering general info on the computer and saving it in the folder you ran this script from." -ForegroundColor Cyan
    autogatherInfo
} 

Write-Host "Completed." -ForegroundColor Cyan