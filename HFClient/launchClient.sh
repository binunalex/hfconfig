#!/bin/bash
rm -rf CLI
mkdir -p CLI/src
cd CLI
cp ../*.sh .
cp ../pom.xml .
cp ../src/*.java src/
mkdir wallets
mvn clean
./cp_certs.sh 
mvn install
cp -f target/HFClient-0.0.1-SNAPSHOT-jar-with-dependencies.jar HFClient.jar
cp -f *.pem src
cp -f *.yaml src
cp -f HFClient.jar src
cd src/
java -cp HFClient.jar FabricService
