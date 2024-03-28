# Check if we are running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # orginal: Start-Process -FilePath "powershell" -ArgumentList "-File .\coreSetup.ps1" -Verb RunAs
    # We are not running as administrator, so start a new process with 'RunAs'
    Start-Process powershell.exe "-File", ($myinvocation.MyCommand.Definition) -Verb RunAs
    exit
}

# Load assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
$clients = @("test")

function Test-PSVersion {
    param (
        [System.Windows.Forms.TextBox]$textBox,
        $logBox
    )
    $textBox.Text = "Checking powershell version"
    $logBox.AppendText("Checking powershell version`r`n")
    if ($PSVersionTable.PSVersion.Major -lt 5) {
       # $textBox.AppendText("Your powershell is too old!`r`n")
       $textBox.Text = "Your powershell is too old!"

        return $false
    }
    $logBox.AppendText("Powershell version is new enough!`r`n")

    return $true
}

function Test-Winget {
    param (
        [System.Windows.Forms.TextBox]$textBox,
        $logBox
    )
    $textBox.Text = "Checking winget"
    $logBox.AppendText("Checking winget`r`n")
    try {
        $wingetCheck = Get-Command winget -ErrorAction Stop
    }
    catch {
        $textBox.Text = "Winget has blocking issues!"
        $logBox.AppendText("Winget has blocking issues!`r`n")

        return $false
    }
    $logBox.AppendText("Winget seems to be working.`r`n")

    return $true
}

function Invoke-Base-Updates {
    param(
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$progressBar,
        $logBox
    )
    $progressBar.Value = 1
    $textBox.Text = "Running winget source update"
    $logBox.AppendText("Running winget source update`r`n")
    winget source update
    $logBox.AppendText("Winget source updated`r`n")
    $progressBar.Value = 50
    $textBox.Text = "Running winget updates"
    $logBox.AppendText("Running winget updates`r`n")
    winget update --all --silent
    $progressBar.Value = 100
    $logBox.AppendText("Winget updates ran.`r`n")
}

function Install-Apps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$apps,
        [string]$source,
        [string]$scope,
        [System.Windows.Forms.TextBox]$textBox,
        $logBox
    )
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $app = $apps[$i]
        $textbox.Text = "Installing $app"
        $wingetList = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            $logBox.AppendText("$app already installed`r`n")
        }
        else {
            Install-App -app $app -source $source -scope $scope
            if ($LASTEXITCODE -eq 0) {
                $logBox.AppendText("$app installed`r`n")
            }
            else {
                $logBox.AppendText("$app failed to install`r`n")
            }
        }
    }
    $logBox.AppendText("Done.`r`n")
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

function Uninstall-Apps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$apps,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.TextBox]$textBox,
        $logBox
    )
    $totalApps = $apps.Count
    $progressBar.Value = 1
    for ($i = 0; $i -lt $totalApps; $i++) {
        Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
        $app = $apps[$i]
        $progressBar.Value = $([Math]::Floor((($i + 1) / $totalApps) * 100))
        $textBox.Text = "Uninstalling $app"
        # Check if the application is installed
        $wingetList = winget list --name $app
        if ($LASTEXITCODE -eq 0) {
            $wingetUninstall = winget uninstall $app --silent
            if ($LASTEXITCODE -eq 0) {
                $logBox.AppendText("$app uninstalled`r`n")
            }
            else {
                $logBox.AppendText("$app failed to uninstall`r`n")
            }
        }
        else {
            $logBox.AppendText("$app not installed.`r`n")
        }
    }
    $progressBar.Value = 100
    $logBox.AppendText("Done.`r`n")
    $textBox.Text = "Done"
}

function Optimize-PowerSettings {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.TextBox]$textBox,
        $logBox
    )
    $subProgressBar.Value = 1
    $logBox.AppendText("Updating Power settings...`r`n")
    $textBox.Text = "Updating Monitor Power settings"
    powercfg.exe -x -monitor-timeout-ac 60
    $progressBar.Value = 10
    powercfg.exe -x -monitor-timeout-dc 60
    $progressBar.Value = 20
    $textBox.Text = "Updating Disk Power settings"
    powercfg.exe -x -disk-timeout-ac 0
    $progressBar.Value = 30
    powercfg.exe -x -disk-timeout-dc 0
    $progressBar.Value = 40
    $textBox.Text = "Updating Standby Power settings"
    powercfg.exe -x -standby-timeout-ac 0
    $progressBar.Value = 50
    powercfg.exe -x -standby-timeout-dc 0
    $progressBar.Value = 60
    $textBox.Text = "Updating Hibernate Power settings"
    powercfg.exe -x -hibernate-timeout-ac 0
    $progressBar.Value = 70
    powercfg.exe -x -hibernate-timeout-dc 0
    $progressBar.Value = 80
    powercfg.exe -h off
    $progressBar.Value = 100
    $textBox.Text = "Done"
    $logBox.Text = "Done adjusting power settings`r`n"
}

function Read-GeneralInfo {
    return @{
        "Date Create"    = Get-Date -Format "yyyy-MM-dd"
        "Script Version" = 1
        "OS Version"     = (Get-CimInstance -ClassName Win32_OperatingSystem).Version
        "ServiceTag"     = (Get-CimInstance -ClassName win32_bios).SerialNumber
        "Hostname"       = $env:computername
        "Domain"         = $env:USERDOMAIN
    }
}

function Read-PrinterInfo {
    $printerNames = Get-Printer | Select-Object -ExpandProperty Name
    $printerInfo = @{}
    for ($i = 0; $i -lt $printerNames.Count; $i++) {
        $printerInfo["Printer $($i + 1)"] = $printerNames[$i]
    }

    return $printerInfo
}

function Read-NetworkInfo {
    $ipAddresses = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object InterfaceAlias, IpAddress
    $ipAddressesInfo = @{}
    for ($i = 0; $i -lt $ipAddresses.Count; $i++) {
        $ipAddressesInfo["IP $($i + 1)"] = $ipAddresses[$i].IPAddress
    }

    return $ipAddressesInfo
}

function Read-LocalShareInfo {
    $shares = (Get-SmbShare | Where-Object { $_.ScopeName -eq "Default" }).Name
    $sharesInfo = @{}
    for ($i = 0; $i -lt $shares.Count; $i++) {
        $sharesInfo["Share $($i + 1)"] = $shares[$i]
    }

    return $sharesInfo
}

function Read-RemoteShareInfo {
    $shares = @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*\*" }).Root
    $sharesInfo = @{}
    for ($i = 0; $i -lt $shares.Count; $i++) {
        $sharesInfo["Share $($i + 1)"] = $shares[$i]
    }

    return $sharesInfo
}

function Invoke-System-Info-Gather {
    $ipAddresses = Invoke-Command -ScriptBlock {
        Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object InterfaceAlias, IpAddress
    }
    $currentUser = $env:USERNAME
    $shares = Invoke-Command -ScriptBlock {
        (Get-SmbShare | Where-Object { $_.ScopeName -eq "Default" }).Name
    }
    $remoteShares = Invoke-Command -ScriptBlock {
        (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "\\*\*" }).DisplayRoot
    }
    $printers = Invoke-Command -ScriptBlock {
        Get-Printer | Select-Object Name
    }
    $drives = @(Invoke-Command -ScriptBlock {
            Get-PSDrive -PSProvider 'FileSystem' | Select-Object Name, @{Name = "Size(GB)"; Expression = { [math]::Round($_.Used / 1GB) } }, @{Name = "FreeSpace(GB)"; Expression = { [math]::Round($_.Free / 1GB) } }
        })
    $domain = $env:USERDOMAIN
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
    $serviceInfoJson = ConvertTo-Json $serviceInfoObj -Depth 4
    $jsonFilePath = "~\Desktop\SystemInfo~$client~$domain~$hostname.json"
    $serviceInfoJson | Out-File -FilePath $jsonFilePath -Encoding ascii

    return $serviceInfoJson
}

#the following functions build the gui

function Initialize-Form {
    param(
        [hashtable] $ObjectDimensions = @{ Width=1024; Height=768 },
        [System.Windows.Forms.Form]$Form,
        [string]$Text = "My Form"
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Text
    $form.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
    $form.StartPosition = "CenterScreen"
    return $form
}

function Initialize-Control {
    param(
        [hashtable] $ObjectDimensions = @{ Width=200; Height=20 },
        [PSCustomObject]$CurrentLocation = @{ X=50; Y=70 },
        [System.Windows.Forms.Form]$Form,
        [string]$ControlType,
        [string]$Text = ""
    )
    switch ($ControlType) {
        "ProgressBar" {
            $control = New-Object System.Windows.Forms.ProgressBar
            $control.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
            $control.Value = 1
        }
        "TextBox" {
            $control = New-Object System.Windows.Forms.TextBox
            $control.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
            $control.Readonly = $true
        }
        "SpinnerLabel" {
            $control = New-Object System.Windows.Forms.Label
            $control.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
            $control.Text = $Text
        }
        "Log" {
            $control = New-Object System.Windows.Forms.TextBox
            $control.Size = New-Object System.Drawing.Size(200, 100)
            $control.Multiline = $true
            $control.ScrollBars = 'Vertical'
            $control.Readonly = $true   
        }
    }
    $control.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $CurrentLocation.X = 10
    $CurrentLocation.Y += $ObjectDimensions.Height

    return $control
}

function Initialize-PictureBox {
    param(
        [hashtable] $ObjectDimensions = @{ Width=60; Height=30 },
        [PSCustomObject]$CurrentLocation,
        [System.Windows.Forms.Form]$Form,
        [string]$Text,
        $url = "https://trustbiztech.com/public/logos/biztech.png"
    )
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $webClient = New-Object System.Net.WebClient
    $imagePath = [System.IO.Path]::GetTempFileName()
    $webClient.DownloadFile($url, $imagePath)
    $pictureBox.Image = [System.Drawing.Image]::Fromfile($imagePath)
    $pictureBox.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)  # Change this to your desired size
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $pictureBox.Location = New-Object System.Drawing.Point(($CurrentLocation.X - $pictureBox.Width - 20),($CurrentLocation.Y - $pictureBox.Height - 40)) 

    return $pictureBox
}

function Initialize-Button {
    param(
        [hashtable] $ObjectDimensions = @{ Width=100; Height=20 },
        [PSCustomObject]$CurrentLocation = @{ X=100; Y=35 },
        [System.Windows.Forms.Form]$Form,
        [string]$Text = "Click me",
        $NewLine = $true
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $button.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
    $button.Text = $Text
    
    if($NewLine) {
    $CurrentLocation.X = 10
    $CurrentLocation.Y += $ObjectDimensions.Height
    } else {
        $CurrentLocation.X += $ObjectDimensions.Width
    }
    
    return $button
}

function Invoke-Spinner {
    param(
        $spinnerLabel,
        $currentStep
    )
    $spinnerChars = @('/', '|', '\', '-')
    $spinnerLabel.Text = $spinnerChars[$currentStep % $spinnerChars.Length]
}

function Invoke-ProgressBar {
    param(
        $progressBar,
        $currentStep
    )
    $progressBar.Value = $currentStep
}

function New-DataGridViewFromHashtable {
    param(
        [hashtable] $ObjectDimensions = @{ Width=900; Height=80 },
        [PSCustomObject]$CurrentLocation = @{ X=100; Y=35 },
        [hashtable]$hashTable
    )
    if ($hashTable.Count -eq 0) {
        Write-Host "The hashtable is empty."
    } else {
        # Convert the hashtable to a DataTable
        $dataTable = New-Object System.Data.DataTable
        $hashTable.Keys | Where-Object { $_ } | ForEach-Object {
            $dataTable.Columns.Add($_) | Out-Null
        }
        $row = $dataTable.NewRow()
        $hashTable.Keys | Where-Object { $_ } | ForEach-Object {
            $row[$_]= $hashTable[$_]
        }
        $dataTable.Rows.Add($row)

        # Create a new DataGridView
        $dataGridView = New-Object System.Windows.Forms.DataGridView
        $dataGridView.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
        $dataGridView.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
        $dataGridView.AutoSizeColumnsMode = 'AllCells'
        $dataGridView.AllowUserToAddRows = $false

        # Display the hashtable data
        $dataGridView.DataSource = $dataTable

        $CurrentLocation.X = 10
        $CurrentLocation.Y += $ObjectDimensions.Height
    }
    return $dataGridView
}

function Invoke-DataGridViewFromHashtable {
    param(
        [hashtable] $ObjectDimensions = @{ Width=900; Height=100 },
        [PSCustomObject]$CurrentLocation = @{ X=100; Y=35 },
        [hashtable]$hashTable
    )
    if ($hashTable.Count -eq 0) {
        Write-Host "The hashtable is empty."
    } else {
        Write-Host("`r`n$hashTable`r`n")
        # Convert the hashtable to a DataTable
        $dataTable = New-Object System.Data.DataTable
        $hashTable.Keys | Where-Object { $_ } | ForEach-Object {
            $dataTable.Columns.Add($_) | Out-Null
        }
        $row = $dataTable.NewRow()
        $hashTable.Keys | Where-Object { $_ } | ForEach-Object {
            $row[$_]= $hashTable[$_]
        }
        $dataTable.Rows.Add($row)

        # Create a new DataGridView
        $dataGridView = New-Object System.Windows.Forms.DataGridView
        $dataGridView.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
        $dataGridView.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
        $dataGridView.AutoSizeColumnsMode = 'AllCells'
        $dataGridView.AllowUserToAddRows = $false

        # Display the hashtable data
        $dataGridView.DataSource = $dataTable

        $CurrentLocation.X = 10
        $CurrentLocation.Y += $ObjectDimensions.Height + 10

        return $dataGridView
    }
}


$RGI = Read-GeneralInfo
$RPI = Read-PrinterInfo
$RNI = Read-NetworkInfo
$RLSI = Read-LocalShareInfo
$RRSI = Read-RemoteShareInfo
$location = New-Object -TypeName psobject -Property @{ X=10; Y=10 }
# Create form and controls
$form = Initialize-Form -CurrentLocation $location
$firstButton = Initialize-Button -CurrentLocation $location -Text "Sanity Checks" -NewLine $false
$secondButton = Initialize-Button -CurrentLocation $location -Text "Base Updates" -NewLine $false
$baseAppsButton = Initialize-Button -CurrentLocation $location -Text "Install Apps" -NewLine $false
$optionalAppsButton = Initialize-Button -CurrentLocation $location -Text "Install Opt. Apps" -NewLine $false
$optionalLongRunningAppsButton = Initialize-Button -CurrentLocation $location -Text "Install Other Apps" -NewLine $false
$developerAppsButton = Initialize-Button -CurrentLocation $location -Text "Install Dev Apps" -NewLine $false
$uninstallAppsButton = Initialize-Button -CurrentLocation $location -Text "Remove Apps" -NewLine $false
$uninstallDellAppsButton = Initialize-Button -CurrentLocation $location -Text "Remove Dell Apps" -NewLine $false
$powerSettingsButton = Initialize-Button -CurrentLocation $location -Text "Adjust Power"
$overallProgressBar = Initialize-Control -ControlType "ProgressBar" -CurrentLocation $location -Form $form
$progressBar = Initialize-Control -ControlType "ProgressBar" -CurrentLocation $location -Form $form
$textBox = Initialize-Control -ControlType "TextBox" -CurrentLocation $location -Form $form
$logBox = Initialize-Control -ControlType "Log" -CurrentLocation $location -Form $form 
#special ui
$location.X = 10
$location.Y = $form.Height-60
$spinnerLabel = Initialize-Control -ControlType "SpinnerLabel" -CurrentLocation $location -Form $form -Text "-"
$location.X = $form.Width
$location.Y = $form.Height
$pictureBox = Initialize-PictureBox -CurrentLocation $location
#$dataGridViewRGI = Invoke-DataGridViewFromHashtable -CurrentLocation $location -Form $form -hashTable $RGI
#$dataGridViewRPI = Invoke-DataGridViewFromHashtable -CurrentLocation $location -Form $form -hashTable $RPI
#$dataGridViewRNI = Invoke-DataGridViewFromHashtable -CurrentLocation $location -Form $form -hashTable $RNI
#$dataGridViewRLSI = Invoke-DataGridViewFromHashtable -CurrentLocation $location -Form $form -hashTable $RLSI
#$dataGridViewRRSI = Invoke-DataGridViewFromHashtable -CurrentLocation $location -Form $form -hashTable $RRSI

#now we add the commands for the buttons
$firstButton.Add_Click({
    $progressBar.Value = 0
    Invoke-ProgressBar -progressBar $progressBar -textBox $textBox -currentStep $i
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    if (Test-PSVersion -textBox $textBox -logBox $logBox) {
        $textBox.Text = "Done"
    } else {
        exit
    }
    $progressBar.Value = 50
    if (Test-Winget -textBox $textBox -logBox $logBox) {
        $textBox.Text = "Done"
    } else {
        exit
    }
    $progressBar.Value = 100
    $overallProgressBar.Value += 10
    $this.Enabled = $false
}) 
$secondButton.Add_Click({
    $progressBar.Value = 0
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    Invoke-Base-Updates -textBox $textBox -logBox $logBox -progressBar $progressBar
    $overallProgressBar.Value += 10
    $this.Enabled = $false
}) 
$baseAppsButton.Add_Click({
    $progressBar.Value = 1
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    $appsCount = $apps.Count
    $appsScopeRequiredCount = $appsScopeRequired.Count
    $appThatNeedWingetSourceDeclaredCount = $appThatNeedWingetSourceDeclared.Count
    $totalApps = $appsCount + $appsScopeRequiredCount + $appThatNeedWingetSourceDeclaredCount
    $logBox.AppendText("Installing $totalApps apps...`r`n")
    Install-Apps -apps $apps  -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appsCount apps...`r`n")
    $progressBar.Value = 33
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "winget" -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appThatNeedWingetSourceDeclared.Count apps...`r`n")
    $progressBar.Value += 33
    Install-Apps -apps $appsScopeRequired -source "winget" -scope "machine" -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appsScopeRequiredCount apps...`r`n")
    $progressBar.Value += 33
    $overallProgressBar.Value += 10
    $progressBar.Value = 100
    $logBox.AppendText("Done installing apps...`r`n")
    $this.Enabled = $false
}) 

$optionalAppsButton.Add_Click({
    $progressBar.Value = 1
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    $appsCount = $optionalApps.Count
    $totalApps = $appsCount
    $logBox.AppendText("Installing $totalApps optional apps...`r`n")
    Install-Apps -apps $optionalApps  -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appsCount apps...`r`n")
    $progressBar.Value = 100
    $logBox.AppendText("Done installing optional apps...`r`n")
    $this.Enabled = $false
}) 

$optionalLongRunningAppsButton.Add_Click({
    $progressBar.Value = 1
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    $appsCount = $optionalApps.Count
    $totalApps = $appsCount
    $logBox.AppendText("Installing $totalApps optional apps...`r`n")
    Install-Apps -apps $optionalAppsWithComplications  -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appsCount apps...`r`n")
    $progressBar.Value = 100
    $logBox.AppendText("Done installing optional+ apps...`r`n")
    $this.Enabled = $false
}) 

$developerAppsButton.Add_Click({
    $progressBar.Value = 1
    Invoke-Spinner -spinnerLabel $spinnerLabel -currentStep $i
    $appsCount = $devApps.Count
    $totalApps = $appsCount
    $logBox.AppendText("Installing $totalApps developer apps...`r`n")
    Install-Apps -apps $devApps  -textBox $textBox -logBox $logBox
    $logBox.AppendText("Done installing $appsCount apps...`r`n")
    $progressBar.Value = 100
    $logBox.AppendText("Done installing developer apps...`r`n")
    $this.Enabled = $false
}) 

$uninstallAppsButton.Add_Click({
    $progressBar.Value = 1
    $appsCount = $appsToRemove.Count
    $logBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $appsToRemove -textBox $textBox -logBox $logBox -progressBar $progressBar
    $overallProgressBar.Value += 10
    $this.Enabled = $false
})

$uninstallDellAppsButton.Add_Click({
    $progressBar.Value = 1
    $appsCount = $dellAppsToRemove.Count
    $logBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $dellAppsToRemove -textBox $textBox -logBox $logBox -progressBar $progressBar
    $overallProgressBar.Value += 10
    $this.Enabled = $false
})
$powerSettingsButton.Add_Click({
    $progressBar.Value = 1
    $logBox.AppendText("Adjusting Power Settings...`r`n")
    Optimize-PowerSettings -textBox $textBox -logBox $logBox -progressBar $progressBar
    $overallProgressBar.Value += 10
    $this.Enabled = $false
})

# Add controls to form
$form.Controls.Add($firstButton)
$form.Controls.Add($secondButton)
$form.Controls.Add($baseAppsButton)
$form.Controls.Add($uninstallAppsButton)
$form.Controls.Add($uninstallDellAppsButton)
$form.Controls.Add($powerSettingsButton)
$form.Controls.Add($optionalAppsButton)
$form.Controls.Add($optionalLongRunningAppsButton)
$form.Controls.Add($developerAppsButton)
$form.Controls.Add($overallProgressBar)
$form.Controls.Add($progressBar)
$form.Controls.Add($textBox)
$form.Controls.Add($logBox)

$form.Controls.Add($spinnerLabel)
$form.Controls.Add($pictureBox)
# Add the DataGridView to the form
#$form.Controls.Add($dataGridViewRGI)
#$form.Controls.Add($dataGridViewRPI)
#$form.Controls.Add($dataGridViewRNI)
#$form.Controls.Add($dataGridViewRLSI)
#$form.Controls.Add($dataGridViewRRSI)

# Show form
$form.ShowDialog()
