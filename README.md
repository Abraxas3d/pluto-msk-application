# Dialogus (formerly pluto-msk-application)
C-code applications for the PLUTO MSK implementation 

## how-to:

### Build the application

See section below for how to build the application.

### Transfer the application to the Pluto

To move the built application (here, `msk_test` in your current
working directory) to the Pluto, working around the many limitations
of the Pluto's networking, is a four-step process:

1. Move the built application to the host directly connected
to the Pluto by USB cable. Assuming that host is named `raspi`
and your account on that host is named `ori`:
```
$ scp msk_test ori@raspi.local:msk_test
```

2. Log into 'raspi' (from your computer):
```
$ ssh ori@raspi.local
```

3. Log into the Pluto (from raspi). Assuming the Pluto is using
the default IP address:
```
ori@raspi $ ssh root@192.168.2.1
root@192.168.2.1's password: 
______ _       _              ___________ _____ 
| ___ \ |     | |            |  _  | ___ \_   _|
| |_/ / |_   _| |_ ___ ______| | | | |_/ / | |  
|  __/| | | | | __/ _ \______| | | |    /  | |  
| |   | | |_| | || (_) |     \ \_/ / |\ \ _| |_ 
\_|   |_|\__,_|\__\___/       \___/\_| \_|\___/ 
3d89 F5OEO (2024)

[pluto:~]#
```

4. From the Pluto, use SCP to transfer the built application
from raspi to the Pluto:
```
[pluto:~]# scp ori@192.168.2.10:msk_test /tmp/msk_test
ori@192.168.2.10's password:
```

You may be prompted for a password at each step. There are
two different passwords involved. The password for root
on the Pluto is `analog` unless you changed it at image
build time.

If you're familiar with SSH configuration, you can make
some of these steps easier and/or more scriptable. However,
the Pluto doesn't (by default) have any persistent storage,
so any trick that involves configuring the Pluto is likely
to be difficult.

### Execute the application

Next, we need to run the application on the Pluto.

You could just run it from the Pluto's command line, but
this is __not recommended__. You'll find that printing out
frequent debug messages that way is enough to bog down the
Pluto's processor, and there's no way to capture a large
log file on the Pluto itself.

Instead, you should stream the application's output to
a terminal on a more powerful machine. If you have a
reasonably powerful computer connected directly to the
Pluto, this works:
```
ssh -t root@192.168.2.1 /tmp/msk_test
```

We often prefer to work with a tiny computer like a
Raspberry Pi connected directly to the Pluto. Depending
on the model of Raspberry Pi, it might also be a little
slow for this purpose, especially if you try to capture
a lot of debug output to a slow SD card. In that case,
we have had good luck using the Raspberry Pi as a
_jump host_ for the SSH connection from a powerful
desktop or laptop to the Pluto. To do this entirely
from the command line:
```
ssh -J ori@raspi.local -t root@192.168.3.2 /tmp/msk_test
```

## What is what

Mainline development has switched from `msk_rx_init.c`
to `opulent_voice.c`, as we switch the focus to communicating
with the MSK modulator in a realistic manner.

## Building the Application on Ubuntu (cross-platform)

This worked for me on a fresh Ubuntu 24.10 VM created by OrbStack.

```
cd $HOME
sudo apt install wget xz-utils git

# The cross toolchain should match the firmware build:
wget http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
tar xvf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
export PATH=$HOME/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin/:$PATH
# make the path change permanent by adding the line above to an appropriate login script file

wget https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v0.38/sysroot-v0.38.tar.gz
tar xvfz sysroot-v0.38.tar.gz 
mv staging pluto-0.38.sysroot

# git clone <url for this repo>
cd pluto-msk-application
# copy msk_top_regs.h from firmware build to this directory

arm-linux-gnueabihf-gcc -mfloat-abi=hard --sysroot=$HOME/pluto-0.38.sysroot -g -D ENDLESS_PRBS -D NO_INIT_ON_SUCCESS -D RF_LOOPBACK -o msk_test-xmit msk_rx_init.c -lpthread -liio -lm -Wall -Wextra && arm-linux-gnueabihf-gcc -mfloat-abi=hard --sysroot=$HOME/pluto-0.38.sysroot -g -D ENDLESS_PRBS -D NO_INIT_ON_SUCCESS -D RX_ACTIVE -o msk_test-recv msk_rx_init.c -lpthread -liio -lm -Wall -Wextra
# The above line builds two versions of the application.
# The `xmit` version has `RF_LOOPBACK` enabled; it transmits PRBS forever.
# The `recv` version has `RX_ACTIVE` enabled; it does not transmit.
# Both versions try to receive and validate the data using PRBS Mon.
# Both versions continue to run without re-inits if all is going well.q
```

Notes:

1. Newer versions of the cross-development toolchain are unlikely to work without
some extra fiddling. You want to use this one, that matches the toolchain that built
the standard plutoSDR firmware, unless you're working with custom firmware built
with a different toolchain.

2. You don't need to install any IIO-related packages on the build host, but it's
harmless if you do. The `iio.h` include file and the `libiio` link library both
come out of the sysroot in this build.

3. You need the file `msk_top_regs.h` from the custom HDL build that's loaded into
the Pluto's FPGA. It defines the register access map. The application you build
won't work on a Pluto with an FPGA image having an incompatible register map.
(Don't add `msk_top_regs.h` to this repository. It belongs to the HDL build.
When you clone this repo, copy `msk_top_regs.h` from the HDL build repo
you will be working with.)

4. The application code can build several different versions, depending on the
definition of preprocessor symbols such as `RF_LOOPBACK` and `RX_ACTIVE` and
`OPV_FRAME_MODE`. On the command line shown above, I'm assuming none of those
symbols is defined in the source code. We define the ones we want on the command
line with the `-D` flag.

5. You don't have to build two versions on the same command line as shown here.
That's just a convenience for the case we are dealing with as I write this:
debugging over-the-air operation using two Plutos, one transmitting PRBS into a
signal splitter connected to both Pluto receive ports. For this case, we always
need those two versions.

6. If you're using the specified toolchain, you should not need `-std=gnu99` on
the compiler command line. It might be useful with some other toolchains.

## Building with a Container

If your local host machine is not running Linux, or if you don't want to clutter
up your machine with the cross-platform toolchain, you may find it convenient to
do the cross-platform building in a (Docker) container. For example, I've used
this method to build the application on a Mac.

`Dockerfile` contains the steps to build the container image:

```
docker build --platform linux/amd64 -t build-application .
```

Create a shell script to perform the build operation(s) you need. The commands
are just like the ones we used in the previous section. The file
`build-both-loopback-rx.sh` is an example of such a script.

To run the script in the container, use a command like this:

```
docker run --platform=linux/amd64 --volume .:/repo build-application /bin/sh build-both-loopback-rx.sh
```

Better yet, put that command into a shell script of its own, as we have done
in `conbuild-both-loopback-rx.sh`, and run the shell script (with no arguments
needed) whenever you want to rebuild the application(s).

If all goes well, the cross-platform compiler running inside the container will
have written the Pluto executable(s) into the current directory on your host.
