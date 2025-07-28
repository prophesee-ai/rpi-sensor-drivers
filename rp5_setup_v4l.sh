#!/bin/bash

for d in {0..4}; do
    # Execute the command for the current -d value
    OUTPUT=$(media-ctl -p -d "$d" | grep Sens)

    # Check if the output is non-empty
    if [[ -n "$OUTPUT" ]]; then
        if [[ -n "$(media-ctl -p -d "$d" | grep genx320)" ]]; then
            SENSOR_TYPE=genx320
            IMG_SZ=320x320
        elif [[ -n "$(media-ctl -p -d "$d" | grep imx636)" ]]; then
            SENSOR_TYPE=imx636
            IMG_SZ=1280x720
            # inject eof of 64 bit
            subdev_entity=$(media-ctl -d "$d" -p | awk -v entity="imx636" '$0 ~ "entity" && $0 ~ entity { in_entity=1 } in_entity && /device node name/ { print $NF; exit }')
            v4l2-ctl --device $subdev_entity --set-ctrl enable_end_of_frame_marker=3
        else
            echo "Unsupported sensor type!"
            exit 1
        fi

        if [[ -n "$(media-ctl -p -d $d | grep 11-003c)" ]]; then
            if media-ctl -p -d "$d" | grep -q "/dev/video0"; then
                DEV="/dev/video0"
            elif media-ctl -p -d "$d" | grep -q "/dev/video8"; then
                DEV="/dev/video8"
            fi
            I2CSLOT=11
        elif [[ -n "$(media-ctl -p -d $d | grep 10-003c)" ]]; then
            if media-ctl -p -d "$d" | grep -q "/dev/video0"; then
                DEV="/dev/video0"
            elif media-ctl -p -d "$d" | grep -q "/dev/video8"; then
                DEV="/dev/video8"
            fi
            I2CSLOT=10
        else
            echo "Unsupported sensor type!"
            exit 1
        fi

        # Save the output to a file or process it
        echo "Found sensor ${SENSOR_TYPE} in /dev/media$d with device $DEV"

        # activate the link (always the same address)
        echo "Activating csi link"
        media-ctl -d "$d" --links '"csi2":4 -> "rp1-cfe-csi2_ch0":0 [1]'

        echo "Setting v4l mode"
        # semi hard-coded setup, might have to be specified.
        if [ -c "$DEV" ]; then
            media-ctl -d "$d" --set-v4l2 "\"${SENSOR_TYPE} ${I2CSLOT}-003c\":0 [fmt:Y8_1X8/4096x391]"
            # only possible if sensor is turned on
            # media-ctl -d "$d" --set-v4l2 "\"${SENSOR_TYPE} ${I2CSLOT}-003c\":0 [crop:(0,0)/${IMG_SZ}]"
            v4l2-ctl -d $DEV --set-fmt-video=width=4096,height=391,pixelformat=GREY
        else
            echo "Device is not correctly set up"
            exit 1
        fi
    fi
done
