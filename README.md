# Introduction

This project provides Prophesee event-based sensor drivers for raspberry pi. 
It uses prophesee's [linux-sensor-drivers](https://github.com/prophesee-ai/linux-sensor-drivers) with some modifications for the specific platform.

# Installation

1. Requirements:
    ``` bash
    sudo apt install raspberrypi-kernel-headers dkms
    ```
2. Install drivers with dkms:
    ``` bash
    make all
    sudo dkms add .
    sudo dkms build psee_sensor_drivers/1.0
    sudo dkms install psee_sensor_drivers/1.0
    ```
3. Install support software: [openeb](https://github.com/prophesee-ai/openeb.git)/5.1.1:

    This repository also provides a patch ("openeb-for-rpi.patch") to be able to control sensors.
    
    * Install dependencies:
    ``` bash
        sudo apt update
        sudo apt -y install apt-utils build-essential software-properties-common wget unzip curl git cmake
        sudo apt -y install libopencv-dev libboost-all-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler
        sudo apt -y install libhdf5-dev hdf5-tools libglew-dev libglfw3-dev libcanberra-gtk-module ffmpeg 
        sudo apt -y install pybind11-dev
    ```
    * Install patched openeb (the same would apply for metavision)
    ``` bash
        git clone https://github.com/prophesee-ai/openeb.git --branch 5.1.1 --single-branch
        cd openeb 
        git apply ${RPI_SENSOR_DRIVERS_PATH}/openeb-for-rpi.patch
        mkdir build && cd build
        cmake .. -DUSE_OPENGL_ES3=ON -DCMAKE_BUILD_TYPE=Release
        cmake --build . --config Release -- -j 4
        sudo make install
    ```

# Usage

1. Manually or at boot time, load the sensor driver by loading the device tree overlay:
    ``` bash
    # load genx320 in slot 1:
    sudo dtoverlay genx320
    # In RP5, you can set parameter cam0/cam1 specifying the slot (default is cam1).
    # for a sensor plugged in slot 0 therefore:
    sudo dtoverlay genx320,cam0
    ```
    > You can confirm correct loading of the driver with `dmesg`.

2. Setup formats/links/parameters for v4l:
    ``` bash
    # this script is located within this repository. It configures v4l for any found/known sensor.
    ./rp5_setup_v4l.sh
    ```
3. Environment variables:
    > We make use of 2 environment variables to finetune aspects of the acquisition pipeline:
    ``` bash 
    # to parse mipi frame end markers in the openeb v4l2 plugin.
    export PSEE_VAR_V4L2_BSIZE=1
    # to boost performance, using dma-heap instead of mmap.
    export V4L2_HEAP=vidbuf_cached
    ```

3. Streaming data:
    - the preferred way to interact with our sensors is using openeb/metavision (ie. metavision_viewer)
    - another option is to stream via v4l2 or yavta:
    ``` bash
    v4l2-ctl --device /dev/video0 --stream-mmap --stream-to=output.raw --stream-count=10 --verbose
    ```
    > the data recorded will contain invalid chunks, because our sensors output variable amounts of data that is stored in fixed size mipi frames (4096x391).
    >
    > To retrieve valid data, the mipi frames have to be cut at mipi frame end markers (which we inject on the sensor side).
    > 
    > --> mipi frame end markers are encoded as "OTHER" events. They vary for event formats:
    > - EVT3: E019
    > - EVT21: 0xEXXXX019XXXXXXXX (X - variable)

    ```
