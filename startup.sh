#!/bin/bash
set -ex

# Set up paths and networks
source .env.local

# Connect to internet
netsh wlan connect ssid=${SSID_INTERNET} name=${SSID_INTERNET_PROFILE}  || exit 1  # connect to internet
sleep 5  # wait for the connection to be established

cd $START_DIR/mirte-in-the-loop || exit 1

git checkout $BRANCH || exit 1

git pull origin $BRANCH || exit 1

# Need to update the repository first, so that the workflow script is up to date
./workflow.sh  || exit 1
