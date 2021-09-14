#!/bin/bash

docker rm -f $(docker ps -a -q)
#docker rmi -f $(docker images -a -q)
#./samples.sh

python3 generator.py
