#!/bin/bash
cd /root/ros2_humble
cp /root/packages.txt ./

PACKAGE_LIST_FILE="packages.txt"
mkdir -p src

# humble Packages setup
mapfile -t package_names < "$PACKAGE_LIST_FILE"
for package_name in "${package_names[@]}"; do
    echo "Processing package: $package_name"
    # Generate the .rosinstall file for the package
    rosinstall_generator "$package_name" --rosdistro humble --deps > "humble-${package_name}.rosinstall"

    # Import the package using vcs
    vcs import src < "humble-${package_name}.rosinstall"
done

# Update packages
apt upgrade -y

# Initialize and update rosdep if needed
if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    rosdep init
fi
rosdep update

# Install dependencies
apt update
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

# Build ROS2
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# Package the build
rm -r src
tar -czf ./ros2Humble.tar.gz ./install
