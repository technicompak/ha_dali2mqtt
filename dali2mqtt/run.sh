#!/usr/bin/with-contenv bash
set -euo pipefail
export PATH="/opt/venv/bin:$PATH"

MQTT_HOST=$(jq -r '.mqtt.host' /data/options.json)
MQTT_PORT=$(jq -r '.mqtt.port' /data/options.json)
MQTT_USER=$(jq -r '.mqtt.username' /data/options.json)
MQTT_PASS=$(jq -r '.mqtt.password' /data/options.json)
BASE_TOPIC=$(jq -r '.mqtt.base_topic' /data/options.json)

DALI_DEVICE=$(jq -r '.dali.device' /data/options.json)
DALI_DRIVER=$(jq -r '.dali.driver' /data/options.json)
LOG_LEVEL=$(jq -r '.dali.log_level' /data/options.json)

echo "[dali2mqtt] Start: device=${DALI_DEVICE}, driver=${DALI_DRIVER}, topic=${BASE_TOPIC}"

for i in $(seq 1 30); do
  [ -e "${DALI_DEVICE}" ] && break
  echo "[dali2mqtt] waiting for ${DALI_DEVICE} ..."
  sleep 0.5
done
if [ ! -e "${DALI_DEVICE}" ]; then
  echo "[dali2mqtt] ERROR: ${DALI_DEVICE} not found"
  exit 1
fi

# 👉 WICHTIG: erst ins Repo wechseln, dann Modul starten
cd /opt/dali2mqtt

exec python -m dali2mqtt.dali2mqtt \
  --mqtt-server "${MQTT_HOST}" \
  --mqtt-port "${MQTT_PORT}" \
  ${MQTT_USER:+--mqtt-username "${MQTT_USER}"} \
  ${MQTT_PASS:+--mqtt-password "${MQTT_PASS}"} \
  --mqtt-base-topic "${BASE_TOPIC}" \
  --dali-driver "${DALI_DRIVER}" \
  --device "${DALI_DEVICE}" \
  --log-level "${LOG_LEVEL}"
