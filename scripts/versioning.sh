# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

# To build mingw-w64-gcc for Windows on Linux, a bootstrap with exactly the
# same version of GCC & mingw-w64 is required, otherwise some
# headers might not be there, like:
# libsrc/bits.c:15:10: fatal error: bits2_5.h: No such file or directory

# -----------------------------------------------------------------------------

function gcc_mingw_build_common()
{
  mingw_download "${XBB_MINGW_VERSION}"

  # -------------------------------------------------------------------------
  # Build the native dependencies.

  libiconv_build "${XBB_LIBICONV_VERSION}"

  ncurses_build "${XBB_NCURSES_VERSION}"

  # new makeinfo needed by binutils 2.41 and up
  # checking for suffix of object files...   MAKEINFO doc/bfd.info
  # /Users/ilg/Work/xpack-dev-tools-build/riscv-none-elf-gcc-13.2.0-1/darwin-x64/sources/binutils-2.41/bfd/doc/bfd.texi:245: Node `Sections' requires a sectioning command (e.g., @unnumberedsubsec).
  # Note: binutils_build needs xbb_activate_installed_bin.

  # Requires libiconf & ncurses.
  texinfo_build "${XBB_TEXINFO_VERSION}"

  # -------------------------------------------------------------------------
  # Build the target dependencies.

  xbb_reset_env
  xbb_set_target "mingw-w64-native"

  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then
    (
      # Build the bootstrap (a native Linux application).
      # The results are in:
      # - x86_64-pc-linux-gnu/install/bin (executables)
      # - x86_64-pc-linux-gnu/x86_64-w64-mingw32/build
      # - x86_64-pc-linux-gnu/x86_64-w64-mingw32/install/include
      # - x86_64-pc-linux-gnu/x86_64-w64-mingw32/install/lib
      gcc_mingw_build_dependencies

      gcc_mingw_build_all_triplets
    )

    xbb_reset_env
    # Before set target (to possibly update CC & co variables).
    xbb_activate_installed_bin

    xbb_set_target "mingw-w64-cross"
  fi

  # Switch used during development to test bootstrap.
  if [ "${XBB_APPLICATION_BOOTSTRAP_ONLY:-""}" != "y" ]
  then

    gcc_mingw_build_dependencies

    # -------------------------------------------------------------------------
    # Build the application binaries.

    xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
    xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

    (
      # To access makeinfo, needed by binutils.
      xbb_activate_installed_bin "${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin"

      gcc_mingw_build_all_triplets
    )

  fi

  # Save a few MB.
  rm -rf "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/info"
}

# -----------------------------------------------------------------------------

function application_build_versioned_components()
{
  export XBB_GCC_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 GCC ${XBB_REQUESTED_TARGET_MACHINE}"
  export XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils ${XBB_REQUESTED_TARGET_MACHINE}"

  export XBB_GCC_VERSION="$(xbb_strip_version_pre_release "${XBB_RELEASE_VERSION}")"
  export XBB_GCC_VERSION_MAJOR=$(xbb_get_version_major "${XBB_GCC_VERSION}")

  # ---------------------------------------------------------------------------

  export XBB_GCC_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 GCC${XBB_BOOTSTRAP_SUFFIX} ${XBB_TARGET_MACHINE}"
  export XBB_BINUTILS_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils${XBB_BOOTSTRAP_SUFFIX} ${XBB_TARGET_MACHINE}"

  export XBB_GCC_SRC_FOLDER_NAME="gcc-${XBB_GCC_VERSION}"

  # There is no GDB, since this is strictly a cross toolchain, and the
  # binaries run only on Windows.

  # 32-bit first, since it is more probable to fail.
  XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" "x86_64-w64-mingw32" )
  # XBB_MINGW_TRIPLETS=( "x86_64-w64-mingw32" ) # Use it temporarily during tests.
  # XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" ) # Use it temporarily during tests.

  # ---------------------------------------------------------------------------

  # Keep the versions in sync with gcc-xpack.
  # https://ftp.gnu.org/gnu/gcc/
  # The release date for XX.1.0 seems to be May, and for XX.2.0 August.

  # XBB_GCC_GIT_URL="git://gcc.gnu.org/git/gcc.git"
  # XBB_GCC_GIT_URL="https://github.com/gcc-mirror/gcc.git"
  # XBB_GCC_GIT_BRANCH="master"
  # XBB_GCC_GIT_COMMIT="fe99ab1f5e9920fd46ef8148fcffde6729d68523"

  # ---------------------------------------------------------------------------
  if [[ "${XBB_RELEASE_VERSION}" =~ 11[.][5][.].*-.* ]] || \
     [[ "${XBB_RELEASE_VERSION}" =~ 12[.][4][.].*-.* ]] || \
     [[ "${XBB_RELEASE_VERSION}" =~ 13[.][3][.].*-.* ]] || \
     [[ "${XBB_RELEASE_VERSION}" =~ 14[.][012][.].*-.* ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://github.com/gcc-mirror/gcc
    if [[ "${XBB_RELEASE_VERSION}" =~ 14[.][012][.].*-.* ]]
    then
      XBB_GCC_GIT_URL="https://github.com/gcc-mirror/gcc.git"
      XBB_GCC_GIT_BRANCH="releases/gcc-14"
    elif [[ "${XBB_RELEASE_VERSION}" =~ 13[.][3][.].*-.* ]]
    then
      XBB_GCC_GIT_URL="https://github.com/gcc-mirror/gcc.git"
      XBB_GCC_GIT_BRANCH="releases/gcc-13"
    fi

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.41" # "2.41"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="11.0.1"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.3.0"
    # https://www.mpfr.org/history.html
    XBB_MPFR_VERSION="4.2.1"
    # https://www.multiprecision.org/mpc/download.html
    XBB_MPC_VERSION="1.2.1"
    # https://sourceforge.net/projects/libisl/files/
    XBB_ISL_VERSION="0.26"

    # https://github.com/facebook/zstd/releases
    XBB_ZSTD_VERSION="1.5.5"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.3.1" # "1.2.13"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"

    # https://ftp.gnu.org/gnu/ncurses/
    XBB_NCURSES_VERSION="6.4"

    # https://github.com/westes/texinfo/releases
    XBB_TEXINFO_VERSION="7.0.3"

    # https://sourceforge.net/projects/lzmautils/files/
    # Avoid 5.6.[01]!
    XBB_XZ_VERSION="5.4.6" # "5.4.4"

    # https://github.com/libexpat/libexpat/releases
    # XBB_EXPAT_VERSION="2.5.0" # "2.4.8"
    # https://ftp.gnu.org/gnu/gdb/
    XBB_GDB_VERSION="14.2" # "13.2"

    # Number
    XBB_MINGW_VERSION_MAJOR=$(xbb_get_version_major "${XBB_MINGW_VERSION}")

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}.git.patch"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    gcc_mingw_build_common

  # ---------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 11[.][4][.].*-.* ]] || \
       [[ "${XBB_RELEASE_VERSION}" =~ 12[.][3][.].*-.* ]] || \
       [[ "${XBB_RELEASE_VERSION}" =~ 13[.][2][.].*-.* ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.41" # "2.39"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="11.0.1" # "10.0.0"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.3.0" # "6.2.1"
    # https://www.mpfr.org/history.html
    XBB_MPFR_VERSION="4.2.1" # "4.1.0"
    # https://www.multiprecision.org/mpc/download.html
    XBB_MPC_VERSION="1.2.1"
    # https://sourceforge.net/projects/libisl/files/
    XBB_ISL_VERSION="0.26" # "0.24"

    # https://github.com/facebook/zstd/releases
    XBB_ZSTD_VERSION="1.5.5" # "1.5.2"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.13" # "1.2.11"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"

    # https://ftp.gnu.org/gnu/ncurses/
    XBB_NCURSES_VERSION="6.4" # "6.3"

    # https://github.com/westes/texinfo/releases
    XBB_TEXINFO_VERSION="7.0.3"

    # https://sourceforge.net/projects/lzmautils/files/
    # Avoid 5.6.[01]!
    XBB_XZ_VERSION="5.4.4" # "5.2.5"

    # https://github.com/libexpat/libexpat/releases
    # XBB_EXPAT_VERSION="2.5.0" # "2.4.8"
    # https://ftp.gnu.org/gnu/gdb/
    XBB_GDB_VERSION="13.2" # "12.1"

    # Number
    XBB_MINGW_VERSION_MAJOR=$(xbb_get_version_major "${XBB_MINGW_VERSION}")

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}.git.patch"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    gcc_mingw_build_common

  # ---------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 12[.][12][.]0-[1] ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.39"
    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="10.0.0"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.11"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.2.1"
    # https://www.mpfr.org/history.html
    XBB_MPFR_VERSION="4.1.0"
    # https://www.multiprecision.org/mpc/download.html
    XBB_MPC_VERSION="1.2.1"
    # https://sourceforge.net/projects/libisl/files/
    XBB_ISL_VERSION="0.24"

    # https://github.com/facebook/zstd/releases
    XBB_ZSTD_VERSION="1.5.2"

    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.2.5"

    # https://ftp.gnu.org/gnu/ncurses/
    # XBB_NCURSES_VERSION="6.3"
    # https://github.com/libexpat/libexpat/releases
    # XBB_EXPAT_VERSION="2.4.8"

    # Number
    XBB_MINGW_VERSION_MAJOR=$(xbb_get_version_major "${XBB_MINGW_VERSION}")

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}.git.patch"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    gcc_mingw_build_common

  # ---------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 11[.]3[.]0-[1] ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.38"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="9.0.0"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.16"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.11"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.2.1"
    # https://www.mpfr.org/history.html
    XBB_MPFR_VERSION="4.1.0"
    # https://www.multiprecision.org/mpc/download.html
    XBB_MPC_VERSION="1.2.1"
      # https://sourceforge.net/projects/libisl/files/
    XBB_ISL_VERSION="0.24"

    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.2.5"

     # https://github.com/facebook/zstd/releases
    XBB_ZSTD_VERSION="1.5.2"

    # Number
    XBB_MINGW_VERSION_MAJOR=$(xbb_get_version_major "${XBB_MINGW_VERSION}")

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}-cross.git.patch"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    gcc_mingw_build_common

  # ---------------------------------------------------------------------------
  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
