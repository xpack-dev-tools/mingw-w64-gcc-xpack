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
  local mingw_triplet="$2"
  local name_suffix="${3:-""}"

  local mingw_binutils_src_folder_name="binutils-${mingw_binutils_version}"

  local mingw_binutils_archive="${mingw_binutils_src_folder_name}.tar.xz"
  local mingw_binutils_url="https://ftp.gnu.org/gnu/binutils/${mingw_binutils_archive}"

  local mingw_binutils_folder_name="${mingw_triplet}-binutils-${mingw_binutils_version}${name_suffix}"

  local mingw_binutils_patch_file_path="${helper_folder_path}/patches/binutils-${mingw_binutils_version}.patch"
  local mingw_binutils_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_binutils_folder_name}-installed"
  if [ ! -f "${mingw_binutils_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    download_and_extract "${mingw_binutils_url}" "${mingw_binutils_archive}" \
      "${mingw_binutils_src_folder_name}" \
      "${mingw_binutils_patch_file_path}"

    mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}"

    (
      mkdir -pv "${XBB_BUILD_FOLDER_PATH}/${mingw_binutils_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${mingw_binutils_folder_name}"

      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # Currently static does not make a difference.
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
          echo "Running ${mingw_triplet} binutils${name_suffix} configure..."

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}/configure" --help
          fi

          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}") # Arch, HB
          # Ineffective.
          # config_options+=("--libdir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}/lib")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}/share/man")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}") # Same as BUILD for bootstrap
          config_options+=("--target=${mingw_triplet}") # Arch, HB

          if [ "${XBB_HOST_PLATFORM}" == "win32" ]
          then
            config_options+=("--program-prefix=${mingw_triplet}-")
          fi

          # TODO: why HB uses it and Arch does not?
          # config_options+=("--with-sysroot=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")
          config_options+=("--with-pkgversion=${XBB_BINUTILS_BRANDING}")

          config_options+=("--with-libiconv-prefix=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}${name_suffix}")

          # Use the zlib compiled from sources.
          config_options+=("--with-system-zlib")

          config_options+=("--enable-static")
          # Shared is a bit tricky, since it leads to multiple libraries
          # with the same name, which should not be copied to libexec,
          # but LC_RPATH must be adjusted to the actual location.
          config_options+=("--enable-shared")

          config_options+=("--enable-64-bit-bfd")
          config_options+=("--enable-build-warnings=no")
          config_options+=("--enable-cet")
          config_options+=("--enable-deterministic-archives") # Arch
          config_options+=("--enable-gold")
          config_options+=("--enable-install-libiberty")
          config_options+=("--enable-interwork")
          config_options+=("--enable-libssp")
          config_options+=("--enable-lto") # Arch
          config_options+=("--enable-plugins") # Arch
          config_options+=("--enable-relro")
          config_options+=("--enable-targets=${mingw_triplet}") # HB
          config_options+=("--enable-threads")

          config_options+=("--disable-debug")
          config_options+=("--disable-dependency-tracking")
          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            config_options+=("--disable-silent-rules")
          fi

          config_options+=("--disable-gdb")
          config_options+=("--disable-gdbserver")
          config_options+=("--disable-libdecnumber")

          # The mingw binaries have architecture specific names,
          # so multilib makes no sense.
          config_options+=("--disable-multilib") # Arch, HB

          config_options+=("--disable-new-dtags")
          config_options+=("--disable-nls") # Arch, HB
          config_options+=("--disable-readline")
          config_options+=("--disable-sim")
          config_options+=("--disable-werror") # Arch

          run_verbose bash "${XBB_SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running ${mingw_triplet} binutils${name_suffix} make..."

        # Build.
        run_verbose make -j ${XBB_JOBS}

        show_libs "ld/ld-new"
        show_libs "gas/as-new"
        show_libs "binutils/readelf"

        # make install-strip
        run_verbose make install

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/make-output-$(ndate).txt"

      if [ -z "${name_suffix}" ]
      then
        copy_license \
          "${XBB_SOURCES_FOLDER_PATH}/${mingw_binutils_src_folder_name}" \
          "binutils-${mingw_binutils_version}"
      fi
    )

    (
      test_mingw2_binutils "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/bin" "${mingw_triplet}" "${name_suffix}"
    ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_binutils_folder_name}/test-output-$(ndate).txt"

    hash -r

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_binutils_stamp_file_path}"

  else
    echo "Component ${mingw_triplet} binutils already installed."
  fi

  if [ -z "${name_suffix}" ]
  then
    tests_add "test_mingw2_binutils" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${name_suffix}/bin" "${mingw_triplet}" "${name_suffix}"
  fi
}

function test_mingw2_binutils()
{
  local test_bin_path="$1"
  local mingw_triplet="$2"
  local name_suffix="${3:-""}"

  (
    echo
    echo "Checking the ${mingw_triplet} binutils${name_suffix} shared libraries..."

    show_libs "${test_bin_path}/${mingw_triplet}-ar${XBB_HOST_DOT_EXE}"

    show_libs "${test_bin_path}/${mingw_triplet}-as${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-ld${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-nm${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-objcopy${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-objdump${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-ranlib${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-size${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-strings${XBB_HOST_DOT_EXE}"
    show_libs "${test_bin_path}/${mingw_triplet}-strip${XBB_HOST_DOT_EXE}"

    echo
    echo "Testing if ${mingw_triplet} binutils${name_suffix} binaries start properly..."

    run_app "${test_bin_path}/${mingw_triplet}-ar" --version
    run_app "${test_bin_path}/${mingw_triplet}-as" --version
    run_app "${test_bin_path}/${mingw_triplet}-ld" --version
    run_app "${test_bin_path}/${mingw_triplet}-nm" --version
    run_app "${test_bin_path}/${mingw_triplet}-objcopy" --version
    run_app "${test_bin_path}/${mingw_triplet}-objdump" --version
    run_app "${test_bin_path}/${mingw_triplet}-ranlib" --version
    run_app "${test_bin_path}/${mingw_triplet}-size" --version
    run_app "${test_bin_path}/${mingw_triplet}-strings" --version
    run_app "${test_bin_path}/${mingw_triplet}-strip" --version

    echo
    echo "Testing if ${mingw_triplet} binutils${name_suffix} binaries display help..."

    run_app "${test_bin_path}/${mingw_triplet}-ar" --help
    run_app "${test_bin_path}/${mingw_triplet}-as" --help
    run_app "${test_bin_path}/${mingw_triplet}-ld" --help
    run_app "${test_bin_path}/${mingw_triplet}-nm" --help
    run_app "${test_bin_path}/${mingw_triplet}-objcopy" --help
    run_app "${test_bin_path}/${mingw_triplet}-objdump" --help
    run_app "${test_bin_path}/${mingw_triplet}-ranlib" --help
    run_app "${test_bin_path}/${mingw_triplet}-size" --help
    run_app "${test_bin_path}/${mingw_triplet}-strings" --help
    run_app "${test_bin_path}/${mingw_triplet}-strip" --help || true
  )
}

# -----------------------------------------------------------------------------
