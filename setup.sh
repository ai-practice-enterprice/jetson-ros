#!/bin/bash

# Build the Docker image for ARM64 architecture
docker build --platform linux/arm64/v8 -t ros2_humble_image .

# Run the Docker container with ARM64 emulation
docker create --platform linux/arm64/v8 -v "$(pwd)/ros2_humble:/root/ros2_humble" --name ros2_humble_build ros2_humble_image

echo "Container setup complete. Run './run.sh' to build ROS2."
