# Nutze direkt das arch-spezifische HA-Base-Image
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.19

# System-Pakete
RUN apk add --no-cache \
      python3 py3-pip py3-virtualenv \
      libusb hidapi hidapi-dev libusb-dev \
      build-base jq bash

# Virtuelle Umgebung anlegen und dali2mqtt installieren
RUN python3 -m venv /opt/venv \
 && . /opt/venv/bin/activate \
 && pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir dali2mqtt

# Venv in PATH aufnehmen
ENV PATH="/opt/venv/bin:$PATH"

# Startskript
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
