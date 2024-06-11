# CoreSetup
[Download coreSetup EXE version here](https://github.com/mrdatawolf/CoreSetup/raw/main/coreSetupGUI.exe)

**Right-click here and select "Save link as..." to download the script.**

[Download coreSetup PS1 version here](https://github.com/mrdatawolf/CoreSetup/raw/main/coreSetup.ps1)

[Download coreUpdate PS1 here](https://github.com/mrdatawolf/CoreSetup/raw/main/coreUpdate.ps1)


Uses winget to uninstall apps we don't want on systems.
Also uses winget to installs various apps we want.
Also updates applications if we want.
Also allows us to set default power options.
Get the latest version at https://github.com/mrdatawolf/CoreSetup

**Because it's a powershell script you need to allow it to run on your system.  If you don't know what this means then DO NOT USE this script.**
**Fully run the Windows and Dell updates before this!!!!!** 
**It needs the Windows updates to be done and Dell apps will be removed.**
**To minimize issues - Open a powershell prompt first and type winget list.  Answer yes.**

## Common solutions for first runs
### If it fails saying scripts can't be run:
set-executionpolicy remotesigned 
then Y when it asks how to change it.
### If it is just sitting on the winget update task 
press y and enter.  It is acutally asking if you agree to the souce agreement terms. if you want to actually see the original prompt open a powershell window and do winget list instead.
### If it closes right away or you see a ExecutionPolicy error
1. Win10
* Set-ExecutionPolicy Unrestricted
2. Win11
* Set-ExecutionPolicy -Scope CurrentUser Unrestricted

## You can also try
From (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_signing?view=powershell-7.4):
To run an unsigned script, use the Unblock-File cmdlet or use the following procedure.
1. Save the script file on your computer.
2. Click Start, click My Computer, and locate the saved script file.
3. Right-click the script file, and then click Properties.
4. Click Unblock. 
