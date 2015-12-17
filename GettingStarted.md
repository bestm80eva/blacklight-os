# Downloading #
## Selecting a Package ##

The first thing you need to do is find a package that's right for you. There are three ways to obtain Blacklight OS: a **.zipped floppy disk image**, in a **source tarball**, or from the **Subversion repository**. For more information on each of the packages, see [Which Download Should I Get?](WhichDownloadShouldIGet.md).

## Downloading Your Package ##

The floppy images and source tarballs are available on the [Downloads tab](https://code.google.com/p/blacklight-os/downloads/list). For information on how to check out a latest unstable build, see the [Source tab](https://code.google.com/p/blacklight-os/source/checkout).

# Building Blacklight OS #

If you have chosen the Subversion repository, you need to run `build.bat` in order to assemble the latest kernel. This process requires the latest version of [NASM](http://www.nasm.us/). You can then update a floppy image with your new `uvlight.krn` file. Options for editing the floppy image include a fabulous shareware program called [WinImage](http://www.winimage.com/) or the freeware [ImDisk](http://www.ltr-data.se/opencode.html/#ImDisk).

# Running Blacklight OS #

The floppy image can be directly booted by an x86 emulator/virtualization platform such as QEMU or VirtualBox (the latter is that which is primarily used for testing Blacklight OS by the development team), or it can be written to a physical floppy and used to boot a physical computer. Congratulations, you now have a working copy of Blacklight OS!