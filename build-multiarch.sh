#!/usr/bin/env bash

set -o errexit
set -o pipefail

DOCKER_IMAGE="wwwil/pms-docker"
DOCKER_TAG="1.22.1.4228-724c56e62"

docker build --tag "${DOCKER_IMAGE}:${DOCKER_TAG}-amd64" \
  --build-arg TAG="${DOCKER_TAG}" \
  --file Dockerfile .

docker build --tag "${DOCKER_IMAGE}:${DOCKER_TAG}-arm64v8" \
  --build-arg TAG="${DOCKER_TAG}" \
  --file Dockerfile.arm64 .

docker build --tag "${DOCKER_IMAGE}:${DOCKER_TAG}-arm32v7" \
  --build-arg TAG="${DOCKER_TAG}" \
  --file Dockerfile.armv7 .

if [[ $1 == "--push" ]]; then
  docker push "${DOCKER_IMAGE}:${DOCKER_TAG}-amd64"
  docker push "${DOCKER_IMAGE}:${DOCKER_TAG}-arm64v8"
  docker push "${DOCKER_IMAGE}:${DOCKER_TAG}-arm32v7"
  docker manifest create \
    "${DOCKER_IMAGE}:${DOCKER_TAG}" \
    --amend "${DOCKER_IMAGE}:${DOCKER_TAG}-amd64" \
    --amend "${DOCKER_IMAGE}:${DOCKER_TAG}-arm64v8" \
    --amend "${DOCKER_IMAGE}:${DOCKER_TAG}-arm32v7"
  docker manifest push "${DOCKER_IMAGE}:${DOCKER_TAG}"
fi
