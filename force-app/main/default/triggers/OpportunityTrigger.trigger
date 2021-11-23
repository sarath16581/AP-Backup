/**************************************************
Type:       Trigger for Opportunity Object
Purpose:    For inserts/updates, roll up Opportunity Amount
            to corresponding Account Plan Opportunity Value             
History:
--------------------------------------------------
15.09.2011    Richard Enojas(Salesforce.com)    Created
30.09.2011    Prakash Varsani - removed automatic opportunity assessment creation
17.10.2011	  Richard Enojas(Salesforce.com)	Added checking for custom setting
**************************************************/
trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
    	if(trigger.isAfter){
        	if(trigger.isInsert || trigger.isUpdate){
            
            	Set<Id> acctplanIds = new Set<Id>();
                        
            	for(Opportunity opp : trigger.new){
                	if (opp.Account_Plan__c!=null){
                    	if( (trigger.isInsert) ||
                        	(trigger.isUpdate && (opp.Account_Plan__c!=trigger.oldMap.get(opp.Id).Account_Plan__c ||
                        		opp.Amount!=trigger.oldMap.get(opp.Id).Amount))){
                            acctplanIds.add(opp.Account_Plan__c);       
                    	}
                	}
            	}
            	if(!acctplanIds.isEmpty())
                OpportunityUtility.updateAccountPlan(acctplanIds);
        	}
    	}
    }
}