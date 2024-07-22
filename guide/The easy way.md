## UEFI Secure Boot and OpenCore: the easy way

There are users who are not looking for an increase in security when booting OpenCore and macOS but only a way to have UEFI Secure Boot enabled and boot OpenCore without disabling it. This may be because they want to boot Windows with UEFI Secure Boot or because the machine they are using has it enabled and they cannot disable it (business computers especially). 

Although the level of security provided by this method is probably lower than the one already mentioned (creating our own keys on a Linux system, digitally signing the OpenCore files and including our secure keys in the firmware), it is a much simpler way and consumes much less time so, if you are one of those who only want to be able to boot OpenCore with UEFI Secure Boot enabled, this can be very useful. 

What is proposed is **to enroll the OpenCore .efi files to the db secure variable**, which is a list of allowed signatures, so that UEFI Secure Boot accepts these .efi files as safe. We do not modify .efi files, we just tell the firmware to consider them safe to boot even if UEFI Secure Boot is enabled. 

1.- BIOS: Disable UEFI Secure Boot

2.- macOS

- Create a USB stick and put OpenCore on the EFI partition in the usual way
- Get the file `/usr/standalone/i386/boot.efi `and put it in the EFI folder of the USB stick
- Restart

3.- BIOS:

- Secure Boot >> Key management >> Reset to Default Keys

- Secure Boot >> Key management >> Enroll EFI image

- Add the .efi files one by one from the EFI folder of the USB stick
	- EFI/BOOT/bootx64.efi
	- EFI/OC/OpenCore.efi
	- EFI/OC/Driver/*.efi
	- EFI/OC/Tools/*.efi
	- EFI/boot.efi

- Restart

4.- BIOS: Enable UEFI Secure Boot and reboot to select boot device
 
5.- Select partition 1 of the USB stick and check if OpenCore and macOS boot as expected.

If everything works well, you can boot with this same version of OpenCore from any internal or external drive with UEFI Secure Boot enabled.

Whenever you update OpenCore, you need to replace OpenCore .efi files. And every time you update macOS you must get the new boot.efi file of the i386 folder and do Enroll EfI Image again. Maybe it's better to do Secure Boot >> Key management >> Reset to Default Keys before enrolling the new .efi files.

Windows still boots fine with UEFI Secure Boot enabled as OEM secure variables and Microsoft certificates registered in the firmware have not been changed.

This method seems to have a much lower risk of ending up with a locked or even bricked BIOS.

### Source

[slose1](https://github.com/slose1/B460M-aorus-elite-Opencore)

This user proposes adding some macOS files to the db variable in addition to the OpenCore files, these are:

- /usr/standalone/i386/boot.efi
- /usr/standalone/i386/apfs_aligned.efi
- /usr/standalone/i386/apfs.efi
- /usr/standalone/firmware/FUD/MultiUpdater/MultiUpdater.efi
- /usr/standalone/firmware/FUD/USBCAccessoryFirmwareUpdater/HPMUtil.efi

These files must be copied to the OpenCore EFI folder on the USB stick and registered with the Enroll EFI Image option as we did with OpenCore .efi files.

But I have tested **with and without** enrolling these macOS files in the firmware and I have seen that the only file required, at least in my case, is **boot.efi**. I have tried enrolling only boot.efi and OpenCore .efi files and OpenCore boots fine with UEFI Secure Boot enabled. Of course it also does enrolling up the other 4 files too but to me they don't seem to be necessary.

