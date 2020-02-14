#!/bin/bash

source ../venv/bin/activate
../md.py < foo.md > index.html
docker build -t quickstart .
for x in $(docker ps -a | grep -E "[0-9a-f]{12}\s+quickstart" | cut -c -12); do
    docker rm -f $x
done
docker run -d -p 8000:80 quickstart
