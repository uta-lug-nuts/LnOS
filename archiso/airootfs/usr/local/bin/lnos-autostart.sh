#!/bin/bash

# /*
# Copyright 2025 UTA-LugNuts Authors.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */


#
# @file lnos-autostart.sh
# @brief Installs Arch linux and 
# @author Trevor Bakker
# @date 2025
#

# Wait for system to fully boot
sleep 3

echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""

# Wait a moment for system to settle
sleep 2

# Auto-detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    TARGET="x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    TARGET="aarch64"
else
    TARGET="x86_64"  # fallback
fi

echo "Detected architecture: $ARCH (target: $TARGET)"
echo ""

# Check if installer exists
if [[ ! -f "/root/LnOS/scripts/LnOS-installer.sh" ]]; then
    echo "ERROR: LnOS installer not found!"
    echo "Available files in /root/LnOS/scripts/:"
    ls -la /root/LnOS/scripts/ 2>/dev/null || echo "Directory not found"
    echo ""
    echo "Dropping to shell..."
    exec /bin/bash
fi

# Make sure installer is executable
chmod +x /root/LnOS/scripts/LnOS-installer.sh

echo "Starting LnOS installer..."
echo ""

# Change to installer directory and run
cd /root/LnOS/scripts
exec ./LnOS-installer.sh --target=$TARGET