trigger ArticleTrigger on Article__c (before insert, after insert, before update, after update) {  
    //added after insert and after update
    //added additional logic to check if subscription model must be triggered based on the changes made in the consignment. - Modified by: David Catindoy (Aug 22, 2016)
    //Aug 30, 2016 - Modified to the change API name of the custom setting checkbox that determine if subscription model automation is turned on.
  system.debug('####################################### Article__c trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');
    
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if(Trigger.isInsert) {
            if (!StarTrackConsignmentSearchUtil.isFromWebservice(Trigger.new)) {
                if(Trigger.isBefore){
                    ArticleUtil.setCountryName(Trigger.new);
                    ArticleUtil.updateAddressesWithCountryNames(Trigger.new);
                }
            } else{
                if(Trigger.isBefore){
                    ArticleUtil.serviceTypeCalculation(Trigger.new, new Map<Id, Article__c>()); //Update consignment service type and product group.
                }
                if(Trigger.isAfter){
                    ArticleUtil.consignmentDepotCalculation(new Map<Id, Article__c>(Trigger.new), new Map<Id, Article__c>()); //Update consignment depot based on the calculation.
                }
            }
        }
            
        if(Trigger.isUpdate) {
            if(!StarTrackConsignmentSearchUtil.isFromWebservice(Trigger.new)) {
                if (Trigger.isBefore) {
                    ArticleUtil.processContentsItems(Trigger.newMap, Trigger.oldMap);
                    ArticleUtil.processAdditionalServices(Trigger.newMap, Trigger.oldMap);
                    ArticleUtil.processCommunicationDecisions(Trigger.newMap, Trigger.oldMap);
                    ArticleUtil.processDeliveryPreferenceOptions(Trigger.newMap, Trigger.oldMap);
                    ArticleUtil.setCountryName(Trigger.new);
                    ArticleUtil.updateAddressesWithCountryNames(Trigger.new);
                }
            } else{
                if(Trigger.isBefore){
                    ArticleUtil.serviceTypeCalculation(Trigger.new, Trigger.oldMap); //Update consignment service type and product group.
                }
                if(Trigger.isAfter){
                    ArticleUtil.consignmentDepotCalculation(Trigger.newMap, Trigger.oldMap); //Update consignment depot based on the calculation.
                    ArticleUtil.updateRelatedCases(Trigger.newMap, Trigger.oldMap); //Update related case record and/or LDC case records.
                    //Check if subscription checkbox is turned on
                    if(StarTrack_Settings__c.getOrgDefaults().Subscription_Automation_Enabled__c){
                        ArticleUtil.subscriptionModel(Trigger.newMap, Trigger.oldMap); //Call method to perform case, task, and workflow records automation based on the consignment summary status.
                    }
                }
            }
        }
        
        if(Trigger.isDelete){
        }
    }        
}