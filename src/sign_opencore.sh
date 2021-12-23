#!/bin/bash
# Copyright (c) 2021 by profzei
# Licensed under the terms of the GPL v3

# OpenCore download link
LINK=$1
# https://github.com/acidanthera/OpenCorePkg/releases/download/0.7.5/OpenCore-0.7.5-RELEASE.zip
VERSION=$2
# 0.7.5 current

# Terminal command in Linux
# sh ./sign_opencore.sh https://github.com/acidanthera/OpenCorePkg/releases/download/0.7.5/OpenCore-0.7.5-RELEASE.zip 0.7.5

echo "==============================="
echo "Creating required directories"
mkdir Signed
mkdir Signed/Drivers
mkdir Signed/Tools
mkdir Signed/Download
mkdir Signed/BOOT
echo "==============================="
echo Downloading HfsPlus
wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Signed/Download/HfsPlus.efi
#echo "==============================="
# uncomment the next 2 lines if you use OpenLinuxBoot
#echo Downloading ext4_x64.efi
#wget -nv https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/ext4_x64.efi -O ./Signed/Download/ext4_x64.efi
echo "==============================="
echo Downloading and unziping OpenCore
wget -nv $LINK
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Signed/Download"
echo "==============================="
# If you don't want to delete downloaded OpenCore zip file, comment next line
rm "OpenCore-${VERSION}-RELEASE.zip"
echo "==============================="
echo "Checking ISK files"
if [ -f "./ISK.key" ]; then
    echo "ISK.key was decrypted successfully"
fi

if [ -f "./ISK.pem" ]; then
    echo "ISK.pem was decrypted successfully"
fi
echo "==============================="
echo "Signing drivers, tools, BOOTx64.efi and OpenCore.efi"
sleep 2
# You can modify drivers and tools to be signed to your like
echo ""
sbsign --key ISK.key --cert ISK.pem --output ./Signed/BOOT/BOOTx64.efi ./Signed/Download/X64/EFI/BOOT/BOOTx64.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/OpenCore.efi ./Signed/Download/X64/EFI/OC/OpenCore.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/OpenRuntime.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenRuntime.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/OpenCanopy.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenCanopy.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/CrScreenshotDxe.efi ./Signed/Download/X64/EFI/OC/Drivers/CrScreenshotDxe.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/Tools/OpenShell.efi ./Signed/Download/X64/EFI/OC/Tools/OpenShell.efi
sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/HfsPlus.efi ./Signed/Download/HfsPlus.efi

# You can sign also keytool to boot from USB with UEFI Secure Boot enabled
sbsign --key ISK.key --cert ISK.pem --output ./Signed/KeyTool.efi ./KeyTool.efi

# uncomment the next 2 lines if you use OpenLinuxBoot
#sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/OpenLinuxBoot.efi ./Signed/Download/X64/EFI/OC/Drivers/OpenLinuxBoot.efi
#sbsign --key ISK.key --cert ISK.pem --output ./Signed/Drivers/ext4_x64.efi ./Signed/Download/ext4_x64.efi
echo "==============================="
# Clean: remove downloaded files
rm -rf ./Signed/Download
echo "Cleaned."
