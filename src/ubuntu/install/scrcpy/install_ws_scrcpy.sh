#!/usr/bin/env bash
set -ex

ARCH=$(arch  | sed 's/x86_64/amd64/g')

apt-get update
apt-get install -y  android-tools-adb android-tools-fastboot \
                    ffmpeg libsdl2-2.0-0 adb wget \
                    gcc git pkg-config meson ninja-build libsdl2-dev \
                    libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                    libswresample-dev libusb-1.0-0 libusb-1.0-0-dev jq gettext-base \
                    xfce4-clipman xfce4-clipman-plugin unzip coreutils vlc

mkdir -p /opt/
cd /opt/

# https://github.com/regulad/doppelganger-front/blob/7703ec1e640ac09ab81a53ecbbe6a4d0f00a7c59/scripts/download-scrcpy-server.sh
# Set variables
DOWNLOAD_URL="https://nightly.link/regulad/scrcpy/workflows/scrcpy-server/feature%2Fwebsocket-v1.19.x/scrcpy-server.zip"
TEMP_DIR=$(mktemp -d)
DESTINATION_DIR="/opt/scrcpy-server"
DESTINATION_FILE="${DESTINATION_DIR}/scrcpy-server"

# Create destination directory if it doesn't exist
mkdir -p "$DESTINATION_DIR"

# Download the zip file
echo "Downloading scrcpy-server.zip..."
if ! curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/scrcpy-server.zip"; then
    echo "Failed to download the file. Please check your internet connection and try again."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Unzip the file
echo "Extracting scrcpy-server.zip..."
if ! unzip -q "$TEMP_DIR/scrcpy-server.zip" -d "$TEMP_DIR"; then
    echo "Failed to extract the zip file. It might be corrupted."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy and rename the server file
echo "Copying server file to $DESTINATION_FILE..."
if ! cp "$TEMP_DIR/scrcpy-server" "$DESTINATION_FILE"; then
    echo "Failed to copy the server file to the destination."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "Successfully downloaded and placed scrcpy-server.jar in $DESTINATION_FILE"

git clone https://github.com/regulad/scrcpy
cd scrcpy
git checkout feature/websocket-v1.19.x

BUILD_DIR=/opt/scrcpy/build-auto

meson "$BUILD_DIR" --buildtype release --strip -Db_lto=true -Dprebuilt_server=$DESTINATION_FILE
ninja -C "$BUILD_DIR"
ninja -C "$BUILD_DIR" install

# now we need to install sndcpy as well
cd /opt/

# Define the URL and destination directory with SNDCPY_ prefix for environment variables
SNDCPY_DOWNLOAD_URL="https://github.com/rom1v/sndcpy/releases/download/v1.1/sndcpy-v1.1.zip"
SNDCPY_DESTINATION_DIR="/opt/sndcpy"
SNDCPY_TEMP_DIR=$(mktemp -d)

# Ensure the destination directory exists
mkdir -p "$SNDCPY_DESTINATION_DIR"

# Download the zip file to the temporary directory
echo "Downloading sndcpy.zip..."
curl -L "$SNDCPY_DOWNLOAD_URL" -o "$SNDCPY_TEMP_DIR/sndcpy.zip"

# Unzip the file to the destination directory
echo "Extracting sndcpy.zip to $SNDCPY_DESTINATION_DIR..."
unzip -q "$SNDCPY_TEMP_DIR/sndcpy.zip" -d "$SNDCPY_DESTINATION_DIR"

# Clean up the temporary directory
rm -rf "$SNDCPY_TEMP_DIR"

echo "sndcpy has been successfully downloaded and extracted to $SNDCPY_DESTINATION_DIR"
