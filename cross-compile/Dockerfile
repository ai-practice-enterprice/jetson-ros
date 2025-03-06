# Use an Ubuntu 22.04 base image for x86 as the host
FROM ubuntu:22.04 AS builder

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic tools and dependencies on the host
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    python3-pip \
    pkg-config \
    qemu-user-static \
    debootstrap \
    binfmt-support \
    crossbuild-essential-arm64 \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools for ROS2
RUN pip3 install --no-cache-dir vcstool colcon-common-extensions

# Create a sysroot for aarch64 using debootstrap with complete Ubuntu 20.04 (focal)
RUN debootstrap --arch=arm64 --variant=minbase --include=libc6-dev,gcc,g++,python3,python3-dev,libpython3-dev,cmake,pkg-config,build-essential,git \
    focal /sysroot http://ports.ubuntu.com/ubuntu-ports

# Set up QEMU for aarch64 emulation
RUN cp /usr/bin/qemu-aarch64-static /sysroot/usr/bin/
RUN chroot /sysroot /bin/bash -c "apt-get update"

# Configure repositories for the sysroot
RUN echo "deb http://ports.ubuntu.com/ubuntu-ports focal main restricted universe multiverse" > /sysroot/etc/apt/sources.list && \
    echo "deb http://ports.ubuntu.com/ubuntu-ports focal-updates main restricted universe multiverse" >> /sysroot/etc/apt/sources.list && \
    echo "deb http://ports.ubuntu.com/ubuntu-ports focal-security main restricted universe multiverse" >> /sysroot/etc/apt/sources.list

# Install essential development packages in the sysroot
RUN chroot /sysroot apt-get update && \
    chroot /sysroot apt-get install -y \
    python3-pip \
    python3-dev \
    libacl1-dev \
    libssl-dev \
    libtinyxml2-dev \
    libasio-dev \
    libtinyxml-dev \
    libcunit1-dev \
    libncurses5-dev \
    libacl1-dev \
    acl \
    libc6-dev \
    linux-libc-dev \
    libc-dev-bin \
    libgcc-9-dev \
    libssl-dev \
    gcc-9 \
    g++-9 \
    libc-dev \
    && \
    chroot /sysroot pip3 install colcon-common-extensions && \
    chroot /sysroot apt-get clean

# Set up the ROS2 workspace
WORKDIR /ros2_humble
COPY ./ros2.repos ./ros2.repos
RUN mkdir -p src && \
    vcs import src < ros2.repos && \
    rm ros2.repos

# Create the CMake toolchain file for aarch64
RUN echo "set(CMAKE_SYSTEM_NAME Linux)" > /aarch64.toolchain.cmake && \
    echo "set(CMAKE_SYSTEM_PROCESSOR aarch64)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH /sysroot)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_C_FLAGS \"-march=armv8-a -I/sysroot/usr/include -I/sysroot/usr/include/aarch64-linux-gnu\" CACHE STRING \"c flags\")" >> /aarch64.toolchain.cmake && \
    echo "set(CMAKE_CXX_FLAGS \"-march=armv8-a -I/sysroot/usr/include -I/sysroot/usr/include/aarch64-linux-gnu\" CACHE STRING \"c++ flags\")" >> /aarch64.toolchain.cmake

# Set environment variables for cross-compilation
ENV CC=/usr/bin/aarch64-linux-gnu-gcc
ENV CXX=/usr/bin/aarch64-linux-gnu-g++
ENV PKG_CONFIG_PATH=/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig
ENV CFLAGS="-I/sysroot/usr/include -I/sysroot/usr/include/aarch64-linux-gnu"
ENV CXXFLAGS="-I/sysroot/usr/include -I/sysroot/usr/include/aarch64-linux-gnu"

# Modify the iceoryx package to work with cross-compilation (if needed)
# Skip iceoryx for now to avoid compilation issues
RUN touch /ros2_humble/src/iceoryx/COLCON_IGNORE

# Build ROS2 Humble with reduced dependencies
RUN colcon build --merge-install --cmake-force-configure \
    --cmake-args -DCMAKE_TOOLCHAIN_FILE=/aarch64.toolchain.cmake \
    -DBUILD_TESTING=OFF \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DTHIRDPARTY_Asio=ON \
    -DTHIRDPARTY=ON \
    --no-warn-unused-cli

CMD ["bash"]
