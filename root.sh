#!/bin/sh
ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                     VISHAL FREEROOT AND PYTHON 3.10 INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2024, RecodeStudios.Cloud"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  printf "Do you want to install Ubuntu? (YES/no): "
  read install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS]|[yY])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz       "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}" || true

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf "$ROOTFS_DIR/usr/local/bin/proot"
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}" || true

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    chmod 755 $ROOTFS_DIR/usr/local/bin/proot || true
    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot || true
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin || true
  touch $ROOTFS_DIR/.installed
fi

CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET_COLOR='\033[0m'

display_gg() {
  printf "${WHITE}___________________________________________________${RESET_COLOR}\n"
  printf "\n"
  printf "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}\n"
}

clear 2>/dev/null || true
display_gg

# Ensure running as root for apt and installs
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root: sudo sh root.sh"
  exit 1
fi

echo "[0/5] Running apt update and ensuring sudo/curl/wget/ca-certificates are installed..."
if command -v apt >/dev/null 2>&1; then
  apt update -y || echo "apt update failed or offline"
  apt install -y sudo curl wget ca-certificates || echo "apt install attempted"
else
  echo "apt not found on this system; skipping apt steps."
fi

# Embedded python installer will be created as python.sh next to this script and also copied to /usr/local/bin
LOCAL_PY_SH="$ROOTFS_DIR/python.sh"
GLOBAL_PY_SH="/usr/local/bin/python.sh"
PYTHON_VERSION="3.10.13"

cat > "$LOCAL_PY_SH" <<'PYSH'
#!/bin/sh
# python.sh - Python 3.10.13 installer/launcher (embedded)
set -eu
PY_VERSION="3.10.13"
PREFIX="/usr/local/python${PY_VERSION}"
TARBALL="Python-${PY_VERSION}.tgz"
SRC_DIR="Python-${PY_VERSION}"
DOWNLOAD_URL="https://www.python.org/ftp/python/${PY_VERSION}/${TARBALL}"
PROFILE_D="/etc/profile.d/freeroot_python.sh"

printf "----------------------------------------------
"
printf " Python %s Installer (python.sh)
" "$PY_VERSION"
printf "----------------------------------------------
"

if command -v python3.10 >/dev/null 2>&1; then
  INSTALLED_VER=$(python3.10 -V 2>/dev/null | awk '{print $2}' || echo "")
  if [ "$INSTALLED_VER" = "$PY_VERSION" ]; then
    printf "✅ Python %s already installed!
" "$PY_VERSION"
    printf "Launching python3.10...
"
    exec python3.10
  else
    printf "Found python3.10 version %s, requested %s. Proceeding to install requested version.
" "$INSTALLED_VER" "$PY_VERSION"
  fi
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Please run as root: sudo sh python.sh"
  exit 1
fi

printf "[1/5] Installing build dependencies...
"
if command -v apt >/dev/null 2>&1; then
  apt update -y || echo "apt update failed or offline"
  apt install -y --no-install-recommends build-essential curl wget libssl-dev zlib1g-dev libncurses5-dev libbz2-dev     libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev ca-certificates
else
  echo "apt not available on this distro. Cannot auto-install build deps."
  exit 2
fi

printf "[2/5] Downloading Python %s source...
" "$PY_VERSION"
cd /usr/src || exit 1
if [ ! -f "$TARBALL" ]; then
  wget -q "$DOWNLOAD_URL" -O "$TARBALL" || { echo "Download failed"; exit 2; }
else
  echo "Source tarball already present."
fi

printf "[3/5] Extracting source...
"
rm -rf "$SRC_DIR"
tar -xf "$TARBALL"
cd "$SRC_DIR" || exit 1

printf "[4/5] Configuring build...
"
./configure --enable-optimizations --prefix="$PREFIX"

printf "[5/5] Compiling and installing (may take several minutes)...
"
make -j"$(nproc)"
make altinstall

ln -sf "${PREFIX}/bin/python3.10" /usr/local/bin/python3.10
if [ -f "${PREFIX}/bin/pip3.10" ]; then
  ln -sf "${PREFIX}/bin/pip3.10" /usr/local/bin/pip3.10
fi

if [ ! -f "$PROFILE_D" ]; then
  echo "export PATH="${PREFIX}/bin:\$PATH"" > "$PROFILE_D"
  chmod 644 "$PROFILE_D"
fi

if command -v ldconfig >/dev/null 2>&1; then
  ldconfig || true
fi

printf "\n✅ Python %s installation complete!\n" "$PY_VERSION"
printf "Location: %s\n" "$PREFIX"
printf "Version : "
/usr/local/bin/python3.10 --version 2>/dev/null || python3.10 --version 2>/dev/null || echo "unknown"
printf "\nLaunching python3.10...\n"
exec /usr/local/bin/python3.10
PYSH

chmod +x "$LOCAL_PY_SH" || true

# copy to global path for convenience
cp "$LOCAL_PY_SH" "$GLOBAL_PY_SH" 2>/dev/null || true
chmod +x "$GLOBAL_PY_SH" 2>/dev/null || true

# If requested version already installed, launch; else run embedded installer
if command -v python3.10 >/dev/null 2>&1; then
  INSTALLED_VER=$(python3.10 -V 2>/dev/null | awk '{print $2}' || echo "")
  if [ "$INSTALLED_VER" = "$PYTHON_VERSION" ]; then
    echo "✅ Python $PYTHON_VERSION already installed. Launching python3.10..."
    exec python3.10
  fi
fi

echo "[2/5] Running embedded python.sh installer..."
exec sh "$GLOBAL_PY_SH"
