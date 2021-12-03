# OpenCore and UEFI Secure Boot with Windows Subsystem for Linux
This guide proposes the activation of UEFI Secure Boot in OpenCore from a Windows 11 with Windows Subsystem for Linux, so the installation and configuration of a complete Linux system is not necessary. Some knowledge of basic Linux commands is still required, but less time and effort is required.
 
**1. Preface**
 
Motherboard UEFI firmware has Secure Boot capability so that only digitally signed boot loader files with keys that are embedded in the firmware are allowed. With UEFI Secure Boot enabled:

- Windows can boot as the firmware includes Microsoft certificates (sometimes also certificates from the motherboard manufacturer)
- macOS cannot boot; a Linux system is necessary to generate the keys and sign OpenCore files with them, this is the reason why we currently run OpenCore and macOS with UEFI Secure Boot disabled.

This text is based on the guides by:

- *khronokernel* [UEFI Secure Boot](https://github.com/dortania/OpenCore-Post-Install/blob/c0e7f282975f7d6224878b71648c27ce0ed304e6/universal/security/uefisecureboot.md)
- *profzei* [Enable BIOS Secure Boot with OpenCore](https://github.com/profzei/Matebook-X-Pro-2018/wiki/Enable-BIOS-Secure-Boot-with-OpenCore)
- *sakaki* [Sakaki's EFI Install Guide/Configuring Secure Boot](https://wiki.gentoo.org/wiki/User:Sakaki/Sakaki's_EFI_Install_Guide/Configuring_Secure_Boot)
- *Ubuntu* [How to sign things for Secure Boot](https://ubuntu.com/blog/how-to-sign-things-for-secure-boot)

*sakaki* and *Ubuntu* discuss how to boot Linux with UEFI Secure Boot enabled but *khronokernel* and *profzei* refer specifically to OpenCore and macOS. The 4 guides agree on the need to do it from a Linux system since the required tools do not exist for macOS. The Linux system required to sign OpenCore files can be a significant inconvenience because of the work involved in installing and configuring it (either on a separate disk or in a virtual machine). Once in Linux, everything is done from Terminal so much of the installed system is not really necessary.\
This task can be simplified thanks to a not widely used infrastructure that exists in Windows 10 (build 18917 or later) and Windows 11: Windows Subsystem for Linux (WSL). We can boot a genuine Ubuntu image provided by Canonical. This makes possible to run commands natively in a Bash terminal within a Windows environment that behaves like Linux.

**Note**: in the issue number 1796 of the OpenCore bug tracker "Support UEFI SecureBoot within OpenCore" vit9696 comments about developing a simpler method of doing this, probably from within OpenCore and macOS and without the need to integrate the keys into the UEFI signature, but it is something that does not have high priority so we have to wait for updates.

**2. Installing WSL from command line**

Open PowerShell as Administrator >> run `wsl --install` command:\
`PS C: /Users/me> wsl --install`\
`Installing: Virtual Machine Platform`\
`Virtual Machine Platform has been installed.`\
`Installing: Windows Subsystem for Linux`\
`Windows Subsystem for Linux has been installed.`\
`Downloading: WSL Kernel`\
`Installing: WSL Kernel`\
`WSL Kernel has been installed.`\
`Downloading: GUI App Technical Support`\
`Installing: GUI application technical support`\
`GUI Application Support has been installed.`\
`Downloading: Ubuntu`\
`The requested operation was successful. The changes will take effect after the system reboots.`

At the end, it requests username and password (they are not related to the ones you use in Windows). This will be the default account and will automatically log into the home folder. It is an administrator account and can run commands with sudo.\
WSL boots from the Ubuntu icon in the application menu or by typing ubuntu in the command line window. A Bash Terminal window is shown with the prompt in our user folder.\
Windows disks are accessible in the path */mnt/c*, */mnt/d* and so on. The Linux system is accessible from Windows Explorer >> Linux. It is not recommended to modify Ubuntu elements from Windows Explorer, it is preferable to do it from within WSL.
If at any time you forget the Linux password >> open PowerShell >> `wsl -u root` (open Ubuntu in the Windows user's directory) >> `passwd <user>` >> request a new password >> exit.

**3. Installing the tools**

In the Ubuntu Terminal window:

`sudo apt update && sudo apt upgrade`\
(to update repositories of installation packages)\
`sudo apt-get install unzip`\
(unzip is not installed by default with WSL Ubuntu, zip utility is already installed)\
`sudo apt-get install sbsigntool`\
(digital signature utility for UEFI Secure Boot)\
`sudo apt-get install efitools`\
(tools to manage UEFI Secure Boot variables).

Openssl tool is also required but it is already installed on Ubuntu.
 
If we want to see the utilities already installed in Ubuntu we can use the command
`sudo apt list --installed`.

**_Creating the keys to shove into the firmware and sign OpenCore_**

Create a working dir:\
`mkdir efykeys
cd efykeys`

Create PK (Platform Key):\
`openssl req -new -x509 -newkey rsa: 2048 -sha256 -days 3650 -nodes -subj "/ CN = NAME PK Platform Key /" -keyout PK.key -out PK.pem`

Create KEK (Key Exchange Key):\
`openssl req -new -x509 -newkey rsa: 2048 -sha256 -days 3650 -nodes -subj "/ CN = NAME KEK Exchange Key /" -keyout KEK.key -out KEK.pem`

Create ISK (Initial Supplier Key):\
`openssl req -new -x509 -newkey rsa: 2048 -sha256 -days 3650 -nodes -subj "/ CN = NAME ISK Image Signing Key /" -keyout ISK.key -out ISK.pem`

Note: replace NAME with something characteristic that helps you to recognise the keys when you view them from the UEFI menu, for example KEYS2021.

Correct permissions for key files:\
`chmod 0600 * .key`

Download Microsoft certificates:\
[Microsoft Windows Production CA 2011](http://go.microsoft.com/fwlink/?LinkID=321192)\
[Microsoft UEFI driver signing CA key](http://go.microsoft.com/fwlink/?LinkId=321194)

Copy Windows certificates to the working folder:\
`cp /mnt/c/Users/me/Downloads/MicCorUEFCA2011_2011-06-27.crt/home/me/efikeys/cp /mnt/c/Users/me/Downloads/MicWinProPCA2011_2011-10-19.crt/home/yo/efikeys/`

Digitally sign Microsoft certificates:\
`openssl x509 -in MicWinProPCA2011_2011-10-19.crt -inform DER -out MicWinProPCA2011_2011-10-19.pem -outform PEM
openssl x509 -in MicCorUEFCA2011_2011-06-27.crt -inform DER -out MicCorUEFCA2011_2011-06-27.pem -outform PEM`

Convert PEM files to ESL format suitable for UEFI Secure Boot:\
`cert-to-efi-sig-list -g $ (uuidgen) PK.pem PK.esl\
cert-to-efi-sig-list -g $ (uuidgen) KEK.pem KEK.esl\
cert-to-efi-sig-list -g $ (uuidgen) ISK.pem ISK.esl\
cert-to-efi-sig-list -g $ (uuidgen) MicWinProPCA2011_2011-10-19.pem MicWinProPCA2011_2011-10-19.esl\
cert-to-efi-sig-list -g $ (uuidgen) MicCorUEFCA2011_2011-06-27.pem MicCorUEFCA2011_2011-06-27.esl`

Create the database including the signed Microsoft certificates:\
`cat ISK.esl MicWinProPCA2011_2011-10-19.esl MicCorUEFCA2011_2011-06-27.esl> db.esl`

Digitally sign ESL files:\
(PK signs with herself)\
`sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth\
Timestamp is 2021-11-2 00:05:40\
Authentication Payload size 887\
Signature of size 1221\
Signature at: 40`\
(KEK is signed with PK)\
`sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth\
Timestamp is 2021-11-2 00:05:47\
Authentication Payload size 891\
Signature of size 1221\
Signature at: 40`\
(the database is signed with KEK).\
`sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth\
Timestamp is 2021-11-2 00:05:52\
Authentication Payload size 4042\
Signature of size 1224\
Signature at: 40`\

The .auth files (PK.auth, kek.auth and db.auth) will be used to integrate our signatures into the firmware. Copy these files to a folder outside Ubuntu so that they are accessible from Windows. The ISK.key and ISK.pem files will be used to sign OpenCore files.

**4. Signing OpenCore files**

Files with .efi extension must be signed: OpenCore.efi, BOOTx64.efi, Drivers and Tools.

Create working directory:\
`mkdir oc`

Copy ISK.key and ISK.pem to the oc folder:\
`cp ISK.key ISK.pem oc\
cd oc`

User *profzei* has a script *sign_opencore.sh* that automates this process: create required folders, download and unzip OpenCore current version (0.7.5 at the time of writing), download HFSPlus.efi, check ISK keys, digitally sign files and copy them to the Signed folder. The script must be in the oc folder next to ISK.key and ISK.pem. It is slightly modified by me to suit my needs. You can also modify it to your liking. Check the drivers and tools that you use and modify the script in the signing files part to include those that are not currently included.\
Copy this [text](https://gist.github.com/perez987/1707f26b256a2bc849b4fc272de20280) into a text editor and save it with the name *sign_opencore.sh* (you can do it on Windows).

Copy it into the oc folder:\
`cp /mnt/c/Users/me/Downloads/sign_opencore.sh /home/me/efikeys/oc`

This script needs 2 parameters to be run: OpenCore download site and version number. For example, with version 0.7.5 (current):\
`sh ./sign_opencore.sh https://github.com/acidanthera/OpenCorePkg/releases/download/0.7.5/OpenCore-0.7.5-RELEASE.zip 0.7.5`

At the end we will have in the Signed folder the OpenCore .efi files digitally signed with our own keys. Copy the Signed folder to a folder (outside Ubuntu) that is accessible from Windows and/or macOS to put the signed files in the OpenCore EFI folder replacing the ones with the same name.
