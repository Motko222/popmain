#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$(docker exec popmain ./pop --version | awk '{print $NF}' | sed 's/\r//g')
container=$(docker ps -a | grep "popmain" | awk '{print $NF}')
docker_status=$(docker inspect $container | jq -r .[].State.Status)
errors=$(docker logs popmain | grep -c -E "ERROR")

#json1=$(curl -sk https://localhost/health)
#mem_hits=$(echo $json1 | jq -r .memory_cache.hits)/$(echo $json1 | jq -r .memory_cache.misses)
#disk_hits=$(echo $json1 | jq -r .disk_cache.hits)/$(echo $json1 | jq -r .disk_cache.misses)

docker exec popmain ./pop status > /root/logs/pipemain-status
docker exec popmain ./pop earnings > /root/logs/pipemain-earnings
#docker exec popmain curl -s http://localhost:8081/health/detailed | jq > /root/logs/pipemain-health

status_node=$(cat /root/logs/pipemain-status | grep Status | head -1 | awk '{print $NF}')
last=$(cat /root/logs/pipemain-status | grep Heartbeat | head -1 | awk '{print $4" "$5" "$6}' \
 | sed 's/ seconds /s /' | sed 's/ minutes /m /' | sed 's/ hours /h /' | sed 's/ days /d /')
status_health=$(cat /root/logs/pipemain-health | jq -r .status)
unpaid=$(cat /root/logs/pipemain-earnings | grep Unpaid | head -1 | awk '{print $NF}')
total=$(cat /root/logs/pipemain-earnings | grep Total | head -1 | awk '{print $NF}')
wallet=$(cat /root/logs/pipemain-earnings | grep Wallet | head -1 | awk '{print $NF}')
quality=$(cat /root/logs/pipemain-earnings | grep "Quality Multiplier" | head -1 | awk '{print $NF}')
whitelist=$(cat /root/logs/pipemain-earnings | grep "Whitelist Bonus" | head -1 | awk '{print $5}')

status="ok" && message="$last heartbeat"
[ $errors -gt 500 ] && status="warning" && message="too many errors"
[ "$docker_status" != "running" ] && status="error" && message="docker not running ($docker_status)"
[ "$status_node" != "ONLINE" ] && status="warning" && message="not online"

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
       "id":"$folder-$ID",
       "machine":"$MACHINE",
       "grp":"node",
       "owner":"$OWNER"
  },
  "fields": {
        "chain":"pipe network",
        "network":"mainnet",
        "version":"$version",
        "status":"$status",
        "message":"$message",
        "errors":$errors,
        "url":"",
        "m1":"total=$total unpaid=$unpaid",
        "m2":"status=$status_node last=$last mem=$MEMORY_CACHE_SIZE_MB disk=$DISK_CACHE_SIZE_GB",
        "m3":"quality=$quality whitelist=$whitelist",
        "wallet":"$wallet"
  }
}
EOF

cat $json | jq
