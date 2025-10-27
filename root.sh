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

# ----------------------------------------------------------------------
#  If Python 3.10 already installed, skip everything & launch it
# ----------------------------------------------------------------------
if [ -e "$ROOTFS_DIR/.python_installed" ]; then
  echo "Python 3.10 environment detected — launching directly..."
  $ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf \
    /bin/bash -c ". /root/.bashrc && python3.10"
  exit 0
fi

# ----------------------------------------------------------------------
#  Normal installation (first run)
# ----------------------------------------------------------------------
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#               VISHAL ROOT AND PYTHON 3.10 OUTO INSTALL"
  echo "#"
  echo "#######################################################################################"

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
    rm -f $ROOTFS_DIR/usr/local/bin/proot
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

echo ""
echo ">>> Running apt update & sudo installation inside Ubuntu..."
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  /bin/bash -c "apt update -y && apt install sudo -y"

echo ""
echo ">>> Installing Python 3.10 (first time setup)..."
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  /bin/bash -c "
    apt install -y build-essential curl libssl-dev zlib1g-dev libncurses5-dev \
      libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev \
      xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev &&
    cd /tmp &&
    curl -O https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz &&
    tar -xf Python-3.10.13.tgz &&
    cd Python-3.10.13 &&
    ./configure --prefix=/root/python3.10 --enable-optimizations &&
    make -j$(nproc) &&
    make install &&
    echo 'export PATH=/root/python3.10/bin:\$PATH' >> /root/.bashrc &&
    . /root/.bashrc
  "

# Mark that Python setup completed
touch "$ROOTFS_DIR/.python_installed"

echo ""
echo ">>> Python 3.10 installation complete!"
echo ""

# Launch Python directly
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  /bin/bash -c ". /root/.bashrc && python3.10"
