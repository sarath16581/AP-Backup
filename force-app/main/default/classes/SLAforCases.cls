/*
 * @author: Rajesh P. (Mav3rik)
 * @description: Create Callback Request for 5 Days SLA (SSSW Network) Queue. 
 * @description: If SLA of 5 Days passed (business days [40 hours]), scheduler will trigger this class to create callback request.
 * @description: This is batch class and execute SLAforCasesService to create callback request(s).
 * @history:02-APR-2019, class created.
*/
global with sharing class SLAforCases implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //.. Get valid Record Type Ids(SSSW)
        Set<Id> validRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
        
        //.. Get Custom Metadata for Callback Settings.
		Callback_Request_Settings__mdt callbackMdt = [SELECT CaseStatus__c,Case_Queue_Name__c, CustomerType__c, Initial_SLA_in_Hours__c, Case_Type__c, Enquiry_Sub_Type__c, Product_Category__c
                                                      FROM Callback_Request_Settings__mdt 
                                                      WHERE QualifiedApiName = 'Callback_Request_Settings'];
              
        //.. Querying case records required to be validated against SLA Criteria in Business Days/Hours.
        return Database.getQueryLocator([SELECT Id, Status, CreatedDate, Calc_Owner_Name__c, RecordTypeId, BusinessHoursId 
                                         FROM Case 
                                         WHERE Status =: callbackMdt.CaseStatus__c 
                                         AND Owner_is_Queue__c = TRUE 
                                         AND Calc_Owner_Name__c =: callbackMdt.Case_Queue_Name__c 
                                         AND RecordTypeId IN: validRecTypes
                                         AND Type =: callbackMdt.Case_Type__c
                                         AND Customer_Type__c =: callbackMdt.CustomerType__c
                                         AND ProductCategory__c IN: callbackMdt.Product_Category__c.Split(',')
                                         AND EnquirySubType__c IN: callbackMdt.Enquiry_Sub_Type__c.Split(',')
                                         ORDER BY CreatedDate DESC]);
    }
    
    //.. @description: Call SLAforCasesService to create callback request(s)
    global void execute(Database.BatchableContext BC, list<Case> caseList){
        SLAforCasesService.validateSLAandCreateCBRequest(caseList);
    }
    
    //.. @description: Final method is not required.
    global void finish(Database.BatchableContext BC){}
}