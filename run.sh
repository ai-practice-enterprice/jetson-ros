#!/bin/bash

# Build the Docker image for ARM64 architecture
docker build --platform linux/arm64/v8 -t ros2_humble_image .

# Run the Docker container with ARM64 emulation
# Remove the container when it exits
docker run --rm -it --platform linux/arm64/v8 -v "$(pwd)/output:/root/output" ros2_humble_image
