# Change & release log

Entries in this file are in reverse chronological order.

## 2023-01-03

* v12.2.0-1 released
* fcccab9 re-generate workflows
* a6b0323 package.json: bump deps
* e2061ee package.json: loglevel trace
* 66e41b7 .vscode/settings.json: ignoreWords
* 9cf4ae5 re-generate workflows
* 8b0dd49 CHANGELOG update
* 43873bb versioning.sh: reorder XPM_*_VERSION definitions
* 7a8143f versioning.sh: reorder *_installed_bin
* b122d7d package.json: bump deps

## 2023-01-02

* 07a992f package.json: reformat

## 2023-01-01

* c10ca84 package.json: pass xpm version & loglevel
* 577a1ef README update

## 2022-12-28

* 3bee50b re-generate workflows
* 5493065 README update
* 5483b46 CHANGELOG update
* 5a31f98 package.json: bump deps
* 9e5e951 regexp '[.].*'

## 2022-12-27

* c90f92b versioning.sh: GCC patch no longer reuse cross
* 4727379 README update
* 00adf8b versioning.sh: binutils 2.39
* 979750d re-generate from templates

## 2022-12-26

* 84cae7a remove empty dependencies
* c7061a9 README updates

## 2022-12-25

* f2a66e0 README update
* a150fe9 versioning.sh: remove explicit xbb_set_executables_install_path

## 2022-12-24

* b57ef95 README update
* d851eda versioning.sh: explicit set_executables
* 87178b9 versioning.sh: rename .git.patch
* beb5a92 README update
* d3d9465 package-lock.json: update
* 7c25c91 re-generate workflows
* bf448fc READMEs update
* 62d692b package.json: bump deps
* bd7a711 rename functions

## 2022-12-20

* d4c6058 package.json: bump deps
* 040a2b2 test-prime.yml: temporarily keep only linux & windows

## 2022-12-19

* e6344db README update
* 6b356ca package.json: bump deps

## 2022-12-17

* dd9f97d reorder triplets, 32-bit first

## 2022-12-16

* e3c71e3 package.json: test-pre-release --cache

## 2022-12-15

* c4f2ab0 tests/run.sh: update
* 99c7133 re-generate workflows
* b1d3911 tests: update.sh
* a417f57 package.json: bump deps
* 753c327 README updates

## 2022-12-12

* 7048f41 package.json: add caffeinate builds for macOS

## 2022-12-02

* 055cc39 versioning.sh: xbb_reset_env
* b9176cd versioning.sh: remove build_mingw_*, moved to helper
* 8960c8c README updates
* 685d8ad move renamed XBB_SHOW_DLLS to application.sh

## 2022-12-01

* 63eed89 README updates
* affdd3d package.json: add git-pull-helper

## 2022-11-26

* 1fe2b58 application.sh: add compiler-tests to deps

## 2022-11-24

* 5efe8b6 README update
* d5b9b78 README update
* 0ca29c3 versioning.sh: cosmetics

## 2022-11-23

* df4a794 versioning.sh: call xbb_set_extra_target_env

## 2022-11-18

* fd4f906 application.sh: update deps to binutils
* 83ab789 versioning.sh: use --triplet
* 1da7ece versioning.sh: rename build_mingw_gcc_all_triplets
* 9644940 versioning.sh: rename build_mingw_gcc_dependencies
* 20430db .vscode/settings.json: watcherExclude
* 7c12cf8 .vscode/settings.json: watcherExclude

## 2022-11-14

* 3d5b9be package.json: bump deps

## 2022-11-12

* 13bcb37 package.json: bump deps
* c387c3d package.json: bump deps
* cf1f7bc tests/run.sh: fix syntax
* af685c0 tests/run.sh: update
* 3ed1aec README update
* 38e93c6 Revert "package.json: try -x to diagnose final failure"
* 1c4c6f8 Revert "versioning.sh: 64-bit only for tests"
* be35caf package.json: bump deps
* 272caad versioning.sh: 64-bit only for tests
* e0cbfa0 package.json: try -x to diagnose final failure
* 4139468 package.json: bump deps

## 2022-11-11

* 6d3590e package.json: bump deps
* 8da4f32 move dependencies to helper
* 18205d2 package.json: bump deps
* 0c08052 package.json: bump deps
* 76a0fb7 package.json: bump deps
* 82fbaf9 versioning.sh: rework common code
* c72271d dependencies: rename build_mingw_ (remove 2)
* f25f102 gcc-mingw.sh: fix win64 in test_expect_wine
* a70693a gcc-mingw.sh: show libraries in tests

## 2022-11-10

* e7bc972 versioning.sh: rename xbb_set_executables_install_path
* aacf8ea rename xbb_activate_dependencies_dev
* 36956eb rename XBB_EXECUTABLES_INSTALL_FOLDER_PATH
* 8077775 versioning.sh: rework bootstrap
* 4654c56 gcc-mingw.sh: fix too many sections
* 078ef22 package.json: add gcc dependency

## 2022-11-09

* prepare v12.2.0-1
* update for XBB v5.0.0

## 2022-09-25

* v11.3.0-1.3 published on npmjs.com
* v11.3.0-1.2 published on npmjs.com (bad bin paths)
* v11.3.0-1.1 published on npmjs.com (bad bin paths)
* v11.3.0-1 released

## 2022-09-17

* copy/paste from gcc-xpack
