#!/bin/bash
set -xe

# Clone the repository given in the first argument with branch given in the second argument
# Usage: ./clone_repository.sh <repository_name> <branch_name>

# If the second argument is not provided, set to "main"
if [ -z "$2" ]; then
    BRANCH_NAME="main"
else
    BRANCH_NAME=$2
fi
rm -rf $1
git clone -b $BRANCH_NAME https://github.com/mirte-robot/$1.git