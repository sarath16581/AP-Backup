public class TDF_FeedChatterPostFromPB{

    //wrapper class for getting chatter message and WorkOrder Id from Process Builder
    public class InputValues{
        @InvocableVariable(label='WordOrder ID' required=true)
        public string workOrderId;
        @InvocableVariable(label='Chatter Msg' required=true)
        public String chatterMsg;
    }

    //Method enabled to call from Process Builder
    //Used for Posting Chatter Message on WorkOrder
    @InvocableMethod(label='Post to Chatter')
    public static void postChatterFeed(List<InputValues> inputs) {
    	
        Set<String> dispatcherNameSet = new Set<String>();        
        List<ServiceTerritory> serviceTerritoryList = new List<ServiceTerritory>();
		Map<String, String> collaborationGroupMap = new Map<String, String>();
		Map<String, String> inputValuesMap = new Map<String, String>();

        //populate Map from the list of inputs coming from Process Builder
        for(InputValues objInput : inputs){
        	inputValuesMap.put(objInput.workOrderId, objInput.chatterMsg);
        }
        System.debug('inputValuesMap->'+inputValuesMap);
        
        //get all the Service Territories
        serviceTerritoryList = [SELECT Id, TerritoryDispatcher__c FROM ServiceTerritory];        

        //loop through the Service Territories and add the Territory Dispatcher Name in a Set
        for(ServiceTerritory objServiceTerritory : serviceTerritoryList){
            if(objServiceTerritory.TerritoryDispatcher__c != null){
                dispatcherNameSet.add(objServiceTerritory.TerritoryDispatcher__c);
            }
        }

        //loop throght the Collaboration Groups from the Name set of Dispatcher and populate Map
        for(CollaborationGroup objCollaborationGroup : [SELECT Id, Name FROM CollaborationGroup WHERE Name IN : dispatcherNameSet]){
            for(ServiceTerritory objST : serviceTerritoryList){
                if(objCollaborationGroup.Name == objST.TerritoryDispatcher__c){
                    collaborationGroupMap.put(objST.TerritoryDispatcher__c, objCollaborationGroup.Id);
                }
            }
        }

        //loop through the WorkOrders and Post Chatter Message mentioning Territory Dispatcher if Dispatcher defined on Service Territory
        for(WorkOrder objWorkOrder : [SELECT Id, (SELECT Id, ServiceTerritory.TerritoryDispatcher__c FROM ServiceAppointments LIMIT 1) FROM WorkOrder WHERE Id IN : inputValuesMap.keySet()]){
            
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            textSegmentInput.text = inputValuesMap.get(objWorkOrder.Id)+'\n';
            messageBodyInput.messageSegments.add(textSegmentInput);

            if(objWorkOrder.ServiceAppointments.size()>0){
                if(collaborationGroupMap.get(objWorkOrder.ServiceAppointments[0].ServiceTerritory.TerritoryDispatcher__c) != null){
                    mentionSegmentInput.id = collaborationGroupMap.get(objWorkOrder.ServiceAppointments[0].ServiceTerritory.TerritoryDispatcher__c);
                    messageBodyInput.messageSegments.add(mentionSegmentInput);
                }
            }                                

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = objWorkOrder.Id;

            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);        	
        }                
    }
}