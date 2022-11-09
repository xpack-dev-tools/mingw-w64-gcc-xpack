# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function xbb_activate_gcc_bootstrap_bins()
{
  export PATH="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin:${PATH}"
}

# The XBB MinGW GCC lacks `__LIBGCC_EH_FRAME_SECTION_NAME__`, needed
# by modern GCC, so the workaround is to build a bootstrap toolchain.

function build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  (
    mkdir -p "${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}"
    mkdir -p "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}"

    # Do not use yet, it requires some more work for bootstrap.
    # build_zlib "${XBB_ZLIB_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"

    # Libraries, required by gcc & other.
    build_gmp "${XBB_GMP_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"
    build_mpfr "${XBB_MPFR_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"
    build_mpc "${XBB_MPC_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"
    build_isl "${XBB_ISL_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"

    build_libiconv "${XBB_LIBICONV_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"

    set_bins_install "${APP_INSTALL_FOLDER_PATH}"

    for triplet in "${XBB_MINGW_TRIPLETS[@]}"
    do

      build_mingw2_binutils "${XBB_BINUTILS_VERSION}" "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"

      # Deploy the headers, they are needed by the compiler.
      build_mingw2_headers "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"

      # Build only the compiler, without libraries.
      build_mingw2_gcc_first "${XBB_GCC_VERSION}" "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"

      # Build some native tools.
      # build_mingw_libmangle
      # build_mingw_gendef
      build_mingw2_widl "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}" # Refers to mingw headers.

      (
        xbb_activate_gcc_bootstrap_bins

        (
          # Fails if CC is defined to a native compiler.
          xbb_prepare_gcc_env "${triplet}-"

          build_mingw2_crt "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"
          build_mingw2_winpthreads "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"
        )

        # With the run-time available, build the C/C++ libraries and the rest.
        build_mingw2_gcc_final "${triplet}" "${XBB_BOOTSTRAP_SUFFIX}"
      )

    done
  )
}

# -----------------------------------------------------------------------------

function build_common()
{
  (
    # download_gcc "${XBB_GCC_VERSION}"
    download_mingw "${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # The bootstrap is needed because the 32-bit toolchain is not
    # available in the XBB Docker images.
    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      (
        # Subshell to keep the native environment isolated.

        set_xbb_env "native"
        set_compiler_env

        build_mingw_bootstrap
      )

      xbb_prepare_gcc_env "x86_64-w64-mingw32-"

      # Use the newly compiled bootstrap compiler.
      xbb_activate_gcc_bootstrap_bins
    fi

    # -------------------------------------------------------------------------
    # Build the target dependencies.

    xbb_set_target "mingw-w64-native"

    build_libiconv "${XBB_LIBICONV_VERSION}"

    # New zlib, used in most of the tools.
    # depends=('glibc')
    build_zlib "${XBB_ZLIB_VERSION}"

    # Libraries, required by gcc & other.
    # depends=('gcc-libs' 'sh')
    build_gmp "${XBB_GMP_VERSION}"

    # depends=('gmp>=5.0')
    build_mpfr "${XBB_MPFR_VERSION}"

    # depends=('mpfr')
    build_mpc "${XBB_MPC_VERSION}"

    # depends=('gmp')
    build_isl "${XBB_ISL_VERSION}"

    build_xz "${XBB_XZ_VERSION}"

    # depends on zlib, xz, (lz4)
    build_zstd "${XBB_ZSTD_VERSION}"

    # -------------------------------------------------------------------------
    # Build the application binaries.

    xbb_set_binaries_install "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
    xbb_set_libraries_install "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

    for triplet in "${XBB_MINGW_TRIPLETS[@]}"
    do

      build_mingw2_binutils "${XBB_BINUTILS_VERSION}" "${triplet}"

      # Deploy the headers, they are needed by the compiler.
      build_mingw2_headers "${triplet}"

      build_mingw2_gcc_first "${XBB_GCC_VERSION}" "${triplet}"

      build_mingw2_widl "${triplet}"

      # libmangle requires a patch to remove <malloc.h>
      build_mingw2_libmangle "${triplet}"
      build_mingw2_gendef "${triplet}"

      (
        xbb_activate_installed_bin

        xbb_prepare_gcc_env "${triplet}-"

        build_mingw2_crt "${triplet}"
        build_mingw2_winpthreads "${triplet}"
      )

      # With the run-time available, build the C/C++ libraries and the rest.
      build_mingw2_gcc_final "${triplet}"

    done

    # Save a few MB.
    rm -rf "${XBB_BINARIES_INSTALL_FOLDER_PATH}/share/info"
  )
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
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
