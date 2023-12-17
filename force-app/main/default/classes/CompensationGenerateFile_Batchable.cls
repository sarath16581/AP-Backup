/**************************************************
Description:       Created to facilitate EFT compensations. This can be used to create a csv file with all EFT details and save the file in a folder.
History:
----------------------------------------------------------------------------------------------
2018-08-22  dilshan.egodawela@auspost.com.au Created
2019-09-13  Nathan.Franklin@auspost.com.au : Updated logic to fetch batchId, to fix INC1460293
2022-09-19  Swati.mogadala@auspost.com.au  : Changed DL for notification from 'DLITCCOTESServiceCloud@auspost.com.au' to 'dlitcandssalesforcesupport@auspost.com.au'
2023-10-03  Swati.mogadala@auspost.com.au   : Addded GLPROFITCENTRE__c field to the file with column name 'Cover Type Code'
**********************************************************************************************/
 
global without sharing class CompensationGenerateFile_Batchable implements Database.Batchable<sObject>, Database.Stateful {
  
  //header columns : used as the header for the output file
  private String columnHeader = 'Invoice Date, Posting Date, Reference, Header Text, Vendor Number, Business Area, Payment Terms, '+
                +'Text, Account, Amount, Cover Type Code, Cost Centre Code, Text, Tax Code, Supplier Name, Street, City, Postcode, State, Country, Bank Key, Bank Account, Bank Country, Control Key \n';
    private List<String> rowValues = new List<String>();
    private Set<Id> recordstoClose = new Set<Id>();
    private String query;
    private Set<Id> processableIds = new Set<Id>();
    private Integer batchId;
    
    //default constructer that can be used to schedule as a batch job
    //this will process all "Approved" Compensation records that has not yet been processed.
    global CompensationGenerateFile_Batchable() { 
    this.query = 'SELECT Id, Name, Status__c, Case__r.CaseNumber,Contact__r.Name,Contact__r.MailingStreet,Contact__r.MailingCity,Contact__r.MailingState,Contact__r.MailingPostalCode, AMOUNT__c, CostCentreCode__c, BSB__c, Account_Number__c, GLPROFITCENTRE__c '+
            +'FROM Compensation__c '+
            +'WHERE Status__c = \'Approved\' AND RecordType.DeveloperName = \'EFT\' '+
            +'ORDER BY LastModifiedDate DESC';
    }
    //this can used to process specific compensation records that are being passed in as a set of Ids.
    //Can be used to rerun any failed records or for debugging purposes
    global CompensationGenerateFile_Batchable(Set<Id> processableIds) {
    this.processableIds = processableIds;
    this.query = 'SELECT Id, Name, Status__c, Case__r.CaseNumber,Contact__r.Name,Contact__r.MailingStreet,Contact__r.MailingCity,Contact__r.MailingState,Contact__r.MailingPostalCode, AMOUNT__c, CostCentreCode__c, BSB__c, Account_Number__c, GLPROFITCENTRE__c '+
            +'FROM Compensation__c '+
            +'WHERE Id IN :processableIds AND RecordType.DeveloperName = \'EFT\' ';
    }
    //This method can be used to process Compensastion records by batchID(already processed at least once)
    //Can be used to re-run any previous batches if needed.
    global CompensationGenerateFile_Batchable(Integer batchNo) {
      //Integer batch = Integer.valueOf(batchNo);
    this.query = 'SELECT Id, Name, Status__c, Case__r.CaseNumber,Contact__r.Name,Contact__r.MailingStreet,Contact__r.MailingCity,Contact__r.MailingState,Contact__r.MailingPostalCode, AMOUNT__c, CostCentreCode__c, BSB__c, Account_Number__c, GLPROFITCENTRE__c '+
            +'FROM Compensation__c '+
            +'WHERE Batch_Id__c = '+batchNo+' AND RecordType.DeveloperName = \'EFT\' ';
    }
    
  global Database.QueryLocator start(Database.BatchableContext BC) {
    
    return Database.getQueryLocator(query);
  }
  
  global void execute(Database.BatchableContext BC, List<sObject> scope) {
        
    //contruction of the data row, in the order of the header string.
    //for every compensation record passed into here will be converted to a string which will later be used in file generation
    for(Compensation__c Comp : (List<Compensation__c>)scope) {
      
      //new list to help with formatting the row values.
      List<Object> rowComponents = new List<Object>();
      
      rowComponents.add('"' + system.today().format().replace('"', '\\"') + '"');
      rowComponents.add('');
      rowComponents.add('"' + Comp.Case__r.CaseNumber.replace('"', '\\"') + '"');
      rowComponents.add('"' + Comp.Id + '"');
      rowComponents.add('"101"');
      rowComponents.add('"2"');
      rowComponents.add('"0"');
      rowComponents.add('"*EFT Refund"');
      rowComponents.add('"4155"');
      rowComponents.add(Comp.AMOUNT__c == null ? 0.0 : Comp.AMOUNT__c);
      rowComponents.add(Comp.GLPROFITCENTRE__c);
      rowComponents.add(Comp.CostCentreCode__c ==  null ? '' : '"' + Comp.CostCentreCode__c.replace('"', '\\"') + '"');
      rowComponents.add('"Refund"');
      rowComponents.add('"ZA"');
      rowComponents.add(Comp.Contact__r.Name == null ? '' : '"' + Comp.Contact__r.Name.replace('"', '\\"') + '"');
      rowComponents.add('"180 Lonsdale St"');
      rowComponents.add('"Melbourne"');
      rowComponents.add('"3000"');
      rowComponents.add('"VIC"');
      rowComponents.add('"AU"');
      rowComponents.add(Comp.BSB__c == null ? '' : '="'+Comp.BSB__c+'"');
      rowComponents.add(Comp.Account_Number__c == null ? '' : '="'+Comp.Account_Number__c+'"');
      rowComponents.add('"au"');
      rowComponents.add('');
      
      String thisRow = '';
      
      for(Object rowComponent : rowComponents) {
        thisRow += (String.isEmpty(thisRow) ? '' : ',') + rowComponent;
      }
      System.Debug('this row :'+thisRow);
            
            rowValues.add(thisRow);
      recordstoClose.add(Comp.Id);
    }
  }
  
  global void finish(Database.BatchableContext BC) {
    if(!rowValues.isEmpty()) {
      //get the library
      ContentWorkspace compensationWS = [Select Id, Name from ContentWorkspace where Name = 'Compensation' limit 1];
           
          if(compensationWS != null) {
        try {
          //get the current batch Id
          List<Compensation__c> result = [Select Batch_Id__c
                            From  Compensation__c
                            Where RecordType.DeveloperName = 'EFT'
                            Order by Batch_Id__c Desc Nulls Last
                            Limit 1];

          //increament the current batch Id with 1 to generate the new batch id.
          batchId = (result.isEmpty() || result[0].Batch_Id__c == null ? 1 : Integer.valueOf(result[0].Batch_Id__c)) + 1;
              
                //this is the name of the output file
                String documentName = 'Compensation Batch('+batchId+') '+Date.today().format();
                //output file contents with the header column
                String outputFile = columnHeader + String.join(rowValues,'\n');
                 
                 //commented out to switch documents to use salesforce files
                //Insert the generated CSV file in Document object under "Compensation".
                //Document doc = new Document(Name = documentName, Body = Blob.valueOf(outputFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
                //Database.SaveResult saveResult = Database.insert(doc,false);
                
                //create new content version
                ContentVersion doc = new ContentVersion(title = documentName,PathOnClient=documentName+'.csv', VersionData = Blob.valueOf(outputFile));
                insert doc;
          //query Contect version to get the content document id.
                ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :doc.Id];
                
                //create Contentworkspace to link the document to the library
                ContentWorkspaceDoc contentlink=new ContentWorkspaceDoc();
                contentlink.ContentDocumentId  = testContent.ContentDocumentId;
                contentlink.ContentWorkspaceId = compensationWS.Id;
                insert contentlink;
                
                //enqueue the record update to avoid future method limitations
              //pass in records to update and the batch Id 
                System.enqueueJob(new QueueClass(recordstoClose,batchId));
              
        }
              catch (Exception e) {
                
          //log the caught exception and return error response
          UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Compensation File Genetation Batch',
                          CompensationGenerateFile_Batchable.class.getName(), 'File Save',
                          null, LoggingLevel.ERROR);
          //send notification
          CompensationGenerateFile_Batchable.sendEmail('Compensation File Save Error','DLITCandSSalesForceSupport@auspost.com.au');
          
              }
          }
    }  
  }
  
  public class QueueClass implements Queueable {
    
      Set<Id> recordids;
      Integer batchId;
      List<Compensation__c> compstoUpdate = new List<Compensation__c>();
      //accepts a set of records to update and their new batch number
      public QueueClass(Set<Id> recordIds,Integer batch) {
          this.recordIds = recordIds;
          this.batchId = batch;
      }
      
      public void execute(QueueableContext context) {
      //update compensation records with the new batch Id and change the status to identify which records has been processed.
          for(Compensation__c c : [select Id, Name, Batch_Id__c, Status__c from Compensation__c where Id IN :recordIds]) {
             c.Status__c = 'Processing';
             c.Batch_Id__c = batchId;
             compstoUpdate.add(c);
          }
          Database.SaveResult[] saveResults = Database.update(compstoUpdate,false);
          //list to record errors if occured
          List<String> gotErrors = new List<String>();
          for(Database.SaveResult sr : saveResults) {
        if (!sr.isSuccess()) {
          //log the dml results
        UTIL_LoggingService.logDmlResults(new List<Database.Saveresult>{sr}, null, compstoUpdate, 'Compensation File Genetation Batch',
                          CompensationGenerateFile_Batchable.class.getName(), 'Compensation Status change', '', LoggingLevel.ERROR);
        gotErrors.add(sr.getErrors()[0].getMessage());
        }
          }
          //send notification
          if(!gotErrors.isEmpty()) {
        CompensationGenerateFile_Batchable.sendEmail('Compensation update batch Error','DLITCandSSalesForceSupport@auspost.com.au');
          }
      }
  }
    
    public static void sendEmail(String subject,String toAddress) {
        //send notification
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setToAddresses( new List<String> {toAddress} );
        mail.setPlainTextBody('Error occurred on '+CompensationGenerateFile_Batchable.class.getName()+'.\r\n Please check logs for details');

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    }
}