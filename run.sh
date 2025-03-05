#!/bin/bash

# Start the container, which will automatically run the build script
echo "Starting build process..."
docker start -a ros2_humble_build
echo "Build process finished. Container has stopped."
