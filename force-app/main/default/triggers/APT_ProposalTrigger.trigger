/** 
Description: Share Quote/Proposal with Opportunity Team Members
Created By: Mausam Padhiyar
Created Date: 14th Aug, 2015
Last Modified By: Mausam Padhiyar
Last Modified Date: 21st Oct, 2015 > Sync with Opportunity

Last Modified By - Mausam Padhiyar
Last Modified Date - 16th March, 2017 | CR - Kg Rounding

Last Modified By - Mathew Jose
Last Modified Date - 22nd Oct, 2020 | Added contracting entity calculation logic.

Last Modified By - Krishna Velani
Last Modified Date - 6th May, 2021 | STP-5088 setOpportunityDriver method to update Proposal Owner at line 50

Last Modified By - Mansi Shah
Last Modified Date - 10th June 2021 | Added Code to blank out Approval related fields on Approval Rejection/Cancellation

Last Modified By - Darshan Chauhan
Last Modified Date - 2021-06-15 Darshan Chauhan - Removing unessecary code for Approval Rejection

Last Modified By - Mansi Shah
Last Modified Date - 14th July 2021 | Added call for onBeforeInsert method and commented method call for setOpportunityDriver
*/
trigger APT_ProposalTrigger on Apttus_Proposal__Proposal__c (before insert, after insert, after update,before update) {
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