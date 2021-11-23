/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 07/09/2015    
  * @description  : This Class is scheduled to run the batch class SAPContracts_Agreements_Batchable
  */
/*******************************  History ************************************************
07/09/2015  snigdha.sahu@auspost.com.au   Created
    
*******************************  History ************************************************/
global without sharing class SAPContracts_Agreements_Schedulable implements Schedulable {

    public static Integer BATCH_SIZE = 200;
    
    /** 
      * @name: execute()
      * @desciption: execution code lies in this method- here we run the batch class
      * @param: SchedulableContext sc
      * @return: NA
      *
      */
    global void execute(SchedulableContext sc) {
    
        SAPContracts_Agreements_Batchable sapConAg = new SAPContracts_Agreements_Batchable();
        Database.executeBatch(sapConAg, BATCH_SIZE);
    
    }
  
}