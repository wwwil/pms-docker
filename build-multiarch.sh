#!/usr/bin/env bash

set -o errexit
set -o pipefail

DOCKER_IMAGE="wwwil/pms-docker"

docker build --tag "${DOCKER_IMAGE}:amd64" \
  --build-arg TAG=latest \
  --file Dockerfile .

docker build --tag "${DOCKER_IMAGE}:arm64v8" \
  --build-arg TAG=latest \
  --file Dockerfile.arm64 .

docker build --tag "${DOCKER_IMAGE}:arm32v7" \
  --build-arg TAG=latest \
  --file Dockerfile.armv7 .

if [[ $1 == "--push" ]]; then
  docker push "${DOCKER_IMAGE}:amd64"
  docker push "${DOCKER_IMAGE}:arm64v8"
  docker push "${DOCKER_IMAGE}:arm32v7"
  docker manifest create \
    "${DOCKER_IMAGE}:latest" \
    --amend "${DOCKER_IMAGE}:amd64" \
    --amend "${DOCKER_IMAGE}:arm64v8" \
    --amend "${DOCKER_IMAGE}:arm32v7"
  docker manifest push "${DOCKER_IMAGE}:latest"
fi
