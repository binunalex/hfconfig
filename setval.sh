#!/bin/bash
CHANNEL_ID=mychannel
source peer_vars.sh
changeOrg $NODENUMBER 1
SMARTCONTRACT=sacc
K=$1
V=$2
peer chaincode invoke $ORDERERS -C $CHANNEL_ID -n $SMARTCONTRACT $PEER_CON_PARAMS -c "{\"Args\": [\"Args\",$K,$V]}"
