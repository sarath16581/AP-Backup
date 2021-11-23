/**************************************************
Type:       Apex Schedulable Batch Job Class for OPC Validation Service
Purpose:    Executes the OPCValidationService_Batchable class
Used By:    
History:
--------------------------------------------------
12-09-2013  Clinton McIntyre (Salesforce.com)    OPC Validation Rebuild
**************************************************/
global without sharing class OPCValidationService_Schedulable implements Schedulable {

  public static Integer BATCH_SIZE = BatchJobSettings__c.getInstance().OPC_Validation_Batch_Size__c.intValue();

  global void execute(SchedulableContext sc) {
    System.assert(BATCH_SIZE != null, 'BATCH_SIZE cannot be null!');
    OPCValidationService_Batchable opcvalidation = new OPCValidationService_Batchable(false);
    Database.executeBatch(opcvalidation, BATCH_SIZE);
  }
}