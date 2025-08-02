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

# Skip if not on tty1
if [[ $(tty) != "/dev/tty1" ]]; then
    exit 0
fi

# Clear screen and show welcome
clear
echo "=========================================="
echo "      Welcome to LnOS Live Environment"
echo "=========================================="
echo ""
echo "Network should be automatically configured."
echo ""

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
echo "Starting LnOS installer automatically in 5 seconds..."
echo "Press Ctrl+C to cancel and drop to shell."
echo ""

# 5 second countdown
for i in {5..1}; do
    echo -n "$i... "
    sleep 1
done
echo ""
echo ""

echo "Starting LnOS installer..."
cd /root/LnOS/scripts

# Execute the installer
exec ./LnOS-installer.sh --target=$TARGET