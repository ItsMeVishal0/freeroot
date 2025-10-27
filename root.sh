#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
ARCH=$(uname -m)

# Detect architecture
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# Stylish colours
CYAN='\e[0;36m'
WHITE='\e[0;37m'
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
RESET_COLOR='\e[0m'

# ------------------------------
#  FIRST TIME SETUP + CONFIRMATION
# ------------------------------
if [ ! -e $ROOTFS_DIR/.installed ]; then
  clear
  echo -e "${YELLOW}##################################################################${RESET_COLOR}"
  echo -e "${YELLOW}#${RESET_COLOR}"
  echo -e "${YELLOW}#   »»—⎯⁠⁠⁠⁠‌꯭꯭νιѕнαL𝅃 ₊꯭♡゙꯭. » Auto Ubuntu + Python 3.10 Installer${RESET_COLOR}"
  echo -e "${YELLOW}#${RESET_COLOR}"
  echo -e "${YELLOW}##################################################################${RESET_COLOR}"
  echo ""
  read -p "💬 Do you want to install Ubuntu? (YES/no): " install_ubuntu
  case "$install_ubuntu" in
    YES|yes|Y|y)
      echo "🌍 Installing Ubuntu environment..."
      wget -O /tmp/rootfs.tar.gz "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
      mkdir -p $ROOTFS_DIR
      tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
      touch $ROOTFS_DIR/.installed
      ;;
    *)
      echo "❌ Installation aborted."
      exit 0
      ;;
  esac
fi

# Ensure proot binary exists
if [ ! -f $ROOTFS_DIR/usr/local/bin/proot ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  echo "⬇️  Downloading proot for $ARCH..."
  wget -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
  chmod +x $ROOTFS_DIR/usr/local/bin/proot
fi

# ------------------------------
#  MISSION COMPLETE MESSAGE
# ------------------------------
display_msg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
  echo -e ""
}

clear
display_msg

# ------------------------------
#  ENTER UBUNTU ENVIRONMENT
# ------------------------------
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit /bin/bash -c '
# ---------- Inside Ubuntu environment ----------

# Stylish permanent prompt
if ! grep -q "νιѕнαL@ubuntu" /root/.bashrc; then
  echo "export PS1=\"\[\e[1;33m\]»»—⎯νιѕнαL@ubuntu ➤ \[\e[0m\]\"" >> /root/.bashrc
fi
. /root/.bashrc

echo ""
echo "___________________________________________________"
echo "           -----> Mission Completed ! <----"
echo ""
echo "💡 Type: python.sh  —  to start Python 3.10 installation"
echo ""

# Create python.sh trigger installer
cat > /root/python.sh << "EOF"
#!/bin/bash
echo ""
echo "🚀 Starting Python 3.10 Installation..."
sleep 1

apt update && apt install -y sudo
apt install -y build-essential curl libssl-dev zlib1g-dev libncurses5-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
libxmlsec1-dev libffi-dev liblzma-dev

cd /tmp && curl -O https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
tar -xf Python-3.10.13.tgz
cd Python-3.10.13
./configure --prefix=/root/python3.10 --enable-optimizations
make -j$(nproc)
make install

echo "export PATH=/root/python3.10/bin:\$PATH" >> /root/.bashrc
touch /root/.python_installed

echo ""
echo "✅ Python 3.10 Installed Successfully!"
echo "💡 Restart terminal or run:  source ~/.bashrc"
EOF

chmod +x /root/python.sh

# If already installed, auto-load
if [ -f /root/.python_installed ]; then
  echo ""
  echo ">>> Python 3.10 already installed. Opening environment..."
  echo ""
  export PATH=/root/python3.10/bin:$PATH
  exec bash --rcfile /root/.bashrc
else
  exec bash --rcfile /root/.bashrc
fi
'
