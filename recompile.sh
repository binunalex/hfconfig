#!/bin/bash

cd ../../fabric
docker rm -f $(docker ps -a -q)
docker rmi -f $(docker images -a -q)
make dist-clean all
make clean
make build
make docker
docker tag hyperledger/fabric-orderer:latest orderer:compiled
docker tag hyperledger/fabric-peer:latest peer:compiled
cd ../fabric-samples/Hyperledger-Fabric2-0-configurator/
