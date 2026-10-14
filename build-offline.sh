#!/bin/bash
# Rebuild libmpv-2.dll for visiv from the source archives in this folder, without network access.
#
# Usage (Ubuntu 24.04, also WSL2):  ./build-offline.sh <work-dir>
#   1. Install the build tools listed in README.md (apt packages, meson, ninja, nasm, python3 with mako/jinja2).
#   2. Place the two toolchain tarballs (generally available, unmodified) into this folder:
#        gcc-14.4.0.tar.xz      https://ftp.gnu.org/gnu/gcc/gcc-14.4.0/gcc-14.4.0.tar.xz
#        binutils-2.45.1.tar.xz https://ftp.gnu.org/gnu/binutils/binutils-2.45.1.tar.xz
#      (SHA-256 values in README.md.)
#   3. Run this script. Result: <work-dir>/build/mpv-dev/libmpv-2.dll
#
# The recipe (mpv-winbuild-cmake-visiv) normally clones every package from git. Here each package comes from its
# archive in sources/: the script unpacks it, turns it into a local git repository with the same upstream commit
# message, and marks that commit as the upstream branch, so the recipe's own steps (git am for our patches,
# reset to upstream) work unchanged. The CMake module the recipe downloads at configure time
# (ExternalProject.cmake from CMake v3.31.6) is included in offline/.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mkdir -p "$1" && cd "$1" && pwd)"
SRC="$WORK/src_packages"
export GIT_AUTHOR_NAME=mpvbuild GIT_AUTHOR_EMAIL=mpvbuild@localhost GIT_COMMITTER_NAME=mpvbuild GIT_COMMITTER_EMAIL=mpvbuild@localhost
export GIT_AUTHOR_DATE="2026-09-30T00:00:00Z" GIT_COMMITTER_DATE="2026-09-30T00:00:00Z"
# Under WSL, PATH also lists the Windows folders (/mnt/c/…): build tools must not come from there, and lookups on the
# Windows drive are slow and can hang. Keep only Linux paths.
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '^/mnt/' | paste -sd: -)"
export PATH

for t in gcc-14.4.0.tar.xz binutils-2.45.1.tar.xz; do
  [ -f "$HERE/$t" ] || { echo "Missing $t (see step 2 above)"; exit 1; }
done
(cd "$HERE" && sha256sum -c SHA256SUMS --quiet)

rm -rf "$SRC" "$WORK/recipe" "$WORK/build"
mkdir -p "$SRC" "$WORK/recipe"
tar -xJf "$HERE"/mpv-winbuild-cmake-visiv-*.tar.xz -C "$WORK/recipe" --strip-components=1

# Packages from git: unpack, local repository, upstream = this commit
tail -n +2 "$HERE/manifest.tsv" | while IFS=$'\t' read -r pkg url commit file _rest; do
  [ "$commit" = "-" ] && continue
  tar -xJf "$HERE/$file" -C "$SRC"
  git -C "$SRC/$pkg" init -q -b visiv
  git -C "$SRC/$pkg" add -A
  git -C "$SRC/$pkg" commit -q --no-verify -m "$pkg $commit (from source archive)"
  git -C "$SRC/$pkg" remote add origin "$url"
  git -C "$SRC/$pkg" update-ref refs/remotes/origin/visiv HEAD
  git -C "$SRC/$pkg" branch -q --set-upstream-to=origin/visiv
  echo "$pkg ${commit:0:12}"
done
# Tarball packages: the recipe looks for them in src_packages/<name>/ and checks the hash
mkdir -p "$SRC/libiconv" "$SRC/gcc" "$SRC/gcc-binutils"
cp "$HERE/sources/libiconv-1.18.tar.gz" "$SRC/libiconv/"
cp "$HERE/gcc-14.4.0.tar.xz" "$SRC/gcc/"
cp "$HERE/binutils-2.45.1.tar.xz" "$SRC/gcc-binutils/"

# CMake modules the recipe would download at configure time (cmake/download_externalproject.cmake)
M="$WORK/build/cmake/Modules"
mkdir -p "$M/ExternalProject"
unzip -q "$WORK/recipe/cmake/CMake-v3.31.6-Modules-ExternalProject.zip" -d "$M/ExternalProject"
cp "$HERE/offline/ExternalProject.cmake" "$M/"
(cd "$WORK/build/cmake" && patch -s -p1 -i "$WORK/recipe/packages/cmake-0001-ExternalProject-changes.patch")
touch "$M/setup_done"

# Two inputs the C++/WinRT generator fetches while it is built (cppwinrt's CMakeLists.txt and the recipe's
# toolchain/cppwinrt.cmake): the winmd library at the commit cppwinrt pins (git bundle, same commit id) and the
# Windows metadata file Windows.winmd from microsoft/windows-rs. Served from sources/ via a git URL rewrite and a
# stand-in for wget that knows only this one address.
export GIT_CONFIG_GLOBAL="$WORK/gitconfig-offline"
git config --file "$GIT_CONFIG_GLOBAL" url."$HERE/sources/winmd-0f1eae3bfa63.bundle".insteadOf \
  https://github.com/microsoft/winmd.git
mkdir -p "$WORK/offline-bin"
cat > "$WORK/offline-bin/wget" <<EOF
#!/bin/bash
out=""; url=""
while [ \$# -gt 0 ]; do case "\$1" in -O) out=\$2; shift 2 ;; *) url=\$1; shift ;; esac; done
case "\$url" in
  */crates/libs/default/Windows.winmd) cp "$HERE/sources/windows-rs-1445e73254b1-Windows.winmd" "\$out" ;;
  *) echo "offline build: no download for \$url" >&2; exit 1 ;;
esac
EOF
chmod +x "$WORK/offline-bin/wget"
export PATH="$WORK/offline-bin:$PATH"

cd "$WORK"
cmake -DTARGET_ARCH=x86_64-w64-mingw32 -DGCC_ARCH=x86-64 -DSINGLE_SOURCE_LOCATION="$SRC" \
      -DRUSTUP_LOCATION="$WORK/install_rustup" -DENABLE_CCACHE=OFF -G Ninja -B build -S recipe
cd build
ninja gcc
ninja mpv
ls -l mpv-dev/libmpv-2.dll
