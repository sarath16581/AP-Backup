trigger NPSSurveyTrigger on NPSSurvey__c (after insert, after update, before insert, before update) {
	system.debug('####################################### NPSSurveyTrigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) 
    {   
        if(trigger.isInsert){
        	
            if(trigger.isBefore){    
                system.debug('####################################### NPSSurveyTrigger isInsert & isBefore #####################################');
                
		        NPSSurveyUtil.linkAgentIdFromCase(Trigger.new);
		        
            }
            
            if(trigger.isAfter){
                system.debug('####################################### NPSSurveyTrigger isInsert & isAfter #####################################');
                
            }
        }

        if(trigger.isUpdate){
            if(trigger.isBefore){
                system.debug('####################################### NPSSurveyTrigger isUpdate & isBefore #####################################');
                
            }
            
            if(trigger.isAfter){
                system.debug('####################################### NPSSurveyTrigger isUpdate & isAfter #####################################');
                
            }
        } 
    }
}