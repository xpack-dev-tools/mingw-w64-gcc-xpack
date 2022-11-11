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

# XBB_MINGW_GCC_PATCH_FILE_NAME
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
  local mingw_triplet="$2"
  local name_suffix="${3:-""}"

  # Number
  local mingw_gcc_version_major=$(echo ${mingw_gcc_version} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

  local mingw_gcc_src_folder_name="gcc-${mingw_gcc_version}"

  local mingw_gcc_archive="${mingw_gcc_src_folder_name}.tar.xz"
  local mingw_gcc_url="https://ftp.gnu.org/gnu/gcc/gcc-${mingw_gcc_version}/${mingw_gcc_archive}"

  export mingw_gcc_folder_name="${mingw_triplet}-gcc-${mingw_gcc_version}${name_suffix}"

  local mingw_gcc_step1_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_triplet}-gcc-first-${mingw_gcc_version}${name_suffix}-installed"
  if [ ! -f "${mingw_gcc_step1_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    download_and_extract "${mingw_gcc_url}" "${mingw_gcc_archive}" \
      "${mingw_gcc_src_folder_name}" \
      "${XBB_MINGW_GCC_PATCH_FILE_NAME:-none}"

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

      xbb_activate_dependencies_dev "${name_suffix}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      if [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        # x86_64-w64-mingw32/bin/as: insn-emit.o: too many sections (32823)
        # `-Wa,-mbig-obj` is passed to the wrong compiler, and fails
        CXXFLAGS=$(echo ${CXXFLAGS} | sed -e 's|-ffunction-sections -fdata-sections||')
      fi

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
          echo "Running ${mingw_triplet}-gcc${name_suffix} first configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            # For the native build, --disable-shared failed with errors in libstdc++-v3
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/configure" --help
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/gcc/configure" --help

            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/libgcc/configure" --help
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/libstdc++-v3/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}") # Arch /usr
          config_options+=("--libexecdir=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/lib") # Arch /usr/lib
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}") # Same as BUILD for bootstrap
          config_options+=("--target=${mingw_triplet}") # Arch

          if [ "${XBB_HOST_PLATFORM}" == "win32" ]
          then
            config_options+=("--program-prefix=${mingw_triplet}-")

            # config_options+=("--with-arch=x86-64")
            # config_options+=("--with-tune=generic")

            config_options+=("--enable-mingw-wildcard")

            # This should point to the location where mingw headers are,
            # relative to --prefix, but starting with /.
            # config_options+=("--with-native-system-header-dir=${mingw_triplet}/include")

            # Disable look up installations paths in the registry.
            config_options+=("--disable-win32-registry")
            # Turn off symbol versioning in the shared library
            config_options+=("--disable-symvers")
          fi

          # config_options+=("--with-sysroot=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")
          config_options+=("--with-pkgversion=${XBB_GCC_BRANDING}")

          config_options+=("--with-default-libstdcxx-abi=new")
          config_options+=("--with-diagnostics-color=auto")
          config_options+=("--with-dwarf2") # Arch

          # In file included from /Host/home/ilg/Work/mingw-w64-gcc-11.3.0-1/win32-x64/sources/gcc-11.3.0/libcc1/findcomp.cc:28:
          # /Host/home/ilg/Work/mingw-w64-gcc-11.3.0-1/win32-x64/sources/gcc-11.3.0/libcc1/../gcc/system.h:698:10: fatal error: gmp.h: No such file or directory
          config_options+=("--with-gmp=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")
          config_options+=("--with-mpfr=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")
          config_options+=("--with-mpc=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")
          config_options+=("--with-isl=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")
          config_options+=("--with-libiconv-prefix=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")
          config_options+=("--with-zstd=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")

          # Use the zlib compiled from sources.
          config_options+=("--with-system-zlib")

          config_options+=("--without-cuda-driver")

          config_options+=("--enable-languages=c,c++,fortran,objc,obj-c++,lto") # Arch

          config_options+=("--enable-shared") # Arch
          config_options+=("--enable-static") # Arch

          config_options+=("--enable-__cxa_atexit")
          config_options+=("--enable-checking=release") # Arch
          config_options+=("--enable-cloog-backend=isl") # Arch
          config_options+=("--enable-fully-dynamic-string") # Arch
          config_options+=("--enable-libgomp") # Arch
          config_options+=("--enable-libatomic")
          config_options+=("--enable-graphite")
          config_options+=("--enable-libquadmath")
          config_options+=("--enable-libquadmath-support")
          config_options+=("--enable-libssp")

          config_options+=("--enable-libstdcxx")
          config_options+=("--enable-libstdcxx-time=yes")
          config_options+=("--enable-libstdcxx-visibility")
          config_options+=("--enable-libstdcxx-threads")
          config_options+=("--enable-libstdcxx-filesystem-ts=yes") # Arch
          config_options+=("--enable-libstdcxx-time=yes") # Arch
          config_options+=("--enable-lto") # Arch
          config_options+=("--enable-pie-tools")
          config_options+=("--enable-threads=posix") # Arch

          # Fails with:
          # x86_64-w64-mingw32/bin/ld: cannot find -lgcc_s: No such file or directory
          # config_options+=("--enable-version-specific-runtime-libs")

          # Apparently innefective, on i686 libgcc_s_dw2-1.dll is used anyway.
          # config_options+=("--disable-dw2-exceptions")
          config_options+=("--disable-install-libiberty")
          config_options+=("--disable-libstdcxx-debug")
          config_options+=("--disable-libstdcxx-pch")
          config_options+=("--disable-multilib") # Arch
          config_options+=("--disable-nls")
          config_options+=("--disable-sjlj-exceptions") # Arch
          config_options+=("--disable-werror")

          # Arch configures only the gcc folder, but in this case it
          # fails with missing libiberty.a.
          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${mingw_gcc_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/config-step1-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/configure-step1-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet}-gcc${name_suffix} first make..."

        # Build.
        run_verbose make -j ${XBB_JOBS} all-gcc

        run_verbose make install-strip-gcc

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/make-step1-output-$(ndate).txt"
    )

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_gcc_step1_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}-gcc${name_suffix} first already installed."
  fi
}

function build_mingw_gcc_final()
{
  local mingw_triplet="$1"
  local name_suffix="${2:-""}"

  local mingw_gcc_final_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_triplet}-gcc-final-${mingw_gcc_version}${name_suffix}-installed"
  if [ ! -f "${mingw_gcc_final_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_gcc_folder_name}"

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

      xbb_show_env_develop

      echo
      echo "Running ${mingw_triplet}-gcc${name_suffix} final configure..."

      run_verbose make -j configure-target-libgcc

      if false # [ -f "${mingw_triplet}/libgcc/auto-target.h" ]
      then
        # Might no longer be needed with modern GCC.
        run_verbose grep 'HAVE_SYS_MMAN_H' "${mingw_triplet}/libgcc/auto-target.h"
        run_verbose sed -i.bak -e 's|#define HAVE_SYS_MMAN_H 1|#define HAVE_SYS_MMAN_H 0|' \
          "${mingw_triplet}/libgcc/auto-target.h"
        run_verbose diff "${mingw_triplet}/libgcc/auto-target.h.bak" "${mingw_triplet}/libgcc/auto-target.h" || true
      fi

      echo
      echo "Running ${mingw_triplet}-gcc${name_suffix} final make..."

      # Build.
      run_verbose make -j ${XBB_JOBS}

      # make install-strip
      run_verbose make install-strip

      if [ -z "${name_suffix}"]
      then
        (
          cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}"
          run_verbose find . -name '*.dll'
          # The DLLs are expected to be in the /${mingw_triplet}/lib folder.
          run_verbose find bin lib -name '*.dll' -exec cp -v '{}' "${mingw_triplet}/lib" ';'
        )
      fi

      # Remove weird files like x86_64-w64-mingw32-x86_64-w64-mingw32-c++.exe
      run_verbose rm -rf "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/bin/${mingw_triplet}-${mingw_triplet}-"*.exe

    ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/make-final-output-$(ndate).txt"

    (
      if true
      then

        # TODO!
        # For *-w64-mingw32-strip
        xbb_activate_installed_bin

        echo
        echo "Stripping ${mingw_triplet}-gcc${name_suffix} libraries..."

        cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}" # ! usr

        set +e
        find ${mingw_triplet} \
          -name '*.so' -type f \
          -print \
          -exec "${mingw_triplet}-strip" --strip-debug '{}' ';'
        find ${mingw_triplet} \
          -name '*.so.*'  \
          -type f \
          -print \
          -exec "${mingw_triplet}-strip" --strip-debug '{}' ';'
        # Note: without ranlib, windows builds failed.
        find ${mingw_triplet} lib/gcc/${mingw_triplet} \
          -name '*.a'  \
          -type f  \
          -print \
          -exec "${mingw_triplet}-strip" --strip-debug '{}' ';' \
          -exec "${mingw_triplet}-ranlib" '{}' ';'
        set -e

      fi
    ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/strip-final-output-$(ndate).txt"

    # Run the local tests only for the bootstrap, the tests for the final
    # version are performed at the end.
    if [ "${name_suffix}" == "-bootstrap" ]
    then
      (
        if [ "${XBB_HOST_PLATFORM}" == "win32" ]
        then
          # The tests also need the libraries DLLs; later on are copied.
          export WINEPATH="${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}/bin"
        fi
        test_mingw2_gcc "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/bin" "${mingw_triplet}" "${name_suffix}"
      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_gcc_folder_name}/test-final-output-$(ndate).txt"
    fi

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_gcc_final_stamp_file_path}"

  else
    echo "Component ${mingw_triplet}-gcc${name_suffix} final already installed."
  fi

  if [ -z "${name_suffix}" ]
  then
    tests_add "test_mingw2_gcc" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/bin" "${mingw_triplet}" "${name_suffix}"
  fi
}

function test_mingw2_gcc()
{
  local test_bin_path="$1"
  local mingw_triplet="$2"
  local name_suffix="${3:-""}"

  (
    CC="${test_bin_path}/${mingw_triplet}-gcc"
    CXX="${test_bin_path}/${mingw_triplet}-g++"
    F90="${test_bin_path}/${mingw_triplet}-gfortran"

    AR="${test_bin_path}/${mingw_triplet}-gcc-ar"
    NM="${test_bin_path}/${mingw_triplet}-gcc-nm"
    RANLIB="${test_bin_path}/${mingw_triplet}-gcc-ranlib"

    OBJDUMP="${test_bin_path}/${mingw_triplet}-objdump"

    GCOV="${test_bin_path}/${mingw_triplet}-gcov"

    DLLTOOL="${test_bin_path}/${mingw_triplet}-dlltool"
    GENDEF="${test_bin_path}/${mingw_triplet}-gendef"
    WIDL="${test_bin_path}/${mingw_triplet}-widl"

    echo
    echo "Checking the ${mingw_triplet}-gcc${name_suffix} shared libraries..."

    show_libs "${CC}"
    show_libs "${CXX}"
    if [ -f "${F90}" ]
    then
      show_libs "${F90}"
    fi

    show_libs "${AR}"
    show_libs "${NM}"
    show_libs "${RANLIB}"
    show_libs "${GCOV}"

    show_libs "$(${CC} --print-prog-name=cc1)"
    show_libs "$(${CC} --print-prog-name=cc1plus)"
    show_libs "$(${CC} --print-prog-name=collect2)"
    show_libs "$(${CC} --print-prog-name=lto1)"
    show_libs "$(${CC} --print-prog-name=lto-wrapper)"

    echo
    echo "Testing if ${mingw_triplet}-gcc${name_suffix} binaries start properly..."

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

    # Not necessary in the bootstrap.
    if [ -z "${name_suffix}" ]
    then
      run_app "${GENDEF}" --help
    fi

    echo
    echo "Showing the ${mingw_triplet}-gcc${name_suffix} configurations..."

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
    echo "Testing if ${mingw_triplet}-gcc${name_suffix} compiles simple Hello programs..."

    rm -rf "${XBB_TESTS_FOLDER_PATH}/${mingw_triplet}-gcc${name_suffix}"
    mkdir -pv "${XBB_TESTS_FOLDER_PATH}/${mingw_triplet}-gcc${name_suffix}"; cd "${XBB_TESTS_FOLDER_PATH}/${mingw_triplet}-gcc${name_suffix}"

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
    if [ "${XBB_IS_DEVELOP}" == "y" ]
    then
      VERBOSE_FLAG="-v"
    fi

    # Always addressed to the mingw linker, which is GNU ld.
    GC_SECTION="-Wl,--gc-sections"

    # -------------------------------------------------------------------------

    # Run tests in all 3 cases.
    test_mingw2_gcc_one "${test_bin_path}" "${mingw_triplet}" "" "" "${name_suffix}"
    test_mingw2_gcc_one "${test_bin_path}" "${mingw_triplet}" "static-lib-" "" "${name_suffix}"
    test_mingw2_gcc_one "${test_bin_path}" "${mingw_triplet}" "static-" "" "${name_suffix}"

    # -------------------------------------------------------------------------
  )
}

function test_mingw2_gcc_one()
{
  local test_bin_path="$1"
  local mingw_triplet="$2"
  local prefix="$3" # "", "static-lib-", "static-"
  local suffix="$4" # ""; reserved for something like "-bootstrap"
  local name_suffix="${5:-""}"

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
    export WINEPATH="${test_bin_path}/../${mingw_triplet}/lib;${WINEPATH:-}"
    echo "WINEPATH=${WINEPATH}"
  fi

  # ---------------------------------------------------------------------------

  # Test C compile and link in a single step.
  run_app "${CC}" -v -o "${prefix}simple-hello-c1${suffix}.exe" simple-hello.c ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-hello-c1${suffix}.exe" "Hello"

  # Test C compile and link in a single step with gc.
  run_app "${CC}" ${VERBOSE_FLAG} -o "${prefix}gc-simple-hello-c1${suffix}.exe" simple-hello.c -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}gc-simple-hello-c1${suffix}.exe" "Hello"

  # Test C compile and link in separate steps.
  run_app "${CC}" -o "simple-hello-c.o" -c simple-hello.c -ffunction-sections -fdata-sections
  run_app "${CC}" ${VERBOSE_FLAG} -o "${prefix}simple-hello-c2${suffix}.exe" simple-hello-c.o ${GC_SECTION} ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-hello-c2${suffix}.exe" "Hello"

  # Test LTO C compile and link in a single step.
  run_app "${CC}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-c1${suffix}.exe" simple-hello.c -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}lto-simple-hello-c1${suffix}.exe" "Hello"

  # Test LTO C compile and link in separate steps.
  run_app "${CC}" -o lto-simple-hello-c.o -c simple-hello.c -ffunction-sections -fdata-sections -flto
  run_app "${CC}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-c2${suffix}.exe" lto-simple-hello-c.o -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}lto-simple-hello-c2${suffix}.exe" "Hello"

  # ---------------------------------------------------------------------------

  # Test C++ compile and link in a single step.
  run_app "${CXX}" -v -o "${prefix}simple-hello-cpp1${suffix}.exe" simple-hello.cpp ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-hello-cpp1${suffix}.exe" "Hello"

  # Test C++ compile and link in a single step with gc.
  run_app "${CXX}" -v -o "${prefix}gc-simple-hello-cpp1${suffix}.exe" simple-hello.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}gc-simple-hello-cpp1${suffix}.exe" "Hello"

  # Test C++ compile and link in separate steps.
  run_app "${CXX}" -o simple-hello-cpp.o -c simple-hello.cpp -ffunction-sections -fdata-sections
  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-hello-cpp2${suffix}.exe" simple-hello-cpp.o -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-hello-cpp2${suffix}.exe" "Hello"

  # Test LTO C++ compile and link in a single step.
  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-cpp1${suffix}.exe" simple-hello.cpp -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}lto-simple-hello-cpp1${suffix}.exe" "Hello"

  # Test LTO C++ compile and link in separate steps.
  run_app "${CXX}" -o lto-simple-hello-cpp.o -c simple-hello.cpp -ffunction-sections -fdata-sections -flto
  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}lto-simple-hello-cpp2${suffix}.exe" lto-simple-hello-cpp.o -ffunction-sections -fdata-sections ${GC_SECTION} -flto ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}lto-simple-hello-cpp2${suffix}.exe" "Hello"

  # ---------------------------------------------------------------------------

  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-exception${suffix}.exe" simple-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-exception${suffix}.exe" "MyException"

  # -O0 is an attempt to prevent any interferences with the optimiser.
  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-str-exception${suffix}.exe" simple-str-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-str-exception${suffix}.exe" "MyStringException"

  run_app "${CXX}" ${VERBOSE_FLAG} -o "${prefix}simple-int-exception${suffix}.exe" simple-int-exception.cpp -ffunction-sections -fdata-sections ${GC_SECTION} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-int-exception${suffix}.exe" "42"

  # ---------------------------------------------------------------------------

  # Test a very simple Objective-C (a printf).
  run_app "${CC}" ${VERBOSE_FLAG} -o "${prefix}simple-objc${suffix}.exe" simple-objc.m -O0 ${STATIC_LIBGCC}
  test_expect_wine "${mingw_triplet}" "${prefix}simple-objc${suffix}.exe" "Hello World"

  # ---------------------------------------------------------------------------

  # Test a very simple Fortran (a print).
  run_app "${F90}" ${VERBOSE_FLAG}  -o "${prefix}hello-f${suffix}.exe" hello.f90 ${STATIC_LIBGCC}
  # The space is expected.
  test_expect_wine "${mingw_triplet}" "${prefix}hello-f${suffix}.exe" " Hello"

  run_app "${F90}" ${VERBOSE_FLAG}  -o "${prefix}concurrent-f${suffix}.exe" concurrent.f90 ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}concurrent-f${suffix}.exe"

  # ---------------------------------------------------------------------------
  # Tests borrowed from the llvm-mingw project.

  run_app "${CC}" -o "${prefix}hello${suffix}.exe" hello.c ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}hello${suffix}.exe"

  run_app "${CC}" -o "${prefix}setjmp${suffix}.exe" setjmp-patched.c ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}setjmp${suffix}.exe"

  run_app "${CC}" -o "${prefix}hello-tls${suffix}.exe" hello-tls.c ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}hello-tls${suffix}.exe"

  run_app "${CC}" -o "${prefix}crt-test${suffix}.exe" crt-test.c ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}crt-test${suffix}.exe"

  if [ "${prefix}" != "static-" ]
  then
    run_app "${CC}" -o autoimport-lib.dll autoimport-lib.c -shared  -Wl,--out-implib,libautoimport-lib.dll.a ${VERBOSE_FLAG} ${STATIC_LIBGCC}
    show_dlls "${mingw_triplet}-objdump" autoimport-lib.dll

    run_app "${CC}" -o "${prefix}autoimport-main${suffix}.exe" autoimport-main.c -L. -lautoimport-lib ${VERBOSE_FLAG} ${STATIC_LIBGCC}
    run_wine "${mingw_triplet}" "${prefix}autoimport-main${suffix}.exe"
  fi

  # The IDL output isn't arch specific, but test each arch frontend
  run_app "${WIDL}" -o idltest.h idltest.idl -h
  run_app "${CC}" -o "${prefix}idltest${suffix}.exe" idltest.c -I. -lole32 ${VERBOSE_FLAG} ${STATIC_LIBGCC}
  run_wine "${mingw_triplet}" "${prefix}idltest${suffix}.exe"

  run_app ${CXX} -o "${prefix}hello-cpp${suffix}.exe" hello-cpp.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}hello-cpp${suffix}.exe"

  run_app ${CXX} -o "${prefix}hello-exception${suffix}.exe" hello-exception.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}hello-exception${suffix}.exe"

  run_app ${CXX} -o "${prefix}exception-locale${suffix}.exe" exception-locale.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}exception-locale${suffix}.exe"

  run_app ${CXX} -o "${prefix}exception-reduced${suffix}.exe" exception-reduced.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}exception-reduced${suffix}.exe"

  run_app ${CXX} -o "${prefix}global-terminate${suffix}.exe" global-terminate.cpp -std=c++17 ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}global-terminate${suffix}.exe"

  run_app ${CXX} -o "${prefix}longjmp-cleanup${suffix}.exe" longjmp-cleanup.cpp ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}longjmp-cleanup${suffix}.exe"

  run_app ${CXX} -o tlstest-lib.dll tlstest-lib.cpp -shared -Wl,--out-implib,libtlstest-lib.dll.a ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  show_dlls "${mingw_triplet}-objdump" "tlstest-lib.dll"

  run_app ${CXX} -o "${prefix}tlstest-main${suffix}.exe" tlstest-main.cpp ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}
  run_wine "${mingw_triplet}" "${prefix}tlstest-main${suffix}.exe"

  if [ "${prefix}" != "static-" ]
  then
    run_app ${CXX} -o throwcatch-lib.dll throwcatch-lib.cpp -shared -Wl,--out-implib,libthrowcatch-lib.dll.a ${VERBOSE_FLAG}

    run_app ${CXX} -o "${prefix}throwcatch-main${suffix}.exe" throwcatch-main.cpp -L. -lthrowcatch-lib ${VERBOSE_FLAG} ${STATIC_LIBGCC} ${STATIC_LIBSTD}

    run_wine "${mingw_triplet}" "${prefix}throwcatch-main${suffix}.exe"
  fi

  # On Windows only the -flto linker is capable of understanding weak symbols.
  run_app "${CC}" -c -o "${prefix}hello-weak${suffix}.c.o" hello-weak.c -flto
  run_app "${CC}" -c -o "${prefix}hello-f-weak${suffix}.c.o" hello-f-weak.c -flto
  run_app "${CC}" -o "${prefix}hello-weak${suffix}.exe" "${prefix}hello-weak${suffix}.c.o" "${prefix}hello-f-weak${suffix}.c.o" ${VERBOSE_FLAG} -lm ${STATIC_LIBGCC} -flto
  test_expect_wine "${mingw_triplet}" "${prefix}hello-weak${suffix}.exe" "Hello World!"

  # ---------------------------------------------------------------------------
}

function test_expect_wine()
{
  local mingw_triplet="$1"
  local app_name="$2"
  local expected="$3"
  shift 3

  if [ "${XBB_IS_DEVELOP}" == "y" ]
  then
    # TODO: remove absolute path when migrating to xPacks.
    # (for now i686-w64-mingw32-objdump is not available in the Docker image)
    show_dlls "${mingw_triplet}-objdump" "${app_name}"
  fi

  # No 32-bit support in XBB wine.
  # module:load_wow64_ntdll failed to load L"\\??\\C:\\windows\\syswow64\\ntdll.dll" error c0000135
  if [ "${mingw_triplet}" == "x86_64-w64-mingw32" ]
  then
    (
      local wine_path=$(which wine64 2>/dev/null)
      if [ ! -z "${wine_path}" ]
      then
        local output
        # Remove the trailing CR present on Windows.
        if [ "${app_name:0:1}" == "/" ]
        then
          output="$(wine64 "${app_name}" "$@" | sed 's/\r$//')"
        else
          output="$(wine64 "./${app_name}" "$@" | sed 's/\r$//')"
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
  else
    echo
    echo "wine" "${app_name}" "$@" "- ${mingw_triplet} unsupported"
  fi
}

function run_wine()
{
  local mingw_triplet="$1"
  local app_name="$2"
  shift 2

  if [ "${XBB_IS_DEVELOP}" == "y" ]
  then
    show_dlls "${mingw_triplet}-objdump" "${app_name}"
  fi

  # No 32-bit support in XBB wine.
  # module:load_wow64_ntdll failed to load L"\\??\\C:\\windows\\syswow64\\ntdll.dll" error c0000135
  if [ "${mingw_triplet}" == "x86_64-w64-mingw32" ]
  then
    (
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

