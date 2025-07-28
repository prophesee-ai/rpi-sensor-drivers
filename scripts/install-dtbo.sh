#!/bin/bash
set -e

DTBO_NAME_0="genx320.dtbo"
DTBO_NAME_1="imx636.dtbo"

echo "Installing Device Tree Overlays: $DTBO_NAME_0, $DTBO_NAME_1"

# Copy the overlay
sudo install -m 0644 "$DTBO_NAME_0" "/boot/overlays/"
sudo install -m 0644 "$DTBO_NAME_1" "/boot/overlays/"
