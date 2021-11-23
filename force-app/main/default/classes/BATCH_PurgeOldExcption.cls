/**
  * @author        Urmi Chatterjee
  * @date          16/10/2013
  * @description   Batch Class for Deleting ExceptionLog__c records which have CreatedDate prior to certain number of days from today, based on User requirement.
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

global class BATCH_PurgeOldExcption implements Database.Batchable<sObject> {

    public String queryString; 
    
    /**
      * @description       This method queries the soql query defined in the scheduler class and passes the List of records obtained to the execute method.
      * @param             currentScope A reference to the Database.BatchableContext object
      * @return            Database.QueryLocator
      * @throws            NA
      */
    global Database.QueryLocator start(Database.BatchableContext currentScope){
         return Database.getQueryLocator(queryString);
    }
    
    /**
      * @description       This method deletes the List of records passed to it and in case of a failure logs an ExceptionLog__c record.
      * @param             currentScope A reference to the Database.BatchableContext object
      * @param             queryResult List of the records obtained in the start() method
      * @return            void
      * @throws            NA
      */
    global void execute(Database.BatchableContext currentScope, List<sObject> queryResult){
        List<ExceptionLog__c> faultLogList = new List<ExceptionLog__c>();
        ExceptionLog__c excpData = new ExceptionLog__c();
        Database.DeleteResult[] dmlExResult = Database.Delete(queryResult, false);
        
        // Optional code to be included only when including error handling framework
        for(Database.DeleteResult dmlDelete : dmlExResult){
            if(!dmlDelete .isSuccess()){
                Database.Error[] errorMsg = dmlDelete.getErrors();
                String exceptionCode = UTIL_ErrorConstants.BLANK_SPACE;
                if (errorMsg.size() > 0){
                    exceptionCode = errorMsg[0].statusCode.name();
                }
                excpData = new ExceptionLog__c(ExceptionDetails__c = String.valueOf(errorMsg).left(32000), ClassName__c = UTIL_ErrorConstants.BATCH_CLASS_NAME,
                                               ExceptionType__c = UTIL_ErrorConstants.DML_EXCEPTION, ExceptionLogTimestamp__c = System.Now(),
                                               isHandled__c = true, MethodName__c = UTIL_ErrorConstants.BATCH_METHOD_NAME, ContextUser__c = UserInfo.getUserId(),
                                               OrgId__c = UserInfo.getOrganizationId(), 
                                               Severity__c=LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId()).LoggingLevel__c, 
                                               ExceptionCode__c = exceptionCode); 
            }
            faultLogList.add(excpData);
        }        
        if(!faultLogList.isEmpty()){
            UTIL_LoggingService.logListException(faultLogList);
        }
        // End of Optional Code
    }

    /**
      * @description       This method implements finish logic for the Batch Class
      * @param             currentScope A reference to the Database.BatchableContext object
      * @return            void
      * @throws            NA
      */
    global void finish(Database.BatchableContext currentScope){
    }
}