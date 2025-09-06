#!/usr/bin/with-contenv bash
set -euo pipefail

# Venv in PATH + unbuffered Python-Logs
export PATH="/opt/venv/bin:$PATH"
export PYTHONUNBUFFERED=1
# libusb Debug (0–4). Für Diagnose 3 lassen, später auf 0 stellen.
export LIBUSB_DEBUG=3

# ---- Optionen aus /data/options.json laden
MQTT_HOST=$(jq -r '.mqtt.host' /data/options.json)
MQTT_PORT=$(jq -r '.mqtt.port' /data/options.json)
MQTT_USER=$(jq -r '.mqtt.username' /data/options.json)
MQTT_PASS=$(jq -r '.mqtt.password' /data/options.json)
BASE_TOPIC=$(jq -r '.mqtt.base_topic' /data/options.json)

DALI_DEVICE=$(jq -r '.dali.device' /data/options.json)
DALI_DRIVER=$(jq -r '.dali.driver' /data/options.json)
LOG_LEVEL=$(jq -r '.dali.log_level' /data/options.json)
HA_DISCOVERY_PREFIX=$(jq -r '.ha_discovery_prefix' /data/options.json)

# Für Preflight/Launcher auch als ENV exportieren
export MQTT_HOST MQTT_PORT MQTT_USER MQTT_PASS BASE_TOPIC
export DALI_DEVICE DALI_DRIVER LOG_LEVEL HA_DISCOVERY_PREFIX

echo "[dali2mqtt] Start: device=${DALI_DEVICE}, driver=${DALI_DRIVER}, topic=${BASE_TOPIC}"
echo "[dali2mqtt] MQTT target: host=${MQTT_HOST} port=${MQTT_PORT} user=${MQTT_USER}"
echo "[dali2mqtt] HA discovery prefix: ${HA_DISCOVERY_PREFIX}"

# ---- Auf HID-Device warten (max. ~15s)
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

# ---- USB-Permissions & HID-Unbind (für libusb Zugriff)
if [ -d /dev/bus/usb ]; then
  echo "[dali2mqtt] chmod /dev/bus/usb (try make rw)"
  chmod -R a+rw /dev/bus/usb 2>/dev/null || true
fi

unbind_hid_drivers() {
  local paths=(
    /sys/bus/usb/drivers/usbhid/unbind
    /sys/bus/usb/drivers/hid-generic/unbind
  )
  local did=0
  local any_writable=0
  for UNBIND in "${paths[@]}"; do
    if [ -w "$UNBIND" ]; then
      any_writable=1
      for dev in /sys/bus/usb/devices/*; do
        [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ] || continue
        vid=$(cat "$dev/idVendor" 2>/dev/null || echo "")
        pid=$(cat "$dev/idProduct" 2>/dev/null || echo "")
        if [ "$vid" = "17b5" ] && [ "$pid" = "0020" ]; then
          for intf in "$dev":1.*; do
            base=$(basename "$intf")
            if [ -d "$intf" ]; then
              echo "[dali2mqtt] unbind $(basename "$(dirname "$UNBIND")") for $base"
              echo "$base" > "$UNBIND" 2>/dev/null || true
              did=1
            fi
          done
        fi
      done
    fi
  done
  if [ "$any_writable" -eq 0 ]; then
    echo "[dali2mqtt] usbhid unbind not writable (likely AppArmor/caps)"
  elif [ "$did" -eq 0 ]; then
    echo "[dali2mqtt] no matching interfaces to unbind (already detached or different VID:PID)"
  fi
}
unbind_hid_drivers

# ---- Ins geklonte Repo wechseln
cd /opt/dali2mqtt

# ---- MQTT Preflight (verbindet kurz, loggt rc)
python - <<'PY'
import os, time, sys
import paho.mqtt.client as mqtt

host = os.environ.get("MQTT_HOST")
port = int(os.environ.get("MQTT_PORT", "1883"))
user = os.environ.get("MQTT_USER") or None
password = os.environ.get("MQTT_PASS") or None

print(f"[preflight] using host={host} port={port} user={user}")

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
    for _ in range(40):
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

# ---- Start dali2mqtt (inkl. HA Discovery)
exec python -m dali2mqtt.dali2mqtt \
  --mqtt-server "${MQTT_HOST}" \
  --mqtt-port "${MQTT_PORT}" \
  ${MQTT_USER:+--mqtt-username "${MQTT_USER}"} \
  ${MQTT_PASS:+--mqtt-password "${MQTT_PASS}"} \
  --mqtt-base-topic "${BASE_TOPIC}" \
  --ha-discovery-prefix "${HA_DISCOVERY_PREFIX}" \
  --dali-driver "${DALI_DRIVER}" \
  --device "${DALI_DEVICE}" \
  --log-level "${LOG_LEVEL}"
