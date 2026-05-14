#!/usr/bin/env bash
set -e

WALLET="prl1pe7zkszr3kmcqrnkuds0xkks5skumdekt4tkywrud8xx9zhutplkshujc6t"
WORKER="$(hostname -s)"
POOL_URL="pool.akoyapool.com:3333"

CONFIG_DIR="/etc/akoya-miner"
CONFIG_FILE="${CONFIG_DIR}/config.json"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "=================================================="
echo " Akoya Miner Installer"
echo "=================================================="
echo "Wallet : ${WALLET}"
echo "Worker : ${WORKER}"
echo "Pool   : ${POOL_URL}"
echo "=================================================="

echo
echo "[1/4] Creating config.json..."

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
echo "[2/4] Running official installer..."

curl -sSL https://get.akoyapool.com/install.sh | $SUDO bash

echo
echo "[3/4] Verifying config.json..."

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
echo "[4/4] Checking miner status..."

akoya-miner status || true

echo
echo "=================================================="
echo " INSTALLATION COMPLETE"
echo "=================================================="