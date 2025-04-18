#!/usr/bin/env bash

echo "Creating Python virtual environment..."
python3 -m venv .env

echo "Installing requirements..."
.env/bin/pip install -r requirements.txt

echo "Running main script for $1..."
.env/bin/python3 main.py $1
