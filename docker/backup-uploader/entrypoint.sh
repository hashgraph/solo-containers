#!/bin/bash

echo "$(date '+%Y-%m-%d %H:%M:%S') INITIALIZING BACKUP CONTAINER"
while :
do
    # Source the main script here so that it runs in the current shell. Two
    # important reasons:
    #
    # 1. all environment variables are passed in
    # 2. ensure multiple copies can't be running (as there is no copy)
    ( . /app/backup.sh)
    sleep 300
done
