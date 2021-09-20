We use Markdown and Ubuntu 18: [link to Markdown](https://guides.github.com/features/mastering-markdown/#syntax)

<h1> Installation Instructions: </h1>

<h2> Prerequisites: </h2>

First install [Java 11](https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04). <br>
Then install [Python 3.7](https://linuxize.com/post/how-to-install-python-3-7-on-ubuntu-18-04/) <br>
Install [NodeJS](https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/) <br>
Install [Docker](https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/) <br>
Install [Golang](https://tecadmin.net/install-go-on-ubuntu/) <br>

Assuming the $HOME variable points to your home directory, setup the Go-related environment variables as follows: <br>

export GOROOT=$HOME/go <br>
export GOPATH=$HOME/gopath <br>
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin <br>
export PATH=/root/gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH <br>

Install [Hyperledger Fabric Binaries and Samples](https://hyperledger-fabric.readthedocs.io/en/release-2.2/install.html#) <br>

The Go-related environment variables should be like these :

export GOROOT=$HOME/go
export GOPATH=$HOME/gopath
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=/root/gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

After installing, launch the Hyperledger Fabric:

. setContext 0 #here you set the "anchor peer"
./generateAll.sh

Wait for a while. Then run a client:

cd HFClient
./launchClient.sh

You will be running a few queries - moidfication and fetch


	
