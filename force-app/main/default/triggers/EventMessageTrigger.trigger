/**
  * @author       : (Unknown)
  * @description  : EventMessage Triggers
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    2020-06-12          arjun.singh@auspost.com.au                  Added before update event as well to capture the Machine Details on upsert of Event messages record 
                                                                    as a part of MyNetwork Uplift             
*******************************  History ************************************************/
trigger EventMessageTrigger on EventMessage__c (before insert, after insert, before update) {

    system.debug('####################################### event message trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) 
    {   
        if (!StarTrackConsignmentSearchUtil.isFromWebservice(Trigger.new)) {
            if(trigger.isInsert){
                
                if(trigger.isBefore){               
                    system.debug('####################################### isInsert & isBefore #####################################');
                    
                    EventMessageUtil.linkToNetworkFacility(trigger.new);
                    // Added a Method to capture Machine details name on event message insert as a part of MyNetwork Uplift
                    EventMessageUtil.populateMachineDetails(trigger.new);
                }
                
                if(trigger.isAfter){
                    system.debug('####################################### isInsert & isAfter #####################################');
                    
                    EventMessageUtil.updateCases(trigger.new);
                    EventMessageUtil.createSignatureAttachments(trigger.new);
                    EventMessageUtil.updateArticles(trigger.new);
                }
            }

            if(trigger.isUpdate){
                if(trigger.isBefore){
                    // Added a Method to capture Machine details name on event message update as a part of MyNetwork Uplift
                    EventMessageUtil.populateMachineDetails(trigger.new);
                    system.debug('####################################### isUpdate & isBefore #####################################');

                }
                
                if(trigger.isAfter){
                    system.debug('####################################### isUpdate & isAfter #####################################');
                    
                }
            } 
        }
        
    }

}