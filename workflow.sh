#!/bin/bash

# get conda working in a bash script
eval "$(command conda 'shell.bash' 'hook')"

MIRTE_SRC_DIR=/usr/local/src/mirte

# Use the timestamp to set up the log file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="logs/${TIMESTAMP}.log"

# Set up paths and networks
source .env.local

cd $START_DIR/mirte-in-the-loop
if [ $? -eq 0 ]; then
    echo "Starting from directory ${PWD}" >> $LOG_FILE
else
    echo "Could not find starting directory" >> $LOG_FILE
    exit 1
fi
echo Internet SSID is $SSID_INTERNET >> $LOG_FILE

# Connect to internet
./helper_scripts/connect_to_wifi.sh ${SSID_INTERNET} ${SSID_INTERNET_PROFILE}
if [ $? -eq 0 ]; then
    echo "Connected to ${SSID_INTERNET} internet network successfully" >> $LOG_FILE
else
    echo "Could not connect to ${SSID_INTERNET} WiFi network" >> $LOG_FILE
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

# Clone the mirte-web-interface repository
#SEB TODO: parameterise this
mkdir -p gitdir
cd gitdir || exit 1
rm -rf mirte-web-interface
git clone https://github.com/mirte-robot/mirte-web-interface.git
cd mirte-web-interface
git checkout main
cd $START_DIR/mirte-in-the-loop

# Connect to MIRTE WiFi
./helper_scripts/connect_to_wifi.sh ${SSID_MIRTE} ${SSID_MIRTE_PROFILE}
if [ $? -eq 0 ]; then
    echo "Connected to ${SSID_MIRTE} MIRTE WiFi network successfully" >> $LOG_FILE
else
    echo "Could not connect to ${SSID_MIRTE} MIRTE WiFi network" >> $LOG_FILE
    exit 1
fi

# Update the mirte-web-interface repository and install it
scp -r gitdir/mirte-web-interface/ mirte@mirte.local:$MIRTE_SRC_DIR/mirte-web-interface-new
#SEB TODO: install the new web interface

#  Run the tests
conda run -n mirte-itl --live-stream bash -c "pytest" >> $LOG_FILE  # test MIRTE
if [ $? -eq 0 ]; then
    echo "Congratulations! All tests passed" >> $LOG_FILE
else
    echo "Errors in tests" >> $LOG_FILE
    exit 1
fi
