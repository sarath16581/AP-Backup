/*------------------------------------------------------------
  Author:           Adrian Recio
  Date Created:     21/09/2018
  Description:      Standardset controller class for ContentDocument object
  Test Class:       FileEditControllerTest
  
  History
  <Date>          <Authors Name>       <Brief Description of Change>
  21/09/2018       Adrian Recio        Created standard set controller class for contentdocument
  21/10/2018       Melissa Carino      Added code comments to FileEditController
   
------------------------------------------------------------*/

public without sharing class FileEditController {

    // Parent agreement/apttus contract Id
    public string aptContractId;
    // List of content versions for document update
    public List<ContentVersion> mainCvList{get; set;}
    // standard set controller of contentversion
    public ApexPages.StandardSetController setCon {get; set;}

    /*------------------------------------------------------------
   Author:        Adrian Recio
   Company:       Salesforce
   Description:   Instantiates standard set controller for list of files related to Apttus contract url Id parameter
   Inputs:        N/A
   Returns:       N/A
   History
   <Date>      <Authors Name>     <Brief Description of Change>
   20-Sep-2018  Adrian Recio     First version.
   ------------------------------------------------------------*/
    public FileEditController(){
        // Get Id of parent apttus contract based on current page url
        aptContractId = ApexPages.currentPage().getParameters().get('Id');

        // Retrieve files related to apttus contract
        List<ContentVersion> cvListSelect = new List<ContentVersion>();
        List<ContentDocumentLink> cdlList = [SELECT ID, ContentDocumentID, LinkedEntityID
                                                FROM ContentDocumentLink
                                                WHERE LinkedEntityID = :aptContractId];

        Set<Id>conDocSet = new Set<Id>();

        // Build set of content document Ids
        for(ContentDocumentLink cdl: cdlList) {
            conDocSet.add(cdl.ContentDocumentID);
        }

        // Retrieve content versions for update based on matching contentdcoumentId
        setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT ID, Title, ContentDocumentID,Is_Signed__c ,Signature_Type__c, Document_Type__C, IsLatest
                                                                                FROM ContentVersion
                                                                                WHERE ContentDocumentID IN :conDocSet
                                                                                AND IsLatest = TRUE]));
        mainCvList = setCon.getRecords();
    }

    /*------------------------------------------------------------
     Author:        Adrian Recio
     Company:       Salesforce
     Description:   Save content document list which contains updates to document type.
                    After save, redirect to parent Agreement/ Apttus Contract
     Inputs:        N/A
     Returns:       N/A
     History
     <Date>      <Authors Name>     <Brief Description of Change>
     20-Sep-2018  Adrian Recio     First version.
     ------------------------------------------------------------*/
    public pageReference saveRecords(){
        update mainCvList;
        PageReference pgVar = new PageReference('/' + aptContractId);
        return pgVar;
    }

}