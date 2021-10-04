#!/bin/bash
#RES="src/main/resources/fabricConfig"
#FABRIC_LOC="/root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator"
#FABRIC_LOC="$/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator"
# CA
rm wallets/*
rm *.jar
#cp -f ${FABRIC_LOC}/crypto-config/peerOrganizations/org1.dredev.de/ca/ca.org1.dredev.de-cert.pem ${RES}
cp -f ${PROTPATH}/crypto-config/peerOrganizations/org1.dredev.de/ca/ca.org1.dredev.de-cert.pem .
# Connection Profile
#cp -f ${FABRIC_LOC}/connection_profile.yaml ${RES}
cp -f ${PROTPATH}/connection_profile.yaml .
