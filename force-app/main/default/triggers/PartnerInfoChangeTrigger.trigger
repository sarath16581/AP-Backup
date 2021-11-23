/**************************************************
Type:       Trigger for Partner Info Change Object
Purpose:    Calls various Utils on trigger Actions
History:
--------------------------------------------------
08.08.2015  Ritika Dhandia (Salesforce.com)       Created
**************************************************/

trigger PartnerInfoChangeTrigger on Partner_Info_Change__c (before insert, after update, before update) {

    if(trigger.isInsert){
        if(trigger.isBefore){
            system.debug('####################################### isInsert & isBefore #####################################');
            PartnerInfoChangeUtil.verifyPartnerInfoDuplicate(trigger.new);

            PartnerInfoChangeUtil.updateNetworkManager(trigger.new, null);
        }
    }
    else if(trigger.isUpdate){
        if(trigger.isBefore){
            system.debug('####################################### isUpdate & isBefore #####################################');
            PartnerInfoChangeUtil.updateNetworkManager(trigger.new, trigger.oldMap);
        }
        else if(trigger.isAfter){
            system.debug('####################################### isUpdate & isAfter #####################################');
            PartnerInfoChangeUtil.updateAccount(trigger.oldMap, trigger.newMap);
        }
    }
}