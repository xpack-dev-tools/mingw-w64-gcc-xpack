---
title:  xPack MinGW-w64 GCC v{{ RELEASE_VERSION }} released

TODO: select one summary

summary: "Version **{{ RELEASE_VERSION }}** is a maintenance release; it updates to
the latest upstream master."

summary: "Version **{{ RELEASE_VERSION }}** is a new release; it follows the official GNU GCC release."

version: "{{ RELEASE_VERSION }}"
npm_subversion: 1
download_url: https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/releases/tag/v{{ RELEASE_VERSION }}/

date:   {{ RELEASE_DATE }}

categories:
  - releases
  - gcc

tags:
  - releases
  - gcc

---

[The xPack MinGW-w64 GCC](https://xpack.github.io/mingw-w64-gcc/)
is a standalone cross-platform binary distribution of
[GCC](http://gcc.org).

There are binaries for **GNU/Linux** (Intel 64-bit).

## Download

The binary files are available from GitHub [Releases]({% raw %}{{ page.download_url }}{% endraw %}).

## Prerequisites

- GNU/Linux Intel 64-bit: any system with **GLIBC 2.27** or higher
  (like Ubuntu 18 or later, Debian 10 or later, RedHat 8 later,
  Fedora 29 or later, etc)

## Install

The full details of installing the **xPack MinGW-w64 GCC** on various platforms
are presented in the separate
[Install]({% raw %}{{ site.baseurl }}{% endraw %}/gcc/install/) page.

### Easy install

The easiest way to install GCC is with
[`xpm`]({% raw %}{{ site.baseurl }}{% endraw %}/xpm/)
by using the **binary xPack**, available as
[`@xpack-dev-tools/mingw-w64-gcc`](https://www.npmjs.com/package/@xpack-dev-tools/mingw-w64-gcc)
from the [`npmjs.com`](https://www.npmjs.com) registry.

With the `xpm` tool available, installing
the latest version of the package and adding it as
a dependency for a project is quite easy:

```sh
cd my-project
xpm init # Only at first use.

xpm install @xpack-dev-tools/mingw-w64-gcc@latest

ls -l xpacks/.bin
```

To install this specific version, use:

```sh
xpm install @xpack-dev-tools/mingw-w64-gcc@{% raw %}{{ page.version }}.{{ page.npm_subversion }}{% endraw %}
```

It is also possible to install Meson Build globally, in the user home folder,
but this requires xPack aware tools to automatically identify them and
manage paths.

```sh
xpm install --global @xpack-dev-tools/mingw-w64-gcc@latest
```

### Uninstall

To remove the links from the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/mingw-w64-gcc
```

To completely remove the package from the global store:

```sh
xpm uninstall --global @xpack-dev-tools/mingw-w64-gcc
```

## Compliance

The xPack MinGW-w64 GCC generally follows the official
[GCC](http://gcc.org) releases.

The current version is based on:

- GCC version [11.3.0](https://gcc.gnu.org/gcc-11/) from Aug 19, 2022;
- binutils version
[2.38](https://lists.gnu.org/archive/html/info-gnu/2022-02/msg00009.html)
from Feb 9, 2022.

## Supported languages

The supported languages are:

- C
- C++
- Obj-C
- Obj-C++

Note: Obj-C/C++ support is minimalistic.

## Changes

Compared to the upstream, there are no functional changes.

## Bug fixes

- none

## Enhancements

- none

## Known problems

- none

## Shared libraries

On all platforms the packages are standalone, and expect only the standard
runtime to be present on the host.

All dependencies that are build as shared libraries are copied locally
in the `libexec` folder (or in the same folder as the executable for Windows).

### `DT_RPATH` and `LD_LIBRARY_PATH`

On GNU/Linux the binaries are adjusted to use a relative path:

```console
$ readelf -d library.so | grep runpath
 0x000000000000001d (RPATH)            Library rpath: [$ORIGIN]
```

In the GNU ld.so search strategy, the `DT_RPATH` has
the highest priority, higher than `LD_LIBRARY_PATH`, so if this later one
is set in the environment, it should not interfere with the xPack binaries.

Please note that previous versions, up to mid-2020, used `DT_RUNPATH`, which
has a priority lower than `LD_LIBRARY_PATH`, and does not tolerate setting
it in the environment.

### `@rpath` and `@loader_path`

Similarly, on macOS, the binaries are adjusted with `install_name_tool` to use a
relative path.

## Documentation

To save space and bandwidth, the original GNU GCC documentation is available
[online](https://gcc.gnu.org/onlinedocs/).

## Build

The binaries for all supported platforms
(Windows, macOS and GNU/Linux) were built using the
[xPack Build Box (XBB)](https://xpack.github.io/xbb/), a set
of build environments based on slightly older distributions, that should be
compatible with most recent systems.

The scripts used to build this distribution are in:

- `distro-info/scripts`

For the prerequisites and more details on the build procedure, please see the
[How to build](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/blob/xpack/README-BUILD.md) page.

## CI tests

Before publishing, a set of simple tests were performed on an exhaustive
set of platforms. The results are available from:

- [GitHub Actions](https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/actions/)
- [Travis CI](https://app.travis-ci.com/github/xpack-dev-tools/mingw-w64-gcc-xpack/builds/)

## Tests

The binaries were tested on a variety of platforms,
but mainly to check the integrity of the
build, not the compiler functionality.

## Checksums

The SHA-256 hashes for the files are:
