/**
  * @author        Urmi Chatterjee
  * @date          21/10/2013
  * @description   Test Class for SCH_PurgeOldExcptionScheduler class.
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

@isTest
private class SCH_PurgeOldExcptionScheduler_TEST{
    
    // Start of Constants for Test Methods
    
    private static final String ALIAS = 'sch1';
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String CUSTOM_SETTING_RECORD = 'ExceptionRecordDeletionFilter';
    private static final String SCHEDULED_TIME = '0 0 23 * * ?';
    private static final String JOB_NAME = 'Test Check';
    private static final String JOB_STATUS = 'WAITING';
    
    // End of Constants for Test Methods

    /**
      * @description       Test method to verify whether the scheduler class successfully calls 
                           BATCH_PurgeOldExcption class, which deletes ExceptionLog__c records.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void scheduleDelete(){
        User runUser = UTIL_TestMethods.runningUser(ALIAS, SYSTEM_ADMIN);
        BatchRecordFilter__c exceptionBatchDays = new BatchRecordFilter__c(Name=CUSTOM_SETTING_RECORD, NoOfDays__c=30);
        insert exceptionBatchDays;
        SCH_PurgeOldExcptionScheduler schVar = new SCH_PurgeOldExcptionScheduler();
        String sch = SCHEDULED_TIME ;
        String jobId = UTIL_ErrorConstants.BLANK_SPACE;
        Test.StartTest();
        System.runAs(runUser){
            jobId = System.Schedule(JOB_NAME, sch, schVar);
        }
        Test.stopTest();
        CronTrigger schData = [SELECT Id, State FROM CronTrigger WHERE Id =: jobId];
        System.assertEquals(schData.State, JOB_STATUS);                  
    }
}