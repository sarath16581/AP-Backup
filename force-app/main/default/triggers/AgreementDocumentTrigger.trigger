/******************************************************************************************
    
    Author:         Lyndon Lavapie
    Date Created:   03/10/2016
    Description:    Trigger for Agreement_Document__c Object
    
Change Log:
Date:          Author:                  Description:
03/10/2016     Lyndon Lavapie			Created
17/09/2019     Disha Kariya             Called updateAccount to update Assignment Effective To Date on CMA CPA Licence.
    
*******************************************************************************************/
trigger AgreementDocumentTrigger on Agreement_Document__c (after update, before delete) {
	
    if (Trigger.isBefore) {
        if (Trigger.isdelete) {
            AgreementDocumentTriggerHandler.preventDelete(Trigger.Old);
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            // Update Licence with new Assignment Effective To Date as Renewal Agreement is changed to Active
            AgreementDocumentTriggerHandler.updateAccount(trigger.oldMap, trigger.newMap);
        }
    }
}