# BTWinGet
Uses winget to uninstall apps we don't want on systems.
Also uses winget to installs various apps we want.
Also updates applications if we want
Get the latest version at https://github.com/mrdatawolf/BTWinGet

Because it's a powershell script you need to allow unsigned scripts to run on your system.  If you don't know what this means then DO NOT USE this script.

These might help...
Win10 - Set-ExecutionPolicy Unrestricted
Win11 - Set-ExecutionPolicy -Scope CurrentUser Unrestricted

and this might be even better (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.4):
To run an unsigned script, use the Unblock-File cmdlet or use the following procedure.

    Save the script file on your computer.
    Click Start, click My Computer, and locate the saved script file.
    Right-click the script file, and then click Properties.
    Click Unblock.
