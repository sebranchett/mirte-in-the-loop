#!/bin/bash
set -ex

# Set up paths and networks
source .env.local

# Connect to internet
./helper_scripts/connect_to_wifi.sh ${SSID_INTERNET} ${SSID_INTERNET_PROFILE}  || exit 1  # connect to internet

cd $START_DIR/mirte-in-the-loop || exit 1

git checkout $BRANCH || exit 1

git pull origin $BRANCH || exit 1

# Need to update the repository first, so that the workflow script is up to date
./workflow.sh  || exit 1
