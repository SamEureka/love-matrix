#!/bin/bash

# 2023 (c) Sam Dennon

# Change directory to the location of the Python script
cd /opt/love/

# Start a screen session and run the Python script
sudo screen -dmS toggler python3 toggle_shutdown.py
