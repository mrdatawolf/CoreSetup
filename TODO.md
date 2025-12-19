# CoreSetup - TODO List

## High Priority

### GUI Dashboard Implementation
**Status:** Planned
**Priority:** High
**Estimated Complexity:** High

#### Description
Create a graphical user interface (GUI) dashboard for the CoreSetup script that provides a user-friendly way to select and execute operations without using command-line parameters.

#### Requirements

##### 1. Dashboard Interface
- [ ] Modern, clean UI design
- [ ] Checkbox-based operation selection
- [ ] Real-time progress indicators
- [ ] Operation status display (pending, running, completed, failed)
- [ ] Summary section showing completed operations

##### 2. Features
- [ ] Select multiple operations to run in sequence
- [ ] Show operation descriptions/tooltips
- [ ] Display system information (OS version, PowerShell version, winget status)
- [ ] Pre-flight checks (admin rights, PowerShell 7+, not Windows Home)
- [ ] Run button to execute selected operations
- [ ] Cancel/Stop button for running operations
- [ ] Log viewer/console output display
- [ ] Save/load operation profiles (common combinations)

##### 3. Operation Categories
Group operations logically in the GUI:

**Application Management**
- [ ] Install Base Apps
- [ ] Install Optional Apps
- [ ] Install Office 365
- [ ] Install Dev Apps
- [ ] Run Updates

**Bloatware Removal**
- [ ] Uninstall Windows Apps
- [ ] Uninstall Dell Apps
- [ ] Uninstall HP Apps
- [ ] Uninstall Lenovo Apps
- [ ] Remove New Outlook

**System Configuration**
- [ ] Adjust Power Settings
- [ ] Enable Public Discovery
- [ ] Enable Remote Desktop
- [ ] Disable WiFi and Bluetooth

##### 4. Technical Implementation Options

**Option A: Windows Forms (WinForms)**
```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
```
- ✓ Native to Windows
- ✓ No additional dependencies
- ✓ Well-documented
- ✗ Older technology
- ✗ Less modern UI

**Option B: Windows Presentation Foundation (WPF)**
```powershell
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
```
- ✓ Modern UI capabilities
- ✓ Better styling with XAML
- ✓ Native to Windows
- ✗ Steeper learning curve
- ✗ More complex code

**Option C: Web-based (HTML/CSS/JavaScript with local server)**
```powershell
# Start local web server and open browser
```
- ✓ Modern, flexible UI
- ✓ Easy to style
- ✗ Requires running web server
- ✗ More complex architecture
- ✗ Security considerations

**Option D: Separate GUI Application**
- Create standalone .exe that calls coreSetup.ps1
- Use C#, Python (tkinter/PyQt), or Electron
- ✗ Requires separate build process
- ✗ More complex distribution

**Recommended:** Start with WinForms for simplicity, migrate to WPF if needed.

##### 5. File Structure

```
CoreSetup/
├── coreSetup.ps1           # Main script (existing)
├── coreSetupGUI.ps1        # GUI launcher script
├── gui/
│   ├── MainWindow.ps1      # Main window layout
│   ├── ProgressTracker.ps1 # Progress tracking component
│   ├── Logger.ps1          # Log viewer component
│   └── Profiles.ps1        # Profile management
├── README.md
├── ARCHITECTURE.md
└── TODO.md
```

##### 6. GUI Features Breakdown

**Main Window Components:**
- Title bar with branding and version
- System status panel (top)
  - OS version
  - PowerShell version
  - Admin status
  - Winget status
- Operation selection panel (left/center)
  - Grouped checkboxes
  - Select All / Deselect All buttons
  - Load Profile dropdown
- Action panel (bottom)
  - Run Selected Operations button
  - Cancel button
  - Save as Profile button
- Progress panel (right)
  - Current operation display
  - Progress bar
  - Log output scrollable text box
  - Operation count (X of Y completed)

**User Flow:**
1. Launch GUI (double-click or run `.\coreSetupGUI.ps1`)
2. GUI performs pre-flight checks
   - Verifies admin rights
   - Checks PowerShell 7+
   - Verifies not Windows Home
   - Checks winget availability
3. User selects operations via checkboxes
4. (Optional) User saves selection as profile
5. User clicks "Run Selected Operations"
6. GUI executes operations sequentially
7. Progress updates in real-time
8. Summary displayed on completion
9. User can close or run more operations

##### 7. Profile System
Allow users to save common operation combinations:

**Example Profiles:**
- "New Computer Setup" (Base apps + Uninstall Windows apps + Power settings)
- "Developer Setup" (Dev apps + Base apps + Power settings)
- "Office Setup" (Base apps + Office 365 + Optional apps)
- "Cleanup Only" (Uninstall all bloatware)

**Profile Storage:**
- JSON or XML file in user's profile directory
- Include profile name and selected operations
- Allow import/export for sharing

##### 8. Error Handling
- [ ] Display clear error messages in dialog boxes
- [ ] Log all errors to log viewer
- [ ] Allow continuing after non-critical errors
- [ ] Provide "Retry" option for failed operations

##### 9. Accessibility
- [ ] Keyboard navigation support
- [ ] Screen reader friendly labels
- [ ] High contrast mode support
- [ ] Tooltips for all operations

##### 10. Testing Requirements
- [ ] Test on Windows 10 Pro
- [ ] Test on Windows 11 Pro
- [ ] Test with different screen resolutions
- [ ] Test with high DPI displays
- [ ] Test all operation combinations
- [ ] Test profile save/load
- [ ] Test error scenarios

#### Implementation Phases

**Phase 1: Basic GUI (MVP)**
- Simple WinForms window
- Checkboxes for all operations
- Run button
- Basic progress display
- Call coreSetup.ps1 with appropriate parameters

**Phase 2: Enhanced UX**
- Better visual design
- Real-time log viewer
- Progress bars
- Status icons

**Phase 3: Advanced Features**
- Profile save/load
- Operation categories/grouping
- Pre-flight checks display
- Advanced logging

**Phase 4: Polish**
- Error handling improvements
- Accessibility features
- Help documentation
- About dialog

#### Code Example: Basic WinForms Structure

```powershell
# coreSetupGUI.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CoreSetup Dashboard"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"

# Create checkboxes for each operation
$y = 20
$operations = @{
    "InstallBaseApps" = "Install Base Applications"
    "InstallOptionalApps" = "Install Optional Applications"
    "InstallDevApps" = "Install Developer Applications"
    # ... more operations
}

$checkboxes = @{}
foreach ($op in $operations.GetEnumerator()) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Location = New-Object System.Drawing.Point(20, $y)
    $checkbox.Size = New-Object System.Drawing.Size(400, 20)
    $checkbox.Text = $op.Value
    $checkbox.Name = $op.Key
    $form.Controls.Add($checkbox)
    $checkboxes[$op.Key] = $checkbox
    $y += 25
}

# Create Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Location = New-Object System.Drawing.Point(20, $y + 20)
$runButton.Size = New-Object System.Drawing.Size(120, 30)
$runButton.Text = "Run Selected"
$runButton.Add_Click({
    # Build parameter string
    $params = @()
    foreach ($cb in $checkboxes.GetEnumerator()) {
        if ($cb.Value.Checked) {
            $params += "-$($cb.Key)"
        }
    }

    if ($params.Count -gt 0) {
        # Execute coreSetup.ps1 with selected parameters
        $scriptPath = Join-Path $PSScriptRoot "coreSetup.ps1"
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" $($params -join ' ')" -Verb RunAs
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one operation.", "No Operations Selected")
    }
})
$form.Controls.Add($runButton)

# Show form
$form.ShowDialog()
```

---

## Medium Priority

### Additional Features
- [ ] Configuration file support (allow custom app lists)
- [ ] Logging to file (save all operations to a log file)
- [ ] Rollback functionality (undo operations if possible)
- [ ] Remote execution (run on remote computers via WinRM)
- [ ] Report generation (PDF/HTML summary of operations)
- [ ] Scheduled execution (schedule operations for later)

---

## Low Priority

### Quality of Life Improvements
- [ ] Add verbose mode for detailed output
- [ ] Add quiet mode for minimal output
- [ ] Add dry-run mode (show what would be done without doing it)
- [ ] Add confirmation prompts for destructive operations
- [ ] Color-coded console output (requires PSWriteColor or similar)

---

## Documentation

- [ ] Create video tutorial for using the script
- [ ] Create FAQ document
- [ ] Add troubleshooting guide
- [ ] Document common use cases
- [ ] Create changelog for version tracking

---

## Testing & Quality

- [ ] Add Pester tests for functions
- [ ] Create test suite for different Windows versions
- [ ] Add integration tests
- [ ] Set up CI/CD pipeline (GitHub Actions)
- [ ] Code signing for production releases

---

## Community

- [ ] Set up issue templates on GitHub
- [ ] Create contribution guidelines
- [ ] Add code of conduct
- [ ] Create Discord/discussion forum for support

---

## Notes

- GUI dashboard is the highest priority item
- Consider user feedback before implementing advanced features
- Keep the single-file script simple; move complexity to GUI layer
- Maintain backward compatibility with CLI usage
