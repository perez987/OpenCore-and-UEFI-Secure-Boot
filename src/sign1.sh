
#!/bin/bash
# Copyright (c) 2015 by Roderick W. Smith
# Copyrigth (c) 2021 by profzei
# Licensed under the terms of the GPL v3
# Modified by Lukakeiton and perez987

# Linux command in Terminal
 # sh ./sign.sh 1.0.0

# This blok is useful only the first time, uncommnet if desired
#sudo apt update && sudo apt upgrade

#if ! command -v unzip &> /dev/null
#then
#	echo "Installing unzip..."
#	sudo apt install unzip
#fi

#if ! command -v sbsign &> /dev/null
#then
#	echo "Installing sbsigntool..."
#	sudo apt-get install sbsigntool
#fi

#if ! command -v cert-to-efi-sig-list &> /dev/null
#then
#	echo "Installing efitools..."
#	sudo apt-get install efitools
#fi

VERSION=$1

echo "==================================="
echo "Creating efikeys folder"
echo "==================================="
mkdir efikeys
echo "==================================="
echo "Copying 2023 cert to efikeys"
echo "==================================="
cp WinUEFCA2023.crt efikeys/
cd efikeys
echo "==================================="
echo "Creating PK, KEK and db keys"
echo "==================================="
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA 2024/" -keyout PK.key -out PK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA 2024/" -keyout KEK.key -out KEK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA 2024/" -keyout ISK.key -out ISK.pem
chmod 0600 *.key

echo "==================================="
echo "Downloading 2011 certificates"
echo "==================================="
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicCorUEFCA2011_2011-06-27.crt

echo "==================================="
echo "Signing Microsoft certificates"
echo "==================================="
openssl x509 -in MicWinProPCA2011_2011-10-19.crt -inform DER -out MicWinProPCA2011_2011-10-19.pem -outform PEM
openssl x509 -in MicCorUEFCA2011_2011-06-27.crt -inform DER -out MicCorUEFCA2011_2011-06-27.pem -outform PEM
openssl x509 -in WinUEFCA2023.crt -inform DER -out WinUEFCA2023pem -outform PEM

echo "==================================="
echo "Converting PEM files to ESL"
echo "==================================="
cert-to-efi-sig-list -g $(uuidgen) PK.pem PK.esl
cert-to-efi-sig-list -g $(uuidgen) KEK.pem KEK.esl
cert-to-efi-sig-list -g $(uuidgen) ISK.pem ISK.esl
cert-to-efi-sig-list -g $(uuidgen) MicWinProPCA2011_2011-10-19.pem MicWinProPCA2011_2011-10-19.esl
cert-to-efi-sig-list -g $(uuidgen) MicCorUEFCA2011_2011-06-27.pem MicCorUEFCA2011_2011-06-27.esl
cert-to-efi-sig-list -g $(uuidgen) WinUEFCA2023.pem WinUEFCA2023.esl

echo "==================================="
echo "Creating allowed database"
echo "==================================="
cat ISK.esl MicWinProPCA2011_2011-10-19.esl MicCorUEFCA2011_2011-06-27.esl WinUEFCA2023.esl > db.esl

echo "==================================="
echo "Signing ESL files to auth"
echo "==================================="
sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth
sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth
sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth

echo "==================================="
echo "Copying files to oc folder"
echo "==================================="
cd ..
mkdir oc
cp efikeys/ISK.key oc
cp efikeys/ISK.pem oc
cp efikeys/PK.auth oc
cp efikeys/KEK.auth oc
cp efikeys/db.auth oc
cd oc

echo "==================================="
echo "Creating required directories"
echo "==================================="
mkdir Signed
mkdir Signed/EFI
mkdir Signed/EFI/BOOT
mkdir Signed/EFI/OC
mkdir Signed/EFI/OC/Drivers
mkdir Signed/EFI/OC/Tools
mkdir Signed/Download

echo "==================================="
#LINK="https://github.com/acidanthera/OpenCorePkg/releases/download/${VERSION}/OpenCore-${VERSION}-RELEASE.zip"
LINK="https://github.com/acidanthera/OpenCorePkg/releases/download/1.0.0/OpenCore-1.0.0-RELEASE.zip"
echo "Downlading Opencore ${VERSION}"
echo "==================================="
wget -nv $LINK

echo "==================================="
echo "Downloading HfsPlus.efi"
echo "==================================="
wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Signed/Download/HfsPlus.efi
echo "==================================="
echo "Do you use OpenLinuxBoot? (Y/N)"
read LUKA
LUKA1="Y"
LUKA2="y"
if [ "$LUKA" = "$LUKA1" ] || [ "$LUKA" = "$LUKA2" ]; then
	wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/ext4_x64.efi -O ./Signed/Download/ext4_x64.efi	
fi

echo "==================================="
echo "Unzipping OpenCore ${VERSION}"
echo "==================================="
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Signed/Download"
rm "OpenCore-${VERSION}-RELEASE.zip"
echo "==================================="
echo "Signing OpenCore .efi files"
echo "==================================="
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/BOOT/BOOTx64.efi ./Signed/Download/X64/EFI/BOOT/BOOTx64.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/OpenCore.efi ./Signed/Download/X64/EFI/OC/OpenCore.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/OpenRuntime.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenRuntime.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/OpenCanopy.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenCanopy.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/CrScreenshotDxe.efi ./Signed/Download/X64/EFI/OC/Drivers/CrScreenshotDxe.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/FirmwareSettingsEntry.efi ./Signed/Download/X64/EFI/OC/Drivers/FirmwareSettingsEntry.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/ResetNvramEntry.efi ./Signed/Download/X64/EFI/OC/Drivers/ResetNvramEntry.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/ToggleSipEntry.efi ./Signed/Download/X64/EFI/OC/Drivers/ToggleSipEntry.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Tools/OpenShell.efi ./Signed/Download/X64/EFI/OC/Tools/OpenShell.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/HfsPlus.efi ./Signed/Download/HfsPlus.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/AudioDxe.efi ./Signed/Download/X64/EFI/OC/Drivers/AudioDxe.efi


if [ "$LUKA" = "$LUKA1" ] || [ "$LUKA" = "$LUKA2" ]; then
	sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/OpenLinuxBoot.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenLinuxBoot.efi
	sbsign --key ISK.key --cert ISK.pem --output ./Signed/EFI/OC/Drivers/ext4_x64.efi ./Signed/Download/ext4_x64.efi
	echo "Linux drivers signed"
else
	rm ./Signed/Download/X64/EFI/OC/Drivers/OpenLinuxBoot.efi
fi

echo "================================================"
echo "Signed OpenCore is in oc/Signed folder"
echo "================================================"
