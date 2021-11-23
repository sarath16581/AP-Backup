/**************************************************
Description:    Controller Class for Lightning components stp_CreateCase

History:
--------------------------------------------------
2019-10-02  LJ Created

**************************************************/

public  without sharing class stp_CreateCase {

    /*  Retrieving the consignment details to pre-populate the case
        @Param consignment number
     */
    @AuraEnabled
    public static Article__c consignmentSearch(String consignmentNo){
        try {

            System.debug('[stp_createCase] : consignmentSearch() : Consignment Number :: ' + consignmentNo);
            Article__c  consignment = [
                    SELECT Id,ArticleID__c,Name,Network__c,Freight_Amount__c,CID__c,Billing_Account__c
                    FROM Article__c
                    WHERE Name = :consignmentNo
                    LIMIT 1
            ];
             return consignment;
        } catch (Exception ex){
            system.debug('[stp_createCase] : consignmentSearch() : exception '+ex.getMessage()+' at '+ex.getStacktraceString());
            AuraHandledException e = new AuraHandledException('Error in save Method :: Not a valid consignment Number ');
            throw e;
        }
    }

    /*
    * get the recordtypeId for delivery enquiry Case
    * */
    @AuraEnabled
    public static String getRecordTypeId(){
        String deRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        return deRecordTypeID;
    }

    /* creation of new case
    * params consignmnet No
    * Field values entered on UI
    */
    @AuraEnabled
    public static String createNewCase(String recordData, String consignmentNo) {
        try {
            //Deserialize the JSON String.
            Map<String, String> mapData = (Map<String,String>) JSON.deserialize(recordData, Map<String,String>.class);
            System.debug( '[stp_createCase] : createNewCase() - recordData ::'+ recordData);

            Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();

            //Set the fields to insert a case.
            //Status and Call Purpose are prepopulated value.
            Case insCase = new Case();
            insCase.RecordTypeId = devRecordTypeId;
            insCase.Subject = mapData.get('Subject');
            insCase.Description = mapData.get('Description');
            insCase.Status = mapData.get('Status');
            insCase.Call_Purpose__c = mapData.get('Call_Purpose__c');
            insCase.Enquiry_Type__c = mapData.get('Enquiry_Type__c');

            if(!String.isEmpty(consignmentNo)){
                Article__c  consignment = [
                        SELECT Id,ArticleID__c,Name,Network__c,Freight_Amount__c,CID__c,Billing_Account__c
                        FROM Article__c
                        WHERE Name = :consignmentNo
                        LIMIT 1
                ];
                insCase.ArticleTest__c = consignment.ID;
                insCase.Connote_number__c = consignment.Name;
                insCase.Consignment_Unique_External_ID__c = consignment.ArticleID__c;
                System.debug('[stp_createCase] : createNewCase() - consignment.ID :: '+ consignment.ID);
            }


            //If owner Id is not defined proceed to run assignment rules
            //set dml options to run assignment rules and assign owner id for the  case created
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule= true;
            insCase.setOptions(dmo);

            //Create a case.
            insert insCase;
            System.debug(insCase);

            Case deCase = [SELECT Id, RecordTypeId, CaseNumber FROM Case WHERE Id = :insCase.Id];
            //Return the case number of the inserted case.
            return deCase.CaseNumber;
        } catch (Exception ex){
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            System.debug('[stp_createCAae] : createNewCase() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            AuraHandledException e = new AuraHandledException('Error in save Method :: Consignment not found ');
            //e.setMessage(ex.getMessage());
            throw e;
        }
    }

}