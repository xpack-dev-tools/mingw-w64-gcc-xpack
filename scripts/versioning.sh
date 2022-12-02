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

function build_common()
{
  download_mingw "${XBB_MINGW_VERSION}"

  # -------------------------------------------------------------------------
  # Build the native dependencies.

  # None.

  # -------------------------------------------------------------------------
  # Build the target dependencies.

  xbb_reset_env
  xbb_set_target "mingw-w64-native"

  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then

    (
      # Build the bootstrap (a native Linux application).
      # The result is in x86_64-pc-linux-gnu/x86_64-w64-mingw32.
      build_mingw_gcc_dependencies

      build_mingw_gcc_all_triplets
    )

    xbb_reset_env
    xbb_set_target "mingw-w64-cross"

    xbb_activate_installed_bin
  fi

  build_mingw_gcc_dependencies

  # -------------------------------------------------------------------------
  # Build the application binaries.

  xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
  xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

  build_mingw_gcc_all_triplets

  # Save a few MB.
  rm -rf "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share/info"
}

# -----------------------------------------------------------------------------

function build_application_versioned_components()
{
  export XBB_GCC_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 GCC ${XBB_REQUESTED_TARGET_MACHINE}"
  export XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils ${XBB_REQUESTED_TARGET_MACHINE}"

  export XBB_GCC_VERSION="$(echo "${XBB_RELEASE_VERSION}" | sed -e 's|-.*||')"
  export XBB_GCC_VERSION_MAJOR=$(echo ${XBB_GCC_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

# ---------------------------------------------------------------------------

  export XBB_GCC_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 GCC${XBB_BOOTSTRAP_SUFFIX} ${XBB_TARGET_MACHINE}"
  export XBB_BINUTILS_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils${XBB_BOOTSTRAP_SUFFIX} ${XBB_TARGET_MACHINE}"

  export XBB_GCC_SRC_FOLDER_NAME="gcc-${XBB_GCC_VERSION}"

  # There is no GDB, since this is strictly a cross toolchain, and the
  # binaries run only on Windows.

  XBB_MINGW_TRIPLETS=( "x86_64-w64-mingw32" "i686-w64-mingw32" )
  # XBB_MINGW_TRIPLETS=( "x86_64-w64-mingw32" ) # Use it temporarily during tests.
  # XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" ) # Use it temporarily during tests.

  # ---------------------------------------------------------------------------

  # Keep the versions in sync with gcc-xpack.
  # https://ftp.gnu.org/gnu/gcc/
  # ---------------------------------------------------------------------------
  if [[ "${XBB_RELEASE_VERSION}" =~ 12\.[12]\.0-[1] ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.38"
    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="10.0.0"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"

    # http://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.11"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.2.1"
    # http://www.mpfr.org/history.html
    XBB_MPFR_VERSION="4.1.0"
    # https://www.multiprecision.org/mpc/download.html
    XBB_MPC_VERSION="1.2.1"
    # https://sourceforge.net/projects/libisl/files/
    XBB_ISL_VERSION="0.24"

    # https://ftp.gnu.org/gnu/ncurses/
    # XBB_NCURSES_VERSION="6.3"
    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.2.5"
    # https://github.com/libexpat/libexpat/releases
    # XBB_EXPAT_VERSION="2.4.8"

     # https://github.com/facebook/zstd/releases
    XBB_ZSTD_VERSION="1.5.2"

    # Number
    XBB_MINGW_VERSION_MAJOR=$(echo ${XBB_MINGW_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}-cross.patch.diff"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    build_common

  # ---------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 11\.3\.0-[1] ]]
  then
    # Keep these in sync with gcc-xpack.

    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.38"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="9.0.0"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.16"

    # http://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.11"

    # https://gmplib.org/download/gmp/
    XBB_GMP_VERSION="6.2.1"
    # http://www.mpfr.org/history.html
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
    XBB_MINGW_VERSION_MAJOR=$(echo ${XBB_MINGW_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

    XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}-cross.patch.diff"

    # The original SourceForge location.
    XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-v${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------

    build_common

  # ---------------------------------------------------------------------------
  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
