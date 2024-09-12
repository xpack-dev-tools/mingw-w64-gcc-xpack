# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function tests_run_all()
{
  echo
  echo "[${FUNCNAME[0]} $@]"

  local test_bin_path="$1"

  xbb_reset_env

  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then
    xbb_set_target "mingw-w64-cross"
  else
    xbb_set_target "mingw-w64-native"
  fi

  # 32-bit first, since it is more probable to fail.
  XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" "x86_64-w64-mingw32" )
  for triplet in "${XBB_MINGW_TRIPLETS[@]}"
  do

    # Call the functions defined in the build code.
    binutils_test "${test_bin_path}" "${triplet}-"

    gcc_mingw_test "${test_bin_path}" "${triplet}"

  done
}

# -----------------------------------------------------------------------------
