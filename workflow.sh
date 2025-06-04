#!/bin/bash

# get conda working in a bash script
eval "$(command conda 'shell.bash' 'hook')"

MIRTE_SRC_DIR=/usr/local/src/mirte

# Set up paths and networks
source .env.local
HELPER_DIR="${START_DIR}/mirte-in-the-loop/helper_scripts"

# Use the timestamp to set up the log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${START_DIR}/mirte-in-the-loop/logs/${TIMESTAMP}.log"

cd $START_DIR/mirte-in-the-loop
if [ $? -eq 0 ]; then
    echo "Starting from directory ${PWD}" >> $LOG_FILE
else
    echo "Could not find starting directory" >> $LOG_FILE
    exit 1
fi
echo Internet SSID is $SSID_INTERNET >> $LOG_FILE

# Connect to internet
$HELPER_DIR/connect_to_wifi.sh ${SSID_INTERNET} ${SSID_INTERNET_PROFILE}
if [ $? -eq 0 ]; then
    echo "Connected to internet" >> $LOG_FILE
else
    echo "Could not connect to internet" >> $LOG_FILE
    exit 1
fi

# Update the conda environment
if [ $CONDA_DEFAULT_ENV == "mirte-itl" ]; then
    conda deactivate
fi
conda env remove -y --name mirte-itl  # remove previous conda environment
conda env create -y -f environment.yml
if [ $? -eq 0 ]; then
    echo "Conda environment updated successfully" >> $LOG_FILE
else
    echo "Could not update the Conda environment" >> $LOG_FILE
    exit 1
fi
conda activate mirte-itl
echo "Active Conda environment is: $CONDA_DEFAULT_ENV" >> $LOG_FILE

# Run tests with MOCKING flag
conda run -n mirte-itl --live-stream bash -c "env MOCKING=True pytest" >> $LOG_FILE  # test the test
if [ $? -eq 0 ]; then
    echo "All MOCKING tests passed" >> $LOG_FILE
else
    echo "Errors in MOCKING tests" >> $LOG_FILE
    exit 1
fi

# Connect to MIRTE WiFi
$HELPER_DIR/connect_to_wifi.sh ${SSID_MIRTE} ${SSID_MIRTE_PROFILE}
if [ $? -eq 0 ]; then
    echo "Connected to MIRTE WiFi" >> $LOG_FILE
else
    echo "Could not connect to MIRTE WiFi" >> $LOG_FILE
    exit 1
fi

#  Run the tests
cd $START_DIR/mirte-in-the-loop
conda run -n mirte-itl --live-stream bash -c "pytest" >> $LOG_FILE  # test MIRTE
if [ $? -eq 0 ]; then
    echo "Congratulations! All tests passed" >> $LOG_FILE
else
    echo "Errors in tests" >> $LOG_FILE
    exit 1
fi
