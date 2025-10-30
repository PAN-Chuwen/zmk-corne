# Dockerfile for ZMK Firmware Build Environment
#
# This Dockerfile documents the official ZMK build image we use.
# We DO NOT build this image ourselves - we use the pre-built official image.
#
# Source: https://github.com/zmkfirmware/zmk-docker
# DockerHub: https://hub.docker.com/r/zmkfirmware/zmk-build-arm
#
# Why we use the official image:
# - Maintained by ZMK team (always up-to-date)
# - Pre-built and cached (faster downloads)
# - Battle-tested by thousands of users
# - Complex dependencies (Zephyr SDK, ARM toolchain, ~3GB)
#
# Image versions:
# - stable: Tracks Zephyr 4.1.0 + SDK 0.16.9 (recommended)
# - Latest: Rolling updates (may break builds)
#
# To reproduce the official image from source:
# git clone https://github.com/zmkfirmware/zmk-docker.git
# cd zmk-docker
# docker build --build-arg ZEPHYR_VERSION=4.1.0 \
#              --build-arg ARCHITECTURE=arm \
#              -t zmk-build-arm:local \
#              -f Dockerfile .

FROM zmkfirmware/zmk-build-arm:stable

# Document versions for reproducibility
LABEL maintainer="ZMK Firmware Team"
LABEL zephyr.version="4.1.0"
LABEL zephyr.sdk.version="0.16.9"
LABEL architecture="arm"
LABEL description="ZMK firmware build environment for ARM-based keyboards (nice!nano v2)"

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]

# Usage:
# docker run --rm -v $(pwd):/workspace zmkfirmware/zmk-build-arm:stable bash -c "west build ..."
