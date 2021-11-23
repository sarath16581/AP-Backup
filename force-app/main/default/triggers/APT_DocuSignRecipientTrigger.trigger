/**
* Description: Populate APT_Count_of_Contact_Records__c and APT_Count_of_User_Records__c 
* Created By - Mahesh Patel
* Created Date - 8th Dec, 2020
**/
trigger APT_DocuSignRecipientTrigger on Apttus_DocuApi__DocuSignDefaultRecipient2__c (before insert, before update) 
{
    system.debug('Test trigger.new: ' + trigger.new);
    //before insert update
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) 
    {
        String result = APT_DocuSignRecipientTriggerHandler.beforeInsertUpdateEvent(trigger.new, trigger.oldMap);
        if(result != APT_Constants.SUCCESS_LABEL)
        {
            for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docuSignRecipient : trigger.new) 
            {
                docuSignRecipient.addError(result);
            }               
        }
    }
}