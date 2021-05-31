#!/bin/bash
docker run -d --rm  -p 1024:1024 --name cb-spider -v "$(pwd)/data/spider:/data" -e CBSTORE_ROOT=/data cloudbaristaorg/cb-spider:v0.3.0-espresso
docker run -d --rm  -p 1323:1323 --name cb-tumblebug --link cb-spider:cb-spider -v "$(pwd)/data/tumblebug/conf:/app/conf" -v "$(pwd)/data/tumblebug/meta_db:/app/meta_db/dat" -v "$(pwd)/data/tumblebug/log:/app/log" cloudbaristaorg/cb-tumblebug:v0.3.0-espresso
docker run -d --rm -p 8080:8080 --name cb-ladybug --link cb-spider:cb-spider --link cb-tumblebug:cb-tumblebug -v "$(pwd)/data/ladybug:/data" -e SPIDER_URL=http://cb-spider:1024/spider -e TUMBLEBUG_URL=http://cb-tumblebug:1323/tumblebug -e CBSTORE_ROOT=/data cloudbaristaorg/cb-ladybug:v0.3.0-espresso
docker ps