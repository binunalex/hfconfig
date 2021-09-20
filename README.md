We use Markdown: [link to Markdown](https://guides.github.com/features/mastering-markdown/#syntax)
<h1> Installation Instructions: </h1>

Install prerequisites:
	Java 11, https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04
	Python >= 3.7, https://linuxize.com/post/how-to-install-python-3-7-on-ubuntu-18-04/
	NodeJS 10 or 12, https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/
	Docker, https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/
	Golang, https://tecadmin.net/install-go-on-ubuntu/

Install Hyperledger Fabric Binaries and Samples: https://hyperledger-fabric.readthedocs.io/en/release-2.2/install.html#

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


	
