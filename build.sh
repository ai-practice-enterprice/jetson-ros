#!/bin/bash
echo $(uname -m)
# Create workspace
mkdir src

# Import ROS2 sources
vcs import src < humble-ros-core.rosinstall

# Update packages
apt upgrade -y

# Initialize and update rosdep
rosdep init
rosdep update

# Install dependencies
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

# Build ROS2
colcon build

# Package the build
rm -r src
tar -czf ../ros2Humble.tar.gz .
cp ../ros2Humble.tar.gz /root/output
