# OpenCore and UEFI Secure Boot with Windows Subsystem for Linux

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

User *profzei* has a script *sign_opencore.sh* that automates this process: create required folders, download and unzip OpenCore current version (0.8.4 at the time of writing), download HFSPlus.efi, check ISK keys, digitally sign files and copy them to the Signed folder. The script must be in the oc folder next to ISK.key and ISK.pem. It is slightly modified by me to suit my needs. You can also modify it to your liking. Check the drivers and tools that you use and modify the script in the signing files part to include those that are not currently included.

Copy this text into a text editor and save it with the name *sign_opencore.sh* (you can do it on Windows).

```bash
#!/bin/bash
# Copyright (c) 2021 by profzei
# Licensed under the terms of the GPL v3

LINK=$1
# https://github.com/acidanthera/OpenCorePkg/releases/download/0.8.4/OpenCore-0.8.4-RELEASE.zip
VERSION=$2
# 0.8.4

# Download and unzip OpenCore
wget $LINK
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Downloaded"
rm "OpenCore-${VERSION}-RELEASE.zip"

# Download HfsPlus
wget https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Downloaded/HfsPlus.efi

if [ -f "./ISK.key" ]; then
    echo "ISK.key was decrypted successfully"
fi

if [ -f "./ISK.pem" ]; then
    echo "ISK.pem was decrypted successfully"
fi

# Sign drivers by recursively looking for the .efi files in ./Downloaded directory
# Don't sign files that start with the dot, as this is metadata files
find ./Downloaded/X64/EFI/**/* -type f -name "*.efi" ! -name '.*' | cut -c 3- | xargs -I{} bash -c 'sbsign --key ISK.key --cert ISK.pem --output $(mkdir -p $(dirname "./Signed/{}") | echo "./Signed/{}") ./{}'

# Clean
rm -rf Downloaded
echo "Cleaned..."
```

Copy it into the oc folder:

```shell
cp /mnt/c/Users/me/Downloads/sign_opencore.sh /home/me/efikeys/oc
```

This script needs 2 parameters to be run: OpenCore download site and version number. For example, with version 0.8.4 (current):

```
sh ./sign_opencore.sh https://github.com/acidanthera/OpenCorePkg/releases/download/0.8.4/OpenCore-0.8.4-RELEASE.zip 0.8.4
```

At the end we will have in the Signed folder the OpenCore .efi files digitally signed with our own keys. Copy the Signed folder to a folder (outside Ubuntu) that is accessible from Windows and/or macOS to put the signed files into the OpenCore EFI folder, replacing the ones with the same name.

```
cp -r /home/me/efikeys/ /mnt/c/Users/me/Downloads/
```

## Include signatures into the firmware

Final step is to shove the signature files into the firmware, replacing the existing variables:

- db.auth >> Authorized Signatures
- kek.auth >> KEK (Key Exchange Keys)
- pk.auth >> PK (Platform key).

This can be done in 2 ways: BIOS setting menu or specialized tool KeyTool.

### BIOS

In the Secure Boot section there are usually options to restore default factory keys or to edit variables separately. On my motherboard (Z390 Aorus Elite) this menu is in Boot >> Secure Boot tab >> Key Management.

![Key Management](img/Key-Management.jpeg?raw=true)

If you have modified the keystores before (if it is not the first time) it is highly recommended, to avoid errors, restore default factory keys before adding / editing the new ones >> Restore Factory keys >> Install factory defaults >> Yes.

![Restory Factory Keys.jpeg](img/Restory-Factory-Keys.jpeg?raw=true)

Now you can edit the keys. Select the variable that you are going to modify in this order: Authorized Signatures >> Key Exchange Keys >> Platform Key (PK). In each variable you can see the details, export it, update it (replace), add it to the existing ones or delete it. For example, with Authorized Signatures, options menu is Details / Export / Update / Append / Delete.

![DB Options](img/DB-options.jpeg?raw=true)

To replace one variable with another: select Update >> search in the USB device >> locate and select db.auth >> this allowed signatures database replaces the current one. Likewise with Append if you want to add it to the existing one instead of replacing it. You can use Append with db.auth and kek.auth but pk.auth only allows replacement.\
To see the details, select Details >> variable's details are displayed.\
In the case of Authorized Signatures, after adding db.auth I see 4 authorized signatures: the one I created (ISK Image Signing Key), the two from Microsoft to be able to boot Windows with UEFI Secure Boot enabled and the one from Canonical (extracted from the Ubuntu shimx64.efi file with the shim-to-cert.tool tool included in OpenCore) to also be able to boot Ubuntu (in a separate disk, not in WSL) with UEFI Secure Boot.

![DB Details](img/DB-details.jpeg?raw=true)

### KeyTool

KeyTool is included in the efitools Linux package, you can find the utility in `/usr/share/efitools/efi/KeyTool.efi`.\
Copy KeyTool.efi with the name bootx64.efi into the EFI folder of an USB device (formatted as FAT32 and MBR). Along with bootx64.efi (KeyTool.efi), the EFI folder on the USB device must also include the files db.auth, kek.auth and pk.auth.\
When booting from this USB, it launches the graphical interface of the tool. When keytool starts we see a menu with the options Save Keys / Edit Keys / Execute Binary / Exit. Click on Edit Keys.

![KeyTool](img/keytool1.jpg?raw=true)

Select the variable that you are going to modify in this order: The Allowed Signature Database (db) >> The Key Exchange Keys Database (kek) >> The Platform Key (pk). First select The Allowed Signature Database (db) >> Replace Keys >> USB device >> db.auth >> click Enter >> return to the list of variables (message is dislayed only in case of error).

![KeyTool](img/keytool2.jpg?raw=true)

![KeyTool](img/keytool3.jpg?raw=true)

![KeyTool](img/keytool4.jpg?raw=true)

Repeat the same for The Key Exchange Keys Database (kek) and The Platform Key (pk).

## Ending

After embedding db.auth, kek.auth and pk.auth into the firmware we can boot OpenCore and macOS with UEFI Secure Boot enabled.

## OpenCore Vault + UEFI Secure Boot

There is a way to have UEFI Secure Boot and OpenCore vault at the same time, it's in the OpenCore Configuration.pdf file although the instructions are short and confusing in my opinion. It is a heavy task but at least it is possible to carry it out.

The key is in the order the files are signed, both with personal keys for the UEFI firmware and hashes created from vault.

This requires moving from macOS to Windows and viceversa a few times. In order not to have to switch from mac to windows so many times, I have installed [Ubuntu 14.04](https://mac.getutm.app/gallery/) virtual machine with [UTM](https://github.com/utmapp/UTM) on macOS. The steps are:

1. On Ubuntu >> digitally sign all OC 0.8.5.efi files except OpenCore.efi
2. On macOS >> vault the EFI folder with the signed files, including OpenCore.efi not digitally signed yet
3. On Ubuntu >> sign the OpenCore.efi file which already has Vault applied
4. Back in macOS >> copy the EFI folder into the EFI partition
5. Reboot >> enable UEFI Secure Boot >> OpenCore.

It is a tedious task. The most boring part is copying files between macOS and Ubuntu. UTM in theory has the option to define a shared folder to exchange files but I have not been able to make it work. I have used Wetransfer in Mac and Linux browsers to exchange files between both systems. The shared clipboard between Mac and Linux does work so at least text can be exchanged.

![Ubuntu on UTM](img/Ubuntu-UTM.png?raw=true)
