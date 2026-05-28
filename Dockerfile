FROM debian:trixie

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core system build dependencies
RUN apt-get update && apt-get install -y \
    build-essential git wget flex bison gperf python3 python3-pip python3-venv \
    cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0 pkg-config \
    sudo curl locales && \
    rm -rf /var/lib/apt/lists/*

# Set up system locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Establish directory structures
WORKDIR /builds

# Clone and install ESP-IDF v5.5.1
RUN mkdir -p /opt/esp && cd /opt/esp && \
    git clone -b v5.5.1 --recursive https://github.com/espressif/esp-idf.git && \
    cd esp-idf && \
    ./install.sh

# Copy our automation compilation script into the container image
COPY build.sh /builds/build.sh
RUN chmod +x /builds/build.sh

ENTRYPOINT ["/builds/build.sh"]

