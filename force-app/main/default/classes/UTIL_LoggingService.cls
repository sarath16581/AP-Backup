/**
  * @author        Urmi Chatterjee
  * @date          04/10/2013
  * @description   UTIL class for the purpose of logging handled and unhandled exceptions in the form of ExceptionLog__c record.
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
	31-Jan-2018 - Removed updating error count on existing error log. Nanda Kothamasu - INC1071063
  */

public with sharing class UTIL_LoggingService{ 

    /**
      * @description       This method logs ExceptionLog__c records in case of Exception obtained due to Database.convertLead operation.
      * @param             leadConvertResultResults A List of Database.LeadConvertResult object records
      * @param             relatedsObjects A List of sObject records which threw the exception when being saved
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             level the system.LoggingLevel variable to determine the exception level
      * @return            void
      * @throws            NA
      */
    public static void LogConvertLeadResult(List<Database.LeadConvertResult> leadConvertResultResults, List<sObject> relatedsObjects,
        String appName, String className, string methodName, String triggerName, System.LoggingLevel level) {

        List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();

        if (exceptionLogMeetsSeverityFilter(level.name())){            
            for(integer i=0; i < leadConvertResultResults.size(); ++i) {
                Database.LeadConvertResult currentResultRec = leadConvertResultResults[i];
                if(!currentResultRec.isSuccess()) {
                    Database.Error[] errors = currentResultRec.getErrors();
                    String relatedObjectString = UTIL_ErrorConstants.BLANK_SPACE;
                    if (relatedsObjects.size() > i) {
                        relatedObjectString = UTIL_ErrorConstants.RELATED_OBJECT + relatedsObjects[i];
                    }
                    String errorMessage = (buildErrorMessageFromErrorList(currentResultRec.getLeadId(), errors) + 
                                          relatedObjectString.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT));
                    String exceptionCode = UTIL_ErrorConstants.BLANK_SPACE;
                    if (errors.size() > 0) {
                        exceptionCode = errors[0].statusCode.name();
                    }
                    exceptionLogList.add(new ExceptionLog__c(Application__c = appName, ExceptionCode__c=exceptionCode, 
                                                            ClassName__C =className, MethodName__c = methodname,
                                                            ContextUser__c = UserInfo.getUserId(), NumberOfTimesOccured__c=1,
                                                            ExceptionLogTimestamp__c = System.Now(), ApexTrigger__c=triggerName, 
                                                            ExceptionDetails__c = errorMessage, Severity__c = level.name(),
                                                            ExceptionType__c = UTIL_ErrorConstants.DML_EXCEPTION, isHandled__c = true));
                }
            }
        }     

        if (exceptionLogList.size() > 0) {
             Database.insert(exceptionLogList, false);
        }
    }
    
    /**
      * @description       This method logs ExceptionLog__c records in case of Exception obtained due to Database.SaveResult or Database.DeleteResult operation.
      * @param             svResults A List of Database.Saveresult object records
      * @param             delResults A List of Database.Deleteresult object records
      * @param             objs A List of sObject records which threw the exception when being saved
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             level the system.LoggingLevel variable to determine the exception level
      * @return            void
      * @throws            NA
      */
     public static void logDmlResults(List<Database.Saveresult> svResults, List<Database.DeleteResult> delResults, 
                                      List<sObject> objs, String appName, String className, String methodName, String triggerName, 
                                      system.LoggingLevel level){
         List<ExceptionLog__c>  exceptionLogList = new List<ExceptionLog__c>();
         // Method called in case of save exception
         if(svResults!=null && delResults==null){
             exceptionLogList = createExceptionForSaveResults(svResults, objs, appName, className, methodName, triggerName, level);
         }
         
         // Method called in case of delete exception
         else if(delResults!=null && svResults==null){
             exceptionLogList = createExceptionsForDeleteResults(delResults, objs, appName, className, methodName, triggerName, level);
         }
         
         // Implementing logic to check if this record can be merged with any pre-existing ExceptionLog__c record
         if (exceptionLogList.size() > 0 && svResults!=null && delResults==null) {
             
             List<ExceptionLog__c> mergeLogList = new List<ExceptionLog__c>();                          
             mergeLogList = mergeExistingErrorLogs(exceptionLogList);
             insertExceptionList(mergeLogList);                                                    
         }
         else if (exceptionLogList.size() > 0 && delResults!=null && svResults==null) {
             Database.insert(exceptionLogList, false);
         }
     }
     
     
    /**
      * @description       This method creates ExceptionLog__c records in case of Exception obtained due to Database.SaveResult operation.
      * @param             svResults A List of Database.Saveresult object records
      * @param             relatedsObjects A List of sObject records which threw the exception when being saved
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             level the system.LoggingLevel variable to determine the exception level
      * @return            List<ExceptionLog__c>
      * @throws            NA
      */
     private static List<ExceptionLog__c> createExceptionForSaveResults(List<Database.SaveResult> saveResults, 
                                                                        List<sObject> relatedsObjects, String appName, 
                                                                        String className, string methodName, String triggerName,
                                                                        System.LoggingLevel level) {
         List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();
         if (exceptionLogMeetsSeverityFilter(level.name())){            
             for(integer i=0; i <saveResults.size(); ++i) {
                 Database.SaveResult saveresult = saveResults[i];
                 if(!saveresult.isSuccess()) {
                     Database.Error[] errors = saveresult.getErrors();
                     String relatedObjectString = UTIL_ErrorConstants.BLANK_SPACE;
                     if (relatedsObjects.size() > i) {
                         relatedObjectString = UTIL_ErrorConstants.RELATED_OBJECT + relatedsObjects[i];
                     }
                     String errorMessage = (buildErrorMessageFromErrorList(saveresult.getId(), errors) + 
                                            relatedObjectString.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT));
                     
                     String exceptionCode = UTIL_ErrorConstants.BLANK_SPACE;
                     if (errors.size() > 0) {
                         exceptionCode = errors[0].statusCode.name();
                     }
                     exceptionLogList.add(new ExceptionLog__c(Application__c = appName, ExceptionCode__c=exceptionCode, 
                                                              ClassName__C =className, MethodName__c = methodname,
                                                              ContextUser__c = UserInfo.getUserId(), NumberOfTimesOccured__c=1,
                                                              ExceptionLogTimestamp__c = System.Now(), ApexTrigger__c=triggerName, 
                                                              ExceptionDetails__c = errorMessage, Severity__c = level.name(),
                                                              ExceptionType__c = UTIL_ErrorConstants.DML_EXCEPTION, isHandled__c = true));
                 }
             }
         }
         return exceptionLogList;    
     }
     
     //create exception log for upsert result
     public static void createExceptionForUpsertResults(List<Database.UpsertResult> upsertResults, 
                                                                        List<sObject> relatedsObjects, String appName, 
                                                                        String className, string methodName, String triggerName,
                                                                        System.LoggingLevel level) {
         List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();
         if (exceptionLogMeetsSeverityFilter(level.name())){            
             for(integer i=0; i <upsertResults.size(); ++i) {
                 Database.UpsertResult upsertResult = upsertResults[i];
                if(!upsertResult.isSuccess()) {
                    Database.Error[] errors = upsertResult.getErrors();
                     String relatedObjectString = UTIL_ErrorConstants.BLANK_SPACE;
                     if (relatedsObjects.size() > i) {
                         relatedObjectString = UTIL_ErrorConstants.RELATED_OBJECT + relatedsObjects[i];
                     }
                     String errorMessage = (buildErrorMessageFromErrorList(upsertResult.getId(), errors) + 
                                            relatedObjectString.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT));
                     
                     String exceptionCode = UTIL_ErrorConstants.BLANK_SPACE;
                     if (errors.size() > 0) {
                         exceptionCode = errors[0].statusCode.name();
                     }
                     exceptionLogList.add(new ExceptionLog__c(Application__c = appName, ExceptionCode__c=exceptionCode, 
                                                              ClassName__C =className, MethodName__c = methodname,
                                                              ContextUser__c = UserInfo.getUserId(), NumberOfTimesOccured__c=1,
                                                              ExceptionLogTimestamp__c = System.Now(), ApexTrigger__c=triggerName, 
                                                              ExceptionDetails__c = errorMessage, Severity__c = level.name(),
                                                              ExceptionType__c = UTIL_ErrorConstants.DML_EXCEPTION, isHandled__c = true));
                 }
             }
         }
         if(exceptionLogList.size()>0){
            Database.insert(exceptionLogList, false);
         }     
     }




    /**
      * @description       This method creates ExceptionLog__c records in case of Exception obtained due to Database.DeleteResult operation.
      * @param             deleteResults A List of Database.DeleteResult object records
      * @param             relatedsObjects A List of sObject records which threw the exception when being saved
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             level the system.LoggingLevel variable to determine the exception level
      * @return            List<ExceptionLog__c>
      * @throws            NA
      */
     private static List<ExceptionLog__c> createExceptionsForDeleteResults(List<Database.DeleteResult> deleteResults, 
                                                                           List<sObject> relatedsObjects, String appName, 
                                                                           String className, String methodName, String triggerName, 
                                                                           System.LoggingLevel level) {
         List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();
         if (exceptionLogMeetsSeverityFilter(level.name())){            
             for(integer i = 0; i < deleteResults.size(); ++i) {
                 Database.DeleteResult delResults = deleteResults[i];
                 if(!delResults.isSuccess()) {
                     Database.Error[] errors = delResults.getErrors();
                     String relatedObjectString = UTIL_ErrorConstants.BLANK_SPACE;
                     if (relatedsObjects.size() > i) {
                             relatedObjectString = UTIL_ErrorConstants.RELATED_OBJECT + relatedsObjects[i];
                     }
                     String errorMessage = (buildErrorMessageFromErrorList(delResults.getId(), errors) + 
                                                relatedObjectString.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT));                    
                     String exceptionCode = UTIL_ErrorConstants.BLANK_SPACE;
                     if (errors.size() > 0){
                         exceptionCode = errors[0].statusCode.name();
                     }
                     exceptionLogList.add(new ExceptionLog__c(Application__c = appName , ExceptionCode__c=exceptionCode, 
                                                              ClassName__c = className, MethodNAme__C = methodName,   
                                                              ContextUser__c = UserInfo.getUserId(), NumberOfTimesOccured__c=1,
                                                              ExceptionLogTimestamp__c = System.Now(), ApexTrigger__c=triggerName, 
                                                              ExceptionDetails__c = errorMessage, Severity__c = level.name(),
                                                              ExceptionType__c = UTIL_ErrorConstants.DML_EXCEPTION, isHandled__c = true));
                 }
             }
         }
         return exceptionLogList;
     }
     
    /**
      * @description       This method compares in the List of ExceptionLog__c records to be inserted to
                           check if any record is repeated. If so, that record is eliminated.
      * @param             mergeLogList the List of ExceptionLog__c records obtained from the merge method
      * @return            void
      * @throws            NA
      */
     private static void insertExceptionList(List<ExceptionLog__c> mergeLogList){
         
         List<ExceptionLog__c> filteredList = new List<ExceptionLog__c>();
         ExceptionLog__c copyExcp = new ExceptionLog__c();
         
         for(ExceptionLog__c exceptionLog : mergeLogList){
             if(filteredList.size() == 0){
                  filteredList.add(exceptionLog);
             }
             else{                       
                 for(ExceptionLog__c excpRec: filteredList){
                      if(String.isNotBlank(excpRec.ExceptionDetails__c) && excpRec.ExceptionDetails__c.equalsIgnoreCase(exceptionLog.ExceptionDetails__c) &&
                        (((String.isNotBlank(excpRec.ClassName__c) && excpRec.ClassName__c.equalsIgnoreCase(exceptionLog.ClassName__c)) && 
                          (String.isNotBlank(excpRec.MethodName__c) && excpRec.MethodName__c.equalsIgnoreCase(exceptionLog.MethodName__c))) ||
                         (String.isNotBlank(excpRec.ApexTrigger__c) && excpRec.ApexTrigger__c.equalsIgnoreCase(exceptionLog.ApexTrigger__c)))){
                         excpRec.NumberOfTimesOccured__c = (excpRec.NumberOfTimesOccured__c == null?1:excpRec.NumberOfTimesOccured__c) + 1;
                         copyExcp = null;                                 
                      }
                      else{
                          copyExcp = exceptionLog;
                      }
                 }
                 if(copyExcp != null){
                      filteredList.add(copyExcp);
                 } 
             } 
         }                                                            
         if (!filteredList.isEmpty()) {
             Database.insert(filteredList, false);
         }
     }
    
    
    /**
      * @description       This method is called in case the User obtains a handled Exception. This method in turn calls methods to build and insert ExceptionLog__c records. It also checks if the record can be merged with a pre-existing record.
      * @param             excp the Exception object
      * @param             orgID the organization ID
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             severity the system.LoggingLevel variable to determine the exception level
      * @return            void
      * @throws            NA
      */


    public static void logHandledException(Exception excp, String orgID, String applicationName, String className, String methodName, String triggerName, System.LoggingLevel severity){
        logHandledException(excp, orgID, applicationName, className, methodName, triggerName, severity, '');
    }

    // overload to add the additional info
    public static void logHandledException(Exception excp, String orgID, String applicationName, String className, String methodName, String triggerName, System.LoggingLevel severity, String additionalInfo){

        List<ExceptionLog__c> excpLogVal = new List<ExceptionLog__c>();

        ExceptionLog__c exceptionLog = buildExceptionObject(excp, orgID, applicationName, className, methodName, severity, null, null, triggerName, null, null, null, true); 
        exceptionLog.AdditionalInformation__c = additionalInfo;

        excpLogVal = mergeExistingErrorLogs(new List<ExceptionLog__c>{exceptionLog});
            
        if(excpLogVal!=null && excpLogVal.size()==1){
            logException(exceptionLog);
        }
    }
     
    /**
      * @description       This method is called in case of an unhandled Exception. This method in turn calls processExceptionEmail method to build and insert ExceptionLog__c records.
      * @param             email A reference to the Messaging.InboundEmail object
      * @return            void
      * @throws            NA
      */
     public static void logUnhandledException(Messaging.InboundEmail email){
         Boolean isSandBoxEmail = false;
         if((email.subject.contains(UTIL_ErrorConstants.SANDBOX_EMAIL) || email.plainTextBody.contains(UTIL_ErrorConstants.SANDBOX_EMAIL))){
             isSandboxEmail = true;           
         }
         processExceptionEmail(email, isSandboxEmail);        
     }
     
    /**
      * @description       This method is called by logUnhandledException method. This method builds and inserts ExceptionLog__c records. Also checks if this record can be merged with any pre-existing record.
      * @param             email A reference to the Messaging.InboundEmail object
      * @param             isSandboxEmail the boolean variable to determine if email is generated by a sandbox environment
      * @return            void
      * @throws            Exception
      */
     private static void processExceptionEmail(Messaging.InboundEmail email, boolean isSandboxEmail){
         
         //Variables for Exception Details
         String mailSub=UTIL_ErrorConstants.BLANK_SPACE;
         String emailBody = email.plainTextBody;
         String exceptionName=UTIL_ErrorConstants.BLANK_SPACE;
         String codeSnippet=UTIL_ErrorConstants.BLANK_SPACE;     
         String triggerName=UTIL_ErrorConstants.BLANK_SPACE;
         String className=UTIL_ErrorConstants.BLANK_SPACE;
         String methodName=UTIL_ErrorConstants.BLANK_SPACE;
         String user = UTIL_ErrorConstants.BLANK_SPACE;
         String orgId = UTIL_ErrorConstants.BLANK_SPACE;
         String apexErrMsg = UTIL_ErrorConstants.BLANK_SPACE;   
         //End of Variables for Exception Details
         
         List<ExceptionLog__c> exceptionLogList = new List<ExceptionLog__c>();                 
         ExceptionLog__c exceptionLog = new ExceptionLog__c();
         
         try{
            // Method call to get the mail Subject
            mailSub = mailSubjectVal(email, isSandboxEmail);
             
             // Method to get the code snippet
            codeSnippet = codeSnipVal(mailSub);
            
            // Method to get the type of exception thrown
            exceptionName = exceptionType(mailSub, emailBody);
             
             // Method to get only the Original Error msg
            apexErrMsg = errorMessage(emailBody);
             
            // Logic to get the Apex Class name and Method name if there any
            if(apexErrMsg.contains(UTIL_ErrorConstants.PREFIX_CLASS)){
                 className = apexErrMsg.substring(apexErrMsg.indexOf(UTIL_ErrorConstants.PREFIX_CLASS) + UTIL_ErrorConstants.PREFIX_CLASS.length());
                 methodName = className.substring(className.indexOf(UTIL_ErrorConstants.FULLSTOP)+1, className.indexOf(UTIL_ErrorConstants.COLON)).trim();
                 className = className.substring(0, className.indexOf(UTIL_ErrorConstants.FULLSTOP)).trim();
             }
             
             // Logic to get Apex Trigger name if there is any
             if(apexErrMsg.contains(UTIL_ErrorConstants.PREFIX_TRIGGER)){
                 triggerName = apexErrMsg.substring(apexErrMsg.indexOf(UTIL_ErrorConstants.PREFIX_TRIGGER) + UTIL_ErrorConstants.PREFIX_TRIGGER.length());
                 triggerName = triggerName.substring(0, triggerName.indexOf(UTIL_ErrorConstants.COLON)).trim();
             }
             
             // Logic to get the Context User and The Organization Id
             if(apexErrMsg.contains(UTIL_ErrorConstants.USER)){
                 user = apexErrMsg.subString(apexErrMsg.indexOf(UTIL_ErrorConstants.USER)+UTIL_ErrorConstants.USER.length());
                 String userId = user.subString(user.indexOf(UTIL_ErrorConstants.COLON)+1,user.indexOf(UTIL_ErrorConstants.FORWARD_SLASH)).trim();
                 orgId = user.subString(user.indexOf(UTIL_ErrorConstants.FORWARD_SLASH)+1,user.indexOf(UTIL_ErrorConstants.FORWARD_SLASH)+userId.length()+1).trim();
                 user = userId;
             }
             
             exceptionLog = buildExceptionObject(null, orgId, null, className, methodName, null, apexErrMsg, exceptionName, triggerName,
                                                    UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR , 
                                                    user, codeSnippet,  false);  
                 
             exceptionLogList = mergeExistingErrorLogs(new List<ExceptionLog__c>{exceptionLog});
             
             if(exceptionLogList!=null && exceptionLogList.size()==1){  
                 logException(exceptionLog);
             }                    
         }
         catch(Exception excp){
             logHandledException(excp, UserInfo.getOrganizationId(), UTIL_ErrorConstants.ERROR_APPLICATION, UTIL_ErrorConstants.ERROR_LOG_CLASS, 
                                 UTIL_ErrorConstants.UNHANDLED_ERROR_LOG_METHOD, null, LoggingLevel.ERROR);
         }
     }
     
    /**
      * @description       This method is called by processExceptionEmail method to obtain the mail subject from the Inbound email.
      * @param             email A reference to the Messaging.InboundEmail object
      * @param             isSandboxEmail the boolean variable to determine if email is generated by a sandbox environment
      * @return            String
      * @throws            NA
      */
     private static String mailSubjectVal(Messaging.InboundEmail email, boolean isSandboxEmail){
        String mailSub = UTIL_ErrorConstants.BLANK_SPACE;
        // Storing Subject line to remove forwarded characters
         if(email.subject.toLowerCase().startsWith(UTIL_ErrorConstants.PREFIX_FW)){
             mailSub = email.subject.substring(UTIL_ErrorConstants.PREFIX_FW.length());
         }
         else if(email.subject.toLowerCase().startsWith(UTIL_ErrorConstants.PREFIX_FWD)){
             mailSub = email.subject.substring(UTIL_ErrorConstants.PREFIX_FWD.length());
         }
         else if(email.subject.toLowerCase().startsWith(UTIL_ErrorConstants.PREFIX_RE)){
             mailSub = email.subject.substring(UTIL_ErrorConstants.PREFIX_RE.length());
         }
         else{
             mailSub = email.subject;
         }
         //Checks if email came from Sandbox
         if(isSandboxEmail){
             mailSub = mailSub.substring(mailSub.indexOf(UTIL_ErrorConstants.SANDBOX_EMAIL) + UTIL_ErrorConstants.SANDBOX_EMAIL.length() + 1, 
                                                         mailSub.length());
         }
         return mailSub;
     }
     
     
    /**
      * @description       This method is called by processExceptionEmail method to obtain the code snippet from the mail subject of the Inbound email.
      * @param             mailSub the String containing the Subject of the mail
      * @return            String
      * @throws            NA
      */
     private static String codeSnipVal(String mailSub){
         String codeSnippet = UTIL_ErrorConstants.BLANK_SPACE;
        // Logic to get the code Snippet
         codeSnippet = mailSub.substring(mailSub.indexOf(UTIL_ErrorConstants.COLON) + 1, mailSub.length());
         codeSnippet = codeSnippet.substring(codeSnippet.indexOf(UTIL_ErrorConstants.COLON)+1, codeSnippet.length()).trim();        
         return codeSnippet;
     }
     
    
    /**
      * @description       This method is called by processExceptionEmail method to obtain the exception type from the mail subject or email body.
      * @param             mailSub the String containing the Subject of the mail
      * @param             emailBody the String containing the body of the mail
      * @return            String
      * @throws            NA
      */
     private static String exceptionType(String mailSub, String emailBody){
        String exceptionName = UTIL_ErrorConstants.BLANK_SPACE;
        // Checks if Subject contains Caused By:
         if(mailSub.contains(UTIL_ErrorConstants.CAUSED_BY)){       
             exceptionName = mailSub.substring(mailSub.indexOf(UTIL_ErrorConstants.CAUSED_BY) + UTIL_ErrorConstants.CAUSED_BY.length(), mailSub.length());
             exceptionName = exceptionName.substring(0, exceptionName.indexOf(UTIL_ErrorConstants.COLON));
         }
         // Checks if email body contains Caused By:
         else if(emailBody.contains(UTIL_ErrorConstants.CAUSED_BY)){            
             exceptionName = emailBody.substring(emailBody.indexOf(UTIL_ErrorConstants.CAUSED_BY) + UTIL_ErrorConstants.CAUSED_BY.length(), emailBody.length());
             exceptionName = exceptionName.substring(0, exceptionName.indexOf(UTIL_ErrorConstants.COLON));
         }
         else{
             // Else set the default value for exception
             exceptionName = UTIL_ErrorConstants.OTHER_EXCEPTION;
         }
         exceptionName = exceptionName.trim();
         return exceptionName;
     }
     
     
    /**
      * @description       This method is called by processExceptionEmail method to obtain the actual error message from the email body.
      * @param             emailBody the String containing the body of the mail
      * @return            String
      * @throws            NA
      */
     private static String errorMessage(String emailBody){
        String apexErrMsg = UTIL_ErrorConstants.BLANK_SPACE;
        if(emailBody.contains(UTIL_ErrorConstants.START_APEX_SCRIPT) && !emailBody.contains(UTIL_ErrorConstants.SANDBOX_EMAIL)){ 
            apexErrMsg = emailBody.substring(emailBody.indexOf(UTIL_ErrorConstants.START_APEX_SCRIPT)); 
         }
         else if(emailBody.contains(UTIL_ErrorConstants.START_APEX_SCRIPT) && emailBody.contains(UTIL_ErrorConstants.SANDBOX_EMAIL)){
             apexErrMsg = emailBody.substring(emailBody.indexOf(UTIL_ErrorConstants.SANDBOX_EMAIL)); 
         }
         else {
             apexErrMsg = emailBody;
         }
         apexErrMsg = apexErrMsg.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT);
         return apexErrMsg;
     }
         
     
     /**
      * @description       This method is called to log ExceptionLog__c record, when an Exception occurs due to a Webservice call in the code.                          
      * @param             emailBody the String containing the body of the mail
      * @return            ex The Exception Object
      * @param             orgID the organization ID
      * @param             appName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             triggerName the Trigger Name
      * @param             severity the system.LoggingLevel variable to determine the exception level
      * @param             ws_application the Webservice Application Name
      * @param             ws_callingArea the Webservice Calling Area Name
      * @param             ws_transactionID the Webservice Transaction Id
      * @param             handled the boolean value defining if the Exception is handled or unhandled
      * @throws            NA
      */
     public static void logServiceException (Exception ex, String orgID, String applicationName, String className, 
                                             String methodName, String triggerName, System.LoggingLevel severity, String ws_application, 
                                             String ws_callingArea, String ws_transactionID, Boolean handled){
        
        List<ExceptionLog__c> filteredRecords = new List<ExceptionLog__c>();
        
        ExceptionLog__c exceptionLog = buildExceptionObject(ex, orgID, applicationName, className, methodName, severity,
                                                            null, null, triggerName, null, null, null, handled);
        exceptionLog.WSCallingApplication__c = ws_application;
        exceptionLog.WSCallingArea__c = ws_callingArea;
        exceptionLog.WSTransactionID__c = ws_transactionID;
        
        filteredRecords = mergeExistingErrorLogs(new List<ExceptionLog__c>{exceptionLog});
        
        if(filteredRecords!=null && filteredRecords.size()==1){            
            logException(exceptionlog);
        }
    }
     
     
    /**
      * @description       This method is called by multiple methods, to check if the current ExceptionLog__c record can be merged with any pre-existing record if they have the same class and method name or trigger name. 
      * @param             exceptionLogList the List of Exceptions__c records to be inserted
      * @return            List<ExceptionLog__c>
      * @throws            NA
      */
     private static List<ExceptionLog__c> mergeExistingErrorLogs(List<ExceptionLog__c> exceptionLogList){        
         
         String lineColumn = UTIL_ErrorConstants.BLANK_SPACE;
          List<ExceptionLog__c> exceptionLogToBeInserted = new List<ExceptionLog__c>();
          exceptionLogToBeInserted.addAll(exceptionLogList); // Added by NK
		  return exceptionLogToBeInserted;
        /*  Commented by Nanda Kothamasu - INC1071063
        	List<String> exceptionType = new List<String>();                
            List<ExceptionLog__c> existingExceptionLogs   = new List<ExceptionLog__c>();  
         	List<ExceptionLog__c> exExcpLogs = new List<ExceptionLog__c>();               
         	List<ExceptionLog__c> exceptionLogToBeUpdated = new List<ExceptionLog__c>();  
          	Set<ExceptionLog__c> logList = new Set<ExceptionLog__c>();    
         
			for(ExceptionLog__c excp: exceptionLogList){
              exceptionType.add(excp.ExceptionType__c); // Removed by NK
         	}
         
         existingExceptionLogs = [SELECT Id, Name, ApexTrigger__c, MethodName__c, ClassName__c, ExceptionDetails__c, 
                                         ExceptionLogTimestamp__c, NumberOfTimesOccured__c, ContextUser__c,
                                         WSCallingApplication__c, WSCallingArea__c, WSTransactionID__c, ExceptionType__c 
                                  FROM ExceptionLog__c
                                  WHERE ExceptionType__c IN: exceptionType LIMIT 50000];
                            
         for(ExceptionLog__c excp: exceptionLogList){
             exExcpLogs = new List<ExceptionLog__c>();
             if(String.isNotBlank(excp.ExceptionDetails__c) && excp.ExceptionDetails__c.contains(UTIL_ErrorConstants.LINE_NO)){
                 lineColumn = excp.ExceptionDetails__c.substring(0, excp.ExceptionDetails__c.IndexOf(UTIL_ErrorConstants.LINE_NO));
             }
             else{
                 lineColumn = excp.ExceptionDetails__c;
             }
             if(String.isNotBlank(excp.ExceptionType__c)){
                 for(ExceptionLog__c  exExcp : existingExceptionLogs){
                     if(excp.ExceptionType__c.equalsIgnoreCase(exExcp.ExceptionType__c)){
                         exExcpLogs.add(exExcp);
                     }
                 }  
             } 
             logMergeException(exExcpLogs, lineColumn, excp, exceptionLogToBeUpdated, exceptionLogToBeInserted );
         }
         if(!exceptionLogToBeupdated.isEmpty()){            
             logList.addAll(exceptionLogToBeupdated);
             exceptionLogToBeupdated.clear();
             exceptionLogToBeupdated.addAll(logList);
             Database.update(exceptionLogToBeupdated, false);
         }
		*/
         
     }
     
     
    /**
      * @description       This method is called by mergeExistingErrorLogs method, to update the pre-existing ExceptionLog__c record which is to be merged with the new ExceptionLog__c record.  
      * @param             existingErrorLogs the List of pre-existing ExceptionLog__c records
      * @param             lineColumn the String containing the edited errorDescription
      * @param             newExcp the ExceptionLog__c record to be inserted
      * @param             exceptionLogToBeUpdated the List of pre-existing ExceptionLog__c records to be updated
      * @param             exceptionLogToBeInserted the List of ExceptionLog__c records to be inserted
      * @return            void
      * @throws            Exception
      */
     private static void logMergeException(List<ExceptionLog__c> existingErrorLogs, String lineColumn, ExceptionLog__c newExcp,
                                           List<ExceptionLog__c> exceptionLogToBeUpdated, List<ExceptionLog__c> exceptionLogToBeInserted ){
         
        String excpDetails = UTIL_ErrorConstants.BLANK_SPACE;
        
        for(ExceptionLog__c existingLog : existingErrorLogs) {
             
             if(String.isNotBlank(existingLog.ExceptionDetails__c) && existingLog.ExceptionDetails__c.contains(UTIL_ErrorConstants.LINE_NO)){
                 excpDetails = existingLog.ExceptionDetails__c.substring(0, existingLog.ExceptionDetails__c.IndexOf(UTIL_ErrorConstants.LINE_NO));
             }
             else{
                 excpDetails = existingLog.ExceptionDetails__c;
             }
             
             if(String.isNotBlank(excpDetails) && excpDetails.trim().equalsIgnoreCase(lineColumn.trim()) &&
                String.isNotBlank(existingLog.ContextUser__c) && (existingLog.ContextUser__c == newExcp.ContextUser__c) &&
                (existingLog.ExceptionLogTimestamp__c != null) && (existingLog.ExceptionLogTimestamp__c.date() == (System.now()).date())  && (
               ((String.isNotBlank(existingLog.ClassName__c) && existingLog.ClassName__c.equalsIgnoreCase(newExcp.ClassName__c)) &&
                (String.isNotBlank(existingLog.MethodName__c) && existingLog.MethodName__c.equalsIgnoreCase(newExcp.MethodName__c))) ||
                (String.isNotBlank(existingLog.ApexTrigger__c) && existingLog.ApexTrigger__c.equalsIgnoreCase(newExcp.ApexTrigger__c))) ||
                ((String.isNotBlank(existingLog.WSCallingApplication__c) && existingLog.ClassName__c.equalsIgnoreCase(newExcp.WSCallingApplication__c)) && 
                 (String.isNotBlank(existingLog.WSCallingArea__c) && existingLog.ClassName__c.equalsIgnoreCase(newExcp.WSCallingArea__c)))){
                 
                 existingLog.ExceptionDetails__c = newExcp.ExceptionDetails__c ;                
                 existingLog.NumberOfTimesOccured__c = (existingLog.NumberOfTimesOccured__c == null?1:existingLog.NumberOfTimesOccured__c) + 1;
                 existingLog.ExceptionLogTimestamp__c = System.Now();
                 existingLog.ContextUser__c = newExcp.ContextUser__c;
                 existingLog.WSTransactionID__c = newExcp.WSTransactionID__c ;
                 exceptionLogToBeUpdated.add(existingLog);                 
             }               
         } 
                
         if(exceptionLogToBeUpdated.isEmpty()){ 
             exceptionLogToBeInserted.add(newExcp);
         } 
     }
     

    /**
      * @description       This method is used to insert List of ExceptionLog__c records if their Severity__c value is ERROR.  
      * @param             exceptionLogList the List of pre-existing ExceptionLog__c records
      * @return            void
      * @throws            Exception
      */ 
     public static void logListException(List<ExceptionLog__c> exceptionLogList){
         List<ExceptionLog__c> listToInsert = new List<ExceptionLog__c>();
         List<ExceptionLog__c> filteredList = new List<ExceptionLog__c>();
         
         for( ExceptionLog__c item : exceptionLogList){   
             if(exceptionLogMeetsSeverityFilter(item.Severity__c)){   
                 listToInsert.add(item);
             }
         }
         if(!listToInsert.isEmpty()){
             filteredList = mergeExistingErrorLogs(listToInsert);
             insertExceptionList(filteredList); 
         }         
     }
     
   
    /**
      * @description       This method is used to insert ExceptionLog__c record if their Severity__c value is ERROR.  
      * @param             exceptionLog the ExceptionLog__c record to be created
      * @return            void
      * @throws            NA
      */ 
     private static void logException( ExceptionLog__c exceptionLog){
         if(exceptionLogMeetsSeverityFilter(exceptionLog.severity__c)) {
             Database.insert(exceptionLog, false);
         }
     }
     
    
    /**
      * @description       This method is used to check if the Severity__c value is ERROR. If its values is not ERROR, the ExceptionLog__c record is not inserted.  
      * @param             Severity the String that contains the exception severity level
      * @return            Boolean
      * @throws            NA
      */ 
     private static boolean exceptionLogMeetsSeverityFilter(String severity) {
         boolean result = false;
         if(severity != null) {
             if(severity.equalsIgnoreCase(LogSeverityLevelValue__c.getOrgDefaults().LoggingLevel__c)){
                 result = true;
             }
         }       
         return result;
     }
     
    
    /**
      * @description       This method is used to build the ExceptionLog__c record to be inserted.  
      * @param             excp the Exception object
      * @param             orgID the organization ID
      * @param             applicationName the Application Name
      * @param             className the Class Name
      * @param             methodName the Method Name
      * @param             severity the system.LoggingLevel variable to determine the exception level
      * @param             apexErrMsg the String containing error Message (for unhandledException)
      * @param             exceptionName the String containing exception type (for unhandledException)
      * @param             triggerName the String containing Trigger Name (for unhandledException)
      * @param             severityVal the String containing severity level value (for unhandledException)
      * @param             user the String containing logged in User ID (for unhandledException)
      * @param             codeSnippet the String containing the exception code (for unhandledException)
      * @param             handled the Boolean value to determine if it is handled exception or unhandled
      * @return            ExceptionLog__c
      * @throws            NA
      */ 
     private static ExceptionLog__c buildExceptionObject(Exception excp, String orgID, String applicationName, String className, 
                                                        String methodName, System.LoggingLevel severity, String apexErrMsg, String exceptionName, 
                                                        String triggerName, String severityVal, String user, String codeSnippet, Boolean handled){
         ExceptionLog__c exceptionLog = new ExceptionLog__c();
         exceptionLog.ExceptionDetails__c = handled?buildExceptionDetails(excp):apexErrMsg;
         exceptionLog.OrgId__c = orgID;
         exceptionLog.ExceptionType__c = handled?excp.getTypeName():exceptionName;
         exceptionLog.Application__c = applicationName;
         exceptionLog.ClassName__C = className;
         exceptionLog.MethodName__c = methodName;
         exceptionLog.ApexTrigger__c = triggerName;
         exceptionLog.ContextUser__c = handled?UserInfo.getUserId():[SELECT Id FROM User WHERE ID=: user].Id;
         exceptionLog.Severity__c = handled?severity.name():severityVal;
         if(handled){
             Integer startPoint = excp.getMessage().IndexOf(UTIL_ErrorConstants.EXCEPTION_CODE_FILTER)+UTIL_ErrorConstants.EXCEPTION_CODE_FILTER.length();
             String excpCode = excp.getMessage().substring(startPoint).trim();
             excpCode = (excpCode.split(UTIL_ErrorConstants.BLANK_SPACE))[0];
             exceptionLog.ExceptionCode__c = excpCode.left(excpCode.length()-1);
         }
         else{
             exceptionLog.ExceptionCode__c = codeSnippet;
         }
         exceptionLog.ExceptionDescription__c = handled?excp.getMessage().left(UTIL_ErrorConstants.EXCEPTION_CODE_SIZE_LIMIT):codeSnippet;
         exceptionLog.ExceptionLogTimeStamp__c = System.now();
         exceptionLog.isHandled__c = handled;
         exceptionLog.NumberOfTimesOccured__c = 1;
    
         return exceptionLog;
     }
     
         
    /**
      * @description       This method is used to build the ExceptionDetail__c field value for ExceptionLog__c record to be inserted.  
      * @param             excp the Exception object
      * @return            String
      * @throws            NA
      */ 
     private static String buildExceptionDetails(Exception excp){
         string details = excp.getTypeName()+UTIL_ErrorConstants.COLON+excp.getMessage()+UTIL_ErrorConstants.ENTER+excp.getStackTraceString();
         return details.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT);
     }
     
    
    /**
      * @description       This method is used to build the error message for the ExceptionLog__c record to be inserted in case of Database.SaveResult or Database.DeleteResult operation.  
      * @param             idVal the Id of the record throwing exception during Database.insert or Database.delete
      * @param             errorList the List of Database.Error Object records
      * @return            String
      * @throws            NA
      */
     private static String buildErrorMessageFromErrorList(ID idVal, List<Database.Error> errorList){
         string errorMessage = UTIL_ErrorConstants.RECORD_ID + idVal + UTIL_ErrorConstants.ENTER;
         for(database.Error error : errorList){
             errorMessage += error+UTIL_ErrorConstants.ENTER;
         }
         return errorMessage.left(UTIL_ErrorConstants.EXCEPTION_DETAILS_SIZE_LIMIT);
     }
}