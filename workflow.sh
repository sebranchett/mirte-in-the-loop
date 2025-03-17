#!/bin/bash
# source .env.local
# cd $START_DIR/mirte-in-the-loop
# netsh wlan connect ssid=${SSID_INTERNET} name=${SSID_INTERNET_PROFILE}  # connect to internet
# sleep 5 # wait for the connection to be established
# git pull
conda env remove -y --name mirte-itl  # remove previous conda environment
conda env create -y -f environment.yml
conda run -n mirte-itl --live-stream bash -c "env MOCKING=True pytest"  # test the test
# netsh wlan connect ssid=${SSID_MIRTE} name=${SSID_MIRTE_PROFILE}  # connect to MIRTE
# sleep 5 # wait for the connection to be established
# conda run -n mirte-itl --live-stream bash -c pytest"  # test MIRTE
