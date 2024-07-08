#!/bin/bash

# Get commandline arguments
while (( "$#" )); do
  case "$1" in
    --registry)
      containerRegistry="${2}"
      shift
      ;;
    --username)
      containerRegistryUsername="${2}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Container registery
if [[ $containerRegistry == "" ]]; then
  echo "Container registery [--registry] is not provided! Using default [ghcr.io]..."
  containerRegistry="ghcr.io"
fi

# Container registery username
if [[ $containerRegistryUsername == "" ]]; then
  echo "Container registery username [--username] is not provided! Using default [utr1903]..."
  containerRegistryUsername="utr1903"
fi

# Run as non-root user
if [[ $runAsNonroot == "" ]]; then
  runAsNonroot="false"
fi

# Set variables
appImageName="${containerRegistry}/${containerRegistryUsername}/custom-ubuntu:latest"
echo $appImageName

###################
### Deploy Helm ###
###################

helm upgrade test \
  --install \
  --wait \
  --debug \
  --set imageName=${appImageName} \
  --set imagePullPolicy="Always" \
  --set replicas=1 \
  "./test"
