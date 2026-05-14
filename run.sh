#!/usr/bin/env bash
set -e

WALLET="prl1pe7zkszr3kmcqrnkuds0xkks5skumdekt4tkywrud8xx9zhutplkshujc6t"
WORKER="$(hostname -s)"
POOL_URL="pool.akoyapool.com:3333"

CONFIG_DIR="/etc/akoya-miner"
CONFIG_FILE="${CONFIG_DIR}/config.json"
MINER_DIR="/opt/akoya-miner"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "=================================================="
echo " Akoya Miner Auto Installer"
echo "=================================================="
echo "Wallet : ${WALLET}"
echo "Worker : ${WORKER}"
echo "Pool   : ${POOL_URL}"
echo "=================================================="

echo
echo "[1/7] Cleaning previous installation..."

$SUDO systemctl stop akoya-miner 2>/dev/null || true
$SUDO systemctl disable akoya-miner 2>/dev/null || true
$SUDO rm -rf "${MINER_DIR}" || true
$SUDO rm -rf "${CONFIG_DIR}" || true
$SUDO rm -f /etc/systemd/system/akoya-miner.service || true
$SUDO systemctl daemon-reload || true

echo
echo "[2/7] Installing required packages..."

$SUDO apt-get update -y

$SUDO apt-get install -y --no-install-recommends \
  curl \
  wget

echo
echo "[3/7] Checking CUDA runtime..."

if ! ldconfig -p 2>/dev/null | grep -q "libcudart.so.12"; then
  echo "CUDA runtime not found. Trying to install libcudart12..."

  $SUDO apt-get install -y --no-install-recommends libcudart12 || true
  $SUDO ldconfig || true
else
  echo "CUDA runtime already installed"
fi

echo
echo "[4/7] Creating config..."

$SUDO mkdir -p "${CONFIG_DIR}"

$SUDO tee "${CONFIG_FILE}" >/dev/null <<EOF
{
  "pool": {
    "url": "${POOL_URL}",
    "wallet": "${WALLET}",
    "worker": "${WORKER}"
  }
}
EOF

echo
echo "[5/7] Installing Akoya Miner..."

curl -sSL https://get.akoyapool.com/install.sh | $SUDO bash </dev/null || true

echo
echo "[6/7] Writing final config..."

$SUDO mkdir -p "${CONFIG_DIR}"

$SUDO tee "${CONFIG_FILE}" >/dev/null <<EOF
{
  "pool": {
    "url": "${POOL_URL}",
    "wallet": "${WALLET}",
    "worker": "${WORKER}"
  }
}
EOF

echo
echo "[7/7] Restarting miner..."

$SUDO systemctl daemon-reload || true
$SUDO systemctl enable akoya-miner || true
$SUDO systemctl restart akoya-miner || true

sleep 5

echo
echo "=================================================="
echo " AKOYA MINER STATUS"
echo "=================================================="

akoya-miner status || true

echo
echo "=================================================="
echo " AKOYA MINER LOG"
echo "=================================================="

akoya-miner log || true

echo
echo "=================================================="
echo " INSTALLATION COMPLETE"
echo "=================================================="