#!/bin/bash

for x in $(docker ps -a | grep Exited | cut -c -12); do docker rm -f $x; done
for x in $(docker images -f "dangling=true" -q); do docker rmi $x; done
