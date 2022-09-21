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

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}") # Arch, HB
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${mingw_target}") # Arch, HB

          if [ "${TARGET_PLATFORM}" == "win32" ]
          then
            config_options+=("--program-prefix=${mingw_target}-")
          fi

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
    echo
    echo "Checking the mingw-w64 ${mingw_arch} binutils shared libraries..."

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ar${DOT_EXE}"

    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-as${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ld${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-nm${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objcopy${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objdump${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-ranlib${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-size${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strings${DOT_EXE}"
    show_libs "${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-strip${DOT_EXE}"

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

# GCC_PATCH_FILE_NAME
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
      "${mingw_gcc_src_folder_name}" \
      "${MINGW_GCC_PATCH_FILE_NAME:-none}"

    mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}"

    (
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

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
          config_options+=("--host=${HOST}")
          config_options+=("--target=${mingw_target}") # Arch

          if [ "${TARGET_PLATFORM}" == "win32" ]
          then
            config_options+=("--program-prefix=${mingw_target}-")
          fi

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
      mkdir -pv "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

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
    CC="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc"
    CXX="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-g++"
    F90="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gfortran"

    AR="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-ar"
    NM="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-nm"
    RANLIB="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcc-ranlib"

    OBJDUMP="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-objdump"

    GCOV="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gcov"

    DLLTOOL="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-dlltool"
    # No gendef, libmangle fails on macOS.
    # GENDEF="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-gendef"
    WIDL="${BINS_INSTALL_FOLDER_PATH}/bin/${mingw_target}-widl"

    echo
    echo "Testing if mingw-w64 ${mingw_arch} gcc binaries start properly..."

    run_app "${CC}" --version
    run_app "${CXX}" --version
    if [ -f "${F90}" ]
    then
      run_app "${F90}" --version
    fi

    run_app "${AR}" --version
    run_app "${NM}" --version
    run_app "${RANLIB}" --version

    run_app "${GCOV}" --version
    run_app "${GCOV}-dump" --version
    run_app "${GCOV}-tool" --version

    echo
    echo "Showing the mingw-w64 ${mingw_arch} gcc configurations..."

    run_app "${CC}" --help
    run_app "${CC}" -v
    run_app "${CC}" -dumpversion
    run_app "${CC}" -dumpmachine

    run_app "${CC}" -print-search-dirs
    run_app "${CC}" -print-libgcc-file-name
    run_app "${CC}" -print-multi-directory
    run_app "${CC}" -print-multi-lib
    run_app "${CC}" -print-multi-os-directory
    run_app "${CC}" -print-sysroot
    run_app "${CC}" -print-file-name=libgcc_s_seh-1.dll
    run_app "${CC}" -print-prog-name=cc1

    run_app "${CXX}" --help
    run_app "${CXX}" -v
    run_app "${CXX}" -dumpversion
    run_app "${CXX}" -dumpmachine

    run_app "${CXX}" -print-search-dirs
    run_app "${CXX}" -print-libgcc-file-name
    run_app "${CXX}" -print-multi-directory
    run_app "${CXX}" -print-multi-lib
    run_app "${CXX}" -print-multi-os-directory
    run_app "${CXX}" -print-sysroot
    run_app "${CXX}" -print-file-name=libstdc++-6.dll
    run_app "${CXX}" -print-file-name=libwinpthread-1.dll
    run_app "${CXX}" -print-prog-name=cc1plus

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
    echo "pwd: $(pwd)"

    # -------------------------------------------------------------------------

    # From https://wiki.winehq.org/Wine_User%27s_Guide#DLL_Overrides
    # DLLs usually get loaded in the following order:
    # - The directory the program was started from.
    # - The current directory.
    # - The Windows system directory.
    # - The Windows directory.
    # - The PATH variable directories.

    # -------------------------------------------------------------------------

    cp -rv "${helper_folder_path}/tests/c-cpp"/* .
    cp -rv "${helper_folder_path}/tests/fortran"/* .
    cp -rv "${helper_folder_path}/tests/wine"/* .

    # -------------------------------------------------------------------------

    VERBOSE_FLAG=""
    if [ "${IS_DEVELOP}" == "y" ]
    then
      VERBOSE_FLAG="-v"
    fi

    # Always addressed to the mingw linker, which is GNU ld.
    GC_SECTION="-Wl,--gc-sections"

    # -------------------------------------------------------------------------

    # Run tests in all 3 cases.
    test_mingw_gcc_one "${mingw_arch}" "" ""
    test_mingw_gcc_one "${mingw_arch}" "static-lib-" ""
    test_mingw_gcc_one "${mingw_arch}" "static-" ""

    # -------------------------------------------------------------------------
  )
}

function test_mingw_gcc_one()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local prefix="$2" # "", "static-lib-", "static-"
  local suffix="$3" # ""; reserved for something like "-bootstrap"

  if [ "${prefix}" == "static-lib-" ]
  then
    STATIC_LIBGCC="-static-libgcc"
    # Force static libwinpthread.
    STATIC_LIBSTD="-Wl,-Bstatic,-lstdc++,-lpthread,-Bdynamic" # -static-libstdc++"
  elif [ "${prefix}" == "static-" ]
  then
    STATIC_LIBGCC="-static"
    STATIC_LIBSTD=""
  else
    STATIC_LIBGCC=""
    STATIC_LIBSTD=""

    # The DLLs are available in the /lib folder.
    export WINEPATH="${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/lib;${WINEPATH:-}"
    echo "WINEPATH=${WINEPATH}"
  fi

  # ---------------------------------------------------------------------------

  # Test C compile and link in a single step.
  run_verbose "${CC}" -v -o "${prefix}simple-hello-c1${suffix}.exe" simple-hello.c ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}simple-hello-c1${suffix}.exe" "Hello"

  # Test C compile and link in a single step with gc.
  run_verbose "${CC}" ${VERBOSE_FLAG} -o "${prefix}gc-simple-hello-c1${suffix}.exe" simple-hello.c -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}gc-simple-hello-c1${suffix}.exe" "Hello"

  # Test C compile and link in separate steps.
  run_verbose "${CC}" -o "simple-hello-c.o" -c simple-hello.c -ffunction-sections -fdata-sections
  run_verbose "${CC}" ${VERBOSE_FLAG} -o "${prefix}simple-hello-c2${suffix}.exe" simple-hello-c.o ${GC_SECTION} ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}simple-hello-c2${suffix}.exe" "Hello"

  # Test LTO C compile and link in a single step.
  run_verbose "${CC}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-c1${suffix}.exe" simple-hello.c -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}lto-simple-hello-c1${suffix}.exe" "Hello"

  # Test LTO C compile and link in separate steps.
  run_verbose "${CC}" -o lto-simple-hello-c.o -c simple-hello.c -ffunction-sections -fdata-sections -flto
  run_verbose "${CC}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-c2${suffix}.exe" lto-simple-hello-c.o -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}lto-simple-hello-c2${suffix}.exe" "Hello"

  # ---------------------------------------------------------------------------

  # Test C++ compile and link in a single step.
  run_verbose "${CXX}" -v -o "${prefix}simple-hello-cpp1${suffix}.exe" simple-hello.cpp ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}simple-hello-cpp1${suffix}.exe" "Hello"

  # Test C++ compile and link in a single step with gc.
  run_verbose "${CXX}" -v -o "${prefix}gc-simple-hello-cpp1${suffix}.exe" simple-hello.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}gc-simple-hello-cpp1${suffix}.exe" "Hello"

  # Test C++ compile and link in separate steps.
  run_verbose "${CXX}" -o simple-hello-cpp.o -c simple-hello.cpp -ffunction-sections -fdata-sections
  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-hello-cpp2${suffix}.exe" simple-hello-cpp.o -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}simple-hello-cpp2${suffix}.exe" "Hello"

  # Test LTO C++ compile and link in a single step.
  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-cpp1${suffix}.exe" simple-hello.cpp -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}lto-simple-hello-cpp1${suffix}.exe" "Hello"

  # Test LTO C++ compile and link in separate steps.
  run_verbose "${CXX}" -o lto-simple-hello-cpp.o -c simple-hello.cpp -ffunction-sections -fdata-sections -flto
  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-cpp2${suffix}.exe" lto-simple-hello-cpp.o -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}lto-simple-hello-cpp2${suffix}.exe" "Hello"

  # ---------------------------------------------------------------------------

  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-exception${suffix}.exe" simple-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}simple-exception${suffix}.exe" "MyException"

  # -O0 is an attempt to prevent any interferences with the optimiser.
  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-str-exception${suffix}.exe" simple-str-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}simple-str-exception${suffix}.exe" "MyStringException"

  run_verbose "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-int-exception${suffix}.exe" simple-int-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect "${mingw_arch}" "${prefix}simple-int-exception${suffix}.exe" "42"

  # ---------------------------------------------------------------------------

  # Test a very simple Objective-C (a printf).
  run_verbose "${CC}" ${VERBOSE_FLAG} -o "${prefix}simple-objc${suffix}.exe" simple-objc.m -O0 ${STATIC_LIBGCC}
  test_expect "${mingw_arch}" "${prefix}simple-objc${suffix}.exe" "Hello World"

  # ---------------------------------------------------------------------------

  # Test a very simple Fortran (a print).
  run_verbose "${F90}" ${VERBOSE_FLAG}  -o "${prefix}hello-f${suffix}.exe" hello.f90 ${STATIC_LIBGCC}
  # The space is expected.
  test_expect "${mingw_arch}" "${prefix}hello-f${suffix}.exe" " Hello"

  run_verbose "${F90}" ${VERBOSE_FLAG}  -o "${prefix}concurrent-f${suffix}.exe" concurrent.f90 ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}concurrent-f${suffix}.exe"

  # ---------------------------------------------------------------------------
  # Tests borrowed from the llvm-mingw project.

  run_verbose "${CC}" -o "${prefix}hello${suffix}.exe" hello.c ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}hello${suffix}.exe"

  run_verbose "${CC}" -o "${prefix}setjmp${suffix}.exe" setjmp-patched.c ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}setjmp${suffix}.exe"

  run_verbose "${CC}" -o "${prefix}hello-tls${suffix}.exe" hello-tls.c ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}hello-tls${suffix}.exe"

  run_verbose "${CC}" -o "${prefix}crt-test${suffix}.exe" crt-test.c ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}crt-test${suffix}.exe"

  if [ "${prefix}" != "static-" ]
  then
    run_verbose "${CC}" -o autoimport-lib.dll autoimport-lib.c -shared  -Wl,--out-implib,libautoimport-lib.dll.a ${VERBOSE_FLAG} ${STATIC_LIBGCC}
    show_dlls "${mingw_arch}" autoimport-lib.dll

    run_verbose "${CC}" -o "${prefix}autoimport-main${suffix}.exe" autoimport-main.c -L. -lautoimport-lib ${VERBOSE_FLAG} ${STATIC_LIBGCC}
    run_wine "${mingw_arch}" "${prefix}autoimport-main${suffix}.exe"
  fi

  # The IDL output isn't arch specific, but test each arch frontend
  run_verbose "${WIDL}" -o idltest.h idltest.idl -h
  run_verbose "${CC}" -o "${prefix}idltest${suffix}.exe" idltest.c -I. -lole32 ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_arch}" "${prefix}idltest${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}hello-cpp${suffix}.exe" hello-cpp.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}hello-cpp${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}hello-exception${suffix}.exe" hello-exception.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}hello-exception${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}exception-locale${suffix}.exe" exception-locale.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}exception-locale${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}exception-reduced${suffix}.exe" exception-reduced.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}exception-reduced${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}global-terminate${suffix}.exe" global-terminate.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}global-terminate${suffix}.exe"

  run_verbose ${CXX} -o "${prefix}longjmp-cleanup${suffix}.exe" longjmp-cleanup.cpp ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}longjmp-cleanup${suffix}.exe"

  run_verbose ${CXX} -o tlstest-lib.dll tlstest-lib.cpp -shared -Wl,--out-implib,libtlstest-lib.dll.a ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  show_dlls "${OBJDUMP}" "tlstest-lib.dll"

  run_verbose ${CXX} -o "${prefix}tlstest-main${suffix}.exe" tlstest-main.cpp ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_arch}" "${prefix}tlstest-main${suffix}.exe"

  if [ "${prefix}" != "static-" ]
  then
    run_verbose ${CXX} -o throwcatch-lib.dll throwcatch-lib.cpp -shared -Wl,--out-implib,libthrowcatch-lib.dll.a ${VERBOSE_FLAG}

    run_verbose ${CXX} -o "${prefix}throwcatch-main${suffix}.exe" throwcatch-main.cpp -L. -lthrowcatch-lib ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}

    run_wine "${mingw_arch}" "${prefix}throwcatch-main${suffix}.exe"
  fi

  # On Windows only the -flto linker is capable of understanding weak symbols.
  run_verbose "${CC}" -c -o "${prefix}hello-weak${suffix}.c.o" hello-weak.c -flto
  run_verbose "${CC}" -c -o "${prefix}hello-f-weak${suffix}.c.o" hello-f-weak.c -flto
  run_verbose "${CC}" -o "${prefix}hello-weak${suffix}.exe" "${prefix}hello-weak${suffix}.c.o" "${prefix}hello-f-weak${suffix}.c.o" ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC} -flto
  test_expect "${mingw_arch}" "${prefix}hello-weak${suffix}.exe" "Hello World!"

  # ---------------------------------------------------------------------------
}

function test_expect()
{
  local mingw_arch="$1"
  local app_name="$2"
  local expected="$3"
  shift 3

  if [ "${IS_DEVELOP}" == "y" ]
  then
    show_dlls "${OBJDUMP}" "${app_name}"
  fi

  # No 32-bit support in XBB wine.
  # module:load_wow64_ntdll failed to load L"\\??\\C:\\windows\\syswow64\\ntdll.dll" error c0000135
  if [ "${mingw_arch}" == "x86_64" ]
  then
    (
      xbb_activate

      local wine_path=$(which wine 2>/dev/null)
      if [ ! -z "${wine_path}" ]
      then
        local output
        # Remove the trailing CR present on Windows.
        if [ "${app_name:0:1}" == "/" ]
        then
          output="$(wine "${app_name}" "$@" | sed 's/\r$//')"
        else
          output="$(wine "./${app_name}" "$@" | sed 's/\r$//')"
        fi

        if [ "x${output}x" == "x${expected}x" ]
        then
          echo
          echo "Test \"${app_name}\" passed :-)"
        else
          echo "expected ${#expected}: \"${expected}\""
          echo "got ${#output}: \"${output}\""
          echo
          exit 1
        fi
      else
        echo
        echo "wine" "${app_name}" "$@" "- not available"
      fi
    )
  fi
}

function run_wine()
{
  local mingw_arch="$1"
  local app_name="$2"
  shift 2

  if [ "${IS_DEVELOP}" == "y" ]
  then
    show_dlls "${OBJDUMP}" "${app_name}"
  fi

  # No 32-bit support in XBB wine.
  # module:load_wow64_ntdll failed to load L"\\??\\C:\\windows\\syswow64\\ntdll.dll" error c0000135
  if [ "${mingw_arch}" == "x86_64" ]
  then
    (
      xbb_activate

      local wine_path=$(which wine 2>/dev/null)
      if [ ! -z "${wine_path}" ]
      then
        run_verbose wine "${app_name}" "$@"
      else
        echo
        echo "wine" "${app_name}" "$@" "- not available"
      fi
    )
  fi
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
          echo "Running mingw-w64 ${mingw_arch} widl configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-tools/widl/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}") # Arch /usr
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}") # Native!
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

# Fails on macOS, due to <malloc.h>.
function build_mingw_libmangle()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_libmangle_folder_name="mingw-${mingw_version}-${mingw_arch}-libmangle"

  mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}"

  local mingw_libmangle_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_libmangle_folder_name}-installed"
  if [ ! -f "${mingw_libmangle_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_libmangle_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_libmangle_folder_name}"

      # xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_LIB}"
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
          echo "Running mingw-w64 ${mingw_arch} libmangle configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/libmangle/configure" --help
          fi

          config_options=()
          # Note: native library.
          config_options+=("--prefix=${LIBS_INSTALL_FOLDER_PATH}")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}") # Native!
          config_options+=("--target=${mingw_target}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/libmangle/configure" \
            "${config_options[@]}"

         cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} libmangle make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_libmangle_folder_name}/make-libmangle-output-$(ndate).txt"
    )

    touch "${mingw_libmangle_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_arch} libmangle already installed."
  fi
}


function build_mingw_gendef()
{
  local mingw_arch="$1"
  local mingw_target="${mingw_arch}-w64-mingw32"

  local mingw_gendef_folder_name="mingw-${mingw_version}-${mingw_arch}-gendef"

  mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}"

  local mingw_gendef_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_gendef_folder_name}-installed"
  if [ ! -f "${mingw_gendef_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_gendef_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_gendef_folder_name}"

      # To pick libmangle.
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

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
          echo "Running mingw-w64 ${mingw_arch} gendef configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-tools/gendef/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}")
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}") # Native!
          config_options+=("--target=${mingw_target}")

          config_options+=("--with-mangle=${LIBS_INSTALL_FOLDER_PATH}")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${MINGW_SRC_FOLDER_NAME}/mingw-w64-tools/gendef/configure" \
            "${config_options[@]}"

         cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/config-gendef-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running mingw-w64 ${mingw_arch} gendef make..."

        # Build.
        run_verbose make -j ${JOBS}

        run_verbose make install-strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_gendef_folder_name}/make-output-$(ndate).txt"
    )

    touch "${mingw_gendef_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_arch} gendef already installed."
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

      # To use the new toolchain.
      xbb_activate_installed_bin

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

      # To use the new toolchain.
      xbb_activate_installed_bin

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"

      LDFLAGS="-v"

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
          echo "Running mingw-w64 ${mingw_target} winpthreads configure..."

          if [ "${IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/winpthreads/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${BINS_INSTALL_FOLDER_PATH}/${mingw_target}") # Arch /usr
          config_options+=("--mandir=${LIBS_INSTALL_FOLDER_PATH}/share/man")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${mingw_target}")
          config_options+=("--target=${mingw_target}")

          config_options+=("--with-sysroot=${BINS_INSTALL_FOLDER_PATH}")

          config_options+=("--enable-static")
          config_options+=("--enable-shared")

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

        # GCC install all DLLs in lib; for consistency, move this one too.
        run_verbose mv "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/bin/libwinpthread-1.dll" \
          "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/lib/"

        run_verbose ls -l "${BINS_INSTALL_FOLDER_PATH}/${mingw_target}/lib/libwinpthread"*

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_build_winpthreads_folder_name}/make-output-$(ndate).txt"
    )

    hash -r

    touch "${mingw_winpthreads_stamp_file_path}"

  else
    echo "Component mingw-w64 ${mingw_target} winpthreads already installed."
  fi
}

# -----------------------------------------------------------------------------
