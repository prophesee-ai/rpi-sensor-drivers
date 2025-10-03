#!/bin/bash

for d in {0..4}; do
    # Execute the command for the current -d value
    SENSOR_TYPE=$(media-ctl -p -d "$d" | grep "entity" | grep -oE "imx636|genx320")

    # Check if the output is non-empty
    if [[ -n "$SENSOR_TYPE" ]]; then
        subdev_entity=$(media-ctl -d "$d" -p | awk -v entity="$SENSOR_TYPE" '$0 ~ "entity" && $0 ~ entity { in_entity=1 } in_entity && /device node name/ { print $NF; exit }')
        read BUFFER_WIDTH BUFFER_HEIGHT <<<$(
            v4l2-ctl -d $subdev_entity --list-subdev-framesizes pad=pad0 | sed -n 's/.*- //p' | tr 'x' ' ')
        if [ "$SENSOR_TYPE" = "genx320" ] ; then
            IMG_SZ=320x320
        elif [[ "$SENSOR_TYPE" = "imx636" ]]; then
            IMG_SZ=1280x720
            # inject eof of 64 bit
            v4l2-ctl --device $subdev_entity --set-ctrl enable_end_of_frame_marker=3
        else
            echo "Unsupported sensor type!"
            continue;
        fi

        DEV=$(media-ctl -d "$d" -e "rp1-cfe-csi2_ch0")
        I2CSLOT=$(media-ctl -p -d "$d" | grep "entity" | grep -E "imx636|genx320" | awk '{print $5}')

        # Save the output to a file or process it
        echo "Found sensor ${SENSOR_TYPE} in /dev/media$d with device $DEV. Buffer size will be ${BUFFER_WIDTH}x${BUFFER_HEIGHT}"

        # activate the link (always the same address on rpi5)
        echo "Activating csi link"
        media-ctl -d "$d" --links '"csi2":4 -> "rp1-cfe-csi2_ch0":0 [1]'

        echo "Setting v4l mode"
        # semi hard-coded setup, might have to be specified.
        if [ -c "$DEV" ]; then
            media-ctl -d "$d" --set-v4l2 "\"${SENSOR_TYPE} ${I2CSLOT}\":0 [fmt:Y8_1X8/${BUFFER_WIDTH}x${BUFFER_HEIGHT}]"
            # set crop mode can only be done after init. It is not required for streaming, but may help drivers to infer correct size.
            # media-ctl -d "$d" --set-v4l2 "\"${SENSOR_TYPE} ${I2CSLOT}\":0 [crop:(0,0)/${IMG_SZ}]"
            v4l2-ctl -d $DEV --set-fmt-video=width=${BUFFER_WIDTH},height=${BUFFER_HEIGHT},pixelformat=GREY
        else
            echo "Device is not correctly set up"
            exit 1
        fi
    fi
done
