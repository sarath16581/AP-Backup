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
private class UnhandledExceptionEmailService_TEST{
    
    // Start of Constants for Test Methods
    
    private static final String ALIAS = 'unEr1';
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String TEST_EMAIL = 'automation@testapex.com';
    private static final String CLASS_NAME = 'CreateApexErrorLog';
    private static final String SUBJECT_DATA =  'Fwd: Force.com Sandbox: script exception from Accenture : '+
                                                'TestErrTrig : Attempted to schedule too '+ 
                                                'many concurrent batch jobs in this org (limit is 5)';                                                
    private static final String BODY_DATA_A = 'Apex script unhandled exception by user/organization: ';
    private static final String BODY_DATA_B =  '/00D90000000fOLB unhandled caused by: System.Exception: Attempted to schedule too'+
                                               ' many concurrent batch jobs '+ 
                                               'Class.CreateApexErrorLog.execute: Debug Log: Starts';
    
    // End of Constants for Test Methods
        
    /**
      * @description       Method to create Messaging.InboundEmail type test data.
      * @param             subject Subject of the email
      * @param             body Body of the email
      * @return            Messaging.InboundEmail
      * @throws            NA
      */
    private static Messaging.InboundEmail emailData(String subject, String body){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = subject;
        email.plainTextBody = body;
        email.fromAddress = TEST_EMAIL;
        return email;
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
      * @description       Method to verify Unhandled ExceptionLog__c record is logged when handleInboundEmail method
                           is called from UnhandledExceptionEmailService Class.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledException(){
        User runUser = UTIL_TestMethods.runningUser(ALIAS, SYSTEM_ADMIN);
        insert runUser; 
        severityLevelValue();
        String subject = SUBJECT_DATA;
        String body = UTIL_ErrorConstants.START_APEX_SCRIPT + UTIL_ErrorConstants.SANDBOX_EMAIL + BODY_DATA_A + runUser.Id + BODY_DATA_B;
                      
        Messaging.InboundEmail email1 = emailData(subject, body);
        Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope(); 
        
        UnhandledExceptionEmailService apexErrorLog = new UnhandledExceptionEmailService();
        
        Test.startTest();
        System.runAs(runUser){
            apexErrorLog.handleInboundEmail(email1,env1);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT Id, ClassName__c FROM ExceptionLog__c WHERE ClassName__c=:CLASS_NAME]; 
        System.assertEquals(excpData.ClassName__c, CLASS_NAME);
    }
}