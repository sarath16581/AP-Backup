global without sharing class CaseManagement_Schedulable implements Schedulable {

  //public static Integer BATCH_SIZE = BatchJobSettings__c.getInstance().OPC_Validation_Batch_Size__c.intValue();
    public static Integer BATCH_SIZE = 200;
    
  global void execute(SchedulableContext sc) {
    System.assert(BATCH_SIZE != null, 'BATCH_SIZE cannot be null!');
    
    
    CaseManagement_Batchable caseMgmt = new CaseManagement_Batchable();
    Database.executeBatch(caseMgmt, BATCH_SIZE);
  }
  
}