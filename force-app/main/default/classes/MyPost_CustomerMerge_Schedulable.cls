/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 17/03/2015    
  * @description  : This Class is scheduled to run the batch class to monitor the customers being merged and 
                    to flag the loosing record and merge the loosing record details into the winning record
  */
/*******************************  History ************************************************
17/03/2016  kalpita.talwadekar@auspost.com.au   Created
    
*******************************  History ************************************************/
global without sharing class MyPost_CustomerMerge_Schedulable implements Schedulable {

    public static Integer BATCH_SIZE = 200;
    
    /** 
      * @name: execute()
      * @desciption: execution code lies in this method- here we run the batch class
      * @param: SchedulableContext sc
      * @return: NA
      *
      */
    global void execute(SchedulableContext sc) {
    
        MyPost_CustomerMerge_Batchable caseMgmt = new MyPost_CustomerMerge_Batchable();
        Database.executeBatch(caseMgmt, BATCH_SIZE);
        
        MyPost_PortalUserEdits userEdits = new MyPost_PortalUserEdits();
        Database.executeBatch(userEdits , BATCH_SIZE);
        
        MyPost_PortalCustomerMerge_Batchable caseMgmt2 = new MyPost_PortalCustomerMerge_Batchable();
        Database.executeBatch(caseMgmt2, BATCH_SIZE);
    
    }
  
}