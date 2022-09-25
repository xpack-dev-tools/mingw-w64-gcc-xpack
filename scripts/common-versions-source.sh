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

function xbb_activate_gcc_bootstrap_bins()
{
  export PATH="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin:${PATH}"
}

# The XBB MinGW GCC lacks `__LIBGCC_EH_FRAME_SECTION_NAME__`, needed
# by modern GCC, so the workaround is to build a bootstrap toolchain.

function build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  (
    xbb_activate

    mkdir -p "${BINS_INSTALL_FOLDER_PATH}${BOOTSTRAP_SUFFIX}"
    mkdir -p "${LIBS_INSTALL_FOLDER_PATH}${BOOTSTRAP_SUFFIX}"

    # Do not use yet, it requires some more work for bootstrap.
    # build_zlib "${ZLIB_VERSION}" "${BOOTSTRAP_SUFFIX}"

    # Libraries, required by gcc & other.
    build_gmp "6.2.1" "${BOOTSTRAP_SUFFIX}"
    build_mpfr "4.1.0" "${BOOTSTRAP_SUFFIX}"
    build_mpc "1.2.1" "${BOOTSTRAP_SUFFIX}"
    build_isl "0.24" "${BOOTSTRAP_SUFFIX}"

    build_libiconv "${LIBICONV_VERSION}" "${BOOTSTRAP_SUFFIX}"

    set_bins_install "${APP_INSTALL_FOLDER_PATH}"

    for arch in "${MINGW_ARCHITECTURES[@]}"
    do

      build_mingw2_binutils "${BINUTILS_VERSION}" "${arch}" "${BOOTSTRAP_SUFFIX}"

      # Deploy the headers, they are needed by the compiler.
      build_mingw2_headers "${arch}" "${BOOTSTRAP_SUFFIX}"

      # Build only the compiler, without libraries.
      build_mingw2_gcc_first "${GCC_VERSION}" "${arch}" "${BOOTSTRAP_SUFFIX}"

      # Build some native tools.
      # build_mingw_libmangle
      # build_mingw_gendef
      build_mingw2_widl "${arch}" "${BOOTSTRAP_SUFFIX}" # Refers to mingw headers.

      (
        xbb_activate_gcc_bootstrap_bins

        (
          # Fails if CC is defined to a native compiler.
          prepare_gcc_env "${arch}-w64-mingw32-"

          build_mingw2_crt "${arch}" "${BOOTSTRAP_SUFFIX}"
          build_mingw2_winpthreads "${arch}" "${BOOTSTRAP_SUFFIX}"
        )

        # With the run-time available, build the C/C++ libraries and the rest.
        build_mingw2_gcc_final "${arch}" "${BOOTSTRAP_SUFFIX}"
      )

    done
  )
}

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

# ---------------------------------------------------------------------------

  export BOOTSTRAP_SUFFIX="-bootstrap"
  export GCC_BOOTSTRAP_BRANDING="${DISTRO_NAME} MinGW-w64 GCC${BOOTSTRAP_SUFFIX} ${TARGET_MACHINE}"
  export BINUTILS_BOOTSTRAP_BRANDING="${DISTRO_NAME} MinGW-w64 binutils${BOOTSTRAP_SUFFIX} ${TARGET_MACHINE}"

  export GCC_SRC_FOLDER_NAME="gcc-${GCC_VERSION}"

# ---------------------------------------------------------------------------

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
      # https://ftp.gnu.org/gnu/binutils/
      BINUTILS_VERSION="2.38"

      # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
      MINGW_VERSION="9.0.0"

      # http://zlib.net/fossils/
      ZLIB_VERSION="1.2.11"

      # https://gmplib.org/download/gmp/
      GMP_VERSION="6.2.1"
      # http://www.mpfr.org/history.html
      MPFR_VERSION="4.1.0"
      # https://www.multiprecision.org/mpc/download.html
      MPC_VERSION="1.2.1"
        # https://sourceforge.net/projects/libisl/files/
      ISL_VERSION="0.24"

      # https://ftp.gnu.org/pub/gnu/libiconv/
      LIBICONV_VERSION="1.16"

      # Number
      MINGW_VERSION_MAJOR=$(echo ${MINGW_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

      MINGW_ARCHITECTURES=("x86_64" "i686")
      # MINGW_ARCHITECTURES=("x86_64") # Use it temporarily during tests.
      # MINGW_ARCHITECTURES=("i686") # Use it temporarily during tests.

      GCC_SRC_FOLDER_NAME="gcc-${GCC_VERSION}"

      MINGW_GCC_PATCH_FILE_NAME="gcc-${GCC_VERSION}-cross.patch.diff"

      # The original SourceForge location.
      MINGW_SRC_FOLDER_NAME="mingw-w64-v${MINGW_VERSION}"

      # -----------------------------------------------------------------------

      xbb_activate

      download_mingw "${MINGW_VERSION}"

      # The bootstrap is needed because the 32-bit toolchain is not
      # available in the XBB Docker images.
      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        (
          # Subshell to keep the native environment isolated.

          set_xbb_env "native"
          set_compiler_env

          # export BOOTSTRAP_SUFFIX=""
          build_mingw_bootstrap
        )

        prepare_gcc_env "x86_64-w64-mingw32-"

        # Use the newly compiled bootstrap compiler.
        xbb_activate_gcc_bootstrap_bins
      fi

     # -----------------------------------------------------------------------

      # New zlib, used in most of the tools.
      # depends=('glibc')
      build_zlib "${ZLIB_VERSION}"

      # Libraries, required by gcc & other.
      # depends=('gcc-libs' 'sh')
      build_gmp "${GMP_VERSION}"

      # depends=('gmp>=5.0')
      build_mpfr "${MPFR_VERSION}"

      # depends=('mpfr')
      build_mpc "${MPC_VERSION}"

      (
        if [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          # The GCC linker fails with an assert.
          prepare_clang_env "" ""
        fi

        # depends=('gmp')
        build_isl "${ISL_VERSION}"
      )

      build_libiconv "${LIBICONV_VERSION}"

      # -----------------------------------------------------------------------

      # No need, for Linux/Mac, a bootstrap gcc is built automatically,
      # for Windows it is built manually.
      # build_native_binutils "${BINUTILS_VERSION}"
      # build_native_gcc "${GCC_VERSION}"

      # -----------------------------------------------------------------------

      # From now on, install all binaries in the public area.
      set_bins_install "${APP_INSTALL_FOLDER_PATH}"
      tests_add set_bins_install "${APP_INSTALL_FOLDER_PATH}"

      download_mingw "${MINGW_VERSION}"

      for arch in "${MINGW_ARCHITECTURES[@]}"
      do

        build_mingw2_binutils "${BINUTILS_VERSION}" "${arch}"

        # Deploy the headers, they are needed by the compiler.
        build_mingw2_headers "${arch}"

        build_mingw2_gcc_first "${GCC_VERSION}" "${arch}"

        build_mingw2_widl "${arch}"

        # Disable on all platforms.
        if true # [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          :
          # mingw-w64-v9.0.0/mingw-w64-libraries/libmangle/src/m_token.c:26:10: fatal error: malloc.h: No such file or directory
        else
          build_mingw2_libmangle "${arch}"
          build_mingw2_gendef "${arch}"
        fi

        (
          xbb_activate_installed_bin

          prepare_gcc_env "${arch}-w64-mingw32-"

          build_mingw2_crt "${arch}"
          build_mingw2_winpthreads "${arch}"
        )

        # With the run-time available, build the C/C++ libraries and the rest.
        build_mingw2_gcc_final "${arch}"

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
