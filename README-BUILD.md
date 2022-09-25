# How to build the xPack MinGW-w64 GCC binaries

## Introduction

This project also includes the scripts and additional files required to
build and publish the
[xPack MinGW-w64 GNU Compiler Collection](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack) binaries.

The build scripts use the
[xPack Build Box (XBB)](https://xpack.github.io/xbb/),
a set of elaborate build environments based on recent GCC versions
(Docker containers
for GNU/Linux and Windows or a custom folder for MacOS).

There are two types of builds:

- **local/native builds**, which use the tools available on the
  host machine; generally the binaries do not run on a different system
  distribution/version; intended mostly for development purposes;
- **distribution builds**, which create the archives distributed as
  binaries; expected to run on most modern systems.

This page documents the distribution builds.

For native builds, see the `build-native.sh` script. (to be added)

## Repositories

- <https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack.git> -
  the URL of the xPack build scripts repository
- <https://github.com/xpack-dev-tools/build-helper> - the URL of the
  xPack build helper, used as the `scripts/helper` submodule.
- <https://gcc.gnu.org/git/?p=gcc.git;a=tree> - the main repo

### Branches

- `xpack` - the updated content, used during builds
- `xpack-develop` - the updated content, used during development
- `master` - the original content; it follows the upstream master.

## Prerequisites

The prerequisites are common to all binary builds. Please follow the
instructions in the separate
[Prerequisites for building binaries](https://xpack.github.io/xbb/prerequisites/)
page and return when ready.

Note: Building the Arm binaries requires an Arm machine.

## Download the build scripts

The build scripts are available in the `scripts` folder of the
[`xpack-dev-tools/mingw-w64-gcc-xpack`](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack)
Git repo.

To download them, use the following commands:

```sh
rm -rf ${HOME}/Work/mingw-w64-gcc-xpack.git; \
git clone https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack.git \
  ${HOME}/Work/mingw-w64-gcc-xpack.git; \
git -C ${HOME}/Work/mingw-w64-gcc-xpack.git submodule update --init --recursive
```

> Note: the repository uses submodules; for a successful build it is
> mandatory to recurse the submodules.

For development purposes, clone the `xpack-develop` branch:

```sh
rm -rf ${HOME}/Work/mingw-w64-gcc-xpack.git; \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack.git \
  ${HOME}/Work/mingw-w64-gcc-xpack.git; \
git -C ${HOME}/Work/mingw-w64-gcc-xpack.git submodule update --init --recursive
```

## The `Work` folder

The scripts create a temporary build `Work/mingw-w64-gcc-${version}` folder in
the user home. Although not recommended, if for any reasons you need to
change the location of the `Work` folder,
you can redefine `WORK_FOLDER_PATH` variable before invoking the script.

## Spaces in folder names

Due to the limitations of `make`, builds started in folders with
spaces in names are known to fail.

If on your system the work folder is in such a location, redefine it in a
folder without spaces and set the `WORK_FOLDER_PATH` variable before invoking
the script.

## Customizations

There are many other settings that can be redefined via
environment variables. If necessary,
place them in a file and pass it via `--env-file`. This file is
either passed to Docker or sourced to shell. The Docker syntax
**is not** identical to shell, so some files may
not be accepted by bash.

## Versioning

The version string is an extension to semver, the format looks like `11.3.0-1`.
It includes the three digits with the original GCC version and a fourth
digit with the xPack release number.

When publishing on the **npmjs.com** server, a fifth digit is appended.

## Changes

Compared to the original GNU Compiler Collection distribution,
there should be no functional changes.

The actual changes for each version are documented in the
release web pages.

## How to build local/native binaries

### README-DEVELOP.md

The details on how to prepare the development environment for
GNU Compiler Collection are in the
[`README-DEVELOP.md`](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-DEVELOP.md) file.

## How to build distributions

## Build

The builds currently run on 5 dedicated machines (Intel GNU/Linux,
Arm 32 GNU/Linux, Arm 64 GNU/Linux, Intel macOS and Arm macOS.

### Build the Intel GNU/Linux and Windows binaries

The current platform for GNU/Linux and Windows production builds is a
Debian 11, running on an AMD 5600G PC with 16 GB of RAM
and 512 GB of fast M.2 SSD. The machine name is `xbbli`.

```sh
caffeinate ssh xbbli
```

Before starting a build, check if Docker is started:

```sh
docker info
```

Before running a build for the first time, it is recommended to preload the
docker images.

```sh
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh preload-images
```

The result should look similar to:

```console
$ docker images
REPOSITORY       TAG                    IMAGE ID       CREATED         SIZE
ilegeul/ubuntu   amd64-18.04-xbb-v3.4   ace5ae2e98e5   4 weeks ago     5.11GB
```

It is also recommended to Remove unused Docker space. This is mostly useful
after failed builds, during development, when dangling images may be left
by Docker.

To check the content of a Docker image:

```sh
docker run --interactive --tty ilegeul/ubuntu:amd64-18.04-xbb-v3.4
```

To remove unused files:

```sh
docker system prune --force
```

Since the build takes a while, use `screen` to isolate the build session
from unexpected events, like a broken
network connection or a computer entering sleep.

```sh
screen -S gcc

sudo rm -rf ~/Work/mingw-w64-gcc-*-*
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --linux64 --win64
```

or, for development builds:

```sh
sudo rm -rf ~/Work/mingw-w64-gcc-*-*
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --linux64 --win64
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r gcc`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 110 minutes later, the output of the build script is a set of 4
archives and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l ~/Work/mingw-w64-gcc-*/deploy
total 491416
-rw-rw-rw- 1 ilg ilg 229104864 Sep 25 17:24 xpack-mingw-w64-gcc-11.3.0-1-linux-x64.tar.gz
-rw-rw-rw- 1 ilg ilg       112 Sep 25 17:24 xpack-mingw-w64-gcc-11.3.0-1-linux-x64.tar.gz.sha
-rw-rw-rw- 1 ilg ilg 274091888 Sep 25 18:08 xpack-mingw-w64-gcc-11.3.0-1-win32-x64.zip
-rw-rw-rw- 1 ilg ilg       109 Sep 25 18:08 xpack-mingw-w64-gcc-11.3.0-1-win32-x64.zip.sha
```

### Build the Arm GNU/Linux binaries

The supported Arm architectures are:

- `armhf` for 32-bit devices
- `aarch64` for 64-bit devices

The current platform for Arm GNU/Linux production builds is Raspberry Pi OS,
running on a pair of Raspberry Pi4s, for separate 64/32 binaries.
The machine names are `xbbla64` and `xbbla32`.

```sh
caffeinate ssh xbbla64
caffeinate ssh xbbla32
```

Before starting a build, check if Docker is started:

```sh
docker info
```

Before running a build for the first time, it is recommended to preload the
docker images.

```sh
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh preload-images
```

The result should look similar to:

```console
$ docker images
REPOSITORY       TAG                      IMAGE ID       CREATED          SIZE
hello-world      latest                   46331d942d63   6 weeks ago     9.14kB
ilegeul/ubuntu   arm64v8-18.04-xbb-v3.4   4e7f14f6c886   4 months ago    3.29GB
ilegeul/ubuntu   arm32v7-18.04-xbb-v3.4   a3718a8e6d0f   4 months ago    2.92GB
```

Since the build takes a while, use `screen` to isolate the build session
from unexpected events, like a broken
network connection or a computer entering sleep.

```sh
screen -S gcc

sudo rm -rf ~/Work/mingw-w64-gcc-*-*
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --arm64 --arm32
```

or, for development builds:

```sh
sudo rm -rf ~/Work/mingw-w64-gcc-*-*
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --arm64 --arm32
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r gcc`; to kill the session use `Ctrl-a` `Ctrl-k` and confirm.

About 290 minutes later, the output of the build script is a set of 2
archives and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l ~/Work/mingw-w64-gcc-*/deploy
total 217676
-rw-rw-rw- 1 ilg ilg 222894574 Sep 25 14:59 xpack-mingw-w64-gcc-11.3.0-1-linux-arm64.tar.gz
-rw-rw-rw- 1 ilg ilg       114 Sep 25 14:59 xpack-mingw-w64-gcc-11.3.0-1-linux-arm64.tar.gz.sha
```

and

```console
$ ls -l ~/Work/mingw-w64-gcc-*/deploy
total 204220
-rw-rw-rw- 1 ilg ilg 209114896 Sep 25 14:56 xpack-mingw-w64-gcc-11.3.0-1-linux-arm.tar.gz
-rw-rw-rw- 1 ilg ilg       112 Sep 25 14:56 xpack-mingw-w64-gcc-11.3.0-1-linux-arm.tar.gz.sha
```

### Build the macOS binaries

The current platforms for macOS production builds are:

- a macOS 10.13.6 running on a MacBook Pro 2011 with 32 GB of RAM and
  a fast SSD; the machine name is `xbbmi`
- a macOS 11.6.1 running on a Mac Mini M1 2020 with 16 GB of RAM;
  the machine name is `xbbma`

```sh
caffeinate ssh xbbmi
caffeinate ssh xbbma
```

To build the latest macOS version:

```sh
screen -S gcc

rm -rf ~/Work/mingw-w64-gcc-*-*
caffeinate bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --macos
```

or, for development builds:

```sh
rm -rf ~/Work/mingw-w64-gcc-arm-*-*
caffeinate bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --develop --without-html --disable-tests --macos
```

To detach from the session, use `Ctrl-a` `Ctrl-d`; to reattach use
`screen -r gcc`; to kill the session use `Ctrl-a` `Ctrl-\` or
`Ctrl-a` `Ctrl-k` and confirm.

About 60 minutes later, the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/mingw-w64-gcc-*/deploy
total 491784
-rw-r--r--  1 ilg  staff  239159901 Sep 25 17:46 xpack-mingw-w64-gcc-11.3.0-1-darwin-x64.tar.gz
-rw-r--r--  1 ilg  staff        113 Sep 25 17:46 xpack-mingw-w64-gcc-11.3.0-1-darwin-x64.tar.gz.sha
```

and

```console
$ ls -l ~/Work/mingw-w64-gcc-*/deploy
total 492424
-rw-r--r--  1 ilg  staff  239527734 Sep 25 15:56 xpack-mingw-w64-gcc-11.3.0-1-darwin-arm64.tar.gz
-rw-r--r--  1 ilg  staff        115 Sep 25 15:56 xpack-mingw-w64-gcc-11.3.0-1-darwin-arm64.tar.gz.sha
```


## Subsequent runs

### Separate platform specific builds

Instead of `--all`, you can use any combination of:

```console
--linux64 --win64
```

On Arm, instead of `--all`, you can use any combination of:

```console
--arm64 --arm32
```

### `clean`

To remove most build temporary files, use:

```sh
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --all clean
```

To also remove the library build temporary files, use:

```sh
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --all cleanlibs
```

To remove all temporary files, use:

```sh
bash ${HOME}/Work/mingw-w64-gcc-xpack.git/scripts/helper/build.sh --all cleanall
```

Instead of `--all`, any combination of `--win64 --linux64`
will remove the more specific folders.

For production builds it is recommended to completely remove the build folder.

### `--develop`

For performance reasons, the actual build folders are internal to each
Docker run, and are not persistent. This gives the best speed, but has
the disadvantage that interrupted builds cannot be resumed.

For development builds, it is possible to define the build folders in
the host file system, and resume an interrupted build.

### `--debug`

For development builds, it is also possible to create everything with
`-g -O0` and be able to run debug sessions.

### --jobs

By default, the build steps use all available cores. If, for any reason,
parallel builds fail, it is possible to reduce the load.

### Interrupted builds

The Docker scripts run with root privileges. This is generally not a
problem, since at the end of the script the output files are reassigned
to the actual user.

However, for an interrupted build, this step is skipped, and files in
the install folder will remain owned by root. Thus, before removing
the build folder, it might be necessary to run a recursive `chown`.

## Testing

A simple test is performed by the script at the end, by launching the
executable to check if all shared/dynamic libraries are correctly used.

For a true test you need to unpack the archive in a temporary location
(like `~/Downloads`) and then run the
program from there. For example on macOS the output should
look like:

```console
$ .../xpack-mingw-w64-gcc-11.3.0-1/bin/x86_64-w64-mingw32-gcc --version
x86_64-w64-mingw32-gcc (xPack MinGW-w64 GCC x86_64) 11.3.0
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

## Installed folders

After install, the package should create a structure like this (macOS files;
only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/Library/xPacks/\@xpack-dev-tools/mingw-w64-gcc/11.3.0-1.1/.content/
/Users/ilg/Library/xPacks/@xpack-dev-tools/mingw-w64-gcc/11.3.0-1.1/.content/
├── README.md
├── bin
│   ├── i686-w64-mingw32-addr2line
│   ├── i686-w64-mingw32-ar
│   ├── i686-w64-mingw32-as
│   ├── i686-w64-mingw32-c++
│   ├── i686-w64-mingw32-c++filt
│   ├── i686-w64-mingw32-cpp
│   ├── i686-w64-mingw32-dlltool
│   ├── i686-w64-mingw32-dllwrap
│   ├── i686-w64-mingw32-elfedit
│   ├── i686-w64-mingw32-g++
│   ├── i686-w64-mingw32-gcc
│   ├── i686-w64-mingw32-gcc-11.3.0
│   ├── i686-w64-mingw32-gcc-ar
│   ├── i686-w64-mingw32-gcc-nm
│   ├── i686-w64-mingw32-gcc-ranlib
│   ├── i686-w64-mingw32-gcov
│   ├── i686-w64-mingw32-gcov-dump
│   ├── i686-w64-mingw32-gcov-tool
│   ├── i686-w64-mingw32-gendef
│   ├── i686-w64-mingw32-gfortran
│   ├── i686-w64-mingw32-gprof
│   ├── i686-w64-mingw32-ld
│   ├── i686-w64-mingw32-ld.bfd
│   ├── i686-w64-mingw32-lto-dump
│   ├── i686-w64-mingw32-nm
│   ├── i686-w64-mingw32-objcopy
│   ├── i686-w64-mingw32-objdump
│   ├── i686-w64-mingw32-ranlib
│   ├── i686-w64-mingw32-readelf
│   ├── i686-w64-mingw32-size
│   ├── i686-w64-mingw32-strings
│   ├── i686-w64-mingw32-strip
│   ├── i686-w64-mingw32-widl
│   ├── i686-w64-mingw32-windmc
│   ├── i686-w64-mingw32-windres
│   ├── x86_64-w64-mingw32-addr2line
│   ├── x86_64-w64-mingw32-ar
│   ├── x86_64-w64-mingw32-as
│   ├── x86_64-w64-mingw32-c++
│   ├── x86_64-w64-mingw32-c++filt
│   ├── x86_64-w64-mingw32-cpp
│   ├── x86_64-w64-mingw32-dlltool
│   ├── x86_64-w64-mingw32-dllwrap
│   ├── x86_64-w64-mingw32-elfedit
│   ├── x86_64-w64-mingw32-g++
│   ├── x86_64-w64-mingw32-gcc
│   ├── x86_64-w64-mingw32-gcc-11.3.0
│   ├── x86_64-w64-mingw32-gcc-ar
│   ├── x86_64-w64-mingw32-gcc-nm
│   ├── x86_64-w64-mingw32-gcc-ranlib
│   ├── x86_64-w64-mingw32-gcov
│   ├── x86_64-w64-mingw32-gcov-dump
│   ├── x86_64-w64-mingw32-gcov-tool
│   ├── x86_64-w64-mingw32-gendef
│   ├── x86_64-w64-mingw32-gfortran
│   ├── x86_64-w64-mingw32-gprof
│   ├── x86_64-w64-mingw32-ld
│   ├── x86_64-w64-mingw32-ld.bfd
│   ├── x86_64-w64-mingw32-lto-dump
│   ├── x86_64-w64-mingw32-nm
│   ├── x86_64-w64-mingw32-objcopy
│   ├── x86_64-w64-mingw32-objdump
│   ├── x86_64-w64-mingw32-ranlib
│   ├── x86_64-w64-mingw32-readelf
│   ├── x86_64-w64-mingw32-size
│   ├── x86_64-w64-mingw32-strings
│   ├── x86_64-w64-mingw32-strip
│   ├── x86_64-w64-mingw32-widl
│   ├── x86_64-w64-mingw32-windmc
│   └── x86_64-w64-mingw32-windres
├── distro-info
│   ├── CHANGELOG.md
│   ├── licenses
│   ├── patches
│   └── scripts
├── i686-w64-mingw32
│   ├── bin
│   ├── include
│   └── lib
├── include
├── lib
│   ├── bfd-plugins
│   ├── gcc
│   ├── libcc1.0.so
│   ├── libcc1.a
│   ├── libcc1.la
│   └── libcc1.so -> libcc1.0.so
├── libexec
│   ├── libgcc_s.1.dylib
│   ├── libgmp.10.dylib
│   ├── libiconv.2.dylib
│   ├── libisl.23.dylib
│   ├── libmpc.3.dylib
│   ├── libmpfr.6.dylib
│   ├── libstdc++.6.dylib
│   ├── libz.1.2.11.dylib
│   └── libz.1.dylib -> libz.1.2.11.dylib
├── share
│   ├── gcc-11.3.0
│   └── locale
└── x86_64-w64-mingw32
    ├── bin
    ├── include
    └── lib

21 directories, 85 files
```

No other files are installed in any system folders or other locations.

## Uninstall

The binaries are distributed as portable archives; thus they do not need
to run a setup and do not require an uninstall; simply removing the
folder is enough.

## Files cache

The XBB build scripts use a local cache such that files are downloaded only
during the first run, later runs being able to use the cached files.

However, occasionally some servers may not be available, and the builds
may fail.

The workaround is to manually download the files from an alternate
location (like
<https://github.com/xpack-dev-tools/files-cache/tree/master/libs>),
place them in the XBB cache (`Work/cache`) and restart the build.

## More build details

The build process is split into several scripts. The build starts on
the host, with `build.sh`, which runs `container-build.sh` several
times, once for each target, in one of the two docker containers.
Both scripts include several other helper scripts. The entire process
is quite complex, and an attempt to explain its functionality in a few
words would not be realistic. Thus, the authoritative source of details
remains the source code.
