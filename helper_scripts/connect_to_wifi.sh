#!/bin/bash

# This script connects to a WiFi network and checks if the connection is successful.
# Usage: ./connect_to_wifi.sh <SSID> <SSID_PROFILE>

# SSID and SSID_PROFILE are read in as parameters
ssid=$1
ssid_profile=$2

# if the command nmcli is available (linux), use it to connect to the network
if command -v nmcli &> /dev/null; then
    sudo nmcli c up ${ssid} || exit 1

    # Check if connected to the network we asked for
    sleep 10 # wait for the connection to be established and stable
    network=$(nmcli device wifi list | grep -E '^\*' | grep ${ssid} | wc -l)
    if [ "$network" -eq 0 ]; then
        exit 1
    fi
# otherwise, try netsh (Windows)
elif command -v netsh &> /dev/null; then
    netsh wlan disconnect
    netsh wlan connect ssid=${ssid} name=${ssid_profile}  || exit 1  # connect to internet

    # Check if connected to the network we asked for
    sleep 10 # wait for the connection to be established and stable
    network=$(netsh wlan show interfaces | grep ' SSID' |  grep ${ssid} | wc -l)
    if [ "$network" -eq 0 ]; then
        exit 1
    fi
else
    echo "Neither nmcli nor netsh is available. Cannot connect to WiFi."
    exit 1
fi
