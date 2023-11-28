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
If set we will not install the base apps (like firefox)

.EXAMPLE
btWinGet -o

.EXAMPLE
btWinGet --noauto --nobase

.NOTES
Requires winget. Also you might need to run "Set-ExecutionPolicy Unrestricted" to use powershell scripts.

#>
#Biztech Consulting - 2023
# Written by MrDataWolf
# Tested and co-developed by Gabriel
# Get the latest version at https://github.com/mrdatawolf/BTWinGet
 # Define the version number
 $versionNumber = "1.2.0"
# List of applications ids to install. Note: install we use id to be specific, uninstall uses name
 $apps = @("Mozilla.Firefox", "Google.Chrome")
 $appThatNeedWingetSourceDeclared = @("Adobe Acrobat Reader DC")
# Optional installs
 $optionalApps = @("SonicWALL.NetExtender", "Microsoft.Powershell", "tightvnc")
 $optionalAppsWithComplications = @("Microsoft 365")
#dev installs
 $devApps = @("git.git","vscode", "github desktop", "JanDeDobbeleer.OhMyPosh")

# List of applications names to install. Note: uninstall uses name because the id cane change, install uses id
# Uninstall applications
 $appsToRemove = @("Mail and Calendar", "Spotify Music", "Movies & TV", "Phone Link", "Your Phone", "Game Bar", "LinkedIn", "Skype", "News", "MSN Weather", "Microsoft Family", "xbox", "Xbox Game Speech Window", "Xbox Identity Provider", "Xbox Game Bar Plugin", "Xbox TCUI")
 $dellAppsToRemove = @("Dell SupportAssist", "Dell Digital Delivery Services","Dell Core Services","Dell SupportAssist for Dell Update", "Dell Core Services", "Dell Command | Update for Windows Universal", "Dell Optimizer Core", "Dell SupportAssist Remediation", "Dell SupportAssist for Home PCs", "Dell Digital Delivery", "Dell SupportAssist OS Recovery Plugin for Dell Update")

# Define the progress title
$progressTitle = "Created by MrDataWolf. Version: $versionNumber"

# Define the list of possible clients
$clients = @("AE","BP","BM","BNB","BT","CHAMP","EL","FL","GLC","GLF","GPI","HS","JC","JCURL","M1","MP","MTS","MY","ND","NFL","OMEY","POE","POU","PPP","Safe","SLI","SRM","STL","STROM","TRL","VANCE","VL","WC","LCC","Other")

#show progress
function outputProgress {
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Status,
         [Parameter(Mandatory=$true, Position=1)]
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
    } catch {
        Write-Host "Winget is not installed. This is complicated. Good luck!" -ForegroundColor Red
        exit
    }
}
function Install-Apps {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$apps,
        [string[]]$source
    )

    $totalApps = $apps.Count
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        Write-Progress -Activity "Installing applications - $app" -Status "$([Math]::Floor((($i + 1) / $totalApps) * 100))% Complete:" -PercentComplete ([Math]::Floor((($i + 1) / $totalApps) * 100))
        $wingetList = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            Write-Host " $app already installed"  -ForegroundColor Cyan
        } else {
            if ($source) { winget install $app -s $source --silent } else { winget install $app --silent }
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$app installed" -ForegroundColor Green
            } else {
                Write-Host "$app failed to install" -ForegroundColor Red
            }
        }
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
        $wingetList = winget list --name $app
        if ($LASTEXITCODE -eq 0) {
            $wingetUninstall = winget uninstall $app --silent
            $percentComplete = [Math]::Floor((($i + 1) / $totalApps) * 100)
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$app uninstalled" -ForegroundColor Green
            } else {
                Write-Host "$app failed to uninstall" -ForegroundColor Cyan
            }
        } else {
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
        Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object InterfaceAlias,IpAddress
    }

    outputProgress "Getting current user..." 40
    # Get the currently logged in user
    $currentUser = $env:USERNAME

    outputProgress "Getting shared drives..." 50
    # Get a list of shared drives and their locations
    $shares = Invoke-Command -ScriptBlock {
        (Get-SmbShare | Where-Object {$_.ScopeName -eq "Default"}).Name
    }

    outputProgress "Getting remote shares..." 60
    # Get a list of remote shares and their paths
    $remoteShares = Invoke-Command -ScriptBlock {
        (Get-PSDrive -PSProvider FileSystem | Where-Object {$_.DisplayRoot -like "\\*\*"}).DisplayRoot
    }

    outputProgress "Getting printers..." 70
    # Get a list of printers and their names
    $printers = Invoke-Command -ScriptBlock {
        Get-Printer | Select-Object Name
    }

    outputProgress "Getting drives..." 80
    # Get a list of all drives and their size and free space
    $drives = Invoke-Command -ScriptBlock {
        Get-PSDrive -PSProvider 'FileSystem' | Select-Object Name, @{Name="Size(GB)";Expression={[math]::Round($_.Used/1GB)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.Free/1GB)}}
    }

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
    $jsonFilePath = ".\SystemInfo~$client~$domain~$hostname.json"


    # Write the service information to the CSV file
    $serviceInfoJson | Out-File -FilePath $jsonFilePath -Encoding ascii

    Write-Host "Service information was saved to $jsonFilePath"
}

# Display title line
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Biztech Application Script" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Invoke-Sanity-Checks
if ($args -contains "--noauto") {
    Write-Host "Skipping base installs" -ForegroundColor Cyan
} else {
    # Prompt user to select a client if no argument is provided
    Write-Host "Choose a client to gather information from:" -ForegroundColor Cyan
    Write-Host "Please select a client:"
    for ($i=0; $i -lt $clients.Length; $i++) {
        Write-Host "$i. $($clients[$i])"
    }
    $clientIndex = Read-Host "Enter the number corresponding to the client you want to select"
    $client = $clients[$clientIndex]
}
# Check for optional argument
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
if ($args -contains "--nobase") {
    Write-Host "Skipping base applications" -ForegroundColor Cyan
} else {
    Write-Host "Installing Base Applications..."
    Install-Apps -apps $apps
    Write-Host "Done Installing Base Applications!"
    Write-Host "Installing Base Applications with special needs."
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "winget"
    Write-Host "Done installing Base Applications with special needs."
}
    
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
     Install-Apps -apps $devApps -source "winget"
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

if ($args -contains "--noauto") {
    Write-Host "Skipping info gathering on computer." -ForegroundColor Cyan
} else {
    Write-Host "Gathering general info on the computer and saving it in the folder you ran this script." -ForegroundColor Cyan
    autogatherInfo
}
