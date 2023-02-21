/**
 * @description Share Quote/Proposal with Opportunity Team Members
 * @author  Mausam Padhiyar
 * @date 2015-08-14
 * @Test APT_ProposalTrigger_Test
 * @changelog
 * 2015-10-21 - Mausam Padhiyar - Sync with Opportunity
 * 2017-03-16 - Mausam Padhiyar - CR - Kg Rounding
 * 2020-10-22 - Mathew Jose - Added contracting entity calculation logic.
 * 2021-05-06 - Krishna Velani - STP-5088 setOpportunityDriver method to update Proposal Owner at line 50
 * 2021-06-10 - Mansi Shah - Added Code to blank out Approval related fields on Approval Rejection/Cancellation
 * 2021-06-15 - Darshan Chauhan - Removing unessecary code for Approval Rejection
 * 2021-07-14 - Mansi Shah - Added call for onBeforeInsert method and commented method call for setOpportunityDriver
 * 2022-12-01 - Ken McGuire - Added record sharing logic
 * 2023-02-14 - Ranjeewa Silva - Added support for before delete, after delete and after undelete trigger events
 */
trigger APT_ProposalTrigger on Apttus_Proposal__Proposal__c (before insert, after insert, after update,before update, before delete, after delete, after undelete) {
    
	// Application Domain
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(Apttus_Proposal__Proposal__c.SObjectType))) {
		APTProposalDomainTriggerHandler.newInstance().dispatch();
	}
	
	if(trigger.isAfter == true) {
        if(trigger.isUpdate == true) {
            String result = APT_ProposalTriggerHandler.afterUpdateEvent(trigger.new, trigger.oldMap);
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Proposal__Proposal__c proposal : trigger.new) {
                    proposal.addError(result);
                }               
            }            
        }
    }
    if(trigger.isBefore) {
        if(trigger.isInsert){
            String result1 = APT_ProposalCloneHandler.UpdateProposalandConfigWithCloneFlag(trigger.new);
            if(result1 != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Proposal__Proposal__c proposal : trigger.new) {
                    proposal.addError(result1);
                }               
            }
            // Added by Mansi Shah
            APT_ProposalTriggerHandler.onBeforeInsert(trigger.new);
            // Complete By Mansi Shah
        } 
        //CR - KG Rounding
        if(trigger.isInsert){
            system.debug('*** before insert ***');
            String result = APT_ProposalTriggerHandler.beforeInsertEvent(trigger.new);
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Proposal__Proposal__c proposal : trigger.new) {
                    proposal.addError(result);
                }               
            }
             
        }
        //CR - KG Rounding

        if(trigger.isUpdate){
            Map<Id,String> mapQuote= APT_ProposalTriggerHandler.beforeUpdateEvent(trigger.new, trigger.oldMap);
            String result = APT_ProposalTriggerHandler.setContractingEntities(trigger.newMap);
            //result= APT_ProposalTriggerHandler.setOpportunityDriver(trigger.newMap);
            for(Apttus_Proposal__Proposal__c proposal : trigger.new) {
                if((mapQuote != null && mapQuote.containsKey(proposal.Id)) || result != APT_Constants.SUCCESS_LABEL) {
                    proposal.addError(mapQuote.get(proposal.Id));
                }
            }
            
            //Added By: Mansi Shah
                APT_ProposalTriggerHandler.onBeforeUpdate(trigger.oldMap,trigger.newMap);
            //Compelte Code unit By Mansi Shah   
        }  
    }
    
}