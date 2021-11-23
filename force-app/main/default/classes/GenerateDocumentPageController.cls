/**************************************************
Description:    Controller for the GenerateDocumentPage
History:
--------------------------------------------------
2019-09-19  shashwat.a.nath@accenture.com  Created
**************************************************/

public with sharing class GenerateDocumentPageController {
    // Class Level Variable
    public static Agreement_Document__c agreementRecord;
    // Constructor
    public GenerateDocumentPageController(ApexPages.StandardController controller){

    }
    /**
   *  This remote action Method is invoked  When user clicks on Generate Document button on Partner Agreement Document Record
   *  It recieves partner agreement record id and License Type and searches for the relevant partner rate list .
   *  On Successful rate list retrieval it updates the Partner Agreement Document with the Rate List
   */

    @remoteaction
    public static void updateAgreementDocumentRecord(String recordId , String LicenceType){
        system.debug('Document License Type =>' +LicenceType);
        system.debug('Document Record Id =>' +recordId);
        agreementRecord = new Agreement_Document__c();
        List<Rate_List__c> rateList = new List<Rate_List__c>();
        // Fetching the Rate List Record which matches the Input parameters
        rateList = [SELECT Id FROM Rate_List__c WHERE  Status__c = 'Active' AND Licence_Type__c =:LicenceType  LIMIT 1];
        system.debug('Rate List Size =>' +rateList.size());
        if(!rateList.isEmpty()){
            // Updating the agreement Document Record
            agreementRecord.id = recordId;
            agreementRecord.Rate_List__c = rateList[0].id;
            // Update the Record
            system.debug('Agreement =>' +agreementRecord);
            Database.update(agreementRecord);
        }
    }
}