/******************************************************************************************
    
    Author:         Lyndon Lavapie
    Date Created:   03/10/2016
    Description:    Trigger for Rate_List__c Object
    
    Change Log:
    Date:          Author:                  Description:
    03/10/2016     Lyndon Lavapie			Created
    
*******************************************************************************************/
trigger RateListTrigger on Rate_List__c (before delete) {
    
    if (Trigger.isBefore) {
        if (Trigger.isdelete) {
            RateListTriggerHandler.preventDelete(Trigger.Old);
        }
    }

}