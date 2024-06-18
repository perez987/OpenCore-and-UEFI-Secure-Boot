## OpenCore and UEFI Secure Boot with UTM on macOS

This is another way to enable UEFI Secure Boot with OpenCore without having to install Windows or create a live Linux USB. The entire task is done from within macOS. Clipboard and shared folder features that allow live sharing of text and files between macOS and Linux make the task easier.

### UTM

UTM is an app that allows you to use virtual machines on macOS and iOS. It is free and open software. Information and downloads are available on [GitHub](https://github.com/utmapp/UTM) and on the [website](https://mac.getutm.app).

UTM offers preconfigured virtual machines that you just have to attach to the app and start, it is not necessary to previously install the operating system. You can visit the [Gallery of Virtual Machines](https://mac.getutm.app/gallery/).

Among the preinstalled virtual machines there is no Ubuntu 22.04 but UTM has a [guide](https://docs.getutm.app/guides/ubuntu/) to download and install this version of Ubuntu. I have followed this guide to have an Ubuntu 22.04 virtual system on macOS.

It is important to configure the clipboard and shared folder between macOS and Linux. The guide explains how to do it. Shared clipboard works after installing SPICE Agent which also improves screen resolutions and dynamic switching between them. Its installation is highly recommended, as is QEMU Agent (Additional features such as time syncing, etc.).

Directory sharing can work in 2 different ways: SPICE WebDav or VirtFS. I have used VirtFS which allows you to show the macOS shared folder in the Ubuntu file system. To do this you have to:

- Open Terminal
- Create the shared directory `sudo mkdir Shared`
- Mount the shared directory<br>`sudo mount -t 9p -o trans=virtio share Shared -oversion=9p2000.L`
- Add an entry in fstab to mount the shared folder at boot
	- Open fstab `sudo pico /etc/fstab`
	- Add this entry<br>`share /home/yo/Shared 9p trans=virtio,version=9p2000.L,rw,_netdev,nofail 0 0`

### Creating the keys and signing OpenCore

