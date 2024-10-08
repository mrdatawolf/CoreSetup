param (
    [switch]$automatic,
    [string]$client
)

# Check if the client name is provided as an argument
if (-not $client) {
    $client = Read-Host -Prompt "Please enter the client name"
}

# Show progress
function outputProgress {
    Param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Status,
        [Parameter(Mandatory = $true, Position = 1)]
        [int] $Progress
    )
    Write-Progress -Activity "Catchphrase!" -Status $Status -PercentComplete $Progress
}

$baseFolder = "ChangeMe"
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
    # Get network information
    outputProgress "Getting Network addresses..." 30
   
    # Get all network IP addresses and MAC addresses
    $networkInfo = Invoke-Command -ScriptBlock {
        $ipAddresses = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object InterfaceAlias, IpAddress
        $macAddresses = Get-NetAdapter | Select-Object InterfaceAlias, MacAddress

        # Join IP addresses and MAC addresses based on InterfaceAlias
        $ipAddresses | ForEach-Object {
            $interfaceAlias = $_.InterfaceAlias
            $ipAddress = $_.IpAddress
            $macAddress = ($macAddresses | Where-Object { $_.InterfaceAlias -eq $interfaceAlias }).MacAddress

            [PSCustomObject]@{
                InterfaceAlias = $interfaceAlias
                IpAddress = $ipAddress
                MacAddress = $macAddress
            }
        }
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
        "Network Addresses" = $networkInfo
        "LoggedInUser"   = $currentUser
        "Printers"       = $printers
        "Shares"         = $shares
        "RemoteShares"   = $remoteShares
        "Drives"         = $drives
        "Hostname"       = $hostname
    }

    # Convert the object to a JSON string
    $serviceInfoJson = ConvertTo-Json $serviceInfoObj -Depth 4

    $basePath = "C:\$baseFolder"
    if (-Not (Test-Path -Path $basePath)) {
        New-Item -Path $basePath -ItemType Directory
    }
    $jsonFilePath = "$basePath\SystemInfo~$client~$domain~$hostname.json"
    # Write the service information to the CSV file
    $serviceInfoJson | Out-File -FilePath $jsonFilePath -Encoding ascii
    if (-not $automatic) {
        $fullPath = Resolve-Path -Path $jsonFilePath
        Start-Process "msedge.exe" $fullPath
    }
    #$serviceInfoObj | Select-Object * | Out-GridView -Title "Service information was saved to $jsonFilePath"
}

Write-Host "Gathering general info on the computer and saving it in the folder you ran this script from." -ForegroundColor Cyan
autogatherInfo

Write-Host "Completed." -ForegroundColor Cyan
