# Der Supervisor füllt BUILD_FROM passend zur Architektur (aarch64/armv7/amd64)
ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.19
FROM ${BUILD_FROM}

# Systempakete
RUN apk add --no-cache \
      python3 py3-pip py3-virtualenv \
      libusb hidapi hidapi-dev libusb-dev \
      build-base jq bash

# Virtuelle Umgebung + dali2mqtt installieren (um PEP 668 zu umgehen)
RUN python3 -m venv /opt/venv \
 && . /opt/venv/bin/activate \
 && pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir dali2mqtt

# venv in PATH
ENV PATH="/opt/venv/bin:$PATH"

# Startskript
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
