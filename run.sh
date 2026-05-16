#!/usr/bin/env bash
set -euo pipefail

WORKER_PREFIX="v"
WORKER_NUM="${1:-}"
WORKER_NAME="${WORKER_PREFIX}${WORKER_NUM}"

BASE_DIR="$HOME/mine"

GPU_DIR="$BASE_DIR/launcher"
CPU_DIR="$BASE_DIR/cpu"

GPU_MINER_URL="https://pearlhash.xyz/downloads/pearl-miner"
GPU_MINER_FILE="launcher-miner"
GPU_MINER_RUN="launch"

CPU_MINER_URL="https://github.com/doktor83/SRBMiner-Multi/releases/download/3.2.8/SRBMiner-Multi-3-2-8-Linux.tar.gz"
CPU_ARCHIVE="SRBMiner-Multi-3-2-8-Linux.tar.gz"
CPU_EXTRACT_DIR="SRBMiner-Multi-3-2-8"

LAUNCHER_POOL="84.32.220.219:9000"
LAUNCHER_WALLET="prl1p9gx0lf4mar6f6v8zswctpshs30plhuc4yvrnkdcegd2eatn2g28s3tz6vz"

XMR_POOL="xmr.kryptex.network:7029"
XMR_WALLET="83BiNKP5QDMSKVSUNMYMJHGALNrMtrUX61virMZ3Uz8ti63cDSydKBkMf7R9bVQB1S4pJqYCfgj9nX5hXeCjofWT5EpCxyk"

GPU_LOG="$GPU_DIR/gpu-miner.log"
CPU_LOG="$CPU_DIR/cpu-miner.log"
WATCHDOG_LOG="$BASE_DIR/watchdog.log"

CHECK_INTERVAL=30

if [ -z "$WORKER_NUM" ]; then
  echo "❌ Не передан номер воркера"
  echo "Пример:"
  echo "  ./start-mining.sh 001"
  exit 1
fi

echo "🚀 Worker: $WORKER_NAME"

mkdir -p "$GPU_DIR"
mkdir -p "$CPU_DIR"

cd "$GPU_DIR"

if [ ! -f "$GPU_MINER_RUN" ]; then
  echo "⬇️ Скачиваем GPU майнер LAUNCHER..."
  wget -O "$GPU_MINER_FILE" "$GPU_MINER_URL"

  mv "$GPU_MINER_FILE" "$GPU_MINER_RUN"

  chmod +x "$GPU_MINER_RUN"
fi

cd "$CPU_DIR"

if [ ! -d "$CPU_EXTRACT_DIR" ]; then
  echo "⬇️ Скачиваем CPU майнер..."
  wget -O "$CPU_ARCHIVE" "$CPU_MINER_URL"

  tar -xzvf "$CPU_ARCHIVE"
fi

chmod +x "$CPU_DIR/$CPU_EXTRACT_DIR/SRBMiner-MULTI"

echo "🛑 Останавливаем старые процессы..."

pkill -f "$GPU_MINER_RUN" || true
pkill -f "SRBMiner-MULTI" || true

sleep 3

start_gpu_miner() {
  echo "$(date '+%F %T') ▶️ START GPU MINER LAUNCHER" | tee -a "$WATCHDOG_LOG"

  cd "$GPU_DIR"

  nohup ./"$GPU_MINER_RUN" \
    --host "$LAUNCHER_POOL" \
    --user "$LAUNCHER_WALLET" \
    --worker "$WORKER_NAME" \
    >> "$GPU_LOG" 2>&1 &

  GPU_PID=$!

  echo "$(date '+%F %T') ✅ GPU PID: $GPU_PID" | tee -a "$WATCHDOG_LOG"
}

start_cpu_miner() {
  echo "$(date '+%F %T') ▶️ START CPU MINER RANDOMX" | tee -a "$WATCHDOG_LOG"

  cd "$CPU_DIR/$CPU_EXTRACT_DIR"

  nohup ./SRBMiner-MULTI \
    --algorithm randomx \
    --pool "$XMR_POOL" \
    --wallet "$XMR_WALLET.$WORKER_NAME" \
    --password x \
    --disable-gpu \
    >> "$CPU_LOG" 2>&1 &

  CPU_PID=$!

  echo "$(date '+%F %T') ✅ CPU PID: $CPU_PID" | tee -a "$WATCHDOG_LOG"
}

start_gpu_miner
start_cpu_miner

echo ""
echo "======================================"
echo "✅ Watchdog started"
echo "Worker: $WORKER_NAME"
echo "======================================"
echo ""

while true; do

  if ! pgrep -f "$GPU_MINER_RUN" > /dev/null; then
    echo "$(date '+%F %T') ❌ GPU miner crashed" | tee -a "$WATCHDOG_LOG"

    sleep 5

    start_gpu_miner
  fi

  if ! pgrep -f "SRBMiner-MULTI" > /dev/null; then
    echo "$(date '+%F %T') ❌ CPU miner crashed" | tee -a "$WATCHDOG_LOG"

    sleep 5

    start_cpu_miner
  fi

  sleep "$CHECK_INTERVAL"

done