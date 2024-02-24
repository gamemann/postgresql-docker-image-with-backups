#!/bin/bash
FLAGS=""

IMAGE_NAME="postgresbackups"
IMAGE_TAG="latest"
IMAGE_PATH="image"

# Parse command line arguments.
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --no-cache)
            FLAGS+="--no-cache "
            shift
            ;;
        --name=*)
            IMAGE_NAME="${key#*=}"
            shift
            ;;
        --tag=*)
            IMAGE_TAG="${key#*=}"
            shift
            ;;
        --path=*)
            IMAGE_PATH="${key#*=}"
            shift
            ;;
        --ptag=*)
            FLAGS+="--build-arg TAG=${key#*=}"
            shift
            ;;
        --help)
            echo "build_image.sh"
            echo -e "\t--name=<NAME> - The Docker image name to build. Defaults to postgresbackups."
            echo -e "\t--tag=<TAG> - The Docker image tag to build. Defaults to latest."
            echo -e "\t--path=<PATH> - The path to the Docker image to build. Defaults to image/ directory."
            echo -e "\t--ptag=<TAG> - The Postgres image tag. Defaults to latest."
            echo -e "\t--no-cache - Disables Docker build cache."
            exit 0
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "Building Docker image..."

echo "Image Name: ${IMAGE_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Image Path: ${IMAGE_PATH}/"
echo "Flags: ${FLAGS}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} $FLAGS $IMAGE_PATH