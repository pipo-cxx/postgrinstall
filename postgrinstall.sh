#!/usr/bin/env bash

if [ ! -d ".env" ]
then
    echo "Creating Python virtual environment..."
    python3 -m venv .env
fi

echo "Installing requirements..."
.env/bin/pip install -r requirements.txt

echo "Running main script for $1..."
.env/bin/python3 main.py $1
