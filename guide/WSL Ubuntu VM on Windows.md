
# OpenCore and UEFI Secure Boot with WSL

<table>
 <tr><td><b>This guide proposes the implementation of UEFI Secure Boot in OpenCore from Windows 11 with Windows Subsystem for Linux, so the installation and configuration of a complete Linux system is not necessary. Some knowledge of basic Linux commands is still recommended, but less time and effort is required</b></tr></td>
</table>

## Preface
 
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

## Installing WSL from Microsoft Store

You can install WSL with Ubuntu from the Microsoft Store with the advantage that it is installed for all users, whereas from PowerShell it is installed only for the current user and requires some tasks to be executed as administrator.

*Note*: In the Microsoft Store there are other Linux distributions available to install with WSL, it is even possible to have more than one and they can be managed with the WSL Manager app.

## Installing WSL from command line

Open PowerShell as Administrator >> run `wsl --install` command:

```
PS C:/Users/me> wsl --install
Installing: Virtual Machine Platform
Virtual Machine Platform has been installed.
Installing: Windows Subsystem for Linux
Windows Subsystem for Linux has been installed.
Downloading: WSL Kernel
Installing: WSL Kernel
WSL Kernel has been installed.
Downloading: GUI App Technical Support
Installing: GUI application technical support
GUI Application Support has been installed.
Downloading: Ubuntu
The requested operation was successful. The changes will take effect after the system reboots.
```
## First use of WSL

It requests username and password (they are not related to the ones you use in Windows). This will be the default account and will automatically log into the home folder. It is an administrator account and can run commands with sudo.

WSL boots from the Ubuntu icon in the application menu or by typing ubuntu in the command line window. A Bash Terminal window is shown with the prompt in our user folder.

Windows disks are accessible in the path */mnt/c*, */mnt/d* and so on. The Linux system is accessible from Windows Explorer >> Linux. It is not recommended to modify Ubuntu elements from Windows Explorer, it is preferable to do it from within WSL.\
If at any time you forget the Linux password >> open PowerShell >> `wsl -u root` (open Ubuntu in the Windows user's directory) >> `passwd <user>` >> request a new password >> exit.

## Installing the tools

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

## Creating the keys to shove into the firmware and sign OpenCore

Create a working dir:

```shell
mkdir ~/efikeys
cd efikeys
```

Create PK (Platform Key):

```shell
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=NAME PK Platform Key/" -keyout PK.key -out PK.pem
```

Create KEK (Key Exchange Key):

```shell
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=NAME KEK Exchange Key/" -keyout KEK.key -out KEK.pem
```

Create ISK (Initial Supplier Key):

```shell
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=NAME ISK Image Signing Key/" -keyout ISK.key -out ISK.pem
```

Note: replace NAME with something characteristic that helps you to recognise the keys when you view them from the UEFI menu, for example KEYS2021.

Permissions for key files:

```shell
chmod 0600 *.key
```

Download Microsoft certificates:

- [Microsoft Windows Production CA 2011](http://go.microsoft.com/fwlink/?LinkID=321192)
- [Microsoft UEFI driver signing CA key](http://go.microsoft.com/fwlink/?LinkId=321194)

Copy Windows certificates to the working folder:

```shell
cp /mnt/c/Users/me/Downloads/MicCorUEFCA2011_2011-06-27.crt ~/efikeys/
cp /mnt/c/Users/me/Downloads/MicWinProPCA2011_2011-10-19.crt ~/efikeys/
```

Digitally sign Microsoft certificates:

```shell
openssl x509 -in MicWinProPCA2011_2011-10-19.crt -inform DER -out MicWinProPCA2011_2011-10-19.pem -outform PEM
openssl x509 -in MicCorUEFCA2011_2011-06-27.crt -inform DER -out MicCorUEFCA2011_2011-06-27.pem -outform PEM
```

Convert PEM files to ESL format suitable for UEFI Secure Boot:

```shell
cert-to-efi-sig-list -g $(uuidgen) PK.pem PK.esl
cert-to-efi-sig-list -g $(uuidgen) KEK.pem KEK.esl
cert-to-efi-sig-list -g $(uuidgen) ISK.pem ISK.esl
cert-to-efi-sig-list -g $(uuidgen) MicWinProPCA2011_2011-10-19.pem MicWinProPCA2011_2011-10-19.esl
cert-to-efi-sig-list -g $(uuidgen) MicCorUEFCA2011_2011-06-27.pem MicCorUEFCA2011_2011-06-27.esl
```

Create the database including the signed Microsoft certificates:

```shell
cat ISK.esl MicWinProPCA2011_2011-10-19.esl MicCorUEFCA2011_2011-06-27.esl > db.esl
```

Digitally sign ESL files:

```shell
# PK signs with herself
sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth

# KEK is signed with PK
sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth

# the database is signed with KEK
sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth
```

What to do with PK.auth, kek.auth, db.auth, ISK.key and ISK.pem?
- .auth files (PK.auth, kek.auth and db.auth) will be used to integrate our signatures into the firmware. Copy these files to a folder outside Ubuntu so that they are accessible from Windows
- ISK.key and ISK.pem files will be used to sign OpenCore files.

## Signing OpenCore files

Files with .efi extension must be signed: OpenCore.efi, BOOTx64.efi, Drivers and Tools.

Create working directory:

```
mkdir oc
```

Copy ISK.key and ISK.pem to the oc folder:

```
cp ISK.key ISK.pem oc
cd oc
```

User *profzei* has a script *sign_opencore.sh* (based on a previous one by Roderick W. Smith) that automates this process: create required folders, download and unzip OpenCore current version (0.8.7 at the time of writing), download HFSPlus.efi, check ISK keys, digitally sign files and copy them to the Signed/Downloaded folder. The script must be in the oc folder next to ISK.key and ISK.pem. It is slightly modified by me to suit my needs. You can also modify it to your liking. 

Copy this code on a text editor and save it into the oc folder with the name *sign_opencore.sh*.

```bash
#!/bin/bash
# Copyright (c) 2021 by profzei
# Licensed under the terms of the GPL v3

LINK=$1
# https://github.com/acidanthera/OpenCorePkg/releases/download/0.8.7/OpenCore-0.8.7-RELEASE.zip
VERSION=$2
# 0.8.7

# Download and unzip OpenCore
wget $LINK
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Downloaded"
rm "OpenCore-${VERSION}-RELEASE.zip"

# Download HfsPlus
wget https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Downloaded/X64/EFI/OC/Drivers/HfsPlus.efi

if [ -f "./ISK.key" ]; then
    echo "ISK.key was decrypted successfully"
fi

if [ -f "./ISK.pem" ]; then
    echo "ISK.pem was decrypted successfully"
fi

# Sign drivers by recursively looking for the .efi files in ./Downloaded directory
# Don't sign files that start with the dot, as this is metadata files
# Andrew Blitss's contribution
find ./Downloaded/X64/EFI/**/* -type f -name "*.efi" ! -name '.*' | cut -c 3- | xargs -I{} bash -c 'sbsign --key ISK.key --cert ISK.pem --output $(mkdir -p $(dirname "./Signed/{}") | echo "./Signed/{}") ./{}'

# Clean
rm -rf Downloaded
echo "Cleaned..."
```

This script needs 2 parameters to be run: OpenCore download site and version number. For example, with version 0.8.7 (current):

```
sh ./sign_opencore.sh https://github.com/acidanthera/OpenCorePkg/releases/download/0.8.7/OpenCore-0.8.7-RELEASE.zip 0.8.7
```

At the end we have in the Signed/Downloaded folder the .efi files digitally signed with our own keys.

```bash
/Users/yo/Desktop/oc2/Signed > tree -A
.
└── Downloaded
    └── X64
        └── EFI
            ├── BOOT
            │   └── BOOTx64.efi
            └── OC
                ├── Drivers
                │   ├── ArpDxe.efi
                │   ├── AudioDxe.efi
                │   ├── BiosVideo.efi
                │   ├── CrScreenshotDxe.efi
                │   ├── Dhcp4Dxe.efi
                │   ├── DnsDxe.efi
                │   ├── DpcDxe.efi
                │   ├── Ext4Dxe.efi
                │   ├── Ext4Dxe.efi
                │   ├── HfsPlus.efi
                │   ├── HttpBootDxe.efi
                │   ├── HttpDxe.efi
                │   ├── HttpUtilitiesDxe.efi
                │   ├── Ip4Dxe.efi
                │   ├── MnpDxe.efi
                │   ├── NvmExpressDxe.efi
                │   ├── OpenCanopy.efi
                │   ├── OpenHfsPlus.efi
                │   ├── OpenLinuxBoot.efi
                │   ├── OpenNtfsDxe.efi
                │   ├── OpenPartitionDxe.efi
                │   ├── OpenRuntime.efi
                │   ├── OpenUsbKbDxe.efi
                │   ├── OpenVariableRuntimeDxe.efi
                │   ├── Ps2KeyboardDxe.efi
                │   ├── Ps2MouseDxe.efi
                │   ├── ResetNvramEntry.efi
                │   ├── SnpDxe.efi
                │   ├── TcpDxe.efi
                │   ├── ToggleSipEntry.efi
                │   ├── Udp4Dxe.efi
                │   ├── UsbMouseDxe.efi
                │   └── XhciDxe.efi
                ├── OpenCore.efi
                └── Tools
                    ├── BootKicker.efi
                    ├── CleanNvram.efi
                    ├── ControlMsrE2.efi
                    ├── CsrUtil.efi
                    ├── ChipTune.efi
                    ├── GopStop.efi
                    ├── KeyTester.efi
                    ├── MmapDump.efi
                    ├── OpenControl.efi
                    ├── OpenShell.efi
                    ├── ResetSystem.efi
                    ├── RtcRw.efi
                    └── TpmInfo.efi

7 directories, 47 files
```

Copy the Signed/Downloaded folder to a place outside Ubuntu that is accessible from Windows and/or macOS to put the signed files into the OpenCore EFI folder, replacing the ones with the same name.
