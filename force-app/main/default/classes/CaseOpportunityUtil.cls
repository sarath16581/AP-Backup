public with sharing class CaseOpportunityUtil {
	 public static void updateOPCUnderReviewBySalesManagerFlag(List<Case> cases) {
	 	id salesManagerReviewExceptionRecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');

	 	List<String> opportunityIds = new List<String>();
        for (Case c : cases) {
            if (c.RecordTypeId == salesManagerReviewExceptionRecordTypeId && c.Originating_OPC__c != null) {
                opportunityIds.add(c.Originating_OPC__c);                         
            }               
        }
        
        if (!opportunityIds.isEmpty()) {
	        // Set OPC record Under Review by Sales Manager flag to true when Case is initiated from the OPC
            List<Opp_Product_Classification__c> opportunities = [select id, Under_Review_by_Sales_Manager__c, Classification__c 
            											   		 from Opp_Product_Classification__c 
            											   		 where id in :opportunityIds];

            if (!opportunities.isEmpty()) {
                for (Opp_Product_Classification__c opc : opportunities) {
                    opc.Under_Review_by_Sales_Manager__c = true;
                }
                update opportunities;
            }
        }
    }
	
	public static void updateOpportunityDriver(List<Case> caseList) {
		id salesManagerReviewExceptionRecordTypeId = CaseUtility.getRecordIdWithDevName('Sales_Manager_Review_Exception');
		
		List<String> opportunityIds = new List<String>();
        List<Case> shortListed = new List<Case>();
        for (Case c : caseList) {
            if (c.RecordTypeId == salesManagerReviewExceptionRecordTypeId) {
                opportunityIds.add(c.Opportunity__c);   
                shortListed.add(c);                                         
            }               
        }
        
        if (!opportunityIds.isEmpty()) {
            List<Opportunity> opportunities = [select Id, Owner.Name, OwnerId From Opportunity where Id in :opportunityIds];
           	Map<String, String> opptyIdOwnerIdMap = new Map<String, String>();
            if (opportunities.size() > 0) {
                for (Opportunity oppty : opportunities) {
                    opptyIdOwnerIdMap.put(oppty.Id, oppty.OwnerId);                                 
                }
            }       
	        
	        if(!opptyIdOwnerIdMap.isEmpty()) {
		        for (Case c : shortListed) {
		            c.Opportunity_Driver1__c = opptyIdOwnerIdMap.get(c.Opportunity__c);
		        }
		   	}
        }
    }
}