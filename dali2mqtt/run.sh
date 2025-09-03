#!/usr/bin/with-contenv bash
set -euo pipefail

# Virtuelle Umgebung in PATH + unbuffered Logs
export PATH="/opt/venv/bin:$PATH"
export PYTHONUNBUFFERED=1

# Optionen aus /data/options.json laden
MQTT_HOST=$(jq -r '.mqtt.host' /data/options.json)
MQTT_PORT=$(jq -r '.mqtt.port' /data/options.json)
MQTT_USER=$(jq -r '.mqtt.username' /data/options.json)
MQTT_PASS=$(jq -r '.mqtt.password' /data/options.json)
BASE_TOPIC=$(jq -r '.mqtt.base_topic' /data/options.json)

DALI_DEVICE=$(jq -r '.dali.device' /data/options.json)
DALI_DRIVER=$(jq -r '.dali.driver' /data/options.json)
LOG_LEVEL=$(jq -r '.dali.log_level' /data/options.json)

echo "[dali2mqtt] Start: device=${DALI_DEVICE}, driver=${DALI_DRIVER}, topic=${BASE_TOPIC}"
echo "[dali2mqtt] MQTT target: host=${MQTT_HOST} port=${MQTT_PORT} user=${MQTT_USER}"

# Auf HID-Device warten (max. 15s)
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

# Ins geklonte Repo wechseln
cd /opt/dali2mqtt

# --- MQTT Preflight: Testverbindung ---
python - <<'PY'
import os, time, sys
import paho.mqtt.client as mqtt

host = os.environ.get("MQTT_HOST")
port = int(os.environ.get("MQTT_PORT", "1883"))
user = os.environ.get("MQTT_USER") or None
password = os.environ.get("MQTT_PASS") or None

cli = mqtt.Client(client_id="preflight-dali2mqtt", protocol=mqtt.MQTTv311)
if user:
    cli.username_pw_set(user, password=password)

ok = [False]
def on_connect(c,u,flags,rc):
    print(f"[preflight] MQTT connect rc={rc} (0=OK)")
    ok[0] = (rc == 0)
    c.disconnect()

cli.on_connect = on_connect
try:
    cli.connect(host, port, keepalive=10)
    cli.loop_start()
    for _ in range(20):
        if ok[0]: break
        time.sleep(0.25)
    cli.loop_stop()
except Exception as e:
    print(f"[preflight] MQTT connect EXCEPTION: {e}")

print(f"[preflight] result={ok[0]}")
if not ok[0]:
    sys.exit(12)
PY

if [ $? -ne 0 ]; then
  echo "[dali2mqtt] Abbruch: MQTT Preflight fehlgeschlagen (Host/User/Pass/Port prüfen)"
  exit 1
fi

# Modul starten (CLI-Flags wie im dgomes-Repo)
exec python -m dali2mqtt.dali2mqtt \
  --mqtt-host "${MQTT_HOST}" \
  --mqtt-port "${MQTT_PORT}" \
  ${MQTT_USER:+--mqtt-username "${MQTT_USER}"} \
  ${MQTT_PASS:+--mqtt-password "${MQTT_PASS}"} \
  --base-topic "${BASE_TOPIC}" \
  --dali-driver "${DALI_DRIVER}" \
  --device "${DALI_DEVICE}" \
  --log-level "${LOG_LEVEL}"
