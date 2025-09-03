#!/usr/bin/with-contenv bash
set -euo pipefail

# Venv in PATH + unbuffered Output (sofortige Logs)
export PATH="/opt/venv/bin:$PATH"
export PYTHONUNBUFFERED=1

# Optionen laden
MQTT_HOST=$(jq -r '.mqtt.host' /data/options.json)
MQTT_PORT=$(jq -r '.mqtt.port' /data/options.json)
MQTT_USER=$(jq -r '.mqtt.username' /data/options.json)
MQTT_PASS=$(jq -r '.mqtt.password' /data/options.json)
BASE_TOPIC=$(jq -r '.mqtt.base_topic' /data/options.json)

DALI_DEVICE=$(jq -r '.dali.device' /data/options.json)
DALI_DRIVER=$(jq -r '.dali.driver' /data/options.json)
LOG_LEVEL=$(jq -r '.dali.log_level' /data/options.json)

echo "[dali2mqtt] Start: device=${DALI_DEVICE}, driver=${DALI_DRIVER}, topic=${BASE_TOPIC}"

# Auf HID-Device warten (max ~15s)
for i in $(seq 1 30); do
  if [ -e "${DALI_DEVICE}" ]; then
    break
  fi
  echo "[dali2mqtt] waiting for ${DALI_DEVICE} ..."
  sleep 0.5
done
if [ ! -e "${DALI_DEVICE}" ]; then
  echo "[dali2mqtt] ERROR: ${DALI_DEVICE} not found"
  exit 1
fi

# Ins geklonte Repo wechseln, damit das Modul gefunden wird
cd /opt/dali2mqtt

# Python-/Modul-Check (einmalig ins Log)
python -V || true
python - <<'PY' || true
import sys, pkgutil
print("sys.path:", sys.path)
print("module present (dali2mqtt):", bool(pkgutil.find_loader("dali2mqtt")))
PY

# Modul starten (unbuffered -u via PYTHONUNBUFFERED=1)
exec python -m dali2mqtt.dali2mqtt \
  --mqtt-server "${MQTT_HOST}" \
  --mqtt-port "${MQTT_PORT}" \
  ${MQTT_USER:+--mqtt-username "${MQTT_USER}"} \
  ${MQTT_PASS:+--mqtt-password "${MQTT_PASS}"} \
  --mqtt-base-topic "${BASE_TOPIC}" \
  --dali-driver "${DALI_DRIVER}" \
  --device "${DALI_DEVICE}" \
  --log-level "${LOG_LEVEL}"
