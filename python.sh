#!/usr/bin/env bash
# Vishal's python.sh - Python 3.10.13 installer or launcher
# Author: Vishal
set -euo pipefail

PY_VERSION="3.10.13"
PREFIX="/usr/local/python${PY_VERSION}"
TARBALL="Python-${PY_VERSION}.tgz"
SRC_DIR="Python-${PY_VERSION}"
DOWNLOAD_URL="https://www.python.org/ftp/python/${PY_VERSION}/${TARBALL}"
PROFILE_D="/etc/profile.d/vishal_python.sh"

echo "----------------------------------------------"
echo " Vishal's Python ${PY_VERSION} Installer (python.sh)"
echo "----------------------------------------------"

# Check if python3.10 already installed
if command -v python3.10 >/dev/null 2>&1; then
  INSTALLED_VER="$(python3.10 -V 2>&1 | awk '{print $2}')"
  if [ "$INSTALLED_VER" = "${PY_VERSION}" ]; then
    echo "✅ Python ${PY_VERSION} already installed!"
    echo "Directly entering Python shell..."
    exec python3.10
  else
    echo "⚠️  Found python3.10 version ${INSTALLED_VER}, installing ${PY_VERSION}."
  fi
fi

# Must be root to install
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run as root: sudo bash python.sh"
  exit 1
fi

echo "[1/5] Installing build dependencies..."
apt update -y && apt install -y   build-essential curl wget libssl-dev zlib1g-dev libncurses5-dev libbz2-dev   libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev   libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev ca-certificates

echo "[2/5] Downloading Python ${PY_VERSION} source..."
cd /usr/src
if [ ! -f "$TARBALL" ]; then
  wget -q "$DOWNLOAD_URL" -O "$TARBALL"
else
  echo "Source tarball already exists."
fi

echo "[3/5] Extracting source..."
rm -rf "$SRC_DIR"
tar -xf "$TARBALL"
cd "$SRC_DIR"

echo "[4/5] Configuring and building..."
./configure --enable-optimizations --prefix="$PREFIX"
make -j"$(nproc)"
make altinstall

echo "[5/5] Finalizing installation..."
ln -sf "${PREFIX}/bin/python3.10" /usr/local/bin/python3.10
ln -sf "${PREFIX}/bin/pip3.10" /usr/local/bin/pip3.10

echo "export PATH="${PREFIX}/bin:\$PATH"" > "${PROFILE_D}"

echo ""
echo "✅ Python ${PY_VERSION} installation complete!"
echo "----------------------------------------------"
echo "Version: $(python3.10 --version)"
echo "Path: ${PREFIX}/bin/python3.10"
echo "----------------------------------------------"
echo "To start Python directly, run: python3.10"
