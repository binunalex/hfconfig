<h1> Installation Instructions: </h1>

<h2> Prerequisites: </h2>

Assume the $HOME variable points to your home directory. <br>
Update the distribution: ```sudo apt-get -y update && sudo apt-get -y upgrade```  <br>
Install the C++ developer tools: ```sudo apt-get -y update && sudo apt-get -y install build-essential maven```  <br>
Install [Java SDK 11](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04). <br>
Then install [Python 3.7](https://linuxize.com/post/how-to-install-python-3-7-on-ubuntu-18-04/). In addition install the following packets: <br>
```pip3 install ruamel.yaml```

Remove the previous NodeJS installations: <br>
```apt-get purge --auto-remove nodejs npm``` <br>

Install [NodeJS, version 12](https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/) <br>
Install [the latest Docker](https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04) and [Docker Compose](https://docs.docker.com/compose/install/).<br>
Make sure that Docker-related commands like **docker ps** (listing all containers) run without using [root privileges](https://github.com/sindresorhus/guides/blob/main/docker-without-sudo.md). <br>
Download and install Golang. This is 1.16.4 but you may get the latest one from [here](https://golang.org/dl/) <br>

```wget https://dl.google.com/go/go1.16.4.linux-amd64.tar.gz``` <br>
```sudo tar -xvf go1.16.4.linux-amd64.tar.gz```<br>


Now your Go distribution resides in $HOME/go. <br>

Create the folder **gopath** you will out all your Go projects into: <br>
```mkdir -p $HOME/gopath/src/github.com/hyperledger``` <br>
```cd $HOME/gopath/src/github.com/hyperledger```   <br>

Install [Hyperledger Fabric Binaries and Samples](https://hyperledger-fabric.readthedocs.io/en/release-2.2/install.html#) into the above mentioned folder: <br>
``` curl -sSL https://bit.ly/2ysbOFE | bash -s ```

**Login as root (su -)** and configure the Go-related environment variables as follows: <br>

``` echo 'GOROOT=$HOME/go' >> ~/.bashrc ``` 	<br>
``` echo 'GOPATH=$HOME/gopath' >> ~/.bashrc ``` <br>
``` mkdir -p $GOROOT/bin && mkdir -p $GOPATH/bin``` <br> 
``` echo 'PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> ~/.bashrc ``` <br> 
``` echo 'PATH=$HOME/gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH' >> ~/.bashrc```  <br>
``` source ~/.bashrc ```

<h3> Install Hyperledger Fabric from sources: </h3>

This section is optional and we will use it only in advanced stages when Hyperledger behavior will be altered. 

Change the directory into the Fabric projects:
``` cd $HOME/gopath/src/github.com/hyperledger ```

Download the source code as described [here](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04): <br>
``` git clone https://github.com/hyperledger/fabric.git```  <br>
``` cd $GOPATH/src/github.com/hyperledger/fabric ```   <br>

To rebuild the entire Hyperledger distribution from scratch, you have to run the commands: <br>
``` make dist-clean all ```  <br>
``` make clean ```  <br>
``` make build ```  <br>
``` make docker ```  <br>

After finishing the process run the command ``` docker images ``` and you will find the most up-to-date Docker images for Hyperledger. They are preceded by
the **hyperledger/** word, like **hyperledger/fabric-orderer**. These images will appear in the **images** section of a file **docker-compose.yaml**. that will be used in any setting representing a Hyperledger instance as a Docker Compose swarm.



<h2> Launch the local Hyperledger prototype: </h2>

Clone the example repository into the folder and set up the environment: <br>
``` cd $HOME/gopath/src/github.com/hyperledger/fabric-samples``` <br>
``` git clone https://github.com/binunalex/hfconfig.git ```   <br>
``` cd hfconfig```   <br>

**Login as ROOT** and update the environment: <br>
``` echo "PROTPATH=$(pwd)" >> ~/.bashrc```   <br>
``` source ~/.bashrc```   <br>


Then run the following commands as the root user: <br>
```echo "127.0.0.1 ca.org1.dredev.de" >> /etc/hosts``` <br>
```echo "127.0.0.1 orderer1.dredev.de" >> /etc/hosts``` <br>
```for i in {0..10}``` <br>
```do```<br>
	```echo "127.0.0.1 peer$i.org1.dredev.de" >> /etc/hosts``` <br> 
```done```<br>

This script associates the DNS names of all Hyperledger members (peers,orderers etc) with the local IP. The associations are published in the file **/etc/hosts**. That is, the entire Hyperledger runs locally. In the future we will set different IPs, making Hyperledger run on a cloud.

Set the working directory: ```cd $GOPATH/src/github.com/hyperledger/fabric-samples/hfconfig```.  <br>
Now launch the prototype:  <br> 
  
``` . setContext.sh 0 ``` <br> 
``` ./generateAll.sh```   <br> 

Wait for a while. Then run a client:  <br> 

``` cd HFClient```   <br> 
```./launchClient.sh```  <br> 

You will be running a few queries - modification and fetch.


<h2> Time To Commit: </h2>

When a transaction is sent from a client, Hyperledger Fabric accepts it and sends the response back to the client, **before the transaction is added to block and committed**. This is called "time to response". However, often we want to know not only time to response for a transaction, but also the time to its commit. This is called "time to finality". 

We can record time to finality via the BlockListener interface, look at my example, Line 162-176. Record the time to finality for a few transactions and compare it to "time to return" recorded in Lines 93-97.
