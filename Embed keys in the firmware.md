
# Include signatures into the UEFI firmware

Final step of the process is to insert the signature files into the firmware, replacing the existing variables in this order:

- db.auth >> Authorized Signatures
- kek.auth >> KEK (Key Exchange Keys)
- pk.auth >> PK (Platform key).

This can be done in 2 ways: BIOS setting menu or KeyTool.

### BIOS

In the Secure Boot section there are usually options to restore default factory keys or to edit variables separately. On my motherboard (Z390 Aorus Elite) this menu is in Boot >> Secure Boot tab >> Key Management. 

![Key Management](img/Key-Management.jpeg?raw=true)

If you have modified the keystores before (if it is not the first time) it is highly recommended, to avoid errors, restore default factory keys before adding / editing the new ones >> Restore Factory keys >> Install factory defaults >> Yes.  Another option is Reset To Setup Mode that erases the firmware keys after reboot so that the default ones or the ones created by us can be loaded.

![Restory Factory Keys.jpeg](img/Restory-Factory-Keys.jpeg?raw=true)

Now you can edit the keys. Select the variable that you are going to modify in this order: Authorized Signatures (db) >> Key Exchange Keys (KEK) >> Platform Key (PK). For each variable you can see details, export, update (replace), add to the existing ones or delete. For example, for Authorized Signatures, options are Details / Export / Update / Append / Delete.

![DB Options](img/DB-options.jpeg?raw=true)

To replace one variable with another: select Update >> search in the USB device >> locate and select db.auth >> this allowed signatures database replaces the current one. Likewise with Append if you want to add it to the existing one instead of replacing it. You can use Append with db.auth and kek.auth but pk.auth only allows replacement.<br>
To see the details, select Details >> variable's details are displayed.<br>
E.g.: in Authorized Signatures (db) , after adding db.auth I see 4 authorized signatures: the one I created (ISK Image Signing Key), two from Microsoft to be able to boot Windows with UEFI Secure Boot enabled and the one from Canonical (extracted from the Ubuntu shimx64.efi file with shim-to-cert.tool utility included in OpenCore) to also be able to boot native Ubuntu (in a separate disk, not in WSL) with UEFI Secure Boot enabled.

![DB Details](img/DB-details.jpeg?raw=true)

### KeyTool

KeyTool is included in the efitools Linux package, you can find the utility in `/usr/share/efitools/efi/KeyTool.efi`.

How to use this tool? There are 2 ways:

- Copy KeyTool.efi with the name BOOTx64.efi into the EFI folder of an USB stick formatted as FAT32 and MBR
- Copy KeyTool.efi with the name BOOTx64.efi into the EFI folder of the EFI partition of an USB stick formatted as FAT32 and GUID.

Next to BOOTx64.efi (KeyTool.efi), the EFI folder on the USB device must also include the files db.auth, kek.auth and pk.auth. When booting from this USB, a graphical interface is launched and we see a menu with the options Save Keys / Edit Keys / Execute Binary / Exit. Click on Edit Keys.

![KeyTool](img/keytool1.jpg?raw=true)

Select the variable that you are going to modify in this order: Allowed Signature Database (db) >> Key Exchange Keys Database (kek) >> Platform Key (pk). First select the Allowed Signature Database (db) >> Replace Keys >> USB device >> db.auth >> click Enter >> return to the list of variables (message is displayed only in case of error).

![KeyTool](img/keytool2.jpg?raw=true)

![KeyTool](img/keytool3.jpg?raw=true)

![KeyTool](img/keytool4.jpg?raw=true)

Repeat the same for Key Exchange Keys Database (KEK) and Platform Key (PK).

### Ending

After embedding db.auth, kek.auth and pk.auth into the firmware we can boot OpenCore and macOS with UEFI Secure Boot enabled.
