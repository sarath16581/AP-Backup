/**
  * @author        Urmi Chatterjee
  * @date          21/10/2013
  * @description   Test Class for BATCH_PurgeOldExcption class.
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
private class BATCH_PurgeOldExcption_TEST{
    
    // Start of Constants for Test Methods
    
    private static final String ALIAS = 'btc';
    private static final Integer NUM = 1;
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String TEST_NAME = 'Test';
    
    
    // End of Constants for Test Methods
    
    /**
      * @description       Method to create ExceptionLog__c test record. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static void exceptionData(){
        ExceptionLog__c excpRec = new ExceptionLog__c(ExceptionDetails__c=TEST_NAME);
        insert excpRec;
    }
    
    /**
      * @description       Method to create Custom Setting record to determine severity level. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public static void severityLevelValue(){
        LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
        logLevel.LoggingLevel__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
        insert logLevel;  
    }
    
    /**
      * @description       Test method to verify if the batch class successfully deletes ExceptionLog__c record 
                           which were created 30 days prior to today.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testmethod void dataDelete(){
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM, SYSTEM_ADMIN);
        exceptionData();
        severityLevelValue();
        ExceptionLog__c[] excpRec = Database.query('Select Id From ExceptionLog__c Where CreatedDate < N_DAYS_AGO:30');
        Database.BatchableContext currentScope;
        BATCH_PurgeOldExcption batchVar = new BATCH_PurgeOldExcption();
        Test.startTest();
        System.runAs(runUser){
            batchVar.execute(currentScope, excpRec);
        }
        Test.stopTest();
        excpRec = Database.query('Select Id From ExceptionLog__c Where CreatedDate < N_DAYS_AGO:30');
        System.assert(excpRec.isEmpty());
    }
    
    /**
      * @description       Test method to verify if the batch class throws an exception when we delete all ExceptionLog__c records
                           and delete the same records again.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testmethod void dataDeleteException(){
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+1, SYSTEM_ADMIN);
        exceptionData();
        severityLevelValue();
        ExceptionLog__c[] excpRec = Database.query('Select Id From ExceptionLog__c Where CreatedDate < TOMORROW');
        ExceptionLog__c[] excpRecCopy = excpRec;
        String excpId = excpRec[0].Id;
        Database.BatchableContext currentScope;
        BATCH_PurgeOldExcption batchVar = new BATCH_PurgeOldExcption();
        Test.startTest();
        System.runAs(runUser){
            batchVar.execute(currentScope, excpRec);
            batchVar.execute(currentScope, excpRecCopy);
        }
        Test.stopTest();
        excpRec = Database.query('Select Id From ExceptionLog__c Where CreatedDate < TOMORROW');
        System.assertNotEquals(excpRec[0].Id, excpId);
    }
}