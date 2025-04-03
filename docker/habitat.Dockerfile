FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu20.04

LABEL maintainer="Minho Lee <mino@inha.edu>" \
      version="1.0" \
      description="Minimal Docker Image for Habitat-Sim v0.2.5" \
      org.opencontainers.image.source="https://github.com/iminolee/Habitat-Sim-Docker"

ENV DEBIAN_FRONTEND=noninteractive

# Enable nvidia-container-runtime support
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

ENV WORK_DIR=/workspace

# --------------------------------------------------------------------
# Install required system libraries
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake wget curl git unzip pkg-config \
        libssl-dev libjpeg-dev libpng-dev libtiff-dev libpcl-dev \
        libgtk-3-dev libosmesa6-dev libegl1-mesa-dev freeglut3-dev \
         libassimp-dev libavcodec-dev libavformat-dev libswscale-dev \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# Install Python 3.9 and essential Python packages
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.9 python3.9-dev \
        python3-distutils python3-pip python3-wheel \
        pybind11-dev && \
    ln -sf /usr/bin/python3.9 /usr/bin/python && \
    ln -sf /usr/bin/python3.9 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    pip install --upgrade pip setuptools numpy && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# Install PyTorch with CUDA 12.1 support
# --------------------------------------------------------------------
RUN pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

# --------------------------------------------------------------------
# Install Python dependencies
# --------------------------------------------------------------------
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

# --------------------------------------------------------------------
# Build and install Corrade
# --------------------------------------------------------------------
RUN cd /tmp && \
    git clone --branch v2020.06 --recursive https://github.com/mosra/corrade.git && \
    cd corrade && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/corrade

# --------------------------------------------------------------------
# Build and install Magnum
# --------------------------------------------------------------------
RUN cd /tmp && \
    git clone --branch v2020.06 --recursive https://github.com/mosra/magnum.git && \
    cd magnum && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DBUILD_PYTHON=ON \
             -DPYBIND11_INCLUDE_DIR=/usr/local/lib/python3.9/dist-packages/pybind11/include && \
             make -j$(nproc) && \
             make install && \
             cd / && rm -rf /tmp/magnum

# --------------------------------------------------------------------
# Build and install Magnum Bindings
# --------------------------------------------------------------------
RUN cd /tmp && \
    git clone --branch v2020.06 --recursive https://github.com/mosra/magnum-bindings.git && \
    cd magnum-bindings && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
             -DBUILD_PYTHON=ON \
             -DPYTHON_EXECUTABLE=/usr/bin/python3.9 \
             -DPYBIND11_INCLUDE_DIR=/usr/local/lib/python3.9/dist-packages/pybind11/include && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/magnum-bindings

# --------------------------------------------------------------------
# Build and install Habitat-Sim
# --------------------------------------------------------------------
RUN cd /tmp && \
    git clone -b v0.2.5 https://github.com/facebookresearch/habitat-sim.git && \
    cd habitat-sim && \
    ./build.sh --inplace

# --------------------------------------------------------------------
# Set working directory and entrypoint
# --------------------------------------------------------------------
RUN git config --global --add safe.directory /workspace
WORKDIR ${WORK_DIR}

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]