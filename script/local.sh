#!/usr/bin/env bash

if [ -f ".env" ]; then
    eval "$(
      cat .env | awk '!/^\s*#/' | awk '!/^\s*$/' | while IFS='' read -r line; do
        key=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)
        echo "export $key=$value"
      done
    )"
else
    echo No .env file found!
    exit 0
fi

forge script LocalScript --fork-url http://localhost:8545 --broadcast --slow -g 200 $@
