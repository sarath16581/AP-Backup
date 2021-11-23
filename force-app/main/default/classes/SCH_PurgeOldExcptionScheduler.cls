/**
  * @author        Urmi Chatterjee
  * @date          09/10/2013
  * @description   This is Apex Schedulable Class which will invoke BATCH_PurgeOldExcption Batch Class that deletes exception records.
  * 
  * This software and all content is the property of ACCENTURE or its licensors, 
  * and is for the internal and confidential use of employees and authorized agents 
  * of ACCENTURE solely for the benefit of ACCENTURE and its affiliates.  
  * The software and contents are protected by copyright, trade secret and patent laws, 
  * and other local and international laws and treaties.  
  * Unauthorized use may subject the user to civil and criminal penalties.  
  * The software contains confidential information of ACCENTURE and its affiliates.  
  * You may not access, use, copy, install, modify, transfer, or distribute this software 
  * (electronically or otherwise), or create any copy, adaptation, transcription, or 
  * derivative thereof, except as expressly authorized by ACCENTURE.  
  * You may not divulge, disclose or communicate to any other third party, any of the 
  * confidential information contained in the software, including the software itself.  
  * ACCENTURE maintains full and exclusive right, title and ownership interest in and 
  * to the software and all copyright, patent, trade secret, trademark and other intellectual 
  * property rights therein.
  *
  */

global class SCH_PurgeOldExcptionScheduler implements Schedulable{    
    
    /**
      * @description       This method defines the query which determines which records are to be deleted and invokes the BATCH_PurgeOldExcption Batch Class to delete these records.
      * @param             context A reference to the SchedulableContext object
      * @return            void
      * @throws            NA
      */
    global void execute(SchedulableContext context){
         BatchRecordFilter__c exceptionBatchDays = new BatchRecordFilter__c(); 
         // Record fetched fromt the Custom Setting will depend on the User requirement
         exceptionBatchDays = BatchRecordFilter__c.getInstance(UTIL_ErrorConstants.BATCH_CUSTOM_SETTING_RECORD);
         
         BATCH_PurgeOldExcption batchVar = new BATCH_PurgeOldExcption();
         batchVar.queryString = 'SELECT Id FROM ExceptionLog__c WHERE CreatedDate = N_DAYS_AGO:'+
                                 Integer.valueOf(exceptionBatchDays.NoOfDays__c);
         Database.executeBatch(batchVar);
    }
}