#!/bin/bash

# Hytale Docker Server - Run Script
# This script starts the Hytale server and attaches to it

echo "Starting Hytale server..."

# Start the container in detached mode
docker-compose up -d

# Wait a moment for the container to start
sleep 2

# Attach to the container
echo ""
echo "Attaching to Hytale server console..."
echo "Press Ctrl+P, Ctrl+Q to detach without stopping the server"
echo ""

docker attach hytale
