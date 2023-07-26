
[![GitHub package.json version](https://img.shields.io/github/package-json/v/xpack-dev-tools/mingw-w64-gcc-xpack)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/package.json)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/xpack-dev-tools/mingw-w64-gcc-xpack)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/)
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/mingw-w64-gcc.svg?color=blue)](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/)
[![license](https://img.shields.io/github/license/xpack-dev-tools/mingw-w64-gcc-xpack)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/LICENSE)

# The xPack MinGW-w64 GNU Compiler Collection (GCC)

A standalone cross-platform (Windows/macOS/Linux) **MinGW-w64 GCC**
binary distribution, intended for reproducible builds.

In addition to the the binary archives and the package meta data,
this project also includes the build scripts.

## Overview

This open source project is hosted on GitHub as
[`xpack-dev-tools/mingw-w64-gcc-xpack`](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack)
and provides the platform specific binaries for the
[xPack MinGW-w64 GNU Compiler Collection](https://xpack.github.io/mingw-w64-gcc/);
it includes, in addition to project metadata, the full build scripts.

The binaries can be installed automatically as **binary xPacks** or manually as
**portable archives**.

## Release schedule

This distribution generally follows the official
[GNU Compiler Collection](https://gcc.gnu.org) releases.

## User info

This section is intended as a shortcut for those who plan
to use the GCC binaries. For full details please read the
[xPack MinGW-w64 GNU Compiler Collection](https://xpack.github.io/mingw-w64-gcc/) pages.

### Supported languages

The xPack MinGW-w64 GCC binaries include support for:

- C
- C++
- Fortran
- Obj-C
- Obj-C++

Note: Obj-C support is minimalistic.

### `-static-libgcc -static-libstdc++`

To avoid issues with DLLs, specific when using toolchains installed
in custom locations, it is highly recommended to use only the
static versions of the GCC libraries.

For C programs, append `-static-libgcc` to the linker line.

For C++ programs, since the toolchain is configured to use POSIX threads,
instead of `-static-libstdc++`, use the more explicit variant
`-Wl,-Bstatic,-lstdc++,-lpthread,-Bdynamic` when invoking the linker.

### libwinpthread-1.dll

Due to the specifics of the MinGW-w64 build, the threading library is
not very well integrated into the build, and invoking the compiler
with `-static-libgcc -static-libstdc++` does not apply to this DLL,
so the resulting binaries might still have a reference to it.

### Compiler DLLs

For projects that create multiple executables, using static libraries
is not space efficient, especially for C++, since the code is multiplied
in all executables.

The solution is to copy the required DLLs to the folder where the
compiled .exe files will be installed (like `/bin`).

```console
$ ls -l $(dirname $(bin/x86_64-w64-mingw32-g++ -print-file-name=libstdc++-6.dll))/*.dll
-rwxr-xr-x 1 ilg ilg   38296 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libatomic-1.dll
-rwxr-xr-x 1 ilg ilg  535781 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libgcc_s_seh-1.dll
-rwxr-xr-x 1 ilg ilg 2981114 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libgfortran-5.dll
-rwxr-xr-x 1 ilg ilg  247187 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libgomp-1.dll
-rwxr-xr-x 1 ilg ilg  383320 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libquadmath-0.dll
-rwxr-xr-x 1 ilg ilg   22227 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libssp-0.dll
-rwxr-xr-x 1 ilg ilg 1940952 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libstdc++-6.dll
-rwxr-xr-x 1 ilg ilg  106093 Sep 20 12:58 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/12.2.0/../../../../x86_64-w64-mingw32/lib/../lib/libwinpthread-1.dll
```

and

```console
$ ls -l $(dirname $(bin/i686-w64-mingw32-g++ -print-file-name=libstdc++-6.dll))/*.dll
-rwxr-xr-x 1 ilg ilg   37356 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libatomic-1.dll
-rwxr-xr-x 1 ilg ilg  652335 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libgcc_s_dw2-1.dll
-rwxr-xr-x 1 ilg ilg 2753320 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libgfortran-5.dll
-rwxr-xr-x 1 ilg ilg  266392 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libgomp-1.dll
-rwxr-xr-x 1 ilg ilg  570355 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libquadmath-0.dll
-rwxr-xr-x 1 ilg ilg   22328 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libssp-0.dll
-rwxr-xr-x 1 ilg ilg 2081167 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libstdc++-6.dll
-rwxr-xr-x 1 ilg ilg  112374 Sep 20 13:06 /home/ilg/Work/mingw-w64-gcc-12.2.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/12.2.0/../../../../i686-w64-mingw32/lib/../lib/libwinpthread-1.dll
```

### Easy install

The easiest way to install GCC is using the **binary xPack**, available as
[`@xpack-dev-tools/mingw-w64-gcc`](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc)
from the [`npmjs.com`](https://www.npmjs.com) registry.

#### Prerequisites

A recent [xpm](https://xpack.github.io/xpm/),
which is a portable [Node.js](https://nodejs.org/) command line application
that complements [npm](https://docs.npmjs.com)
with several extra features specific to
**C/C++ projects**.

It is recommended to install/update to the latest version with:

```sh
npm install --location=global xpm@latest
```

For details please follow the instructions in the
[xPack install](https://xpack.github.io/install/) page.

#### Install

With the `xpm` tool available, installing
the latest version of the package and adding it as
a development dependency for a project is quite easy:

```sh
cd my-project
xpm init # Add a package.json if not already present

xpm install @xpack-dev-tools/mingw-w64-gcc@latest --verbose

ls -l xpacks/.bin
```

This command will:

- install the latest available version,
into the central xPacks store, if not already there
- add symbolic links to the central store
(or `.cmd` forwarders on Windows) into
the local `xpacks/.bin` folder.

The central xPacks store is a platform dependent
location in the home folder;
check the output of the `xpm` command for the actual
folder used on your platform.
This location is configurable via the environment variable
`XPACKS_STORE_FOLDER`; for more details please check the
[xpm folders](https://xpack.github.io/xpm/folders/) page.

It is also possible to install GCC globally, in the user home folder:

```sh
xpm install --global @xpack-dev-tools/mingw-w64-gcc@latest --verbose
```

After install, the package should create a structure like this (macOS files;
only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/Library/xPacks/@xpack-dev-tools/mingw-w64-gcc/12.2.0-1.1/.content/
/Users/ilg/Library/xPacks/@xpack-dev-tools/mingw-w64-gcc/12.2.0-1.1/.content/
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
│   ├── i686-w64-mingw32-gcc-12.2.0
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
│   ├── x86_64-w64-mingw32-gcc-12.2.0
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
│   ├── ctf-api.h
│   ├── ctf.h
│   └── libiberty
├── lib
│   ├── bfd-plugins
│   ├── gcc
│   ├── libcc1.0.so
│   ├── libcc1.a
│   ├── libcc1.la
│   ├── libcc1.so -> libcc1.0.so
│   ├── libctf-nobfd.0.dylib
│   ├── libctf-nobfd.a
│   ├── libctf-nobfd.dylib -> libctf-nobfd.0.dylib
│   ├── libctf-nobfd.la
│   ├── libctf.0.dylib
│   ├── libctf.a
│   ├── libctf.dylib -> libctf.0.dylib
│   ├── libctf.la
│   └── libiberty.a
├── libexec
│   ├── libgmp.10.dylib
│   ├── libiconv.2.dylib
│   ├── libisl.23.dylib
│   ├── libmpc.3.dylib
│   ├── libmpfr.6.dylib
│   ├── libz.1.2.11.dylib
│   ├── libz.1.dylib -> libz.1.2.11.dylib
│   └── libzstd.1.5.2.dylib
├── share
│   └── gcc-12.2.0
├── x86_64-apple-darwin21.6.0
│   ├── i686-w64-mingw32
│   └── x86_64-w64-mingw32
└── x86_64-w64-mingw32
    ├── bin
    ├── include
    └── lib

24 directories, 95 files
```

No other files are installed in any system folders or other locations.

#### Uninstall

To remove the links created by xpm in the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/mingw-w64-gcc
```

To completely remove the package from the central xPack store:

```sh
xpm uninstall --global @xpack-dev-tools/mingw-w64-gcc
```

### Manual install

For all platforms, the **xPack MinGW-w64 GNU Compiler Collection**
binaries are released as portable
archives that can be installed in any location.

The archives can be downloaded from the
GitHub [Releases](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/)
page.

For more details please read the
[Install](https://xpack.github.io/mingw-w64-gcc/install/) page.

### Versioning

The version strings used by the GCC project are three number strings
like `12.2.0`; to this string the xPack distribution adds a four number,
but since semver allows only three numbers, all additional ones can
be added only as pre-release strings, separated by a dash,
like `12.2.0-1`. When published as a npm package, the version gets
a fifth number, like `12.2.0-1.1`.

Since adherence of third party packages to semver is not guaranteed,
it is recommended to use semver expressions like `^12.2.0` and `~12.2.0`
with caution, and prefer exact matches, like `12.2.0-1.1`.

## Maintainer info

For maintainer info, please see the
[README-MAINTAINER](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-MAINTAINER.md).

## Support

The quick advice for getting support is to use the GitHub
[Discussions](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/discussions/).

For more details please read the
[Support](https://xpack.github.io/mingw-w64-gcc/support/) page.

## License

Unless otherwise stated, the content is released under the terms of the
[MIT License](https://opensource.org/licenses/mit/),
with all rights reserved to
[Liviu Ionescu](https://github.com/ilg-ul).

The binary distributions include several open-source components; the
corresponding licenses are available in the installed
`distro-info/licenses` folder.

## Download analytics

- GitHub [`xpack-dev-tools/mingw-w64-gcc-xpack`](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/) repo
  - latest xPack release
[![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/mingw-w64-gcc-xpack/latest/total.svg)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/)
  - all xPack releases [![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/mingw-w64-gcc-xpack/total.svg)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/)
  - [individual file counters](https://somsubhra.github.io/github-release-stats/?username=xpack-dev-tools&repository=gcc-xpack) (grouped per release)
- npmjs.com [`@xpack-dev-tools/mingw-w64-gcc`](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/) xPack
  - latest release, per month
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/mingw-w64-gcc.svg)](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/)
[![npm](https://img.shields.io/npm/dm/@xpack-dev-tools/mingw-w64-gcc.svg)](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/)
  - all releases [![npm](https://img.shields.io/npm/dt/@xpack-dev-tools/mingw-w64-gcc.svg)](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/)

Credit to [Shields IO](https://shields.io) for the badges and to
[Somsubhra/github-release-stats](https://github.com/Somsubhra/github-release-stats)
for the individual file counters.
