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
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "##################################################################"
  echo "#"
  echo "#                »»—⎯⁠⁠⁠⁠‌꯭꯭νιѕнαL𝅃 » outo python 3.10 installer"
  echo "#"
  echo "##################################################################"

  read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf $ROOTFS_DIR/usr/local/bin/proot
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
    sleep 1
  done
  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.installed
fi

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

clear
display_gg

# Start proot environment and run setup if first time
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/bash -c '
if [ ! -f /root/.python_installed ]; then
  echo "Updating system..."
  apt update && apt install -y sudo

  echo "Installing Python 3.10 dependencies..."
  apt install -y build-essential curl libssl-dev zlib1g-dev libncurses5-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev

  echo "Downloading Python 3.10..."
  cd /tmp && curl -O https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
  tar -xf Python-3.10.13.tgz
  cd Python-3.10.13

  echo "Compiling Python 3.10..."
  ./configure --prefix=/root/python3.10 --enable-optimizations
  make -j$(nproc)
  make install

  echo "export PATH=/root/python3.10/bin:\$PATH" >> /root/.bashrc
  echo "PS1=\"\[\e[1;33m\]»»—⎯⁠⁠⁠⁠‌꯭꯭νιѕнαL@ubuntu ➤ \[\e[0m\]\"" >> /root/.bashrc
  . /root/.bashrc

  touch /root/.python_installed
  echo ""
  echo ">>> Python 3.10 installation complete!"
  echo ""
  exec bash
else
  echo ""
  echo ">>> Python 3.10 already installed. Opening environment..."
  echo ""
  . /root/.bashrc
  exec bash
fi
'
