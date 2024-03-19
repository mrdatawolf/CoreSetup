Add-Type -assembly System.Windows.Forms

# Check if we are running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # orginal: Start-Process -FilePath "powershell" -ArgumentList "-File .\coreSetup.ps1" -Verb RunAs
    # We are not running as administrator, so start a new process with 'RunAs'
    #Start-Process powershell.exe "-File", ($myinvocation.MyCommand.Definition) -Verb RunAs
    #exit
}

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
$clients = @("test")

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
        [string]$scope,
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$subProgressBar,
        [System.Windows.Forms.Label]$subProgressBarStatus,
        [System.Windows.Forms.Label]$timerLabel
    )
    $timer = Start-Animation -timerLabel $timerLabel
    $totalApps = $apps.Count
    $subProgressBar.Value = 1
    $textBox.AppendText("Installing apps...`r`n")
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        $subProgressBar.Value = $([Math]::Floor((($i + 1) / $totalApps) * 100))
        $subProgressBarStatus.Text = "Installing $app"
        $wingetList = winget list --id $app
        if ($LASTEXITCODE -eq 0) {
            $textBox.AppendText("$app already installed`r`n")
        }
        else {
            Install-App -app $app -source $source -scope $scope
            if ($LASTEXITCODE -eq 0) {
                $textBox.AppendText("$app installed`r`n")
            }
            else {
                $textBox.AppendText("$app failed to install`r`n")
            }
        }
    }
    $subProgressBar.Value = 100
    $textBox.AppendText("Done.`r`n")
    Stop-Animation -timerLabel $timer
}
function Uninstall-Apps {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$apps,
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$subProgressBar,
        [System.Windows.Forms.Label]$subProgressBarStatus,
        [System.Windows.Forms.Label]$timerLabel
    )
    $totalApps = $apps.Count
    $subProgressBar.Value = 1
    $timer = Start-Animation -timerLabel $timerLabel
    for ($i = 0; $i -lt $totalApps; $i++) {
        $app = $apps[$i]
        $subProgressBar.Value = $([Math]::Floor((($i + 1) / $totalApps) * 100))
        $subProgressBarStatus.Text = "Uninstalling $app"
        # Check if the application is installed
        $wingetList = winget list --name $app
        if ($LASTEXITCODE -eq 0) {
            $wingetUninstall = winget uninstall $app --silent
            if ($LASTEXITCODE -eq 0) {
                $textBox.AppendText("$app uninstalled`r`n")
            }
            else {
                $textBox.AppendText("$app failed to uninstall`r`n")
            }
        }
        else {
            $textBox.AppendText("$app not installed.`r`n")
        }
    }
    $subProgressBar.Value = 100
    $textBox.AppendText("Done.`r`n")
    Stop-Animation -timerLabel $timer
}

function powerSetup {
    param (
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$subProgressBar,
        [System.Windows.Forms.Label]$subProgressBarStatus
    )
    $subProgressBar.Value = 1
    $subProgressBarStatus.Text = "Updating Monitor Power settings"
    $textBox.AppendText = "Updating Monitor Power settings`r`n"
    powercfg.exe -x -monitor-timeout-ac 60
    $subProgressBar.Value = 10
    powercfg.exe -x -monitor-timeout-dc 60
    $subProgressBar.Value = 20
    $subProgressBarStatus.Text = "Updating Disk Power settings"
    $textBox.AppendText = "Updating disk Power settings`r`n"
    powercfg.exe -x -disk-timeout-ac 0
    $subProgressBar.Value = 30
    powercfg.exe -x -disk-timeout-dc 0
    $subProgressBar.Value = 40
    $subProgressBarStatus.Text = "Updating Standby Power settings"
    $textBox.AppendText = "Updating Standby Power settings`r`n"
    powercfg.exe -x -standby-timeout-ac 0
    $subProgressBar.Value = 50
    powercfg.exe -x -standby-timeout-dc 0
    $subProgressBar.Value = 60
    $subProgressBarStatus.Text = "Updating Hibernate Power settings"
    $textBox.AppendText = "Updating Hibernate Power settings`r`n"
    powercfg.exe -x -hibernate-timeout-ac 0
    $subProgressBar.Value = 70
    powercfg.exe -x -hibernate-timeout-dc 0
    $subProgressBar.Value = 80
    powercfg.exe -h off
    $subProgressBar.Value = 100
    $subProgressBarStatus.Text = "Done`r`n"
}

function Invoke-Sanity-Checks {
    param (
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$subProgressBar,
        [System.Windows.Forms.Label]$subProgressBarStatus
    )
    $subProgressBar.Value = 1
    $subProgressBarStatus.Text = "Checking powershell version"
    $textBox.AppendText = "Checking powershell version`r`n"
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $textBox.AppendText = "Your powershell is too old!`r`n"
    }
    $subProgressBar.Value = 50
    $subProgressBarStatus.Text = "Checking winget"
    $textBox.AppendText = "Checking winget`r`n"
    # Check if winget is installed
    try {
        $wingetCheck = Get-Command winget -ErrorAction Stop
    }
    catch {
        $resultBox.AppendText = "Winget has blocking issues!`r`n"
    }
    $subProgressBar.Value = 100
    $subProgressBarStatus.Text = "Done`r`n"
}

function Invoke-Base-Updates {
    param(
        [System.Windows.Forms.TextBox]$textBox,
        [System.Windows.Forms.ProgressBar]$subProgressBar,
        [System.Windows.Forms.Label]$subProgressBarStatus
    )
    $subProgressBar.Value = 1
    $subProgressBarStatus.Text = "Running winget source update"
    $textBox.AppendText = "Running winget source update`r`n"
    winget source update
    $subProgressBar.Value = 50
    $subProgressBarStatus.Text = "Running winget updates"
    $textBox.AppendText = "Running winget updates`r`n"
    winget update --all --silent
    $subProgressBar.Value = 100
    $subProgressBarStatus.Text = "Done`r`n"
}

function New-ProgressBar {
    param(
        [hashtable] $ObjectDimensions = @{ Width=700; Height=20 },
        [PSCustomObject]$CurrentLocation,
        [System.Windows.Forms.Form]$Form,
        [string]$Label,
        [string]$Status
    )
    $labelWidth = 100
    $progressBarWidth = 500
    $labelTextBox = New-Object "System.Windows.Forms.Label"
    $labelTextBox.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $labelTextBox.Size = New-Object System.Drawing.Size($labelWidth, $ObjectDimensions.Height)
    $labelTextBox.Text = $Label
    $Form.Controls.Add($labelTextBox)
    $CurrentLocation.X +=$labelWidth
    $control = New-Object "System.Windows.Forms.ProgressBar"
    $control.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $control.Size = New-Object System.Drawing.Size($progressBarWidth, $ObjectDimensions.Height)
    $control.Style = 'Continuous'
    $control.Maximum = 100
    $Form.Controls.Add($control)
    $CurrentLocation.X +=$progressBarWidth
    $statusTextBox = New-Object "System.Windows.Forms.Label"
    $statusTextBox.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $statusTextBox.Size = New-Object System.Drawing.Size(($labelWidth*3), $ObjectDimensions.Height)
    $statusTextBox.Text = $Status
    $Form.Controls.Add($statusTextBox)
    $CurrentLocation.X = 10
    $CurrentLocation.Y += $ObjectDimensions.Height

    return $control, $statusTextBox
}
function New-TextBox {
    param(
        [hashtable] $ObjectDimensions = @{ Width=700; Height=100 },
        [PSCustomObject]$CurrentLocation,
        [System.Windows.Forms.Form]$Form,
        [string]$Text
    )
    
    $textBox = New-Object "System.Windows.Forms.TextBox"
    $textBox.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $textBox.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Vertical'
    $textBox.Readonly = $true
    $textBox.Text = $Text
    $Form.Controls.Add($textBox)

    $CurrentLocation.X = 10
    $CurrentLocation.Y += $ObjectDimensions.Height

    return $textBox
}
function New-Button {
    param(
        [hashtable] $ObjectDimensions = @{ Width=100; Height=30 },
        [PSCustomObject]$CurrentLocation,
        [System.Windows.Forms.Form]$Form,
        [string]$Text
    )
    $button = New-Object "System.Windows.Forms.Button"
    $button.Location = New-Object System.Drawing.Point($CurrentLocation.X, $CurrentLocation.Y)
    $button.Size = New-Object System.Drawing.Size($ObjectDimensions.Width, $ObjectDimensions.Height)
    $button.Text = $Text
    $Form.Controls.Add($button)
    $CurrentLocation.X = 10
    $CurrentLocation.Y += $ObjectDimensions.Height

    return $button
}


function Start-Animation {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Label]$timerLabel
    )
    # Create a timer
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 200 # Set interval to 200 milliseconds
    # Create an array of strings to simulate an animation
    $animationFrames = @('-', '\\', '|', '/')
    # Initialize a counter
    $i = 0
    # Define what should happen when the timer ticks
    $timer.Add_Tick({
        $timerLabel.Text = $animationFrames[$i++ % $animationFrames.Length]
    })
    # Start the timer
    $timer.Start()

    # Return the timer so it can be stopped later
    return $timer
}

function Stop-Animation {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Timer]$timerLabel
    )
    # Stop the timer
    $timerLabel.Stop()
}


$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Core Setup"
$main_form.Size = New-Object Drawing.Size @(1024, 600)

# buttons -----
$buttonX = 100
$buttonY = 20
$location = New-Object -TypeName psobject -Property @{ X=10; Y=10 }
$overallProgressBar, $overallProgressBarStatus = New-ProgressBar -CurrentLocation $location -Form $main_form -Label "Overall" -Status "Started"
$overallProgressBar.Value = 10
$subProgressBar, $subProgressBarStatus = New-ProgressBar -textBox $textBox -CurrentLocation $location -Form $main_form -Label "Current" -Status "Ready"
$subProgressBar.Value = 1
$textBox = New-TextBox -CurrentLocation $location -Form $main_form -Text "Initial Text`r`n"

#Sanity Checks button
$buttonSanity = New-Object "System.Windows.Forms.Button"
$buttonSanity.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonSanity.Size = New-Object System.Drawing.Size($buttonX, $buttonY)
$buttonSanity.Text = "Sanity Checks"
$buttonSanity.Add_Click({ 
    $textBox.AppendText("Invoking Sanity Checks`r`n")
    Invoke-Sanity-Checks -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonSanity.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonSanity)

#base updates button
$buttonUBase = New-Object "System.Windows.Forms.Button"
$buttonUBase.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonUBase.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonUBase.Text = "Base Updates"
$buttonUBase.Add_Click({ 
    $textBox.AppendText("Invoking Base Updates`r`n")
    Invoke-Base-Updates -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonUBase.Enabled = $false
    $textBox.AppendText("Done")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonUBase)

#base apps
$buttonBaseApps = New-Object "System.Windows.Forms.Button"
$buttonBaseApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonBaseApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonBaseApps.Text = "Base Apps"
$buttonBaseApps.Add_Click({
    $subProgressBar.Value = 1 
    $appsCount = $apps.Count + $appsScopeRequired.Count + $appThatNeedWingetSourceDeclared.Count
    $textBox.AppendText("Installing $appsCount apps...`r`n")
    Install-Apps -apps $apps -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $subProgressBar.Value = 1 
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "winget" -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $subProgressBar.Value = 1 
    Install-Apps -apps $appsScopeRequired -source "winget" -scope "machine" -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonBaseApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonBaseApps)

#optional Apps
$buttonOptionalApps = New-Object "System.Windows.Forms.Button"
$buttonOptionalApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonOptionalApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonOptionalApps.Text = "Optional Apps"
$buttonOptionalApps.Add_Click({ 
    $subProgressBar.Value = 1 
    $appsCount = $optionalApps.Count
    $textBox.AppendText("Installing $appsCount apps...`r`n")
    Install-Apps -apps $optionalApps -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonOptionalApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonOptionalApps)

#optional with complications Apps
$buttonOptionalComplicationsApps = New-Object "System.Windows.Forms.Button"
$buttonOptionalComplicationsApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonOptionalComplicationsApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonOptionalComplicationsApps.Text = "Optional+"
$buttonOptionalComplicationsApps.Add_Click({ 
    $subProgressBar.Value = 1 
    $appsCount = $optionalAppsWithComplications.Count
    $textBox.AppendText("Installing $appsCount apps...`r`n")
    Install-Apps -apps $optionalAppsWithComplications -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonOptionalComplicationsApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonOptionalComplicationsApps)

#developer Apps
$buttonDeveloperApps = New-Object "System.Windows.Forms.Button"
$buttonDeveloperApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonDeveloperApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonDeveloperApps.Text = "Developer Apps"
$buttonDeveloperApps.Add_Click({ 
    $subProgressBar.Value = 1 
    $appsCount = $devApps.Count
    $textBox.AppendText("Installing $appsCount apps...`r`n")
    Install-Apps -apps $devApps -source "winget" -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonDeveloperApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonDeveloperApps)

#uninstall Apps
$buttonUninstallApps = New-Object "System.Windows.Forms.Button"
$buttonUninstallApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonUninstallApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonUninstallApps.Text = "Uninstall Apps"
$buttonUninstallApps.Add_Click({ 
    $subProgressBar.Value = 1 
    $appsCount = $appsToRemove.Count
    $textBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $appsToRemove -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonUninstallApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonUninstallApps)

#uninstall Dell Apps
$buttonUninstallDellApps = New-Object "System.Windows.Forms.Button"
$buttonUninstallDellApps.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonUninstallDellApps.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonUninstallDellApps.Text = "Dell Uninstalls"
$buttonUninstallDellApps.Add_Click({ 
    $subProgressBar.Value = 1 
    $appsCount = $dellAppsToRemove.Count
    $textBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $dellAppsToRemove -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus
    $buttonUninstallDellApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonUninstallDellApps)

#Align power seetings
$buttonPowerSettings = New-Object "System.Windows.Forms.Button"
$buttonPowerSettings.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonPowerSettings.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonPowerSettings.Text = "Power Settings"
$buttonPowerSettings.Add_Click({ 
    $subProgressBar.Value = 1 
    $textBox.AppendText("Adjusting power settings...`r`n")
    powerSetup
    $buttonPowerSettings.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
})
$location.X += $buttonX
$main_form.Controls.Add($buttonPowerSettings)

$location.X = 10
$location.Y += $buttonY
# buttons -----

#Run Batch
$buttonPowerSettings = New-Object "System.Windows.Forms.Button"
$buttonPowerSettings.Location = New-Object System.Drawing.Point($location.X, $location.Y)
$buttonPowerSettings.Size = New-Object System.Drawing.Size($buttonX, 20)
$buttonPowerSettings.Text = "Do it!"
$buttonPowerSettings.Add_Click({ 
    $textBox.AppendText("Running batch...`r`n")
    #sanity checks
    $textBox.AppendText("Invoking Sanity Checks`r`n")
    Invoke-Sanity-Checks -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonSanity.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
    #base updates
    $textBox.AppendText("Invoking Base Updates`r`n")
    Invoke-Base-Updates -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonUBase.Enabled = $false
    $textBox.AppendText("Done")
    $overallProgressBar.Value += 10
    #Installing base apps
    $appsCount = $apps.Count + $appsScopeRequired.Count + $appThatNeedWingetSourceDeclared.Count
    $textBox.AppendText("Installing $appsCount apps...`r`n")
    Install-Apps -apps $apps -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $subProgressBar.Value = 1 
    Install-Apps -apps $appThatNeedWingetSourceDeclared -source "winget" -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $subProgressBar.Value = 1 
    Install-Apps -apps $appsScopeRequired -source "winget" -scope "machine" -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonBaseApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
    #uninstall apps
    $appsCount = $appsToRemove.Count
    $textBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $appsToRemove -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus -timerLabel $timerLabel
    $buttonUninstallApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
    #uninstall dell apps
    $appsCount = $dellAppsToRemove.Count
    $textBox.AppendText("Uninstalling $appsCount apps...`r`n")
    Uninstall-Apps -apps $dellAppsToRemove -textBox $textBox -subProgressBar $subProgressBar -subProgressBarStatus $subProgressBarStatus
    $buttonUninstallDellApps.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10
    #power settings
    $textBox.AppendText("Adjusting power settings...`r`n")
    powerSetup
    $buttonPowerSettings.Enabled = $false
    $subProgressBarStatus.Text = "Done"
    $textBox.AppendText("Done`r`n")
    $overallProgressBar.Value += 10

    $buttonPowerSettings.Enabled = $false
    $subProgressBarStatus.Text = "Batch Done"
    $textBox.AppendText("Batch Done`r`n")
    $overallProgressBar.Value = 100
})
$location.X += $buttonX
$main_form.Controls.Add($buttonPowerSettings)

$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.Location = New-Object Drawing.Point($location.X,$location.Y)
$timerLabel.Size = New-Object Drawing.Size(100,20)
$timerLabel.Text = "~"
$main_form.Controls.Add($timerLabel)

$main_form.ShowDialog()
