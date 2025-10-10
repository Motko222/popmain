#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source $path/env
cd $path

docker stop popmain
docker rm popmain

docker run -d \
  --name popmain \
  --env-file env \
  -p 80:80 \
  -p 443:443 \
  -v /opt/popmain:/app \
  -w /app \
  --restart unless-stopped \
  popmain

sleep 1s
docker logs -f popmain
