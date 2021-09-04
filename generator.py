import argparse
import os
from generator_scripts.format import bcolors, NetworkConfiguration
from generator_scripts.gen_configtx import generate_configtx
from generator_scripts.gen_connection_profile import generate_connection_profile
from generator_scripts.gen_crypto_config import generate_crypto_config
from generator_scripts.gen_docker_compose import generate_docker_compose
from generator_scripts.gen_core import generate_core
from generator_scripts.gen_env import generate_env

CHAINCODE=os.getenv('CHAINCODE')  # 'sacc'

config = NetworkConfiguration(_orderer_defport=7050,_peer_defport=7051,_ca_defport=7054,_couchdb_defport=5984,_network_name="byfn",_ordering_service="raft")
orderers=1
orgs=1
peers=5
kafka=-1
domain="dredev.de"
consortium="WebConsortium"
blocksize=10
timeout=1
compose_name="net"

def generate_chaincode_entries():
	fp=open("chaincodes.txt", "w")
	fp.write(CHAINCODE + "\n")
	fp.close()

if __name__ == '__main__':

    try:
        f = open("docker-compose.yaml")
        f.close()
        print("A Docker compose file, Lets stop it!")
        os.system("docker-compose down --volumes --remove-orphans")
        os.system("docker container rm $(docker container ls -a | grep dev-peer)")
        os.system("docker images -a | grep 'dev-peer' | awk '{print $3}' | xargs docker rmi")
    # Do something with the file
    except IOError:
        pass

    print(bcolors.FAIL + ">>> Alright, now let's go! <<< ")
    generate_chaincode_entries()
    print(">>> Need a file called '.env")
    generate_env(compose_name)
    print( ">>> Now lets create the Crypto Config File!")
    if kafka < 0:
        kafka = False
        config.ordering_service = "raft"
        print( "USING RAFT")
    else:
        kafka = True
        config.ordering_service = "kafka"
        print("USING KAFKA")

    generate_crypto_config(_peers=peers,_domain=domain,_orderers=orderers,_orgs=orgs)
    print(bcolors.HEADER + ">>> Crypto Config has been created.")
    generate_configtx(_network_config=config,_orgs=orgs,_orderers=orderers,_domain=domain,_kafka_brokers=kafka,_consortium=consortium,_blocksize=blocksize,_timeout=timeout)
    print(bcolors.HEADER + ">>> config.tx has been created. Now generate the Docker-compose file.")
    generate_docker_compose(_network_config=config,_orderers=orderers,_orgs=orgs,_peers=peers,_domain=domain,_kafka_nodes=kafka)
    print(bcolors.HEADER + ">>> docker-compose.yaml has been created. Now finally generate the core.yaml file.")
    generate_core()
    print(bcolors.HEADER + ">>> core.yaml has been created.")
    generate_connection_profile(_network_config=config,_peers=peers,_orgs=orgs,_orderers=orderers,_domain=domain)
    print(bcolors.HEADER + ">>> All done, you can proceed with Merlin")
    # Setting some Env Variable
    basic_vars = [
        f"NO_ORDERERS=\"{orderers}\"\n",
        f"NO_ORGANIZATIONS=\"{orgs}\"\n",
        f"NO_PEERS=\"{peers}\"\n",
        f"DOMAIN=\"{domain}\"\n"
        f"CONSORTIUM_NAME=\"{consortium}\"\n",
        f"ORDERERS=\"{os.environ['ORDERERS']}\"\n",
        f"PEER_CON_PARAMS=\"{os.environ['PEER_CON_PARAMS']}\"\n",
    ]

    connection_params = [
        "CORE_PEER_LOCALMSPID=Org1MSP\n",
        "CORE_PEER_TLS_ENABLED=true\n",
        f"CORE_PEER_TLS_ROOTCERT_FILE=./crypto-config/peerOrganizations/org1.{domain}/peers/"
        f"peer0.org1.{domain}/tls/ca.crt\n",
        f"CORE_PEER_MSPCONFIGPATH=./crypto-config/peerOrganizations/org1.{domain}/users/"
        f"Admin@org1.{domain}/msp\n",
        f"export CORE_PEER_ADDRESS=localhost:{config.peer_defport}\n",
        "BASEPATH=$PWD/crypto-config\n"
    ]
    if kafka:
        basic_vars.append(f"NO_KAFKA=\"{kafka}\"")


    y = "y" #input(bcolors.FAIL + "Start Merlin now? [y/n]")
    if y == "y":
        out = "y" # input(bcolors.FAIL + "Do you want Debug output? [y/n]")
        if out == "n":
            basic_vars.append("OUTPUTDEV=/dev/null\n")
        with open("peer_vars.sh", "w+") as con:
            
            con.writelines(basic_vars)
            con.writelines(connection_params)
            co = ["changeOrg(){\n",
                  "  org=$2\n",
                  "  peer=$1\n",
                  "  export baseport=$(( 7051+1000*(($NO_PEERS*($org -1))+$peer) ))\n",
                  "  export CORE_PEER_LOCALMSPID=Org${org}MSP\n",
                  "  export CORE_PEER_TLS_ENABLED=true\n",
                  "  export CORE_PEER_TLS_ROOTCERT_FILE=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/peers/"
                  "peer0.org${org}.${DOMAIN}/tls/ca.crt\n",
                  "  export CORE_PEER_MSPCONFIGPATH=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/users/"
                  "Admin@org${org}.${DOMAIN}/msp\n",
                  "  export CORE_PEER_ADDRESS=localhost:${baseport}\n"
                  "}\n"]
            con.writelines(co)
        os.system("bash merlin.sh")
    else:
        print(bcolors.HEADER + "Alright, Quitting")
