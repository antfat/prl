#!/usr/bin/env bash
set -e

WALLET="prl1pe7zkszr3kmcqrnkuds0xkks5skumdekt4tkywrud8xx9zhutplkshujc6t"
WORKER="$(hostname -s)"
POOL_URL="pool.akoyapool.com:3333"

CONFIG_DIR="/etc/akoya-miner"
CONFIG_FILE="${CONFIG_DIR}/config.json"
MINER_DIR="/opt/akoya-miner"
SERVICE_FILE="/etc/systemd/system/akoya-miner.service"

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
echo "[1/8] Cleaning previous installation..."

$SUDO systemctl stop akoya-miner 2>/dev/null || true
$SUDO systemctl disable akoya-miner 2>/dev/null || true
$SUDO rm -rf "${MINER_DIR}" || true
$SUDO rm -rf "${CONFIG_DIR}" || true
$SUDO rm -f "${SERVICE_FILE}" || true
$SUDO systemctl daemon-reload || true

echo
echo "[2/8] Installing required packages..."

$SUDO apt-get update -y

$SUDO apt-get install -y --no-install-recommends \
  curl \
  wget

echo
echo "[3/8] Checking CUDA runtime..."

if ! ldconfig -p 2>/dev/null | grep -q "libcudart.so.12"; then
  echo "CUDA runtime not found. Trying to install libcudart12..."

  $SUDO apt-get install -y --no-install-recommends libcudart12 || true
  $SUDO ldconfig || true
else
  echo "CUDA runtime already installed"
fi

echo
echo "[4/8] Creating config before install..."

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
echo "[5/8] Installing Akoya Miner..."

curl -sSL https://get.akoyapool.com/install.sh | $SUDO bash </dev/null || true

echo
echo "[6/8] Writing final config..."

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
echo "[7/8] Patching systemd service for HiveOS..."

$SUDO tee "${SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=Akoya Miner
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${MINER_DIR}
ExecStart=${MINER_DIR}/akoya-miner
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload || true

echo
echo "[8/8] Starting miner..."

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
