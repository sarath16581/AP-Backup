/******************************************************************************************
    
Author:         Lyndon Lavapie
Date Created:   03/10/2016
Description:    Handler for AgreementDocumentTrigger
    
Change Log:
Date:          Author:                  Description:
03/10/2016     Lyndon Lavapie			Created
17/09/2019     Disha Kariya             Added updateAccount method to add 3 years to Assignment Effective To Date when Renewal agreement document is signed and Active.
    
*******************************************************************************************/
public class AgreementDocumentTriggerHandler {
    private static final String ERROR_MSG = 'Record Cannot be deleted!';
    private static final Set<String> adStatus = new Set<String>{'Ceased','Active'};
    public static final string STATUS_ACTIVE = 'Active';
    public  static final Map<string, Account_Licence_Recordtypes__c> Account_Licence_Recordtypes = Account_Licence_Recordtypes__c.getAll();
    
	/*********************************************************************************************************************************
      Author:     Lyndon Lavapie
      Description:  Adds an error when the user delete a Agreement Document Record with prohibited Status
    				
      Input:        List<Agreement_Document__c>
      Output:        Void
  *********************************************************************************************************************************/
    public static void preventDelete(List<Agreement_Document__c> oldAD){
        
        for(Agreement_Document__c ad:oldAD){
            if(adStatus.contains(ad.Status__c)){
                ad.addError(ERROR_MSG);
            }
        }
    }

    /*
        Method to change the Assignment Effective To Date on CMA CPA Licence for renewal
     */
    public static void updateAccount(map<id, Agreement_Document__c> oldAgreements, map<id, Agreement_Document__c> newAgreements){
        Map<id, Account> mapParentAccounts = new Map<id, Account>();
        Set<Id> parentAccountIds = new Set<Id>();
        //Get Record Types CMA CPA and renewal template name
        Set<String> cmaCpaRecordStrings = new Set<String>();
        Set<String> documentType = new Set<String>();
        String accountString = 'Account';
        for(Account_Licence_Recordtypes__c rec : Account_Licence_Recordtypes.values()){
            if(rec.Renewable__c){
                cmaCpaRecordStrings.add(rec.Name);
                documentType.add(rec.Renew_document_type__c);
            }
        }
        for(Agreement_Document__c agreement : (List<Agreement_Document__c>) RecursionUtility.getUnprocessedRecords('AgreementDocumentTriggerHandler', newAgreements.values(), new Set<String>{'Status__c'})){
            // Check if Status is changed to Active and Document Type is for CMA CPA renew.
            if(agreement.Status__c != oldAgreements.get(agreement.id).Status__c && agreement.Status__c.equalsIgnoreCase(STATUS_ACTIVE) && documentType.contains(agreement.Document_Name__c)){
                //Add CMA CPA licence Id to the list
                parentAccountIds.add(agreement.Licence__c);
            }
        }
        Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(cmaCpaRecordStrings,accountString));
        //Get the licence details
        for(Account licence : [SELECT Id, Assignment_Effective_To_Date__c, Licence_Status__c, Approval_Status__c FROM Account WHERE Id IN :parentAccountIds AND RecordTypeId IN :licenceRTs.keySet()]){
            //Add 3 years to Assignment Effective To Date as Renew is signed and Active
            licence.Assignment_Effective_To_Date__c = licence.Assignment_Effective_To_Date__c.addYears(3);
            mapParentAccounts.put(licence.Id, licence);
        }
        try {
            //Update Licence if needs to be updated.
            if (!mapParentAccounts.isEmpty()) {
                update mapParentAccounts.values();
            }
        }
        catch(Exception exp) {
            //log exceptions
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'AgreementDocumentTriggerHandler',
                    AgreementDocumentTriggerHandler.class.getName(), 'updateAccount', '', LoggingLevel.ERROR);
        }
    }
}