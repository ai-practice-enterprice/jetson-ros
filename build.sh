#!/bin/bash
cd /root/ros2_humble

# Create workspace if it doesn't exist
if [ ! -d "src" ]; then
    mkdir -p src
    cp /root/humble-ros-core.rosinstall ./

    # Import ROS2 sources (only if src is empty)
    vcs import src < humble-ros-core.rosinstall

    # Update packages
    apt upgrade -y

    # Initialize and update rosdep if needed
    if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
        rosdep init
    fi
    rosdep update

    # Install dependencies
    rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"
fi

# Build ROS2
colcon build

# Package the build
rm -r src
tar -czf ./ros2Humble.tar.gz .
