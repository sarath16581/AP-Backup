/**
Description:Trigger to Copy product image from product to proposal Line Item
Created By: Raviteja Epuri
Created Date: 12th Jan, 2016
Last Modified By: Mausam Padhiyar   
Last Modified Date: 4th March, 2016
*/
trigger APT_ProposalLineItemTrigger on Apttus_Proposal__Proposal_Line_Item__c (after insert, before insert, after Update) {

    if(trigger.isBefore) {
        if(trigger.isInsert) {
            system.debug('**trigger.new**'+trigger.new);
            String result = APT_ProposalLineItemTriggerHandler.beforeInsertEvent(trigger.new);
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Proposal__Proposal_Line_Item__c proposallineItem : trigger.new) {
                    proposallineItem.addError(result);
                }               
            }
        }
    }
    
    if(trigger.isAfter) {
        if(trigger.isInsert || trigger.isUpdate) {
            String result = APT_ProposalLineItemTriggerHandler.afterInsertEvent(trigger.new, trigger.isUpdate);
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Proposal__Proposal_Line_Item__c proposallineItem : trigger.new) {
                    proposallineItem.addError(result);
                }               
            }
        }
    }
}