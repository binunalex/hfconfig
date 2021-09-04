#!/bin/bash

source peer_vars.sh
changeOrg $NODENUMBER 1

peer chaincode invoke $ORDERERS -C $CHANNEL_ID -n $CHAINCODE $PEER_CON_PARAMS -c "{\"Args\": [\"query\", $1]}"

