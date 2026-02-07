
###################
Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig]
"BypassTPMCheck"=dword:00000001
"BypassSecureBootCheck"=dword:00000001
"BypassRAMCheck"=dword:00000001

###################
To install Windows 11 on older PCs, please follow the steps below:
1.	Un-Rar the attached file to a USB flash drive.
2.	Start the Windows 11 setup process.
3.	When the error message appears, press Shift + F10 to open the Command Prompt.
4.	In the CMD, type regedit and press Enter.
5.	In the Registry Editor, go to File → Import.
6.	Select the file from the USB flash drive named BypassTPMCheck.reg.
7.	Close the Registry Editor and the Command Prompt.
8.	on setup screen click Back then click Next to continue the installation.
Activate

irm https://get.activated.win | iex
