# HA Supervisor provides BUILD_FROM; we add a reasonable default for local builds
ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.19
FROM ${BUILD_FROM}

# System packages
RUN apk add --no-cache       python3 py3-pip py3-virtualenv       git       libusb hidapi hidapi-dev libusb-dev       build-base jq bash

# Virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Pull dali2mqtt from GitHub and install dependencies
RUN git clone https://github.com/dgomes/dali2mqtt.git /opt/dali2mqtt \ 
 && python -m pip install --no-cache-dir --upgrade pip \ 
 && python -m pip install --no-cache-dir -r /opt/dali2mqtt/requirements.txt

# Copy entrypoint
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
