
## Microsoft 2011 certificate revoked?

### State of the matter

All current UEFI Microsoft certificates are expiring in 2026. These include the **Microsoft Corporation KEK CA 2011**, stored in the KEK database, and two certificates stored in the DB called **Microsoft Windows Production PCA 2011**, which signs the Windows bootloader, and **Microsoft UEFI CA 2011** (or third-party UEFI CA), which signs third-party OS and hardware driver components.

Microsoft is migrating to new ones. The first update will add the **Microsoft Windows UEFI CA 2023** to the firmware db. The new certificate will be used to sign Windows boot components prior to the expiration of the **Microsoft Windows Production CA 2011**. 

---

### Does my motherboard have the new certificate?

Some OEM manufacturers include the 2023 certificate in recent BIOS updates. It is a process that has started recently so (quite a few) UEFI firmware do not include it yet. For example, the latest BIOS version for my motherboard is F11 and it does not have this certificate, it only has the ones from 2011.

To check if you have the new certificate in the firmware go to the BIOS menu where you can see the secure boot keys >> Authorized Signatures (db) >> search for `Windows UEFI CA 2023`. If you only have `Microsoft Windows Production PCA 2011` and `Microsoft Corporation UEFI CA 2011` >> the firmware does not have the 2023 certificate.

There is a Microsoft GitHub site [Secure Boot Objects](https://github.com/microsoft/secureboot_objects) where you can get all the Microsoft updated binaries in a format that you can insert into the firmware using the BIOS menu. This repository is used to hold the secure boot objects recommended by Microsoft to use as the default KEK, DB, and DBX variables.

Go to Releases and get `edk2-x64-secureboot-binaries.zip`
 or `edk2-x64-secureboot-binaries.tar.gz`. Inside the package there are 4 .bin files in BIOS menu compatible format: `DefaultPk.bin`, `DefaultKek.bin`, `DefaultDb.bin` and `DefaultDbx.bin`.
 
By updating the UEFI secure keys with these files, you set the motherboard with the latest versions of Microsoft secure variables. This fixes the *Certificate revoked* or *Security violation* issue that users can have when booting Windows or Linux with UEFI Secure Boot enabled and updated BIOS that includes the 2023 certificate.

---

### OpenCore and the new certificate

But OpenCore users operate differently. We have to create our own secure keys, sign the OpenCore files with them and insert them in the firmware instead of (or added to) the existing ones. 
