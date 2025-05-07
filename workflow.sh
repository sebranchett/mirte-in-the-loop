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


# Make the web installation scripts from mirte-install-scripts install_web.sh script
cd $START_DIR
# if the directory mirte-install-scripts does not exist, clone it
if [ ! -d "mirte-install-scripts" ]; then
    $HELPER_DIR/clone_repository.sh mirte-install-scripts main
    if [ $? -eq 0 ]; then
        echo "Successfully cloned mirte-install-scripts repository" >> $LOG_FILE
    else
        echo "Could not clone mirte-install-scripts repository" >> $LOG_FILE
        exit 1
    fi
else
    echo "mirte-install-scripts directory already exists" >> $LOG_FILE
    cd mirte-install-scripts
    git checkout main
    git pull origin main
    if [ $? -eq 0 ]; then
        echo "Successfully updated mirte-install-scripts repository" >> $LOG_FILE
    else
        echo "Could not update mirte-install-scripts repository" >> $LOG_FILE
        exit 1
    fi
fi
cd $START_DIR/mirte-install-scripts
# Make sure there is a remote set up to the MIRTE server
git remote -v | grep mirte@mirte.local
if [ $? -ne 0 ]; then
    git remote add mirte ssh://mirte@mirte.local/$MIRTE_SRC_DIR/mirte-install-scripts
fi

cd $START_DIR/mirte-in-the-loop
cp $START_DIR/mirte-install-scripts/install_web.sh install.sh && \
sed -i 's/sudo/# sudo/' install.sh && \
sed -i 's/MIRTE_SRC_DIR/START_DIR/' install.sh && \
sed -i "s/START_DIR=.*/START_DIR=\${START_DIR}/" install.sh && \
sed -i 's/.*\/activate/export NODE_VIRTUAL_ENV=$START_DIR\/mirte-web-interface\/node_env\nexport PATH=$NODE_VIRTUAL_ENV\/Scripts:\$PATH/' install.sh && \
sed -i 's/deactivate_node/# deactivate_node/' install.sh || exit 1
grep system $START_DIR/mirte-install-scripts/install_web.sh > update_web_service.sh || exit 1

# Clone the mirte-web-interface repository and build the web interfaces
cd $START_DIR
# if the directory mirte-web-interface does not exist, clone it
if [ ! -d "mirte-web-interface" ]; then
    $HELPER_DIR/clone_repository.sh mirte-web-interface main
    if [ $? -eq 0 ]; then
        echo "Successfully cloned mirte-web-interface repository" >> $LOG_FILE
    else
        echo "Could not clone mirte-web-interface repository" >> $LOG_FILE
        exit 1
    fi
else
    echo "mirte-web-interface directory already exists" >> $LOG_FILE
    cd mirte-web-interface
    git checkout main
    git pull origin main
    if [ $? -eq 0 ]; then
        echo "Successfully updated mirte-web-interface repository" >> $LOG_FILE
    else
        echo "Could not update mirte-web-interface repository" >> $LOG_FILE
        exit 1
    fi
fi
cd $START_DIR/mirte-web-interface
# Make sure there is a remote set up to the MIRTE server
git remote -v | grep mirte@mirte.local
if [ $? -ne 0 ]; then
    git remote add mirte ssh://mirte@mirte.local/$MIRTE_SRC_DIR/mirte-web-interface
fi

# Build the web interfaces
cd $START_DIR/mirte-web-interface
rm -rf node_env && \
${START_DIR}/mirte-in-the-loop/install.sh
if [ $? -eq 0 ]; then
    echo "Successfully built the web front and backend" >> $LOG_FILE
else
    echo "Could not build the web front and backend" >> $LOG_FILE
    exit 1
fi

exit 1

# Connect to MIRTE WiFi
$HELPER_DIR/connect_to_wifi.sh ${SSID_MIRTE} ${SSID_MIRTE_PROFILE}
if [ $? -eq 0 ]; then
    echo "Connected to MIRTE WiFi" >> $LOG_FILE
else
    echo "Could not connect to MIRTE WiFi" >> $LOG_FILE
    exit 1
fi

# Update mirte-install-scripts repository on MIRTE
cd $START_DIR/mirte-install-scripts
git fetch mirte main
git diff mirte/main
if [ $? -eq 0 ]; then
    echo "No changes in mirte-install-scripts." >> $LOG_FILE
else
    scp -r $START_DIR/mirte-install-scripts/ mirte@mirte.local:/$MIRTE_SRC_DIR/mirte-install-scripts || exit 1
    echo "Changes in mirte-install-scripts copied to MIRTE" >> $LOG_FILE
fi

cd $START_DIR/mirte-in-the-loop
scp update_web_service.sh mirte@mirte.local:/$MIRTE_SRC_DIR/ || exit 1

# Update mirte-web-interface repository on MIRTE
cd $START_DIR/mirte-web-interface
git fetch mirte main
git diff mirte/main
if [ $? -eq 0 ]; then
    echo "No changes in mirte-web-interface." >> $LOG_FILE
else
    scp -r $START_DIR/mirte-web-interface/ mirte@mirte.local:/$MIRTE_SRC_DIR/mirte-web-interface || exit 1
    echo "Changes in mirte-web-interface copied to MIRTE" >> $LOG_FILE
    # Update the web service
    ssh mirte@mirte.local ". $MIRTE_SRC_DIR/update_web_service.sh"
    if [ $? -eq 0 ]; then
        echo "Successfully updated the web service" >> $LOG_FILE
    else
        echo "Could not update the web service" >> $LOG_FILE
        exit 1
    fi
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
