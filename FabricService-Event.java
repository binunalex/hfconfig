import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.Properties;
import java.util.Random;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.TimeoutException;
import java.util.function.Consumer;

import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.ContractEvent;
import org.hyperledger.fabric.gateway.ContractException;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Identities;
import org.hyperledger.fabric.gateway.Identity;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;
import org.hyperledger.fabric.gateway.Wallets;
import org.hyperledger.fabric.protos.common.Common.Block;
import org.hyperledger.fabric.sdk.BlockEvent;
import org.hyperledger.fabric.sdk.BlockEvent.TransactionEvent;
import org.hyperledger.fabric.sdk.BlockInfo.TransactionEnvelopeInfo.TransactionActionInfo;
import org.hyperledger.fabric.sdk.BlockListener;
import org.hyperledger.fabric.sdk.ChaincodeID;
import org.hyperledger.fabric.sdk.Channel;
import org.hyperledger.fabric.sdk.HFClient;
import org.hyperledger.fabric.sdk.Peer;
import org.hyperledger.fabric.sdk.ProposalResponse;
import org.hyperledger.fabric.sdk.QueryByChaincodeRequest;
import org.hyperledger.fabric.sdk.TransactionProposalRequest;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.json.JSONArray;

public class FabricService {

    private Gateway gateway;
    private Wallet wallet;
    private Channel channel;
    private HFClient hfClient;
    private Network network;
    
    public static FabricService fabricService = null;
    public static ChaincodeID ccid = null;
    private static Set<String> peerNames = new HashSet<String>();
    private static String channelName = "mychannel";
    private static String contrName = "sacc";
    private static ConcurrentHashMap <String,HashSet<String>> txs = new ConcurrentHashMap <String,HashSet<String>>();
    private static ConcurrentHashMap <String,Long> txstarts = new ConcurrentHashMap <String,Long>();
    
    public static void hfquery(String key) {
		try {
			QueryByChaincodeRequest queryRequest = fabricService.getHfClient().newQueryProposalRequest();
			queryRequest.setChaincodeID(ccid);
			queryRequest.setFcn("get");

			String [] args = new String[]{"a"};
			queryRequest.setArgs(args);
			Collection<ProposalResponse> queryResponses = fabricService.getChannel().queryByChaincode(queryRequest);
		}
	   catch (Exception e) {
		  e.printStackTrace();
	   }

	}
    

    public static void hftransaction(String key,String value) {
    	long stt = System.currentTimeMillis();
      
		try {
			TransactionProposalRequest request = fabricService.getHfClient().newTransactionProposalRequest();
		  
			request.setChaincodeID(ccid);
			request.setFcn("set");               
				
			String[] arguments = new String[2];
			
			arguments[0]=key;
			arguments[1]=value;
			request.setArgs(arguments);
			
			Collection<ProposalResponse> responses = fabricService.getChannel().sendTransactionProposal(request);
			
			CompletableFuture<BlockEvent.TransactionEvent> cf = fabricService.getChannel().sendTransaction(responses);
			
			BlockEvent.TransactionEvent te = cf.get();
			
            System.out.println("TX Submitted: " + te.getTransactionID());
            txs.put(te.getTransactionID(), new HashSet<String>());
            txstarts.put(te.getTransactionID(), System.currentTimeMillis());
            long stt1 = System.currentTimeMillis()-stt;
            System.out.println("TX Returned : " + te.getTransactionID() + " in "+ stt1);
	   }
	   catch (Exception e) {
		   e.printStackTrace();
	   }

      
	}

    
    public static void main(String[] args) {
		if (fabricService==null)
			fabricService = new FabricService();
			
        String certFile = "ca.org1.dredev.de-cert.pem";
        String netConf = "connection_profile.yaml";
        
        try {

            Properties props = new Properties();
            props.put("pemFile", certFile);
            
          
            CAClient caClient = new CAClient(Config.CA_ORG1_URL, props);
            UserContext adminUserContext = caClient.getAdminUserContext();
            if (adminUserContext == null) {
              
                adminUserContext = new UserContext();
                adminUserContext.setName(Config.ADMIN);
                adminUserContext.setAffiliation(Config.ORG1);
                adminUserContext.setMspId(Config.ORG1_MSP);
                caClient.setAdminUserContext(adminUserContext);
                adminUserContext = caClient.enrollAdminUser(Config.ADMIN, Config.ADMIN_PASSWORD);
                System.out.println("The Admin is enrolled");
            }

          
            Identity identity = Identities.newX509Identity(adminUserContext.getMspId(),adminUserContext.getEnrollment());

            fabricService.setWallet(Wallets.newFileSystemWallet(Paths.get("wallets/")));
            fabricService.getWallet().put(adminUserContext.getName(), identity);

           
            Gateway.Builder gatewayBuilder = Gateway.createBuilder();
            
            fabricService.setGateway( gatewayBuilder.discovery(true)
                        .identity(fabricService.getWallet(), adminUserContext.getName())
                        .networkConfig(Paths.get(netConf))
                        .connect());
           
            CryptoSuite cryptoSuite = CryptoSuite.Factory.getCryptoSuite();
            fabricService.setHfClient(HFClient.createNewInstance());
            fabricService.getHfClient().setCryptoSuite(cryptoSuite);
            fabricService.getHfClient().setUserContext(adminUserContext);
            
            fabricService.setNetwork(fabricService.getGateway().getNetwork(channelName));
            fabricService.setChannel(fabricService.getNetwork().getChannel());
            Collection<Peer> peers = fabricService.getNetwork().getChannel().getPeers();
            for (Peer peer: peers) {
            	peerNames.add(peer.getName());
            	System.out.println(peer.getName());
            }
            
            
            
            BlockListener blockListener = new BlockListener() {         
                @Override
                public void received(BlockEvent arg0) {
                    Block block = arg0.getBlock();
                   
                    for (TransactionEvent transactionEvent : arg0.getTransactionEvents()) {
                    	String sid = transactionEvent.getTransactionID();
                    	String pr=transactionEvent.getPeer().getName();
                    	String chid=transactionEvent.getChannelId();
                    	long blkn = transactionEvent.getBlockEvent().getBlockNumber();
                    	int ec=transactionEvent.getTransactionActionInfoCount();
                    	System.out.println("Committed transaction id " + sid+" from peer " + pr + " on channel " + chid + " block " + blkn);
                    	
						}
                    }            

            };

            fabricService.getNetwork().getChannel().registerBlockListener(blockListener);
            
            if (ccid==null)
				ccid = ChaincodeID.newBuilder().setName(contrName).build();
            
            for (int i=0; i<10;i++) {
            	hftransaction("a","b"+i);
			}
            

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public FabricService(){

    }


    private Network getNetwork() {
        return network;
    }

    public void setGateway(Gateway gateway) {
        this.gateway = gateway;
    }

    public void setWallet(Wallet wallet) {
        this.wallet = wallet;
    }

    public void setChannel(Channel channel) {
        this.channel = channel;
    }

    public void setHfClient(HFClient hfClient) {
        this.hfClient = hfClient;
    }

    public void setNetwork(Network network) {
        this.network = network;
    }

    public Gateway getGateway() {
        return gateway;
    }

    public Wallet getWallet() {
        return wallet;
    }

    public Channel getChannel() {
        return channel;
    }

    public HFClient getHfClient() {
        return hfClient;
    }
}
