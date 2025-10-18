#!/bin/bash

echo "Executing create_pkg.sh..."

mkdir ../../lambda_dist_pkg

cd ../../lambdas

# Create and activate virtual environment...
python3 -m venv venv3.13
source venv3.13/bin/activate

# Installing python dependencies...
FILE=requirements.txt

if [ -f "$FILE" ]; then
    echo "Installing dependencies..."
    echo "From: requirement.txt file exists..."
    pip install -r "$FILE"

else
    echo "Error: requirement.txt does not exist!"
fi

# Deactivate virtual environment...
deactivate

# Create deployment package...
echo "Creating deployment package..."
cd venv3.13/lib/python3.13/site-packages/
cp -r . ../../../../../lambda_dist_pkg
cp -r ../../../../src/*.py ../../../../../lambda_dist_pkg
cd ../../../../

# Removing virtual environment folder...
echo "Removing virtual environment folder..."
rm -rf venv3.13

zip -r ../cicd/terraform/lambdas.zip .

echo "Finished script execution!"