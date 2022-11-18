# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Application specific definitions. Included with source.

# Used to display the application name in branding strings.
XBB_APPLICATION_NAME=${XBB_APPLICATION_NAME:-"MinGW-w64 GCC"}

# Used as part of file/folder paths.
XBB_APPLICATION_LOWER_CASE_NAME=${XBB_APPLICATION_LOWER_CASE_NAME:-"mingw-w64-gcc"}

XBB_APPLICATION_DISTRO_NAME=${XBB_APPLICATION_DISTRO_NAME:-"xPack"}
XBB_APPLICATION_DISTRO_LOWER_CASE_NAME=${XBB_APPLICATION_DISTRO_LOWER_CASE_NAME:-"xpack"}
XBB_APPLICATION_DISTRO_TOP_FOLDER=${XBB_APPLICATION_DISTRO_TOP_FOLDER:-"xPacks"}

XBB_APPLICATION_DESCRIPTION="${XBB_APPLICATION_DISTRO_NAME} ${XBB_APPLICATION_NAME}"

declare -a XBB_APPLICATION_DEPENDENCIES=( )
declare -a XBB_APPLICATION_COMMON_DEPENDENCIES=( binutils mingw gcc-mingw libiconv zlib gmp mpfr mpc isl xz zstd )

# -----------------------------------------------------------------------------

XBB_GITHUB_ORG="${XBB_GITHUB_ORG:-"xpack-dev-tools"}"
XBB_GITHUB_REPO="${XBB_GITHUB_REPO:-"${XBB_APPLICATION_LOWER_CASE_NAME}-xpack"}"
XBB_GITHUB_PRE_RELEASES="${XBB_GITHUB_PRE_RELEASES:-"pre-releases"}"

XBB_NPM_PACKAGE="${XBB_NPM_PACKAGE:-"@xpack-dev-tools/${XBB_APPLICATION_LOWER_CASE_NAME}@next"}"

# -----------------------------------------------------------------------------
