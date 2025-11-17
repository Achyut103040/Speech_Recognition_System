#!/bin/bash
# Wrapper to run buildozer with correct environment

# Set up paths
export PATH="/home/achyut/.local/bin:/usr/bin:/bin"
export ANDROIDAPI=33
export ANDROIDMINAPI=21

# Change to project directory
cd "$(dirname "$0")"

# Run buildozer
exec /home/achyut/.local/bin/buildozer "$@"
