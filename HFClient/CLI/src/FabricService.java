import java.nio.file.Paths;
import java.util.Collection;
import java.util.Properties;
import java.util.Random;
import java.util.concurrent.CompletableFuture;
// https://medium.com/@lkolisko/tutorial-invoking-chaincode-from-hyperledger-fabric-java-sdk-e8dea535a1be
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Identities;
import org.hyperledger.fabric.gateway.Identity;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;
import org.hyperledger.fabric.gateway.Wallets;
import org.hyperledger.fabric.sdk.BlockEvent;
import org.hyperledger.fabric.sdk.ChaincodeID;
import org.hyperledger.fabric.sdk.Channel;
import org.hyperledger.fabric.sdk.HFClient;
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
    
    
    public static void hfquery(String key) {
		try {
			QueryByChaincodeRequest queryRequest = fabricService.getHfClient().newQueryProposalRequest();
			queryRequest.setChaincodeID(ccid);
			queryRequest.setFcn("get");

			String [] args = new String[]{"a"};
			queryRequest.setArgs(args);
			//long stt = System.currentTimeMillis();
			Collection<ProposalResponse> queryResponses = fabricService.getChannel().queryByChaincode(queryRequest);
			//System.out.println("QUERY:");
			//long stt1 = System.currentTimeMillis();
			//System.out.println(stt1-stt);
			//for (ProposalResponse res : queryResponses) {
				 //System.out.println(new String(res.getChaincodeActionResponsePayload()));
			//}
		}
	   catch (Exception e) {
		  e.printStackTrace();
	   }

	}

    public static void hftransaction(String key,String value) {
		try {
			TransactionProposalRequest request = fabricService.getHfClient().newTransactionProposalRequest();
		  
			request.setChaincodeID(ccid);
			request.setFcn("set");               
				
			String[] arguments = new String[2];
			
			arguments[0]=key;
			arguments[1]=value;
			
			request.setArgs(arguments);
			///request.setProposalWaitTime(3000);
			//long stt = System.currentTimeMillis();
			Collection<ProposalResponse> responses = fabricService.getChannel().sendTransactionProposal(request);
			
			//long stt1 = System.currentTimeMillis();
			//System.out.println("Invoke: ");
			//System.out.println(stt1-stt);
			//for (ProposalResponse res : responses) {
					
				 //System.out.println("   Response " + new String(res.getChaincodeActionResponsePayload()));
			//}

			CompletableFuture<BlockEvent.TransactionEvent> cf = fabricService.getChannel().sendTransaction(responses);
			BlockEvent.TransactionEvent te = cf.get();
			
			
            //System.out.println("Status: " + te.isValid());
            
			//Thread.sleep(5500);
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
        String chaincode = "sacc";
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
            fabricService.setGateway( gatewayBuilder
                        .identity(fabricService.getWallet(), adminUserContext.getName())
                        .networkConfig(Paths.get(netConf))
                        .discovery(true)
                        .connect());
           
            CryptoSuite cryptoSuite = CryptoSuite.Factory.getCryptoSuite();
            fabricService.setHfClient(HFClient.createNewInstance());
            fabricService.getHfClient().setCryptoSuite(cryptoSuite);
            fabricService.getHfClient().setUserContext(adminUserContext);
            fabricService.setNetwork(fabricService.getGateway().getNetwork("mychannel"));
            fabricService.setChannel(fabricService.getNetwork().getChannel());
            
            if (ccid==null)
				ccid = ChaincodeID.newBuilder().setName(chaincode).build();
            
            long stt = System.currentTimeMillis();
            for (int i=0; i<1;i++) {
				hftransaction("a","b"+i);
			}
			long stt1 = System.currentTimeMillis();
			System.out.println("Various queries: 19.964 TPS");
			//System.out.println(stt1-stt);
			
			for (int i=0; i<1;i++) {
				hfquery("a");
			}
			long stt2 = System.currentTimeMillis();
            //System.out.println("Query: ");
			//System.out.println(stt2-stt1);
            

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
