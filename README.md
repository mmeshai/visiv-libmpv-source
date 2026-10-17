# visiv – source code of libmpv-2.dll

visiv is an IPTV player for Windows by nnexd GmbH, Halden 28, 8604 Volketswil, Switzerland. For playback it uses
the library **libmpv** (mpv with FFmpeg and further components), shipped as the separate file `libmpv-2.dll` under
the **GNU Lesser General Public License, version 3 or later**.

This repository provides the **complete corresponding source code** of that file: every component built into it at
the exact version, our changes, the build recipe and a script that rebuilds the DLL without network access. visiv's
own code is not part of libmpv and is not published here.

You may replace `libmpv-2.dll` with your own modified, interface-compatible version. In the Microsoft Store version
Windows protects the program folder: copy the folder to another location, replace `libmpv-2.dll` there and start
`visiv.exe` from the copy.

This offer is valid for at least three years after the last distribution of the visiv version concerned.
Questions: support@visiv.tv

## Which download belongs to which visiv version

| visiv version | libmpv-2.dll | Download (release) |
|---|---|---|
| 1.0.0 | mpv 0.41.0, FFmpeg 8.1.3, OpenSSL 3.5.9, built 2026-10-17 | [`libmpv-20261017-v0.41.0`](../../releases/tag/libmpv-20261017-v0.41.0) |

The DLL inside visiv: SHA-256 `6e071dc45b7cc6933ba64a647928825f7e18724bae83fe876275c05440898175`, 62 034 446 bytes.

The release [`libmpv-20260930-v0.41.0`](../../releases/tag/libmpv-20260930-v0.41.0) contains the same sources and
the same recipe; that DLL was built in a different folder and is not part of any published visiv version. The build of
2026-10-17 was made in `/opt/visiv/mpvbuild` – use the same folder with `build-offline.sh` and the paths inside the
rebuilt DLL match as well.
visiv shows the versions under Settings › Help › About visiv; the licence texts of all components are under
Settings › Help › Licences.

## Contents of a release

One archive `visiv-libmpv-source-<release>.tar` (the files inside are already compressed). Unpacked:

| Path | Content |
|---|---|
| `sources/<package>-<commit>.tar.xz` | 37 components at the exact upstream commit (mpv, FFmpeg, libplacebo, libass, FreeType, HarfBuzz, FriBidi, OpenSSL, dav1d, … and the mingw-w64 runtime). Only the parts the recipe checks out (some packages use a sparse checkout); empty git submodule references are not included because the build does not use them. |
| `sources/libiconv-1.18.tar.gz` | GNU libiconv, original tarball from ftp.gnu.org |
| `sources/winmd-0f1eae3bfa63.bundle` | git bundle of microsoft/winmd at the commit C++/WinRT pins (fetched while building the C++/WinRT generator) |
| `sources/windows-rs-1445e73254b1-Windows.winmd` | Windows metadata from microsoft/windows-rs (input of the C++/WinRT headers), with its MIT/Apache licences |
| `mpv-winbuild-cmake-visiv-<commit>.tar.xz` | the build recipe: shinchiro/mpv-winbuild-cmake at `05a60b3` plus our changes; all source patches are in its `packages/` folder |
| `recipe-changes/` | our 7 changes to the recipe as a patch series (licence configuration without GPL parts, FFmpeg/mpv backports, OpenSSL 3.5 LTS) |
| `offline/` | `ExternalProject.cmake` from CMake v3.31.6 (the recipe downloads it at configure time) and CMake's licence |
| `manifest.tsv` | package, repository URL, upstream commit, archive, file counts, sparse-checkout patterns |
| `build-offline.sh` | rebuilds `libmpv-2.dll` from these files without network access |
| `SHA256SUMS` | checksums of all files above |

## Rebuilding

Tested on Ubuntu 24.04 (WSL2) on 2026-10-17 with network access disabled (`unshare -rn`), from the release
`libmpv-20261017-v0.41.0`: the rebuilt DLL has the same exports, the same imports and the same embedded FFmpeg and mpv
configuration as the shipped one (apart from the build folder).

1. Build tools (the list from the recipe's README, section «Ubuntu Linux / WSL»):

       sudo apt-get install build-essential checkinstall bison flex gettext git mercurial subversion ninja-build \
         gyp cmake yasm nasm automake pkgconf libtool libtool-bin gcc-multilib g++-multilib clang lld libc++1 \
         libc++abi1 libgmp-dev libmpfr-dev libmpc-dev libgcrypt-dev gperf ragel texinfo autopoint re2c asciidoc \
         python3-pip docbook2x unzip p7zip-full curl mimalloc ccache
       pip3 install rst2pdf meson mako jsonschema

   (versions used: CMake 3.28.3, Meson 1.12.1, Ninja 1.11.1, NASM 2.16.01, host GCC 13.3.0)

2. The cross compiler is built from the unmodified GNU releases; put the two tarballs next to `build-offline.sh`:

   | File | SHA-256 |
   |---|---|
   | [gcc-14.4.0.tar.xz](https://ftp.gnu.org/gnu/gcc/gcc-14.4.0/gcc-14.4.0.tar.xz) | `752b6f567beac83159c77a7680b1316bdd784738bff9a9d070112c09da90f6d9` |
   | [binutils-2.45.1.tar.xz](https://ftp.gnu.org/gnu/binutils/binutils-2.45.1.tar.xz) | `5fe101e6fe9d18fdec95962d81ed670fdee5f37e3f48f0bef87bddf862513aa5` |

3. Run `./build-offline.sh /opt/visiv/mpvbuild` (any empty folder works; this is the one used for the DLL in visiv,
   about 30–60 minutes). Result: `/opt/visiv/mpvbuild/build/mpv-dev/libmpv-2.dll`.

The rebuilt DLL is not bit-identical to the shipped one (build paths, time stamps, and the version strings contain
the commit ids of the local git repositories, e.g. `mpv v0.41.0-dev-g…` instead of `mpv v0.41.0-1-g…`), but it is
built from the same sources with the same configuration.

## Licences

The components keep their own licences (LGPL-2.1+/LGPL-3.0+ for mpv, FFmpeg, libplacebo, FriBidi, libiconv,
uchardet; MIT, BSD, ISC, zlib, Apache-2.0 and others for the rest – see each archive and the licence page in visiv).
The combination `libmpv-2.dll` is distributed under the GNU LGPL version 3 or later. No GPL-only or non-free
component is included.

---

**Deutsch:** Dieses Repository enthält den vollständigen Quellcode der Bibliothek `libmpv-2.dll` (mpv, FFmpeg und
weitere Bausteine, LGPL-3.0), die visiv von der nnexd GmbH mitliefert – samt Änderungen, Bau-Rezept und einem Skript,
das die DLL ohne Internet nachbaut. Das Angebot gilt mindestens drei Jahre ab der letzten Auslieferung der jeweiligen
visiv-Version. Fragen: support@visiv.tv
