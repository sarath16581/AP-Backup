/**
 * Date             Version          Owner              Desription
 * 25-July-17         1.0           Bharat P        Initial Version - Updates Current Approval For Credit Approval records
 * 																	  which ahve been Reassigned and Pending for Approval		
 */
global class BatchUpdateCurrentApproverReassignment implements Database.Batchable<sObject>{
	
    Set<Id> setCAIds = new Set<Id>();
    Map<String, List<ProcessInstanceHistory>> caStepsAndWIMap = new Map<String, List<ProcessInstanceHistory>>();
    Map<Id, String> caActorIdMap = new Map<Id, String>();
    List<Credit_Approval__c> caList = new List<Credit_Approval__c>();
    Set<Id> caIdSet = new Set<Id>();
    
    global BatchUpdateCurrentApproverReassignment(){
		for(Credit_Approval__c ca : [select Id, Current_Approver_Name__c FROM Credit_Approval__c where Ready_For_Approval__c =: true And 
                                     Status__c !=: 'Approved' And Status__c !=: 'Rejected' And Status__c !=: 'New']){
			setCAIds.add(ca.Id);
            caList.add(ca);
		}
        if(setCAIds != null && !setCAIds.isEmpty()){
            for(ProcessInstance processInst : [Select Id, TargetObjectId, ProcessDefinitionId, ProcessDefinition.Name, (Select Id, ProcessNodeId, Comments, ProcessInstanceId, ActorId, StepStatus 
                                               From StepsAndWorkItems order by CreatedDate DESC) From ProcessInstance Where TargetObjectId IN :setCAIds 
                                               And Status =: 'Pending' Order by CreatedDate Desc]){
                if(processInst != null && processInst.StepsAndWorkItems != null){
                    if(!caStepsAndWIMap.containsKey(processInst.TargetObjectId)){
                    	caStepsAndWIMap.put(processInst.TargetObjectId, processInst.StepsAndWorkItems);    
                    }                	                                       
                }            	
        	}
        }
        if(caStepsAndWIMap != null && !caStepsAndWIMap.isEmpty()){
        	for(Credit_Approval__c crdApp : caList){
                Map<Id, Id> prcsNodePendingMap = new Map<Id, Id>();
                Map<Id, Id> prcsNodeReasssignMap = new Map<Id, Id>();
                String actorId = null;
                if(caStepsAndWIMap.containsKey(crdApp.Id)){                
                    for(ProcessInstanceHistory piw : caStepsAndWIMap.get(crdApp.Id)){
                        if(piw != null && piw.ProcessNodeId != null){
                            if(piw.StepStatus == 'Pending'){
                            	prcsNodePendingMap.put(piw.ProcessNodeId, piw.ActorId);    
                            }else if(piw.StepStatus == 'Reassigned'){
                            	prcsNodeReasssignMap.put(piw.ProcessNodeId, piw.ActorId);    
                            }
                        }						                        
                    }
                }
                if(prcsNodeReasssignMap != null && !prcsNodeReasssignMap.isEmpty() && prcsNodePendingMap != null 
                   && !prcsNodePendingMap.isEmpty()){
                	for(String pKey : prcsNodeReasssignMap.keySet()){
                        if(prcsNodePendingMap.get(pKey) != null){
                        	actorId = prcsNodePendingMap.get(pKey);    
                        }                        
                    }                        
                }
                if(actorId != null && !String.valueOf(actorId).startsWith('00G')){
                    caActorIdMap.put(crdApp.Id, actorId);
                    caIdSet.add(crdApp.Id);
                }
        	}
        }
  	}
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Current_Approver_Name__c FROM Credit_Approval__c where Id In :caIdSet';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Credit_Approval__c> lstCAReassigned) {
        Savepoint sp = Database.setSavepoint();
        List<Credit_Approval__c> lstNewCA = new List<Credit_Approval__c>();
		try{
            if(lstCAReassigned != null && !lstCAReassigned.isEmpty()){
                for(Credit_Approval__c crdApproval : lstCAReassigned){
                    crdApproval.Current_Approver_Name__c = caActorIdMap.get(crdApproval.Id);
                    lstNewCA.add(crdApproval);
                }
                update lstNewCA;
            }
		}catch(exception ex){
            ex.getMessage();
            Database.rollback(sp);
		}
    }
    
    global void finish(Database.BatchableContext BC){
	}
}