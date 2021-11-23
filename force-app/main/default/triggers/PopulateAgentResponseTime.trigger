trigger PopulateAgentResponseTime on SocialPost (after insert, after update) {
    
    Set<Id> caseIds = new Set<Id>();
    
    for(SocialPost post: Trigger.new){
        if(post.IsOutbound && post.ParentId != null){
            caseIds.add(post.ParentId);
        }
    }
    
    if(!caseIds.isEmpty()){
        List<Case> cases = [SELECT Id, First_response__c
                                    FROM Case 
                                    WHERE Id IN :caseIds 
                                    AND First_response__c = null];
                                    
        if(!cases.isEmpty()){
            for(Case theCase : cases){
                theCase.First_response__c = system.now();
            } 
        }
        
        update cases;
    }

}