# CoreSetup
Uses winget to uninstall apps we don't want on systems.
Also uses winget to installs various apps we want.
Also updates applications if we want.
Also allows us to set default power options.
Get the latest version at https://github.com/mrdatawolf/CoreSetup

**Because it's a powershell script you need to allow it to run on your system.  If you don't know what this means then DO NOT USE this script.**
**Fully run the Windows and Dell updates before this!!!!! It needs the Windows updates to be done and Dell apps will be removed.**
**Open a powershell prompt and type winget list.  Answer yes.**

From (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.4):
To run an unsigned script, use the Unblock-File cmdlet or use the following procedure.

    1. Save the script file on your computer.
    2. Click Start, click My Computer, and locate the saved script file.
    3. Right-click the script file, and then click Properties.
    4. Click Unblock.

These are other ways to allow scripts...
Win10 - Set-ExecutionPolicy Unrestricted
Win11 - Set-ExecutionPolicy -Scope CurrentUser Unrestricted

# common solutions for first runs
If it fails saying scripts can't be run:
set-executionpolicy remotesigned 
then Y when it asks how to change it.
If it is just sitting on the winget update task press y and enter.  It is acutally asking if you agree to the souce agreement terms. if you want to actually see the original prompt open a powershell window and do winget list instead.
