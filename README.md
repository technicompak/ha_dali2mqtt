# DALI2MQTT Home Assistant Add-on (Wrapper)

This is a Home Assistant Add-on wrapper around [dgomes/dali2mqtt].
It clones the upstream repo into the container and runs `python -m dali2mqtt.dali2mqtt`.
Use it to control DALI via a Tridonic/Lunatone HID USB interface (/dev/hidraw0).

## Repository layout
- repository.json
- dali2mqtt/
  - config.yaml
  - Dockerfile
  - run.sh

## Install
1. Push this repository to your public GitHub account.
2. Home Assistant → Settings → Add-ons → Add-on Store → ⋮ → Repositories → Add your repo URL.
3. Install **dali2mqtt (Tridonic/Lunatone HID)**, configure MQTT and set device `/dev/hidraw0`, driver `tridonic`.
