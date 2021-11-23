/**************************************************
Type:       Trigger for Partner Addendum Object
Purpose:    Calls various Utils on trigger Actions
History:
--------------------------------------------------
08.08.2015  Ritika Dhandia (Salesforce.com)       Created
04.07.2019  disha.kariya@auspost.com.au           Updated method name from updateNetworkManager to updateNetworkManagerAndStateAdmin
**************************************************/

trigger PartnerAddendumTrigger on Partner_Addendum__c (before insert, before update, after insert, after update) {
    if(trigger.isInsert){
        if(trigger.isBefore){
            
            system.debug('####################################### isInsert & isBefore #####################################');
            PartnerAddendumUtil.verifyDuplicatePartnerAddendum(trigger.new,null);   

            PartnerAddendumUtil.updateNetworkManagerAndStateAdmin(trigger.new, null);
        }
        else if(trigger.isAfter){

            system.debug('####################################### isInsert & isAfter #####################################');
            PartnerAddendumUtil.updateMinimumLevelOnLicence(trigger.new, null);
        }
    }
    else if(trigger.isUpdate){
        if(trigger.isBefore){
            
            system.debug('####################################### isUpdate & isBefore #####################################');
            PartnerAddendumUtil.verifyDuplicatePartnerAddendum(trigger.new,trigger.oldMap);   

            PartnerAddendumUtil.updateNetworkManagerAndStateAdmin(trigger.new, trigger.oldMap);
        }
        else if(trigger.isAfter){

            system.debug('####################################### isUpdate & isAfter #####################################');
            PartnerAddendumUtil.updateMinimumLevelOnLicence(trigger.new, trigger.oldMap);
        }
    }
}