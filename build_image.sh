#!/bin/bash
echo "Building Docker image..."

FLAGS=

if [[ "$1" == "no-cache" ]]; then
    FLAGS="--no-cache"
fi

docker build -t postgresbackups:latest $FLAGS image