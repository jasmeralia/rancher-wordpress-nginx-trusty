#!/bin/bash

if [ "x$1" == "x" ]; then
  CACHE="--no-cache"
else
  CACHE=""
fi

DATE=$(date +%Y%m%d.%H%M)
echo "Building docker-wordpress-nginx:trusty.$DATE"
docker build $CACHE -t="stormerider/docker-wordpress-nginx:trusty.$DATE" . && \
echo "" && \
echo "Pushing docker-wordpress-nginx:trusty.$DATE" && \
docker push stormerider/docker-wordpress-nginx:trusty.$DATE

echo ""
echo "Building docker-wordpress-nginx:latest"
docker build -t="stormerider/docker-wordpress-nginx:latest" . && \
echo "" && \
echo "Pushing docker-wordpress-nginx:latest" && \
docker push stormerider/docker-wordpress-nginx:latest

echo ""
echo "Building docker-wordpress-nginx:xenial.$DATE"
docker build $CACHE -t="stormerider/docker-wordpress-nginx:xenial.$DATE" . -f Dockerfile-xenial && \
echo "" && \
echo "Pushing docker-wordpress-nginx:xenial.$DATE" && \
docker push stormerider/docker-wordpress-nginx:xenial.$DATE

echo ""
echo "Building docker-wordpress-nginx:xenial"
docker build -t="stormerider/docker-wordpress-nginx:xenial" . -f Dockerfile-xenial && \
echo "" && \
echo "Pushing docker-wordpress-nginx:xenial" && \
docker push stormerider/docker-wordpress-nginx:xenial
