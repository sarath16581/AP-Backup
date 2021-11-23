/*------------------------------------------------------------  
Author:        Mathanan Yogaratnam
Company:       Salesforce.com
Description:   A global utility class for common functions
Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
28-03-2014  Mathanan Yogaratnam Initial Release
------------------------------------------------------------*/

public without sharing class GlobalUtility {

   
    public static void logMessage(String logLevel, String sourceClass, String sourceFunction, String referenceId, String referenceInfo, String logMessage, String payLoad, Exception ex, long timeTaken) {
    /*
    Description:   Overloaded Method to log a single record to the application log table
    Inputs:        logLevel - Debug, Error, Info, Warning
                   sourceClass - Originating trigger or utility class
                   sourceFunction - Method in class above that caused the message
                   referneceId - Process Identifier (e.g. Job Id)
                   referenceInfo - Process information
                   payLoad - Optional based on integration messages
                   ex - the standard exception object for errors
                   timeTaken - The time in milliseconds of the transaction
	*/
               
        ApplicationLogWrapper msg = new ApplicationLogWrapper();
        
        msg.source = sourceClass;
        msg.logMessage = logMessage;
        msg.sourceFunction = sourceFunction;
        msg.referenceId = referenceId;
        msg.referenceInfo = referenceInfo;
        msg.payload = payLoad;
        msg.debugLevel = logLevel;
        msg.ex = ex;
        msg.Timer = timeTaken;
        
        System.Debug('@@@AppMsg 1');
        
        logMessage( msg );
        
    }    

    public static void logMessage(ApplicationLogWrapper appLog)
    {
    /*
    Description:   Overloaded Method to log a single record to the application log table
    Inputs:        The application log wrapper object
	*/
        
        List<ApplicationLogWrapper> appLogs = new List<ApplicationLogWrapper>();
        
        appLogs.add ( appLog );
        
        System.Debug('@@@AppMsg 2');
        
        logMessage ( appLogs );

    }

    public static void logMessage(List<ApplicationLogWrapper> appLogs)
    {
    /*
    Description:   Overloaded Method to log multiple records to the application log table
                   Called directly from trigger context to prevent governor limit exceptions
    Inputs:        The application log wrapper object

	*/
        List<Application_Log__c> insertAppLogs = new List<Application_Log__c>();
        
        System.Debug('@@@AppMsg 3');
        
        for(ApplicationLogWrapper appLog : appLogs){
        
            Application_Log__c log = new Application_Log__c();
            
            log.Source__c = appLog.source;
            log.Source_Function__c = appLog.sourceFunction;
            log.Reference_Id__c = appLog.referenceId;
            log.Reference_Information__c = appLog.referenceInfo;
            log.Message__c = appLog.logMessage;
            log.Integration_Payload__c = appLog.payload;
            
            if(appLog.ex != null){
                log.Stack_Trace__c = appLog.ex.getStackTraceString();
                log.Message__c = applog.ex.getMessage();
                //log.Exception_Type__c = applog.ex.getTypeName();
            }
            
            log.Debug_Level__c = appLog.debugLevel;
            log.Log_Code__c = appLog.logCode;
            log.Timer__c = appLog.timer;
            
            boolean validInsert = false;
            
            //optimisation - move these to a global constant
            if(appLog.debugLevel == 'Debug' && SystemSettings__c.getInstance().LogLevel_Debug__c){
                validInsert = true;
            }
            System.Debug('@@@AppMsg 4 ' + SystemSettings__c.getInstance().LogLevel_Error__c);
            if(appLog.debugLevel == 'Error' && SystemSettings__c.getInstance().LogLevel_Error__c){
                validInsert = true;
            }
            if(appLog.debugLevel == 'Info' && SystemSettings__c.getInstance().LogLevel_Info__c){
                validInsert = true;
            }
            System.Debug('Warning Flag: ' + SystemSettings__c.getInstance().LogLevel_Warning__c);
            if(appLog.debugLevel == 'Warning' && SystemSettings__c.getInstance().LogLevel_Warning__c){
                validInsert = true;
            }
                
            if(validInsert){
                insertAppLogs.add(log);
                System.Debug('Inserted Log from ' + log.source__c + ' debug level: ' + log.Debug_Level__c);
            }
        }
        
        if ( insertAppLogs.size() != 0 ){
            insert insertAppLogs;
        }
        
    }
    

    
}