# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the second edition of the xPack build
# scripts. As the name implies, it should contain only functions and
# should be included with 'source' by the container build scripts.

# The configurations generally follow the Linux Arch configurations, but
# also MSYS2 and HomeBrew were considered.

# The difference is the install location, which no longer uses `/usr`.

# -----------------------------------------------------------------------------
# mingw-w64

function build_mingw_binutils()
{
  # https://ftp.gnu.org/gnu/binutils/

  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-binutils/trunk/PKGBUILD
  #

  # 2017-07-24, "2.29"
  # 2018-07-14, "2.31"
  # 2019-02-02, "2.32"
  # 2019-10-12, "2.33.1"
  # 2020-02-01, "2.34"
  # 2020-07-24, "2.35"
  # 2020-09-19, "2.35.1"
  # 2021-01-24, "2.36"
  # 2021-01-30, "2.35.2"
  # 2021-02-06, "2.36.1"
  # 2021-07-18, "2.37"
  # 2022-02-09, "2.38"
  # 2022-08-05, "2.39"

  local mingw_binutils_version="$1"
  local mingw_arch="$2"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_binutils_src_folder_name="binutils-${mingw_binutils_version}"

  local mingw_binutils_archive="${mingw_binutils_src_folder_name}.tar.xz"
  local mingw_binutils_url="https://ftp.gnu.org/gnu/binutils/${mingw_binutils_archive}"

  local mingw_binutils_folder_name="mingw-binutils-${mingw_binutils_version}-${mingw_arch}"

  local mingw_binutils_patch_file_path="${helper_folder_path}/patches/binutils-${mingw_binutils_version}.patch"
  local mingw_binutils_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_binutils_folder_name}-installed"
  if [ ! -f "${mingw_binutils_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${mingw_binutils_url}" "${mingw_binutils_archive}" \
      "${mingw_binutils_src_folder_name}" \
      "${mingw_binutils_patch_file_path}"

if false
then
    # /bin/bash /Host/home/ilg/Work/mingw-w64-gcc-11.3.0-1/linux-x64/sources/gcc-11.3.0/gcc/mkconfig.sh bconfig.h
    # make: *** No rule to make target '../build-x86_64-pc-linux-gnu/libiberty/libiberty.a', needed by 'build/genmodes'.  Stop.
    sed -i.bak 's|install_to_$(INSTALL_DEST) ||' \
      "${mingw_binutils_src_folder_name}/libiberty/Makefile.in"
fi

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_binutils_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_binutils_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # Currently static does not make a difference.
      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running mingw-w64 ${mingw_arch} binutils configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}/configure" --help
          fi

          config_options=()

          # TODO: check if /usr is needed.
          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}") # Arch, HB
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${mingw_target}") # Arch, HB

          # TODO: why HB uses it and Arch does not?
          # config_options+=("--with-sysroot=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-pkgversion=${BINUTILS_BRANDING}")

          # config_options+=("--enable-static")
          config_options+=("--enable-lto") # Arch
          config_options+=("--enable-plugins") # Arch
          config_options+=("--enable-deterministic-archives") # Arch
          config_options+=("--enable-targets=${mingw_target}") # HB

          # config_options+=("--disable-shared")
          config_options+=("--disable-multilib") # Arch, HB
          config_options+=("--disable-nls") # Arch, HB
          config_options+=("--disable-werror") # arch

          run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}/configure" \
            "${config_options[@]}"

          # run_verbose make configure

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} binutils make..."

        # Build.
        run_verbose make -j ${JOBS}

        show_libs "ld/ld-new"
        show_libs "gas/as-new"
        show_libs "binutils/readelf"

        # make install-strip
        run_verbose make install

        # For just in case, it has nasty consequences when picked
        # in other builds.
        # TODO: check if needed
        # rm -fv "${BINS_INSTALL_FOLDER_PATH}/lib/libiberty.a" "${BINS_INSTALL_FOLDER_PATH}/lib64/libiberty.a"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}" \
        "binutils-${mingw_binutils_version}"
    )

    (
      test_mingw_binutils "${mingw_arch}"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${mingw_binutils_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_arch} binutils already installed."
  fi

  tests_add "test_mingw_binutils" "${mingw_arch}"
}

function test_mingw_binutils()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"
  (
    # xbb_activate_installed_bin

    echo
    echo "Checking the mingw-w64 ${mingw_arch} binutils shared libraries..."

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ar"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-as"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ld"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-nm"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objcopy"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objdump"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ranlib"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-size"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strings"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip"

    echo
    echo "Testing if mingw-w64 ${mingw_arch} binutils binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ar" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-as" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ld" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-nm" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objcopy" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objdump" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ranlib" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-size" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strings" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip" --version

    echo
    echo "Testing if mingw-w64 ${mingw_arch} binutils binaries display help..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ar" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-as" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ld" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-nm" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objcopy" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objdump" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ranlib" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-size" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strings" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip" --help
  )
}

# -----------------------------------------------------------------------------

function build_mingw_gcc_first()
{
  # https://gcc.gnu.org
  # https://gcc.gnu.org/wiki/InstallingGCC

  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-gcc/trunk/PKGBUILD

  # MSYS2 uses a lot of patches.
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gcc/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

  # https://ftp.gnu.org/gnu/gcc/
  # 2019-02-22, "8.3.0"
  # 2019-05-03, "9.1.0"
  # 2019-08-12, "9.2.0"
  # 2019-11-14, "7.5.0" *
  # 2020-03-04, "8.4.0"
  # 2020-03-12, "9.3.0"
  # 2021-04-08, "10.3.0"
  # 2021-04-27, "11.1.0" +
  # 2021-05-14, "8.5.0" *
  # 2021-07-28, "11.2.0"
  # 2022-04-21, "11.3.0"
  # 2022-05-06, "12.1.0"
  # 2022-08-19, "12.2.0"

  export mingw_gcc_version="$1"
  local mingw_arch="$2"
  local mingw_target="${mingw_arch}-w64-mingw32"

  # Number
  local mingw_gcc_version_major=$(echo ${mingw_gcc_version} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

  local mingw_gcc_src_folder_name="gcc-${mingw_gcc_version}"

  local mingw_gcc_archive="${mingw_gcc_src_folder_name}.tar.xz"
  local mingw_gcc_url="https://ftp.gnu.org/gnu/gcc/gcc-${mingw_gcc_version}/${mingw_gcc_archive}"

  export mingw_gcc_folder_name="mingw-gcc-${mingw_gcc_version}-${mingw_arch}"

  local mingw_gcc_step1_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-mingw-gcc-step1-${mingw_gcc_version}-${mingw_arch}-installed"
  if [ ! -f "${mingw_gcc_step1_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${mingw_gcc_url}" "${mingw_gcc_archive}" \
      "${mingw_gcc_src_folder_name}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

if false
then
          (
            # GCC requires the `x86_64-w64-mingw32` folder be mirrored as
            # `mingw` in the root.
            cd "${BINS_INSTALL_FOLDER_PATH}"
            run_verbose rm -fv "mingw"
            run_verbose ln -sv "usr/${mingw_target}" "mingw"
          )
fi


          echo
          echo "Running mingw-w64 ${mingw_arch} gcc step 1 configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            # For the native build, --disable-shared failed with errors in libstdc++-v3
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/configure" --help
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/gcc/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}") # Arch /usr
          config_options+=("--libexecdir=${BINS_INSTALL_FOLDER_PATH}/lib") # Arch /usr/lib
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${BUILD}")
          config_options+=("--target=${mingw_target}") # Arch

          # config_options+=("--with-sysroot=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--with-pkgversion=${GCC_BRANDING}")

          config_options+=("--with-dwarf2") # Arch

          config_options+=("--enable-languages=c,c++,fortran,objc,obj-c++,lto") # Arch
          config_options+=("--enable-shared") # Arch
          config_options+=("--enable-static") # Arch
          config_options+=("--enable-threads=posix") # Arch
          config_options+=("--enable-fully-dynamic-string") # Arch
          config_options+=("--enable-libstdcxx-time=yes") # Arch
          config_options+=("--enable-libstdcxx-filesystem-ts=yes") # Arch
          config_options+=("--enable-cloog-backend=isl") # Arch
          config_options+=("--enable-lto") # Arch
          config_options+=("--enable-libgomp") # Arch
          config_options+=("--enable-checking=release") # Arch

          # config_options+=("--disable-dw2-exceptions")
          config_options+=("--disable-sjlj-exceptions") # Arch
          config_options+=("--disable-multilib") # Arch

          # config_options+=("ac_cv_header_sys_mman_h=no")

          # Arch configures only the gcc folder, but in this case it
          # fails with missing libiberty.a.
          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/config-step1-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/configure-step1-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} gcc step 1 make..."

        # Build.
        run_verbose make -j ${JOBS} all-gcc

        run_verbose make install-strip-gcc

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/make-step1-output-$(ndate).txt"
    )

    hash -r

    touch "${mingw_gcc_step1_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_arch} gcc step 1 already installed."
  fi
}

function build_mingw_gcc_final()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_gcc_final_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-mingw-gcc-final-${mingw_gcc_version}-${mingw_target}-installed"
  if [ ! -f "${mingw_gcc_final_stamp_file_path}" ]
  then

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}"

    (
      echo
      echo "Running mingw-w64 gcc final make..."

      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ "${IS_DEVELOP}" == "y" ]
      then
        env | sort
      fi

      echo
      echo "Running mingw-w64 ${mingw_target} gcc step 2 configure..."

      run_verbose make -j configure-target-libgcc

      if [ -f "${mingw_target}/libgcc/auto-target.h" ]
      then
        # Might no longer be needed with modern GCC.
        run_verbose grep 'HAVE_SYS_MMAN_H' "${mingw_target}/libgcc/auto-target.h"
        run_verbose sed -i.bak -e 's|#define HAVE_SYS_MMAN_H 1|#define HAVE_SYS_MMAN_H 0|' \
          "${mingw_target}/libgcc/auto-target.h"
        run_verbose diff "${mingw_target}/libgcc/auto-target.h.bak" "${mingw_target}/libgcc/auto-target.h" || true
      fi

      echo
      echo "Running mingw-w64 ${mingw_target} gcc step 2 make..."

      # Build.
      run_verbose make -j ${JOBS}

      # make install-strip
      run_verbose make install-strip

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/make-final-output-$(ndate).txt"

    (
      # xbb_activate_installed_bin

      if true
      then

        cd "${BINS_INSTALL_FOLDER_PATH}" # ! usr

        set +e
        find ${mingw_target} \
          -name '*.so' -type f \
          -print \
          -exec "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip" --strip-debug {} \;
        find ${mingw_target} \
          -name '*.so.*'  \
          -type f \
          -print \
          -exec "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip" --strip-debug {} \;
        # Note: without ranlib, windows builds failed.
        find ${mingw_target} lib/gcc/${mingw_target} \
          -name '*.a'  \
          -type f  \
          -print \
          -exec "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip" --strip-debug {} \; \
          -exec "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ranlib" {} \;
        set -e

      fi
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/strip-final-output-$(ndate).txt"

    (
      test_mingw_gcc "${mingw_arch}"
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/test-final-output-$(ndate).txt"

    hash -r

    touch "${mingw_gcc_final_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_target} gcc final already installed."
  fi

  tests_add "test_mingw_gcc" "${mingw_arch}"
}

function test_mingw_gcc()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"
  (
    # xbb_activate_installed_bin

    echo
    echo "Testing if mingw-w64 ${mingw_arch} gcc binaries start properly..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" --version
    if [ -f "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gfortran" ]
    then
      run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gfortran" --version
    fi

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-ar" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-nm" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-ranlib" --version

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcov" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcov-dump" --version
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcov-tool" --version


    echo
    echo "Showing the mingw-w64 ${mingw_arch} gcc configurations..."

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -v
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -dumpversion
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -dumpmachine

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-search-dirs
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-libgcc-file-name
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-multi-directory
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-multi-lib
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-multi-os-directory
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-sysroot
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-file-name=libgcc_s.so
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc" -print-prog-name=cc1

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" --help
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -v
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -dumpversion
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -dumpmachine

    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-search-dirs
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-libgcc-file-name
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-multi-directory
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-multi-lib
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-multi-os-directory
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-sysroot
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-file-name=libstdc++-6.dll
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-file-name=libwinpthread-1.dll
    run_app "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++" -print-prog-name=cc1plus

    echo
    echo "Testing if mingw-w64 ${mingw_arch} gcc compiles simple Hello programs..."

    rm -rf "${HOME}/tmp/mingw-${mingw_arch}-gcc"
    mkdir -pv "${HOME}/tmp/mingw-${mingw_arch}-gcc"
    cd "${HOME}/tmp/mingw-${mingw_arch}-gcc"

    local tests_folder_path="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}"
    local tmp="${tests_folder_path}/tests/mingw-${mingw_arch}-gcc"
    rm -rf "${tmp}"

    mkdir -p "${tmp}"
    cd "${tmp}"

    echo
    echo "Testing if mingw gcc compiles simple Hello programs..."

    mkdir -pv "${HOME}/tmp/mingw-gcc"
    cd "${HOME}/tmp/mingw-gcc"

    # Note: __EOF__ is quoted to prevent substitutions here.
    cat <<'__EOF__' > hello.cpp
#include <iostream>

int
main(int argc, char* argv[])
{
std::cout << "Hello" << std::endl;
}
__EOF__

    run_verbose "${BINS_INSTALL_FOLDER_PATH}/usr/bin/${MINGW_TARGET}-g++" hello.cpp -o hello -v -static-libgcc -static-libstdc++

    # TODO
    # run_verbose wine hello.exe

    # rm -rf hello.*
  )
}

# -----------------------------------------------------------------------------
# mingw-w64

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

function prepare_mingw_env()
{
  export mingw_version="$1"

  # Number
  export mingw_version_major=$(echo ${mingw_version} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

  # The original SourceForge location.
  export mingw_src_folder_name="mingw-w64-v${mingw_version}"
}

function download_mingw()
{
  local mingw_folder_archive="${mingw_src_folder_name}.tar.bz2"
  # The original SourceForge location.
  local mingw_url="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/${mingw_folder_archive}"

  # If SourceForge is down, there is also a GitHub mirror.
  # https://github.com/mirror/mingw-w64
  # mingw_src_folder_name="mingw-w64-${mingw_version}"
  # mingw_folder_archive="v${mingw_version}.tar.gz"
  # mingw_url="https://github.com/mirror/mingw-w64/archive/${mingw_folder_archive}"

  # https://sourceforge.net/p/mingw-w64/wiki2/Cross%20Win32%20and%20Win64%20compiler/
  # https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/configure

  (
    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${mingw_url}" "${mingw_folder_archive}" \
      "${mingw_src_folder_name}"
  )
}

# Used to initialise options in all mingw builds:
# `config_options=("${config_options_common[@]}")`

function prepare_mingw_config_options_common()
{
  # ---------------------------------------------------------------------------
  # Used in multiple configurations.

  config_options_common=()

  local prefix=${BINS_INSTALL_FOLDER_PATH}
  if [ $# -ge 1 ]
  then
    config_options_common+=("--prefix=$1")
  else
    echo "prepare_mingw_config_options_common requires a prefix path"
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

  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_headers_folder_name="mingw-${mingw_version}-${mingw_arch}-headers"

  local mingw_headers_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_headers_folder_name}-installed"
  if [ ! -f "${mingw_headers_stamp_file_path}" ]
  then

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_headers_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"

      # xbb_activate_installed_dev

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running mingw-w64 ${mingw_arch} headers configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-headers/configure" --help
          fi

          # Use architecture subfolders.
          prepare_mingw_config_options_common "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}" # Arch
          config_options=("${config_options_common[@]}")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${mingw_target}") # Arch
          config_options+=("--target=${mingw_target}")

          # config_options+=("--with-tune=generic")

          config_options+=("--enable-sdk=all") # Arch
          config_options+=("--enable-idl") # MYSYS2
          config_options+=("--without-widl") # MSYS2

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-headers/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 headers make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        if false
        then
          # Remove dummy headers, overriden by winpthread.
          # Arch
          rm -v "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/include/pthread_signal.h"
          rm -v "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/include/pthread_time.h"
          rm -v "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/include/pthread_unistd.h"
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_headers_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}" \
        "mingw-w64-${mingw_version}"
    )

    hash -r

    touch "${mingw_headers_stamp_file_path}"

  else
    echo "Component mingw-w64 headers already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_mingw_widl()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_widl_folder_name="mingw-${mingw_version}-${mingw_arch}-widl"

  mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_widl_folder_name}"

  local mingw_widl_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_widl_folder_name}-installed"
  if [ ! -f "${mingw_widl_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_widl_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_widl_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC} -v"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running mingw-w64 ${mingw_arch} widl configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-tools/widl/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}") # Arch /usr
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${BUILD}") # Native!
          config_options+=("--target=${mingw_target}")

          config_options+=("--with-widl-includedir=${BINS_INSTALL_FOLDER_PATH}/include")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-tools/widl/configure" \
            "${config_options[@]}"

         cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} widl make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_widl_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    touch "${mingw_widl_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_arch} widl already installed."
  fi
}

# -----------------------------------------------------------------------------

function build_mingw_crt()
{
  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-crt/trunk/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-crt-git/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_crt_folder_name="mingw-${mingw_version}-${mingw_arch}-crt"

  local mingw_crt_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_crt_folder_name}-installed"
  if [ ! -f "${mingw_crt_stamp_file_path}" ]
  then

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_crt_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"

      xbb_activate_installed_bin
#      xbb_activate_installed_dev

      # Overwrite the flags, -ffunction-sections -fdata-sections result in
      # {standard input}: Assembler messages:
      # {standard input}:693: Error: CFI instruction used without previous .cfi_startproc
      # {standard input}:695: Error: .cfi_endproc without corresponding .cfi_startproc
      # {standard input}:697: Error: .seh_endproc used in segment '.text' instead of expected '.text$WinMainCRTStartup'
      # {standard input}: Error: open CFI at the end of file; missing .cfi_endproc directive
      # {standard input}:7150: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}
      # {standard input}:8937: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}

      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS="-v"

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
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running mingw-w64 ${mingw_arch} crt configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-crt/configure" --help
          fi

          config_options=()

          prepare_mingw_config_options_common "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}" # Arch /usr
          config_options=("${config_options_common[@]}")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--with-sysroot=${BINS_INSTALL_FOLDER_PATH}")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${mingw_target}")
          config_options+=("--target=${mingw_target}")

          if [ "${mingw_arch}" == "x86_64" ]
          then
            config_options+=("--disable-lib32")
            config_options+=("--enable-lib64")
          elif [ "${mingw_arch}" == "i686" ]
          then
            config_options+=("--enable-lib32")
            config_options+=("--disable-lib64")
          else
            echo "Unsupported mingw_target ${mingw_target}."
            exit 1
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-crt/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} crt make..."

        # Build.
        # run_verbose make -j ${JOBS}
        # i686 fails with bfd_open failed reopen stub file
        run_verbose make -j1

        # make install-strip
        run_verbose make install-strip

        ls -l "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_crt_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    touch "${mingw_crt_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_target} crt already installed."
  fi
}

# -----------------------------------------------------------------------------


function build_mingw_winpthreads()
{
  # https://github.com/archlinux/svntogit-community/blob/packages/mingw-w64-winpthreads/trunk/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-winpthreads-git/PKGBUILD
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/mingw-w64.rb

  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_build_winpthreads_folder_name="mingw-${mingw_version}-${mingw_arch}-winpthreads"

  local mingw_winpthreads_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_build_winpthreads_folder_name}-installed"
  if [ ! -f "${mingw_winpthreads_stamp_file_path}" ]
  then

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}"

      xbb_activate_installed_bin
      # xbb_activate_installed_dev

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS="-v"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      # export CC=""
      # prepare_gcc_env "${MINGW_TARGET}-"

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running mingw-w64 ${mingw_target} winpthreads configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/winpthreads/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}/${mingw_target}") # Arch /usr
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")
#          config_options+=("--bindir=${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/lib")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${mingw_target}")
          config_options+=("--target=${mingw_target}")

          config_options+=("--with-sysroot=${BINS_INSTALL_FOLDER_PATH}")

          config_options+=("--enable-static")

          if true
          then
            config_options+=("--enable-shared")
          else
            config_options+=("--disable-shared")
          fi

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/winpthreads/configure" \
            "${config_options[@]}"

         cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_target} winpthreads make..."

        # Build.
        run_verbose make -j ${JOBS}

        # make install-strip
        run_verbose make install

        run_verbose ls -l "${BINS_INSTALL_FOLDER_PATH}/usr/${mingw_target}"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    touch "${mingw_winpthreads_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_target} winpthreads already installed."
  fi
}

# -----------------------------------------------------------------------------
