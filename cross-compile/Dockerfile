# Use Ubuntu 20.04 as the base image for the Docker container
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install basic tools and dependencies for cross-compilation and ROS2 build
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    debootstrap \
    qemu-user-static \
    binfmt-support \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up locales (needed for some ROS2 tools)
RUN locale-gen en_US.UTF-8

# Install Python tools for ROS2
RUN python3 -m pip install --upgrade pip && \
    pip install \
    colcon-common-extensions \
    vcstool \
    rosdep \
    setuptools

# Enable QEMU for ARM64 emulation
RUN update-binfmts --enable qemu-aarch64

# Create a sysroot for Ubuntu 20.04 ARM64 with verbose output and error checking
# Note: The architecture is "arm64" in Ubuntu repositories, not "aarch64"
RUN mkdir -p /sysroot && \
    debootstrap --verbose --arch=arm64 --foreign focal /sysroot http://ports.ubuntu.com/ || { echo "debootstrap first stage failed"; ls -la /sysroot; exit 1; } && \
    cp /usr/bin/qemu-aarch64-static /sysroot/usr/bin/ && \
    chroot /sysroot /debootstrap/debootstrap --second-stage || { echo "debootstrap second stage failed"; ls -la /sysroot; exit 1; }

# Verify sysroot and set up the sources.list manually
RUN mkdir -p /sysroot/etc/apt && \
    echo "deb http://ports.ubuntu.com/ focal main restricted universe multiverse" > /sysroot/etc/apt/sources.list && \
    echo "deb http://ports.ubuntu.com/ focal-updates main restricted universe multiverse" >> /sysroot/etc/apt/sources.list && \
    echo "deb http://ports.ubuntu.com/ focal-security main restricted universe multiverse" >> /sysroot/etc/apt/sources.list

# Install additional dependencies in the sysroot (chroot into sysroot and install)
RUN chroot /sysroot /bin/bash -c "apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    libpython3-dev \
    libacl1-dev \
    && rm -rf /var/lib/apt/lists/*"

# Verify that sys/acl.h exists in the sysroot
RUN ls -l /sysroot/usr/include/sys/acl.h || { echo "sys/acl.h not found in sysroot"; exit 1; }

# Create a CMake toolchain file for cross-compilation
RUN echo "set(CMAKE_SYSTEM_NAME Linux)" > /toolchain.cmake && \
    echo "set(CMAKE_SYSTEM_PROCESSOR aarch64)" >> /toolchain.cmake && \
    echo "set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)" >> /toolchain.cmake && \
    echo "set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)" >> /toolchain.cmake && \
    echo "set(CMAKE_SYSROOT /sysroot)" >> /toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH /sysroot)" >> /toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /toolchain.cmake && \
    echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /toolchain.cmake

# Set up a working directory for ROS2 source and build
WORKDIR /ros2_humble

# Download the ROS2 Humble source code using the repos file
RUN wget https://raw.githubusercontent.com/ros2/ros2/humble/ros2.repos && \
    mkdir src && \
    vcs import src < ros2.repos

# Initialize rosdep and update it
RUN rosdep init || true && \
    rosdep update

# Install ROS2 dependencies using rosdep (targeting the sysroot)
RUN rosdep install --from-paths src --ignore-src --rosdistro humble -y --os=ubuntu:focal \
    --sysroot /sysroot || true

# Build ROS2 Humble with colcon
RUN colcon build \
    --merge-install \
    --cmake-force-configure \
    --cmake-args \
    -DCMAKE_TOOLCHAIN_FILE=/toolchain.cmake \
    -DCMAKE_VERBOSE_MAKEFILE=ON

# Set up the environment for running ROS2 (optional, for testing in container)
ENV ROS_DISTRO=humble \
    ROS_ROOT=/ros2_humble/install
RUN echo "source /ros2_humble/install/setup.bash" >> /root/.bashrc

# Define an entrypoint (optional, for debugging or running commands)
CMD ["/bin/bash"]
