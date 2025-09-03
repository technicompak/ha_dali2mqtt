ARG BUILD_FROM=ghcr.io/home-assistant/${BUILD_ARCH}-base:3.19
FROM $BUILD_FROM

RUN apk add --no-cache           python3 py3-pip           libusb hidapi hidapi-dev libusb-dev           build-base jq bash

RUN pip3 install --no-cache-dir --upgrade pip &&         pip3 install --no-cache-dir dali2mqtt

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
