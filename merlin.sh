#!/bin/bash
export CHANNEL_ID=mychannel		# Channel name
export VERSION=1				# Version of the Smart Contract
export FABRIC_CFG_PATH=$PWD		# This is where the core.yaml is located
source peer_vars.sh
MAINPROFILE=MainChannel
ORDERERPROFILE=OrdererDefault
BASEPATH=$PWD/crypto-config
CHAINCODES=("fabric-orionACL" "fabric-authtoken" "fabric-transaction-log")
CC_SRC_PATH=./chaincodes/go
SLEEPINTERVAL=1
LINE="=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<"
NOCOLOR='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
IFS=$'\n' read -d '' -r -a ccodes < chaincodes.txt

if [[ -z ${OUTPUTDEV} ]]; then
	OUTPUTDEV=/dev/stdout
fi

generateCryptoStuff(){
		
	 	echo -e "${PURPLE}>>> Generating Crypto Material ${NOCOLOR}"
		cryptogen generate --config=./crypto-config.yaml
		echo -e "${ORANGE}[*] Generating channel.tx, genesis.block, anchor peers ${NOCOLOR}"
		configtxgen -profile $ORDERERPROFILE -outputBlock ./config/genesis.block -channelID ordererchannel > ${OUTPUTDEV}
		if [ -f ./config/genesis.block ]; then
				echo -e "		${GREEN}[+] genesis.block created ${NOCOLOR}"
		else
				echo -e "		${RED}[-] genesis.block not created ${NOCOLOR}"
				return 1
		fi
		configtxgen -profile $MAINPROFILE -outputCreateChannelTx ./config/channel.tx -channelID ${CHANNEL_ID} > ${OUTPUTDEV}
		if [ -f ./config/channel.tx ]; then
				echo -e "		${GREEN}[+] channel.tx created ${NOCOLOR}"
		else
				echo -e "		${RED}[-] channel.tx not created ${NOCOLOR}"
				return 1
		fi
		for (( i = 1; i <= $NO_ORGANIZATIONS; i++ )); do
			configtxgen -profile $MAINPROFILE -outputAnchorPeersUpdate ./config/Org${i}MSPanchors.tx -channelID ${CHANNEL_ID} -asOrg Org${i}MSP > ${OUTPUTDEV}
			if [ -f ./config/Org${i}MSPanchors.tx ]; then
					echo -e "		${GREEN}[+] anchor peers for Org${i}MSP created ${NOCOLOR}"
			else
					echo -e "		${RED}[-] anchor peers not created ${NOCOLOR}"
					return 1
			fi
		done
		echo -e "${GREEN}[+] Generating channel.tx, genesis.block, anchor peers ${NOCOLOR}"
		return 0
}

changeOrg(){
	org=$2
	peer=$1

	export baseport=$(( 7051+1000*(($NO_PEERS*($org -1))+$peer) ))
	export CORE_PEER_LOCALMSPID=Org${org}MSP
	export CORE_PEER_TLS_ENABLED=true
	export CORE_PEER_TLS_ROOTCERT_FILE=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/peers/peer0.org${org}.${DOMAIN}/tls/ca.crt
	export CORE_PEER_MSPCONFIGPATH=$BASEPATH/peerOrganizations/org${org}.${DOMAIN}/users/Admin@org${org}.${DOMAIN}/msp
	export CORE_PEER_ADDRESS=localhost:${baseport}
	#echo -e "${CYAN}>>> Changed Org: Org$org Peer$peer ${NOCOLOR}"
}

startDocker(){
	
	echo -e "${PURPLE}>>> I will now start all the containers! Docker do your thing!${NOCOLOR}"
	docker-compose up -d
	echo -e "${PURPLE}>>> Now please give the containers a short amount of time to start. Some Seconds should be enough"
}

createChannel(){
	
	changeOrg 0 1
	if [ ! -f ./config/channel.tx ]; then
			echo -e "${RED}>>> HEY! channel.tx is missing! Generate it first. Aborting"
			return 1
	fi
	set -x
	peer channel create ${ORDERERS} -c ${CHANNEL_ID} -f ./config/channel.tx > ${OUTPUTDEV}
	set +x
	if [ $? -eq 1 ]; then
			echo -e "${PURPLE}>>> Ok second try ${NOCOLOR}"
			sleep $SLEEPINTERVAL
			peer channel create ${ORDERERS} -c ${CHANNEL_ID} -f ./config/channel.tx > ${OUTPUTDEV}
	fi
	echo -e "${PURPLE}>>> Is the block there?"
	if [ $(ls | grep ${CHANNEL_ID}.block) == "${CHANNEL_ID}.block" ]; then
		echo -e "${GREEN}[+] Yes it is, ${CHANNEL_ID}.block"
	else
		echo -e "${RED}[-] No, something went wrong, aborting"
	fi
}

joinChannel(){
		
		echo -e "${ORANGE}[*] Start Joining of Channel ${CHANNEL_ID} ${NOCOLOR}"
		for (( org = 1; org <= $NO_ORGANIZATIONS; org++ )); do
			for (( peer = 0; peer < $NO_PEERS; peer++ )); do
					changeOrg $peer $org
					echo -e "		${ORANGE}[*] Attempting Channel join for peer${peer}.org${org}.${DOMAIN} ${NOCOLOR}"
					peer channel join --tls ${CORE_PEER_TLS_ENABLED} -b ${CHANNEL_ID}.block > ${OUTPUTDEV}
					if [ $? -eq 1 ]; then
							echo -e "		${RED}[-] Channel join failed on peer${peer}.org${org}.${DOMAIN} ${NOCOLOR}"
							return 1
					else
							echo -e "		${GREEN}[+] Channel join succeeded on peer${peer}.org${org}.${DOMAIN} ${NOCOLOR}"
					fi
			done
		done
		echo -e "${GREEN}[+] Joining succeeded ${NOCOLOR}"
		return 0
}

updateAnchors(){
	
	echo -e "${PURPLE}>>> Now we need to update the Anchor peers, to tell them, that they are important for us,\n since they serve as the gateway peers for all the others. ${NOCOLOR}"
	for (( org = 1; org <= $NO_ORGANIZATIONS; org++ )); do
		echo -e "		${ORANGE}[*] Attempting Anchor Update for peer0.org${org}.${DOMAIN} ${NOCOLOR}"
		changeOrg 0 ${org}		# Default Peer0 is always the Anchor
		peer channel update ${ORDERERS} -c ${CHANNEL_ID} -f ./config/Org${org}MSPanchors.tx > ${OUTPUTDEV}
		if [ $? -eq 1 ]; then
				echo -e "		${RED}[-] Anchor Update failed on peer0.org${org}.${DOMAIN} ${NOCOLOR}"
				return 1
		else
				echo -e "		${GREEN}[+] Anchor Update succeeded on peer0.org${org}.${DOMAIN} ${NOCOLOR}"
		fi
	done
	return 0
}

packCC(){
	
	# Read the contents into the array
	# IFS=$'\n' read -d '' -r -a ccodes < chaincodes.txt
	if [ ${#ccodes[@]} -eq 0 ]; then
		echo -e "${LIGHTCYAN}	[i] No Chaincode to install, skipping"
	else
  
		echo -e "${ORANGE}[*] Start packaging... ${NOCOLOR}"

		for chaincode in "${ccodes[@]}"
		do
			echo -e "${ORANGE}	[*] Attempting packing of ${chaincode} Chaincode"
            peer lifecycle chaincode package ${chaincode}.tar.gz --path ${CC_SRC_PATH}/${chaincode} --lang golang --label ${chaincode}_${VERSION}
			#peer lifecycle chaincode package ${chaincode}.tar.gz --path ${CC_SRC_PATH}/${chaincode}/build/libs --lang java --label ${chaincode}_${VERSION} > ${OUTPUTDEV}
			if [ $? -eq 1 ]; then
					echo -e "		${RED}[-] Packing of ${chaincode} Chaincode failed ${NOCOLOR}"
					return 1
			else
					echo -e "		${GREEN}[+] Packing of ${chaincode} Chaincode succeeded ${NOCOLOR}"
			fi
		done
		echo -e "${GREEN}[+] Packing complete! ${NOCOLOR}"
	fi
	return 0
}

installCC(){
	
	if [ ${#ccodes[@]} -eq 0 ]; then
		echo -e "${LIGHTCYAN}	[i] No Chaincode to install, skipping"
	else
		echo -e "${PURPLE}\n>>> The Chaincodes is now being installed on each peer ${NOCOLOR}"
		echo -e "${ORANGE}[*] Start installing... \n${NOCOLOR}"
		for (( org = 1; org <= $NO_ORGANIZATIONS; org++ )); do
			for (( peer = 0; peer < $NO_PEERS; peer++ )); do
				changeOrg $peer $org
				echo -e "	${ORANGE}[*] Attempting install on peer${peer}.org${org}.${DOMAIN} ${NOCOLOR}"
				for chaincode in "${ccodes[@]}"
				do
					echo $"{PWD}"
					peer lifecycle chaincode install ${chaincode}.tar.gz > ${OUTPUTDEV}
					if [ $? -eq 1 ]; then
							echo -e "		${RED}[-] Install of ${chaincode} Chaincode on peer${peer}.org${org}.${DOMAIN} failed!${NOCOLOR}"
							return 1
					fi
				done
				echo -e "${GREEN}	[+] Install on peer${peer}.org${org}.${DOMAIN} ${NOCOLOR} finished \n"
			done
		done
		echo -e "${GREEN}[+] Installing finished ${NOCOLOR}"
		echo -e "${PURPLE}>>> Alright everything seems to be installed, lets verify! ${NOCOLOR}"
		changeOrg 0 1				# peer0.org1.domain
		peer lifecycle chaincode queryinstalled >&log.txt
		if [ $? -eq 1 ]; then
				echo -e "		${RED}[-] Query of Chaincode on peer0.org1.${DOMAIN} failed!${NOCOLOR}"
				return 1
		fi
		cat log.txt
		echo -e "${PURPLE}>>> Package Identifiers: ${NOCOLOR}"
		for chaincode in "${ccodes[@]}"
		do
		    tmp=$(sed -n "/${chaincode}_1/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
			echo -e "${LIGHTBLUE}>>> [>] ${chaincode}: ${tmp}  ${NOCOLOR}"	# indirect, allows to treat CID as a var name
		done
	fi
	return 0
}

approveCC(){
	
	if [ ${#ccodes[@]} -eq 0 ]; then
		echo -e "${LIGHTCYAN}	[i] No Chaincode to install, skipping"
	else
		echo -e "${PURPLE}>>> Now the installed Chaincodes need to be approved by the Orderers and the Organizations! ${NOCOLOR}"
		echo -e "${ORANGE}[*] Start approving... ${NOCOLOR}"
		for (( org = 1; org <= $NO_ORGANIZATIONS; org++ )); do
			changeOrg 0 $org
			for chaincode in "${ccodes[@]}"
			do
				CID=${chaincode}_ID
				changeOrg 0 $org
				echo -e "${ORANGE}		[*] Org${org} is approving ... ${NOCOLOR}"
				peer lifecycle chaincode approveformyorg ${ORDERERS} --channelID ${CHANNEL_ID} --name $chaincode --version ${VERSION} --package-id $(sed -n "/${chaincode}_1/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt) --sequence ${VERSION} --waitForEvent > ${OUTPUTDEV}
				if [ $? -eq 1 ]; then
						echo -e "		${RED}	[-] Org${org} did not approve ${chaincode} Chaincode! ${NOCOLOR}"
						return 1
				fi
			done
		done
		echo -e "${GREEN}[+] Approving complete. ${NOCOLOR}"
	fi
	return 0
}

checkCommitReadiness(){
	
	if [ ${#ccodes[@]} -eq 0 ]; then
		echo -e "${LIGHTCYAN}	[i] No Chaincode to install, skipping"
	else
		echo -e "${PURPLE}>>> Now that the chaincodes are approved by each organization, they need to be committed. First lets check for the commit readiness! ${NOCOLOR}"
		changeOrg 0 1			#peer0.org1
		#changeOrg $peer $org
		for chaincode in "${ccodes[@]}"
		do
			echo -e "${ORANGE}		[*] Checking commit readiness for ${chaincode}... ${NOCOLOR}"
			peer lifecycle chaincode checkcommitreadiness --channelID ${CHANNEL_ID} --name ${chaincode} --version ${VERSION} --sequence ${VERSION} --output json > ${OUTPUTDEV}
			if [ $? -eq 1 ]; then
					echo -e "		${RED}	[-] ${chaincode} not ready to be committed! ${NOCOLOR}"
					return 1
			fi
		done
		echo -e "${PURPLE}>>> JSON with true everywhere? "
	fi
	return 0

}

commitCC(){
	
	if [ ${#ccodes[@]} -eq 0 ]; then
		echo -e "${LIGHTCYAN}	[i] No Chaincode to install, skipping"
	else
		echo -e "${PURPLE}>>> Alright, final step now. Lets commit all of the Chaincodes! ${NOCOLOR}"
		changeOrg 0 1 		# peer0.org1
		#changeOrg $peer $org
		echo -e "${ORANGE}	[*] Start committing... ${NOCOLOR}"
		for chaincode in "${ccodes[@]}"
		do
			echo -e "${ORANGE}		[*] Commit ${chaincode}... ${NOCOLOR}"
			peer lifecycle chaincode commit ${ORDERERS} --channelID ${CHANNEL_ID} --name ${chaincode} $PEER_CON_PARAMS --version ${VERSION} --sequence ${VERSION} > ${OUTPUTDEV}
			if [ $? -eq 1 ]; then
					echo -e "		${RED}	[-] ${chaincode} could not be committed! ${NOCOLOR}"
					return 1
			fi
		done


		echo -e "${GREEN}	[+] Committing complete! ${NOCOLOR}"

		echo -e "${PURPLE}>>> Everything seems to be installed, lets see"

		echo -e "\n${LIGHTCYAN} =<=<=<=<=<=<=<=<=<=<=<=<=<=<= Chaincodes <=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=\n"
		for chaincode in "${ccodes[@]}"
		do
			peer lifecycle chaincode querycommitted --channelID ${CHANNEL_ID} --name ${chaincode} > ${OUTPUTDEV}
		done
		echo -e "\n${LIGHTCYAN} =<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<=<="
	fi
}

writeScripts(){
	QUERYFILE=getval.sh
	INVOKEFILE=setval.sh

	echo -e "${PURPLE}\n>>> I will create an invoke script for you! ${NOCOLOR}"
	if [ -f $INVOKEFILE ]; then
		rm $INVOKEFILE
	fi
	echo -e "#!/bin/bash" >> $INVOKEFILE
	
	echo -e "CHANNEL_ID=$CHANNEL_ID" >> $INVOKEFILE
	echo -e "source peer_vars.sh" >> $INVOKEFILE
	echo -e "changeOrg \$NODENUMBER 1" >> $INVOKEFILE

	echo -e "SMARTCONTRACT=$CHAINCODE" >> $INVOKEFILE
	echo -e "K=\$1" >> $INVOKEFILE
	echo -e "V=\$2" >> $INVOKEFILE
	
	echo -e "peer chaincode invoke \$ORDERERS -C \$CHANNEL_ID -n \$SMARTCONTRACT \$PEER_CON_PARAMS -c \"{\\\"Args\\\": [\\\"Args\\\",\$K,\$V]}\"" >> $INVOKEFILE
	chmod +x $INVOKEFILE
	echo -e "${GREEN}[+] $INVOKEFILE created successfully"

	
	if [ -f $QUERYFILE ]; then
		rm $QUERYFILE
	fi
	echo -e "#!/bin/bash" >> $QUERYFILE
	
	echo -e "CHANNEL_ID=$CHANNEL_ID" >> $QUERYFILE
	echo -e "source peer_vars.sh" >> $QUERYFILE
	echo -e "changeOrg \$NODENUMBER 1" >> $QUERYFILE
	
	echo -e "SMARTCONTRACT=$CHAINCODE" >> $QUERYFILE
	echo -e "K=\$1" >> $QUERYFILE
	
	echo -e "peer chaincode invoke \$ORDERERS -C \$CHANNEL_ID -n \$SMARTCONTRACT \$PEER_CON_PARAMS -c \"{\\\"Args\\\": [\\\"Args\\\",\$K]}\"" >> $QUERYFILE
	chmod +x $QUERYFILE

	echo -e "${GREEN}[+] $QUERYFILE created successfully"
}

start(){

	which configtxgen
	if [ "$?" -eq 0 ]
	then
			echo -e "${GREEN}[+] Configtxgen installed!"
	else
			echo -e "${RED}[-] Configtxgen not installed!"
			return 1
	fi

	which peer
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}[-] peer not installed!"
		return 1
	else
		echo -e "${GREEN}[+] peer installed!"
	fi

	which cryptogen &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}[-] cryptogen not installed!"
		return 1
	else
		echo -e "${GREEN}[+] cryptogen installed!"
	fi

	which docker-compose &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}[-] docker-compose not installed!"
		return 1
	else
		echo -e "${GREEN}[+] docker-compose installed!"
	fi

	which ls &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}[-] ls not installed!"
		return 1
	else
		echo -e "${GREEN}[+] ls installed!"
	fi

	which grep &> /dev/null
	if [ "$?" -ne 0 ]; then
		echo -e "${RED}[-] grep not installed!"
		return 1
	else
		echo -e "${GREEN}[+] grep installed!"
	fi
	echo -e "${GREEN}>>> Great! Every needed tool is installed! \n"
	echo -e "${PURPLE}>>> Check the files!"
	if [ ! -f core.yaml ]; then
			echo -e "${RED}>>> core.yaml missing - aborting"
			return 1
	elif [ ! -f crypto-config.yaml ]; then
			echo -e "${RED}>>> crypto-config.yaml missing - aborting"
			return 1
	elif [ ! -f configtx.yaml ]; then
			echo -e "${RED}>>> configtx.yaml missing - aborting"
			return 1
	elif [ ! -f docker-compose.yaml ]; then
			echo -e "${RED}>>> docker-compose.yaml missing - aborting"
			return 1
	elif [ ! -f .env ]; then
			echo -e "${RED}>>> .env missing - aborting"
			return 1
	else
			echo -e "${GREEN}>>> Alright everything is fine! I will now clean the unnecessary old files"
			rm -rf config crypto-config fabric-* log.txt
			echo -e "${PURPLE}>>> Should be fine now, here we go!"
			return 0
	fi
}


# The startup routine.
# Merlin is initialized and checks all of the necessary tools like configtxgen. It will SampleConsortium
# Clean up all old waste, which would later be overwritten. So be sure to backup anything you want to safe!
start
if [ $? -eq 1 ]; then
		return 1
fi

rm -rf *tar.gz


# The Crypto Generation
# Merlin will create all the necessary certificates and credentials for the different nodes of the network
generateCryptoStuff
if [ $? -eq 1 ]; then
		return 1
fi

# The Docker Start
# Merlin will automatically create all of the defined Docker Containers within the docker-compose.yaml file.
# The Containers need some time to start, so be sure to give some seconds of sleep until you continue!
startDocker
sleep 15

# The Channel Creation
# Merlin will now create a new Channel called $CHANNEL_ID. This depends on the Crypto Cerficates from
# the Crypto Generation step!
createChannel
sleep $SLEEPINTERVAL

# The Channel Join
# Merlin will then automatically join the newly created channel on each peer within the network!
joinChannel
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The Update of the Anchor peers
# After each peer had joined the channel, the corresponding anchor peers need to be updated as well.
# Those are important for the communication across organizations.
updateAnchors
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The Packing of the Chaincode
# After the Channel is setup, the Chaincode can be packaged. This involves a compilation step
# in conjunction with the new lifecycle package method.
packCC
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The Install of the Chaincode
# After the Chaincode has been packaged, it can be installed onto each Client by Merlin.
# This is done with the new lifecycle install method
installCC
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The Approval of the Chaincode
# Each organization need to approve the previously installed chaincode with its attributes!
# Merlin issues requests to each Organization
approveCC
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The Pre-Commit Step
# Merlin will check if each Organization is ready to commit the Chaincode onto the ledger
checkCommitReadiness
if [ $? -eq 1 ]; then
		return 1
fi
sleep $SLEEPINTERVAL

# The final Commit
# The Chaincode gets committed onto the ledger! Now everything should be good to go.
commitCC
if [ $? -eq 1 ]; then
		return 1
fi

#writeScripts

echo -e "${GREEN}\n>>> ALL DONE !!! Happy interacting"

