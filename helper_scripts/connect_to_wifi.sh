#!/bin/bash

# This script connects to a WiFi network and checks if the connection is successful.
# Usage: ./connect_to_wifi.sh <SSID> <SSID_PROFILE>

# SSID and SSID_PROFILE are read in as parameters
ssid=$1
ssid_profile=$2

netsh wlan connect ssid=${ssid} name=${ssid_profile}  || exit 1  # connect to internet

# Check if connected to the network we asked for
sleep 10 # wait for the connection to be established and stable
network=$(netsh wlan show interfaces | grep ' SSID' |  grep ${ssid} | wc -l)
if [ "$network" -eq 0 ]; then
    echo "Could not connect to ${SSID_INTERNET} WiFi network" >> $LOG_FILE
    exit 1
else
    echo "Connected to ${SSID_INTERNET} internet network successfully" >> $LOG_FILE
fi
