#!/bin/bash
set -e

DTBO_NAME_0="genx320.dtbo"
DTBO_NAME_1="imx636.dtbo"
DTBO_DEST="/boot/overlays"

echo "Removing Device Tree Overlay: $DTBO_NAME_0, $DTBO_NAME_1"

# Remove the overlay file
sudo rm -f "$DTBO_DEST/$DTBO_NAME_0"
sudo rm -f "$DTBO_DEST/$DTBO_NAME_1"