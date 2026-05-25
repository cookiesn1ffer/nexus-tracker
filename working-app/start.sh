#!/bin/bash
set -e

echo "=========================================="
echo "   Nexus Tracker - Starting Server"
echo "=========================================="
echo ""

if [ ! -d "server/node_modules" ]; then
    echo "Installing server dependencies..."
    npm install --prefix server
fi

echo ""
echo "Starting server on http://localhost:5000"
echo "Press Ctrl+C to stop"
echo ""
node server/src/index.js
