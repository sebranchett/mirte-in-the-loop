#!/bin/bash

# Use the timestamp to set up the log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="logs/${TIMESTAMP}.log"

# Set up paths and networks
source .env.local

cd $START_DIR/mirte-in-the-loop
if [ $? -eq 0 ]; then
    echo "Starting from directory ${PWD}" >> $LOG_FILE
else
    echo "Could not find starting directory"
    exit 1
fi
echo Internet SSID is $SSID_INTERNET >> $LOG_FILE

# Connect to internet
netsh wlan connect ssid=${SSID_INTERNET} name=${SSID_INTERNET_PROFILE}  # connect to internet
sleep 5 # wait for the connection to be established
# Check if connected to the network we asked for
network=$(netsh wlan show interfaces | grep ' SSID' |  grep ${SSID_INTERNET} | wc -l)
if [ "$network" -gt 0 ]; then
    echo "Connected to ${SSID_INTERNET} internet network successfully" >> $LOG_FILE
else
    echo "Could not connect to ${SSID_INTERNET} WiFi network" >> $LOG_FILE
    exit 1
fi

# Update the conda environment
conda env remove -y --name mirte-itl  # remove previous conda environment
conda env create -y -f environment.yml
if [ $? -eq 0 ]; then
    echo "Conda environment updated successfully" >> $LOG_FILE
else
    echo "Could not update the Conda environment" >> $LOG_FILE
    exit 1
fi

# Run tests with MOCKING flag
conda run -n mirte-itl --live-stream bash -c "env MOCKING=True pytest" >> $LOG_FILE  # test the test
if [ $? -eq 0 ]; then
    echo "All MOCKING tests passed" >> $LOG_FILE
else
    echo "Errors in MOCKING tests" >> $LOG_FILE
    exit 1
fi

# Connect to MIRTE
netsh wlan connect ssid=${SSID_MIRTE} name=${SSID_MIRTE_PROFILE}  # connect to internet
sleep 10 # wait for the connection to be established and stable
# Check if connected to the network we asked for
network=$(netsh wlan show interfaces | grep ' SSID' |  grep ${SSID_MIRTE} | wc -l)
if [ "$network" -gt 0 ]; then
    echo "Connected to ${SSID_MIRTE} MIRTE WiFi network successfully" >> $LOG_FILE
else
    echo "Could not connect to ${SSID_MIRTE} MIRTE WiFi network" >> $LOG_FILE
    exit 1
fi

#  Run the tests
conda run -n mirte-itl --live-stream bash -c "pytest" >> $LOG_FILE  # test MIRTE
if [ $? -eq 0 ]; then
    echo "Congratulations! All tests passed" >> $LOG_FILE
else
    echo "Errors in tests" >> $LOG_FILE
    exit 1
fi
