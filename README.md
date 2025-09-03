# DALI2MQTT Add-on (Tridonic/Lunatone HID)

Repository structure for Home Assistant:
- `repository.json` in the repo root
- `dali2mqtt/` containing `config.yaml`, `Dockerfile`, `run.sh`

## Install
1) Push this repo to GitHub (public).
2) In Home Assistant → Settings → Add-ons → Add-on Store → ⋮ → Repositories → Add your repo URL.
3) Install `dali2mqtt`, configure MQTT + set device `/dev/hidraw0`, driver `tridonic`.

## Notes
- Requires Mosquitto (or any MQTT broker) running.
- DALI bus power required.
