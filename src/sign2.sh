#!/bin/bash
# Copyright (c) 2015 by Roderick W. Smith
# Copyrigth (c) 2021 by profzei
# Licensed under the terms of the GPL v3
# Modified by Andrew Blitss, Andres Hurtado and perez987

# Linux command in Terminal
 # sh ./sign2.sh https://github.com/acidanthera/OpenCorePkg/releases/download/1.0.0/OpenCore-1.0.0-RELEASE.zip 1.0.0


# This blok is useful if you want tu update Ubuntu,
# uncommnet if desired
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

LINK=$1
# https://github.com/acidanthera/OpenCorePkg/releases/download/1.0.0/OpenCore-1.0.0-RELEASE.zip
VERSION=$2
# 1.0.0

echo "==================================="
echo "Create efikeys folder"
echo "==================================="
mkdir efikeys
cd efikeys

echo "==================================="
echo "Create PK, KEK and db keys"
echo "==================================="
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA-2024/" -keyout PK.key -out PK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA-2024/" -keyout KEK.key -out KEK.pem
openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=ROBLA-2024/" -keyout ISK.key -out ISK.pem
chmod 0600 *.key

echo "==================================="
echo "Download 2011 certificates"
echo "==================================="
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt
wget --user-agent="Mozilla" https://www.microsoft.com/pkiops/certs/MicCorUEFCA2011_2011-06-27.crt

echo "==================================="
echo "Sign Microsoft certificates"
echo "==================================="
openssl x509 -in MicWinProPCA2011_2011-10-19.crt -inform DER -out MicWinProPCA2011_2011-10-19.pem -outform PEM
openssl x509 -in MicCorUEFCA2011_2011-06-27.crt -inform DER -out MicCorUEFCA2011_2011-06-27.pem -outform PEM

echo "==================================="
echo "Convert PEM files to ESL"
echo "==================================="
cert-to-efi-sig-list -g $(uuidgen) PK.pem PK.esl
cert-to-efi-sig-list -g $(uuidgen) KEK.pem KEK.esl
cert-to-efi-sig-list -g $(uuidgen) ISK.pem ISK.esl
cert-to-efi-sig-list -g $(uuidgen) MicWinProPCA2011_2011-10-19.pem MicWinProPCA2011_2011-10-19.esl
cert-to-efi-sig-list -g $(uuidgen) MicCorUEFCA2011_2011-06-27.pem MicCorUEFCA2011_2011-06-27.esl

echo "==================================="
echo "Create allowed database"
echo "==================================="
cat ISK.esl MicWinProPCA2011_2011-10-19.esl MicCorUEFCA2011_2011-06-27.esl > db.esl

echo "==================================="
echo "Sign ESL files to auth"
echo "==================================="
sign-efi-sig-list -k PK.key -c PK.pem PK PK.esl PK.auth
sign-efi-sig-list -k PK.key -c PK.pem KEK KEK.esl KEK.auth
sign-efi-sig-list -k KEK.key -c KEK.pem db db.esl db.auth

echo "==================================="
echo "Copy files to oc folder"
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
echo "Download and unzip OpenCore"
echo "==================================="
wget $LINK
unzip "OpenCore-${VERSION}-RELEASE.zip" "X64/*" -d "./Downloaded"
rm "OpenCore-${VERSION}-RELEASE.zip"
 
echo "==================================="
echo "Download HFSPlus (Daniel Hurtado)"
echo "===================================" 
wget https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -O ./Downloaded/X64/EFI/OC/Drivers/HfsPlus.efi

echo "==================================="
echo "Check ISK keys"
echo "==================================="  
if [ -f "./ISK.key" ]; then
    echo "ISK.key was decrypted successfully"
fi
 
if [ -f "./ISK.pem" ]; then
    echo "ISK.pem was decrypted successfully"
fi

echo "==================================="
echo "Sign OpenCore .efi files"
echo "===================================" 
# Sign drivers by recursively looking for the .efi files in ./Downloaded directory
# Don't sign files that start with the dot, as this is metadata files
# Andrew Blitss's contribution0
find ./Downloaded/X64/EFI/**/* -type f -name "*.efi" ! -name '.*' | cut -c 3- | xargs -I{} bash -c 'sbsign --key ISK.key --cert ISK.pem --output $(mkdir -p $(dirname "./Signed/{}") | echo "./Signed/{}") ./{}'

echo "====================================================="
echo "Signed OpenCore is in oc/Signed/Downloaded folder"
echo "====================================================="  
# Clean
rm -rf Downloaded
