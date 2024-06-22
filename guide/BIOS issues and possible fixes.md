

## BIOS issues when modifying Secure Boot variables

When modifying secure variables (update, append, delete or reset to default) issues may occur, some of which are not easy to fix:

- Secure variables cannot be modified in any way with "Security violation" or "Try after system reboot" or "Secure variables are locked down" messages
- BIOS does not pass the POST with error beep code.

From what I have read in different places, these issues seem to be more frequent on Gigabyte motherboards but this is something I cannot be sure of. My motherboard is Gigabyte (Z390 Aorus Elite) and it has presented these issues on several occasions.

The first step to fix it is Reset to Setup Mode in the Secure Boot menu of the BIOS but it is very often not enough. If it fails, CMOS reset or/and BIOS update is added. In stubborn cases, it may be necessary to boot from the backup BIOS.

1. Reset to Setup Mode: this erases the firmware keys after reboot so that the default ones or the ones created by us can be loaded.
2. CMOS reset: most motherboards have a pin for this. With the power removed (it is better to disconnect the cable from the power supply) and the battery lifted, contact is made with a metal object for a few seconds between both pins of the bridge.
3. BIOS update: You can use the current BIOS or the immediately previous one, my experience is that changing the BIOS version (installing the one that is different from the one you have) gives better results.
4. Boot from BIOS backup: you have to know how to do it because it depends on the manufacturer and motherboard model. For example, on my board you have to:
	- Disconnect the power by turning off the power supply button on the rear
	- Remove the battery
	- Shut off the power supply using the switch on the back of the PSU, wait 10-15 seconds
	- Press and hold the case Power On swtich, then while still holding turn on the power supply from the switch on the rear
	- Still holding the case power on switch, the board will start, once it does release the case power on switch and shut off the power supply via the switch on the read of the unit. (Do the latter two parts as quickly as you can once the board starts)
	- The board will shut down
	- Turn the power supply back on using the switch on the rear of the unit
	- Turn on the motherboard by pressing the case power on button.

Not infrequently I have had to combine the 4 methods to fix the issue. Until now, I have always managed to recover the BIOS but it is not guaranteed that at some point it cannot be damaged beyond repair.
