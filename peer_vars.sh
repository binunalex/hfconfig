NO_ORDERERS="1"
NO_ORGANIZATIONS="1"
NO_PEERS="5"
DOMAIN="dredev.de"
CONSORTIUM_NAME="WebConsortium"
ORDERERS="-o localhost:7050 --tls --ordererTLSHostnameOverride orderer1.dredev.de --cafile=./crypto-config/ordererOrganizations/dredev.de/orderers/orderer1.dredev.de/msp/tlscacerts/tlsca.dredev.de-cert.pem"
PEER_CON_PARAMS="--peerAddresses localhost:7051 --tlsRootCertFiles /root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator/crypto-config/peerOrganizations/org1.dredev.de/peers/peer0.org1.dredev.de/tls/ca.crt --peerAddresses localhost:8051 --tlsRootCertFiles /root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator/crypto-config/peerOrganizations/org1.dredev.de/peers/peer1.org1.dredev.de/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles /root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator/crypto-config/peerOrganizations/org1.dredev.de/peers/peer2.org1.dredev.de/tls/ca.crt --peerAddresses localhost:10051 --tlsRootCertFiles /root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator/crypto-config/peerOrganizations/org1.dredev.de/peers/peer3.org1.dredev.de/tls/ca.crt --peerAddresses localhost:11051 --tlsRootCertFiles /root/gopath/src/github.com/hyperledger/fabric-samples/Hyperledger-Fabric2-0-configurator/crypto-config/peerOrganizations/org1.dredev.de/peers/peer4.org1.dredev.de/tls/ca.crt "
CORE_PEER_LOCALMSPID=Org1MSP
CORE_PEER_TLS_ENABLED=true
CORE_PEER_TLS_ROOTCERT_FILE=./crypto-config/peerOrganizations/org1.dredev.de/peers/peer0.org1.dredev.de/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=./crypto-config/peerOrganizations/org1.dredev.de/users/Admin@org1.dredev.de/msp
export CORE_PEER_ADDRESS=localhost:7051
BASEPATH=$PWD/crypto-config
changeOrg(){
  org=$2
  peer=$1
  export baseport=$(( 7051+1000*(($NO_PEERS*($org -1))+$peer) ))
  export CORE_PEER_LOCALMSPID=Org${org}MSP
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_TLS_ROOTCERT_FILE=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/peers/peer0.org${org}.${DOMAIN}/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/users/Admin@org${org}.${DOMAIN}/msp
  export CORE_PEER_ADDRESS=localhost:${baseport}
}
