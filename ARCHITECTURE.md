# CoreSetup Architecture Documentation

## Purpose
This document serves as a reference for AI and developers when modifying or extending the CoreSetup PowerShell script. It explains the architecture, patterns, and conventions used throughout the codebase.

## Table of Contents
1. [Overview](#overview)
2. [File Structure](#file-structure)
3. [Script Architecture](#script-architecture)
4. [Parameter Pattern](#parameter-pattern)
5. [Function Conventions](#function-conventions)
6. [Execution Flow](#execution-flow)
7. [Visual Feedback System](#visual-feedback-system)
8. [Adding New Features](#adding-new-features)
9. [Error Handling](#error-handling)
10. [Testing Considerations](#testing-considerations)

---

## Overview

CoreSetup is a single-file PowerShell script (`coreSetup.ps1`) that automates common Windows computer configuration tasks. It handles:
- Application installation/uninstallation via winget
- System configuration (power settings, network discovery, remote desktop)
- Bloatware removal (Windows, Dell, HP, Lenovo)
- System updates

The script operates in two modes:
- **GUI Mode**: When called with parameters (e.g., from a GUI application)
- **CLI Mode**: Interactive mode when run without parameters

---

## File Structure

```
C:\Users\Public\Projects\GitHub\CoreSetup\
├── coreSetup.ps1          # Main script (single file application)
├── README.md              # User documentation
├── ARCHITECTURE.md        # This file (AI/developer reference)
└── .git/                  # Git repository
```

---

## Script Architecture

The script is organized into distinct sections:

### 1. Documentation Block (Lines 1-57)
```powershell
<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER <ParameterName>
.EXAMPLE
.NOTES
#>
```
- PowerShell comment-based help
- Every parameter must be documented here
- Examples show common usage patterns

### 2. Parameter Declaration (Lines 59-74)
```powershell
param(
    [switch]$ParameterName,
    ...
)
```
- All parameters use `[switch]` type (boolean flags)
- No default values needed for switches
- Order doesn't matter but keep alphabetically organized for maintenance

### 3. GUI Mode Detection (Lines 76-80)
```powershell
$guiMode = $Param1 -or $Param2 -or ... -or $ParamN
```
- Detects if any parameter was provided
- Controls whether script pauses at end (CLI mode only)
- Must include ALL parameters in the OR chain

### 4. Administrator Check (Lines 82-90)
- Verifies script is running with admin privileges
- GUI mode: Fails with error
- CLI mode: Auto-elevates and relaunches

### 5. Application Lists (Lines 92-183)
- Arrays of application IDs and names
- Organized by category
- Used by installation/uninstallation functions

### 6. Functions (Lines 185-401)
- Reusable function definitions
- Named in PascalCase (e.g., `PowerSetup`, `Install-Apps`)
- Self-contained operations

### 7. Main Execution (Lines 403-545)
- Sanity checks
- Conditional execution based on parameters
- Operation counter for summary
- Final summary output

---

## Parameter Pattern

### Declaration
All parameters follow this pattern:

```powershell
param(
    [switch]$ParameterName
)
```

### Documentation
Each parameter needs a documentation block:

```powershell
.PARAMETER ParameterName
Brief description of what this parameter does
```

### GUI Mode Integration
Add to the GUI mode detection:

```powershell
$guiMode = ... -or $ParameterName
```

### Execution Block
Add conditional execution in main section:

```powershell
if ($ParameterName) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "OPERATION NAME IN CAPS"
    Write-Output "========================================"
    FunctionName
    Write-Output ""
}
```

---

## Function Conventions

### Naming Conventions
- **PascalCase** for custom functions: `PowerSetup`, `DisableWiFiAndBluetooth`
- **Verb-Noun** for PowerShell-style functions: `Install-Apps`, `Uninstall-Apps`, `Invoke-Sanity-Checks`

### Function Categories

#### 1. Validation Functions
**Example:** `Invoke-Sanity-Checks` (Lines 186-203)
- Verify prerequisites
- Check PowerShell version
- Verify required tools (winget)
- Fail fast with clear error messages

#### 2. Installation Functions
**Example:** `Install-App` (Lines 205-222), `Install-Apps` (Lines 224-253)
- Handle single or multiple app installations
- Use winget with proper flags
- Support optional source and scope parameters
- Include progress tracking for arrays

#### 3. Uninstallation Functions
**Example:** `Uninstall-Apps` (Lines 255-283)
- Check if app exists before attempting removal
- Provide feedback on success/failure
- Gracefully handle apps that can't be removed

#### 4. Configuration Functions
**Example:** `PowerSetup` (Lines 293-309), `DoPublicDiscovery` (Lines 311-317)
- Modify system settings
- Use native PowerShell cmdlets or system utilities
- Provide step-by-step feedback

#### 5. Complex Operations
**Example:** `RemoveAndBlockNewOutlook` (Lines 328-361), `DisableWiFiAndBluetooth` (Lines 363-401)
- Combine multiple operations
- Include error handling with try/catch
- Check current state before making changes
- Provide detailed progress updates

### Function Structure Template

```powershell
function FunctionName {
    param (
        [Parameter(Mandatory = $true)]
        [type]$paramName
    )

    Write-Output "→ Starting operation..."

    Write-Output "  - Step 1..."
    # Command

    Write-Output "  - Step 2..."
    # Command

    Write-Output "✓ Operation completed"
}
```

---

## Execution Flow

```
1. Script Starts
   ↓
2. Documentation Parsed (for Get-Help)
   ↓
3. Parameters Captured
   ↓
4. GUI Mode Detected
   ↓
5. Administrator Check
   ├─→ Not Admin in GUI mode → Error & Exit
   └─→ Not Admin in CLI mode → Relaunch Elevated
   ↓
6. Welcome Message
   ↓
7. Sanity Checks (PowerShell version, winget)
   ↓
8. Update Winget Sources
   ↓
9. Conditional Operations (if parameter set)
   ├─→ Install Base Apps
   ├─→ Install Optional Apps
   ├─→ Install Office 365
   ├─→ Install Dev Apps
   ├─→ Uninstall Windows Apps
   ├─→ Uninstall Dell Apps
   ├─→ Uninstall HP Apps
   ├─→ Uninstall Lenovo Apps
   ├─→ Run Updates
   ├─→ Adjust Power Settings
   ├─→ Enable Public Discovery
   ├─→ Enable Remote Desktop
   ├─→ Remove New Outlook
   └─→ Disable WiFi and Bluetooth
   ↓
10. Summary (operations count)
    ↓
11. Pause (CLI mode only)
    ↓
12. Exit
```

---

## Visual Feedback System

The script uses consistent symbols for user feedback:

| Symbol | Meaning | Usage |
|--------|---------|-------|
| `→` | Arrow | Operation starting |
| `-` | Dash | Sub-step or detail |
| `✓` | Checkmark | Success |
| `✗` | X mark | Error/Failure |
| `~` | Tilde | Partial success |
| `⚠️` | Warning | Alert/Warning |

### Output Patterns

#### Operation Headers
```powershell
Write-Output "========================================"
Write-Output "OPERATION NAME IN CAPS"
Write-Output "========================================"
```

#### Operation Start
```powershell
Write-Output "→ Performing action..."
```

#### Sub-steps
```powershell
Write-Output "  - Sub-step description..."
```

#### Indented Sub-steps (for loops)
```powershell
Write-Output "    ✓ Individual item success"
```

#### Operation Complete
```powershell
Write-Output "✓ Operation completed successfully"
```

#### Progress Tracking (for arrays)
```powershell
$percentComplete = [Math]::Floor((($i + 1) / $total) * 100)
Write-Output "[$percentComplete%] Processing item..."
```

---

## Adding New Features

### Checklist for Adding a New Feature

#### 1. Add Parameter Documentation (Lines 1-57)
```powershell
.PARAMETER NewFeatureName
Description of what this feature does
```

#### 2. Add Parameter Declaration (Lines 59-74)
```powershell
[switch]$NewFeatureName
```

#### 3. Update GUI Mode Detection (Lines 76-80)
```powershell
$guiMode = ... -or $NewFeatureName
```

#### 4. Create Function (Before line 403)
```powershell
function DoNewFeature {
    Write-Output "→ Starting new feature..."

    # Implementation here

    Write-Output "✓ New feature completed"
}
```

#### 5. Add Execution Block (Lines 403-529)
Place in logical order, typically near similar operations:
```powershell
if ($NewFeatureName) {
    $operationsRun++
    Write-Output "========================================"
    Write-Output "NEW FEATURE NAME"
    Write-Output "========================================"
    DoNewFeature
    Write-Output ""
}
```

### Example: Adding WiFi/Bluetooth Disable Feature

This feature was added following the pattern above. See:
- Documentation: Line 47-48
- Parameter: Line 73
- GUI Mode: Line 80
- Function: Lines 363-401
- Execution: Lines 522-529

---

## Error Handling

### Sanity Checks
Always verify prerequisites before executing operations:
- PowerShell version compatibility
- Required tools availability (winget)
- Administrator privileges
- Windows edition compatibility

### Try/Catch Blocks
Use for operations that might fail:

```powershell
try {
    # Risky operation
    Set-ItemProperty -Path $path -Name $name -Value $value -ErrorAction Stop
    Write-Output "  ✓ Success"
} catch {
    Write-Output "  ✗ Failed: $_"
}
```

### Exit Codes
- `exit 0` - Success
- `exit 1` - Error/Failure

### Winget Error Handling
Check `$LASTEXITCODE` after winget commands:

```powershell
winget install $app --silent
if ($LASTEXITCODE -eq 0) {
    Write-Output "  ✓ Success"
} else {
    Write-Output "  ✗ Failed"
}
```

---

## Testing Considerations

### Manual Testing Checklist
- [ ] Test in GUI mode (with parameters)
- [ ] Test in CLI mode (interactive)
- [ ] Test without administrator privileges
- [ ] Test each new feature independently
- [ ] Test combination of multiple features
- [ ] Test on different Windows versions (10, 11)
- [ ] Test on different editions (Pro, Enterprise, Home if applicable)

### Common Issues
1. **Winget not available** - App Installer needs update from Microsoft Store
2. **Administrator privileges** - Script must run elevated
3. **PowerShell version** - Requires PowerShell 5+ (soon to be 7+)
4. **Network adapters** - Some systems may not have WiFi/Bluetooth
5. **Bloatware varies** - Different manufacturers have different pre-installed apps

---

## Key Technical Details

### Why Single File?
- Easy to distribute and execute
- No installation required
- Self-contained dependencies
- Simple version control

### Why Switches Instead of Boolean Parameters?
Switches in PowerShell are cleaner for CLI usage:
```powershell
# With switches (current pattern)
.\coreSetup.ps1 -InstallBaseApps -RunUpdates

# With boolean parameters (verbose, not used)
.\coreSetup.ps1 -InstallBaseApps:$true -RunUpdates:$true
```

### Winget Flags Explained
```powershell
--silent                          # No user interaction
--accept-package-agreements      # Auto-accept licenses
--accept-source-agreements       # Auto-accept source agreements
--disable-interactivity          # Prevent any prompts
--scope machine                  # Install for all users (requires admin)
-s msstore                       # Use Microsoft Store source
```

### Operations Counter
The `$operationsRun` variable tracks how many operations were executed:
- Increments for each operation performed
- Used in final summary
- Helps user understand what was done

---

## Future Enhancements

### Planned Features
- [ ] GUI Dashboard for visual operation selection
- [ ] Configuration file support (YAML/JSON)
- [ ] Logging to file
- [ ] Rollback functionality
- [ ] Remote execution capabilities
- [ ] Custom application lists per organization

### Architecture Improvements
- Consider breaking into modules if complexity grows
- Add unit tests for functions
- Implement configuration profiles
- Add verbose/debug logging modes

---

## Version History

- **Current**: Single-file PowerShell script
- **Branch**: main
- **Latest Feature**: Disable WiFi and Bluetooth adapters

---

## References

- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Winget Documentation](https://docs.microsoft.com/windows/package-manager/winget/)
- [Windows Adapter Management](https://docs.microsoft.com/powershell/module/netadapter/)

---

## Contributing

When adding new features:
1. Follow existing patterns and conventions
2. Update this ARCHITECTURE.md document
3. Test in both GUI and CLI modes
4. Document parameters in help section
5. Use consistent visual feedback symbols
6. Handle errors gracefully
7. Update README.md with user-facing changes

---

## Contact

Repository: https://github.com/mrdatawolf/CoreSetup
Author: Patrick Moon - 2024
