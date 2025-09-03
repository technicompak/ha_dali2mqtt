#!/usr/bin/with-contenv bash
set -euo pipefail

# (Optional) Sicherstellen, dass die venv im PATH ist
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

# explizit das venv-Binary aufrufen (liegt auch im PATH)
exec dali2mqtt \
  --mqtt-host "${MQTT_HOST}" \
  --mqtt-port "${MQTT_PORT}" \
  ${MQTT_USER:+--mqtt-username "${MQTT_USER}"} \
  ${MQTT_PASS:+--mqtt-password "${MQTT_PASS}"} \
  --base-topic "${BASE_TOPIC}" \
  --dali-driver "${DALI_DRIVER}" \
  --device "${DALI_DEVICE}" \
  --log-level "${LOG_LEVEL}"
