#!/bin/bash

if ! command -v aws &> /dev/null
then
  echo "AWS CLI is not installed, install and configure credentials"
  exit 1
fi

if ! command -v docker &> /dev/null
then
  echo "Docker is not installed"
  exit 1
fi

# When the script exits, make sure we take down any dependency services.
function cleanup()
{
    docker compose down
    exit 0
}
trap cleanup EXIT

docker compose build
docker compose up -d

# Tail service logs.
docker-compose logs -tf