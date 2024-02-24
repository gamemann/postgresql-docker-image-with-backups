#!/bin/bash
echo "Building Docker image..."

FLAGS=""
IMAGE_PATH="image"

# Parse command line arguments.
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --no-cache)
            FLAGS+="--no-cache "
            shift # past argument
            ;;
        --tag=*)
            TAG="${key#*=}"
            FLAGS+="--build-arg TAG=${TAG}"
            shift
            ;;
        --path=*)
            IMAGE_PATH="${key#*=}"
            shift
            ;;
        --help)
            echo "build_image.sh"
            echo -e "\t--tag=<TAG> - The Postgres image tag. Defaults to latest."
            echo -e "\t--no-cache - Disables Docker build cache."
            echo -e "\t--path=<PATH> - The path to the Docker image to build. Defaults to image/ directory."
            exit 0
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "Flags: ${FLAGS}"
echo "Image Path: ${IMAGE_PATH}/"

docker build -t postgresbackups:latest $FLAGS $IMAGE_PATH