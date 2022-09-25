
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/xpack-dev-tools/mingw-w64-gcc-xpack)](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases)
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/mingw-w64-gcc.svg)](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc/)

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

### Compiler DLLs

For projects that create multiple executables, using static libraries
is not space efficient, especially for C++, since the code is multiplied
in all executables.

The solution is to copy the required DLLs to the folder where the
compiled .exe files will be installed (like `/bin`).

```console
$ ls -l $(dirname $(bin/x86_64-w64-mingw32-g++ -print-file-name=libstdc++-6.dll))/*.dll
-rwxr-xr-x 1 ilg ilg   38296 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libatomic-1.dll
-rwxr-xr-x 1 ilg ilg  535781 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libgcc_s_seh-1.dll
-rwxr-xr-x 1 ilg ilg 2981114 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libgfortran-5.dll
-rwxr-xr-x 1 ilg ilg  247187 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libgomp-1.dll
-rwxr-xr-x 1 ilg ilg  383320 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libquadmath-0.dll
-rwxr-xr-x 1 ilg ilg   22227 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libssp-0.dll
-rwxr-xr-x 1 ilg ilg 1940952 Sep 20 13:00 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libstdc++-6.dll
-rwxr-xr-x 1 ilg ilg  106093 Sep 20 12:58 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/x86_64-w64-mingw32/11.3.0/../../../../x86_64-w64-mingw32/lib/../lib/libwinpthread-1.dll
```

and

```console
$ ls -l $(dirname $(bin/i686-w64-mingw32-g++ -print-file-name=libstdc++-6.dll))/*.dll
-rwxr-xr-x 1 ilg ilg   37356 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libatomic-1.dll
-rwxr-xr-x 1 ilg ilg  652335 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libgcc_s_dw2-1.dll
-rwxr-xr-x 1 ilg ilg 2753320 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libgfortran-5.dll
-rwxr-xr-x 1 ilg ilg  266392 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libgomp-1.dll
-rwxr-xr-x 1 ilg ilg  570355 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libquadmath-0.dll
-rwxr-xr-x 1 ilg ilg   22328 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libssp-0.dll
-rwxr-xr-x 1 ilg ilg 2081167 Sep 20 13:08 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libstdc++-6.dll
-rwxr-xr-x 1 ilg ilg  112374 Sep 20 13:06 /home/ilg/Work/mingw-w64-gcc-11.3.0-1-static/linux-x64/install/mingw-w64-gcc/bin/../lib/gcc/i686-w64-mingw32/11.3.0/../../../../i686-w64-mingw32/lib/../lib/libwinpthread-1.dll
```

### Easy install

The easiest way to install GCC is using the **binary xPack**, available as
[`@xpack-dev-tools/mingw-w64-gcc`](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc)
from the [`npmjs.com`](https://www.npmjs.com) registry.

#### Prerequisites

The only requirement is a recent
`xpm`, which is a portable
[Node.js](https://nodejs.org) command line application. To install it,
follow the instructions from the
[xpm](https://xpack.github.io/xpm/install/) page.

#### Install

With the `xpm` tool available, installing
the latest version of the package and adding it as
a dependency for a project is quite easy:

```sh
cd my-project
xpm init # Only at first use.

xpm install @xpack-dev-tools/mingw-w64-gcc@latest

ls -l xpacks/.bin
```

This command will:

- install the latest available version,
into the central xPacks store, if not already there
- add symbolic links to the central store
(or `.cmd` forwarders on Windows) into
the local `xpacks/.bin` folder.

The central xPacks store is a platform dependent
folder; check the output of the `xpm` command for the actual
folder used on your platform).
This location is configurable via the environment variable
`XPACKS_STORE_FOLDER`; for more details please check the
[xpm folders](https://xpack.github.io/xpm/folders/) page.

It is also possible to install GCC globally, in the user home folder:

```sh
xpm install --global @xpack-dev-tools/mingw-w64-gcc@latest
```

#### Uninstall

To remove the links from the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/mingw-w64-gcc
```

To completely remove the package from the global store:

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
like `11.3.0`; to this string the xPack distribution adds a four number,
but since semver allows only three numbers, all additional ones can
be added only as pre-release strings, separated by a dash,
like `11.3.0-1`. When published as a npm package, the version gets
a fifth number, like `11.3.0-1.1`.

Since adherence of third party packages to semver is not guaranteed,
it is recommended to use semver expressions like `^11.3.0` and `~11.3.0`
with caution, and prefer exact matches, like `11.3.0-1.1`.

## Maintainer info

- [How to build](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-BUILD.md)
- [How to make new releases](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-RELEASE.md)
- [How to develop](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-DEVELOP.md)

## Support

The quick answer is to use the GitHub
[Discussions](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/discussions/).

For more details please read the
[Support](https://xpack.github.io/mingw-w64-gcc/support/) page.

## License

The original content is released under the
[MIT License](https://opensource.org/licenses/MIT), with all rights
reserved to [Liviu Ionescu](https://github.com/ilg-ul/).

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
