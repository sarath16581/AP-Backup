/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 03/01/2017    
  * @description  : This class is scheduled to run the batch class BSOTierReconciliation_Bachable
  */
/*******************************  History ************************************************
03/01/2017          snigdha.sahu@auspost.com.au   Created
    
*******************************  History ************************************************/
global without sharing class BSOTierReconciliation_Schedulable implements Schedulable {

    public static Integer BATCH_SIZE = 200;
    
    /** 
      * @name: execute()
      * @desciption: execution code lies in this method- here we run the batch class
      * @param: SchedulableContext sc
      * @return: NA
      *
      */
    global void execute(SchedulableContext sc) {
    
        BSOTierReconciliation_Batchable bsoBatch = new BSOTierReconciliation_Batchable();
        Database.executeBatch(bsoBatch, BATCH_SIZE);
    
    }
  
}