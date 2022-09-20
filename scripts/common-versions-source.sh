# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the xPack build scripts. As the name implies,
# it should contain only functions and should be included with 'source'
# by the build scripts (both native and container).

# -----------------------------------------------------------------------------

function set_bins_install()
{
  export BINS_INSTALL_FOLDER_PATH="${APP_INSTALL_FOLDER_PATH}"
}

function build_versions()
{
  export GCC_BRANDING="${DISTRO_NAME} MinGW-w64 GCC ${TARGET_MACHINE}"
  export BINUTILS_BRANDING="${DISTRO_NAME} MinGW-w64 binutils ${TARGET_MACHINE}"

  export GCC_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-.*||')"
  export GCC_VERSION_MAJOR=$(echo ${GCC_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    echo "Windows not supported"
    echo 1
  fi

  # Keep the versions in sync with gcc-xpack.
  # https://ftp.gnu.org/gnu/gcc/
  # ---------------------------------------------------------------------------
  if [[ "${RELEASE_VERSION}" =~ 12\.[12]\.0-[1] ]]
  then
    # https://ftp.gnu.org/gnu/binutils/
    BINUTILS_VERSION="2.38"
    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    MINGW_VERSION="10.0.0"

    # https://gmplib.org/download/gmp/
    GMP_VERSION="6.2.1"
    # http://www.mpfr.org/history.html
    MPFR_VERSION="4.1.0"
    # https://www.multiprecision.org/mpc/download.html
    MPC_VERSION="1.2.1"
    # https://sourceforge.net/projects/libisl/files/
    ISL_VERSION="0.24"

    # https://ftp.gnu.org/pub/gnu/libiconv/
    LIBICONV_VERSION="1.17"
    # https://ftp.gnu.org/gnu/ncurses/
    NCURSES_VERSION="6.3"
    # https://sourceforge.net/projects/lzmautils/files/
    XZ_VERSION="5.2.5"
    # https://github.com/libexpat/libexpat/releases
    EXPAT_VERSION="2.4.8"
    # https://ftp.gnu.org/gnu/gdb/
    GDB_VERSION="12.1"

    build_common

  # ---------------------------------------------------------------------------
  elif [[ "${RELEASE_VERSION}" =~ 11\.3\.0-[1] ]]
  then
    (
      xbb_activate

      BINUTILS_VERSION="2.38"

      # New zlib, used in most of the tools.
      # depends=('glibc')
      build_zlib "1.2.11"

      # Libraries, required by gcc & other.
      # https://gmplib.org/download/gmp/
      # depends=('gcc-libs' 'sh')
      build_gmp "6.2.1"

      # http://www.mpfr.org/history.html
      # depends=('gmp>=5.0')
      build_mpfr "4.1.0"

      # https://www.multiprecision.org/mpc/download.html
      # depends=('mpfr')
      build_mpc "1.2.1"

      # https://sourceforge.net/projects/libisl/files/
      # depends=('gmp')
      build_isl "0.24"

      # https://ftp.gnu.org/pub/gnu/libiconv/
      build_libiconv "1.16"

      # -----------------------------------------------------------------------

      # No need, a bootstrap gcc is built automatically.
      # build_native_binutils "${BINUTILS_VERSION}"
      # build_native_gcc "${GCC_VERSION}"

      # -----------------------------------------------------------------------

      # From now on, install all binaries in the public area.
      set_bins_install "${APP_INSTALL_FOLDER_PATH}"
      tests_add set_bins_install "${APP_INSTALL_FOLDER_PATH}"

      # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
      prepare_mingw_env "9.0.0"

      download_mingw

      MINGW_ARCHITECTURES=("x86_64" "i686")
      # MINGW_ARCHITECTURES=("x86_64") # Use it temporarily during tests.
      # MINGW_ARCHITECTURES=("i686") # Use it temporarily during tests.

      # depends=('zlib')
      for arch in "${MINGW_ARCHITECTURES[@]}"
      do
        # https://ftp.gnu.org/gnu/binutils/
        build_mingw_binutils "${BINUTILS_VERSION}" "${arch}"

        # Deploy the headers, they are needed by the compiler.
        build_mingw_headers "${arch}"

        build_mingw_gcc_first "11.3.0" "${arch}"

        build_mingw_widl "${arch}"

        (
          prepare_gcc_env "${arch}-w64-mingw32-"

          build_mingw_crt "${arch}"
          build_mingw_winpthreads "${arch}"
        )

        # With the run-time available, build the C/C++ libraries and the rest.
        build_mingw_gcc_final "${arch}"

      done

      # Save a few MB.
      rm -rf "${BINS_INSTALL_FOLDER_PATH}/share/info"
    )

  # ---------------------------------------------------------------------------
  else
    echo "Unsupported ${APP_LC_NAME} version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
