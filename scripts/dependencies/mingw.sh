# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# The configurations generally follow the Linux Arch configurations, but
# also MSYS2 and HomeBrew were considered.

# The difference is the install location, which no longer uses `/usr`.

# -----------------------------------------------------------------------------
# MinGW-w64

# https://www.mingw-w64.org
# https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/

# Arch
# https://archlinux.org/packages/?sort=&q=mingw-w64&maintainer=&flagged=
# https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-headers/trunk/PKGBUILD
# https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-crt/trunk/PKGBUILD
# https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-winpthreads/trunk/PKGBUILD
# https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-binutils/trunk/PKGBUILD
# https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-gcc/trunk/PKGBUILD

# MSYS2
# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-headers-git/PKGBUILD
# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-crt-git/PKGBUILD
# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-winpthreads-git/PKGBUILD
# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-binutils/PKGBUILD
# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gcc/PKGBUILD

# Homebrew
# https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

# 2018-06-03, "5.0.4"
# 2018-09-16, "6.0.0"
# 2019-11-11, "7.0.0"
# 2020-09-18, "8.0.0"
# 2021-05-09, "8.0.2"
# 2021-05-22, "9.0.0"
# 2022-04-04, "10.0.0"

function download_mingw()
{
  local mingw_folder_archive="${XBB_MINGW_SRC_FOLDER_NAME}.tar.bz2"
  # The original SourceForge location.
  local mingw_url="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/${mingw_folder_archive}"

  # If SourceForge is down, there is also a GitHub mirror.
  # https://github.com/mirror/mingw-w64
  # XBB_MINGW_SRC_FOLDER_NAME="mingw-w64-${XBB_MINGW_VERSION}"
  # mingw_folder_archive="v${XBB_MINGW_VERSION}.tar.gz"
  # mingw_url="https://github.com/mirror/mingw-w64/archive/${mingw_folder_archive}"

  # https://sourceforge.net/p/mingw-w64/wiki2/Cross%20Win32%20and%20Win64%20compiler/
  # https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/configure

  (
    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    if [ ! -d "${XBB_MINGW_SRC_FOLDER_NAME}" ]
    then
      download_and_extract "${mingw_url}" "${mingw_folder_archive}" \
        "${XBB_MINGW_SRC_FOLDER_NAME}"

      # On MacOS there is no <malloc.h>
      # mingw-w64-v9.0.0/mingw-w64-libraries/libmangle/src/m_token.c:26:10: fatal error: malloc.h: No such file or directory
      run_verbose sed -i.bak -e '/^#include <malloc.h>/d' \
        "${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/libmangle/src/"*.c
    fi
  )
}

# Used to initialise options in all mingw builds:
# `config_options=("${config_options_common[@]}")`

function prepare_mingw2_config_options_common()
{
  # ---------------------------------------------------------------------------
  # Used in multiple configurations.

  config_options_common=()

  local prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}
  if [ $# -ge 1 ]
  then
    config_options_common+=("--prefix=$1")
  else
    echo "prepare_mingw2_config_options_common requires a prefix path"
    exit 1
  fi

  config_options_common+=("--disable-multilib")

  # https://docs.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-160
  # Windows 7
  config_options_common+=("--with-default-win32-winnt=0x601")

  # `ucrt` is the new Windows Universal C Runtime:
  # https://support.microsoft.com/en-us/topic/update-for-universal-c-runtime-in-windows-c0514201-7fe6-95a3-b0a5-287930f3560c
  # config_options_common+=("--with-default-msvcrt=${MINGW_MSVCRT:-msvcrt}")
  config_options_common+=("--with-default-msvcrt=${MINGW_MSVCRT:-ucrt}")

  config_options_common+=("--enable-wildcard")
  config_options_common+=("--enable-warnings=0")
}


function build_mingw_headers()
{
  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-headers/trunk/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-headers-git/PKGBUILD

  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_headers_folder_name="${mingw_triplet}-headers${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  local mingw_headers_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_headers_folder_name}-installed"
  if [ ! -f "${mingw_headers_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_headers_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} headers configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-headers/configure" --help
          fi

          # Use architecture subfolders.
          prepare_mingw2_config_options_common "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}" # Arch
          config_options=("${config_options_common[@]}")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${mingw_triplet}") # Arch
          config_options+=("--target=${mingw_triplet}")

          # config_options+=("--with-tune=generic")

          config_options+=("--enable-sdk=all") # Arch
          config_options+=("--enable-idl") # MYSYS2
          config_options+=("--without-widl") # MSYS2

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-headers/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} headers make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        # make install-strip
        run_verbose make install-strip

        # ?? run_verbose ln -sv ../include include
        # ?? run_verbose ln -sv "${XBB_TARGET_TRIPLET}" "mingw"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/make-output-$(ndate).txt"

      # No need to do it again for each component.
      if [ -z "${mingw_name_suffix}" ]
      then
        copy_license \
          "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}" \
          "mingw-w64-${XBB_MINGW_VERSION}"
      fi
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_headers_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} headers already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_mingw_widl()
{
  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_widl_folder_name="${mingw_triplet}-widl${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_widl_folder_name}"

  local mingw_widl_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_widl_folder_name}-installed"
  if [ ! -f "${mingw_widl_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${mingw_widl_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_widl_folder_name}"

      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
      xbb_adjust_ldflags_rpath

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} widl configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-tools/widl/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}") # Arch /usr
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}") # Native!
          config_options+=("--target=${mingw_triplet}")

          config_options+=("--with-widl-includedir=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/include")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-tools/widl/configure" \
            "${config_options[@]}"

         cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} widl make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_widl_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} widl already installed."
  fi
}

# Fails on macOS, due to <malloc.h>.
function build_mingw_libmangle()
{
  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_libmangle_folder_name="${mingw_triplet}-libmangle${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}"

  local mingw_libmangle_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_libmangle_folder_name}-installed"
  if [ ! -f "${mingw_libmangle_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${mingw_libmangle_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_libmangle_folder_name}"

      # xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
      xbb_adjust_ldflags_rpath

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} libmangle configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/libmangle/configure" --help
          fi

          config_options=()

          # Note: native library.
          config_options+=("--prefix=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}") # Native!
          config_options+=("--target=${mingw_triplet}")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/libmangle/configure" \
            "${config_options[@]}"

         cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} libmangle make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/make-libmangle-output-$(ndate).txt"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_libmangle_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} libmangle already installed."
  fi
}

# Currently not used, because of libmangle.
function build_mingw_gendef()
{
  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_gendef_folder_name="${mingw_triplet}-gendef${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}"

  local mingw_gendef_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_gendef_folder_name}-installed"
  if [ ! -f "${mingw_gendef_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${mingw_gendef_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_gendef_folder_name}"

      # To pick libmangle.
      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
      xbb_adjust_ldflags_rpath

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} gendef configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-tools/gendef/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}") # Native!
          config_options+=("--target=${mingw_triplet}")

          config_options+=("--program-prefix=${mingw_triplet}-")

          config_options+=("--with-mangle=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${mingw_name_suffix}")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-tools/gendef/configure" \
            "${config_options[@]}"

         cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/config-gendef-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} gendef make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/make-output-$(ndate).txt"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_gendef_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} gendef already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_mingw_crt()
{
  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-crt/trunk/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-crt-git/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_crt_folder_name="${mingw_triplet}-crt${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  local mingw_crt_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_crt_folder_name}-installed"
  if [ ! -f "${mingw_crt_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_crt_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"

      # To use the new toolchain.
      # xbb_activate_installed_bin

      # Overwrite the flags, -ffunction-sections -fdata-sections result in
      # {standard input}: Assembler messages:
      # {standard input}:693: Error: CFI instruction used without previous .cfi_startproc
      # {standard input}:695: Error: .cfi_endproc without corresponding .cfi_startproc
      # {standard input}:697: Error: .seh_endproc used in segment '.text' instead of expected '.text$WinMainCRTStartup'
      # {standard input}: Error: open CFI at the end of file; missing .cfi_endproc directive
      # {standard input}:7150: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}
      # {standard input}:8937: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS=""
      if [ "${XBB_IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      # Without it, apparently a bug in autoconf/c.m4, function AC_PROG_CC, results in:
      # checking for _mingw_mac.h... no
      # configure: error: Please check if the mingw-w64 header set and the build/host option are set properly.
      # (https://github.com/henry0312/build_gcc/issues/1)
      # export CC=""

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} crt configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-crt/configure" --help
          fi

          config_options=()

          prepare_mingw2_config_options_common "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}" # Arch /usr
          config_options=("${config_options_common[@]}")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--with-sysroot=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}") # HB

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${mingw_triplet}") # Arch
          config_options+=("--target=${mingw_triplet}")

          if [ "${mingw_triplet}" == "x86_64-w64-mingw32" ]
          then
            config_options+=("--disable-lib32") # Arch, HB
            config_options+=("--enable-lib64") # Arch, HB
          elif [ "${mingw_triplet}" == "i686-w64-mingw32" ]
          then
            config_options+=("--enable-lib32") # Arch, HB
            config_options+=("--disable-lib64") # Arch, HB
          else
            echo "Unsupported mingw_triplet ${mingw_triplet}."
            exit 1
          fi

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-crt/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet} crt make..."

        # Build.
        # run_verbose make -j ${XBB_JOBS}
        # Parallel builds fail with weird messages.
        # like 'bfd_open failed reopen stub file'
        # Apparently it'll be fixed in v11.
        run_verbose make -j1

        # make install-strip
        run_verbose make install-strip

        ls -l "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_crt_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} crt already installed."
  fi
}

# -----------------------------------------------------------------------------


function build_mingw_winpthreads()
{
  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-winpthreads/trunk/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-winpthreads-git/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_build_winpthreads_folder_name="${mingw_triplet}-winpthreads${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  local mingw_winpthreads_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_build_winpthreads_folder_name}-installed"
  if [ ! -f "${mingw_winpthreads_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"

      # To use the new toolchain.
      # xbb_activate_installed_bin

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS=""
      if [ "${XBB_IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} winpthreads configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/winpthreads/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}") # Arch /usr
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${mingw_triplet}") # Arch
          config_options+=("--target=${mingw_triplet}")

          config_options+=("--with-sysroot=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}") # HB

          config_options+=("--enable-static") # Arch
          config_options+=("--enable-shared") # Arch

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/winpthreads/configure" \
            "${config_options[@]}"

         cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} winpthreads make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        # make install-strip
        run_verbose make install-strip

        if true # [ -z "${mingw_name_suffix}" ]
        then
          # GCC installs all DLLs in lib; for consistency, copy
          # libwinpthread-1.dll there too.
          run_verbose cp -v "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}/bin/libwinpthread-1.dll" \
            "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}/lib/"

          run_verbose ls -l "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}/lib/libwinpthread"*
        fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_winpthreads_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} winpthreads already installed."
  fi
}


# configure: error: C compiler cannot create executables
# build_mingw_winstorecompat "${triplet}"

function build_mingw_winstorecompat()
{
  local mingw_triplet="$1"
  local mingw_name_suffix="${2:-""}"

  local mingw_build_winstorecompat_folder_name="${mingw_triplet}-winstorecompat${mingw_name_suffix}-${XBB_MINGW_VERSION}"

  local mingw_winstorecompat_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_build_winstorecompat_folder_name}-installed"
  if [ ! -f "${mingw_winstorecompat_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}"

      # To use the new toolchain.
      # xbb_activate_installed_bin

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS=""
      if [ "${XBB_IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${mingw_triplet}${mingw_name_suffix} winstorecompat configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/winstorecompat/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${mingw_name_suffix}/${mingw_triplet}") # Arch /usr
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${mingw_triplet}") # Arch
          config_options+=("--target=${mingw_triplet}")

          config_options+=("--enable-static")
          config_options+=("--enable-shared")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${XBB_MINGW_SRC_FOLDER_NAME}/mingw-w64-libraries/winstorecompat/configure" \
            "${config_options[@]}"

         cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}${mingw_name_suffix} winstorecompat make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        # make install-strip
        run_verbose make install-strip

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_build_winstorecompat_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_winstorecompat_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}${mingw_name_suffix} winstorecompat already installed."
  fi
}

# -----------------------------------------------------------------------------
