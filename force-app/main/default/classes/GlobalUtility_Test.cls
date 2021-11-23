/****************************************************************************************
Description: Test class to cover GlobalUtility functionality
Author:        Matt Yogaratnam
Company:       Salesforce.com
Description:   A test class created to test GlobalUtility methods
               Test executed:
               1 - logMessages
History:
-----------------------------------------------------------------------------------------
27-03-2014  Mattt Yogaratnam    		Initial Release
12-06-2018	heguang.miao@coroma.com.au	Updated [TDO-87] Unit tests re-written with scenario based tests.
*****************************************************************************************/

@isTest
global class GlobalUtility_Test {

    @testSetup
    static void setupTestData() {
        //creates a system settings environment in which all levels of logs are accepted.
        SystemSettings__c systemSettingsForTests = new SystemSettings__c(
                Loglevel_Debug__c = true,
                Loglevel_Error__c = true,
                Loglevel_Warning__c = true,
                Loglevel_Info__c = true
        );

        insert systemSettingsForTests;
    }

    /**
     * SCENARIO: Log messages with vaid logLevel and exception
     **/
    @isTest
    static void GlobalUtility_logMessage_validLogLevelWithException() {

        //Throw an exception to capture the object used to create the error
        Exception accountError;

        try {
            Account noFieldsAccount = new Account();
            insert noFieldsAccount;
        } catch (Exception e) {
            accountError = e;
        }

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Error', 'AccountManagement', 'createAccount()', '', '', '', '', accountError, 3000);

        //the log record should have been named correctly
        List<Application_Log__c> applicationLogRecords = [SELECT Id, Source__c, Source_Function__c, Stack_Trace__c FROM Application_Log__c];
        //Check that 1 record was successfully created in the application log table
        system.assertEquals(1, applicationLogRecords.size(),
                'GlobalUtility_logMessage_validLogLevelWithException : error message with valid level should be recorded');

        // Check the content of logs
        system.assertEquals('AccountManagement', applicationLogRecords[0].Source__c,
                'GlobalUtility_logMessage_validLogLevelWithException : source should be recorded');

        system.assertEquals('createAccount()', applicationLogRecords[0].Source_Function__c,
                'GlobalUtility_logMessage_validLogLevelWithException : source function should be recorded');

        system.assertNotEquals(null, applicationLogRecords[0].Stack_Trace__c,
                'GlobalUtility_logMessage_validLogLevelWithException : exception should be reflected');


        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Debug', 'AccountManagement', 'createAccount()', '', '', 'Debug message for testing', '', null, 3000);

        //the account should have been named correctly
        applicationLogRecords = [SELECT Id FROM Application_Log__c];

        //Check that 2 records have successfully been created in the application log table
        system.assertEquals(2, applicationLogRecords.size(),
                'GlobalUtility_logMessage_validLogLevelWithException : debug message should be recorded');

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Info', 'AccountManagement', 'createAccount()', '', '', 'Info message for testing', '', null, 3000);

        //the account should have been named correctly
        applicationLogRecords = [SELECT Id FROM Application_Log__c];
        //Check that 2 records have successfully been created in the application log table
        system.assertEquals(3, applicationLogRecords.size(),
                'GlobalUtility_logMessage_validLogLevelWithException : info message should be recorded');

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Warning', 'AccountManagement', 'createAccount()', '', '', 'Warning message for testing', '', null, 3000);

        //The warning log messages should have been created correctly
        applicationLogRecords = [SELECT Id FROM Application_Log__c];

        //Check that 4 records have successfully been created in the application log table
        system.assertEquals(4, applicationLogRecords.size(),
                'GlobalUtility_logMessage_validLogLevelWithException : warning message should be recorded');
    }

    /**
     * SCENARIO: Log messages with valid log level and empty exception
     **/
    @isTest
    static void GlobalUtility_logMessage_validLogLevelWithEmptyException() {
        GlobalUtility.logMessage('Error', 'AccountManagement', 'createAccount()', '', '', '', '', null, 3000);

        //the log record should have been named correctly
        List<Application_Log__c> applicationLogRecords = [SELECT Id, Source__c, Source_Function__c, Stack_Trace__c FROM Application_Log__c];

        //Check that 1 record was successfully created in the application log table
        system.assertEquals(1, applicationLogRecords.size(),
                'GlobalUtility_logMessage_validLogLevelWithEmptyException : error message with valid level should be recorded');

        // Check the content of logs
        system.assertEquals('AccountManagement', applicationLogRecords[0].Source__c,
                'GlobalUtility_logMessage_validLogLevelWithEmptyException : source should be recorded');

        system.assertEquals('createAccount()', applicationLogRecords[0].Source_Function__c,
                'GlobalUtility_logMessage_validLogLevelWithEmptyException : source function should be recorded');

        system.assertEquals(null, applicationLogRecords[0].Stack_Trace__c,
                'GlobalUtility_logMessage_validLogLevelWithEmptyException : empy exception');
    }

    /**
     * SCENARIO: Log messages with invalid log level
     **/
    @isTest
    static void GlobalUtility_logMessage_invalidLogLevel() {
        // Mimic an invalid log level
        GlobalUtility.logMessage('Unknown', 'AccountManagement', 'createAccount()', '', '', '', '', null, 3000);
        // This will not be logged
        List<Application_Log__c> applicationLogRecords = [SELECT Id, Source__c, Source_Function__c, Stack_Trace__c FROM Application_Log__c];

        system.assertEquals(0, applicationLogRecords.size(),
                'GlobalUtility_logMessage_invalidLogLevel : invalid log level should be ignored');
    }

    /**
     * SCENARIO: Log multiple messages
     **/
    @isTest
    static void GlobalUtility_logMessage_bulkLogging() {
        //Throw an exception to capture the object used to create the error
        Exception accountError;

        try {
            Account noFieldsAccount = new Account();
            insert noFieldsAccount;
        } catch (Exception e) {
            accountError = e;
        }

        //Use the wrapper class to build up a collection of messages
        ApplicationLogWrapper tempLog = new ApplicationLogWrapper();
        List<ApplicationLogWrapper> tempLogList = new List<ApplicationLogWrapper>();

        String[] levels = new String[]{
                'Info', 'Debug', 'Warning', 'Error'
        };

        for (Integer loopCounter = 0; loopCounter < 101; loopCounter++) {

            tempLog.source = 'CustomerManagement';
            tempLog.sourceFunction = 'CustomerManagement()';
            Integer logLevelIndex = system.Math.mod(loopCounter, 4);
            tempLog.debugLevel = levels[logLevelIndex];
            tempLog.ex = accountError;

            tempLogList.add(tempLog);

        }

        //Log all messages using the overloaded method
        GlobalUtility.logMessage(tempLogList);

        //All log records should be present
        List<Application_Log__c> applicationLogRecords = [SELECT Id FROM Application_Log__c];
        //Check that 101 records were successfully created in the application log table
        system.assertEquals(101, applicationLogRecords.size(),
                'GlobalUtility_logMessage_bulkLogging : Batch logging should succeed.');

    }

    /**
     * SCENARIO: Log when system settings are off
     **/
    @isTest
    static void GlobalUtility_logMessages_systemPreferencesOff() {
        // Special case for system settings to reject all logs.
        SystemSettings__c setting = [ SELECT Loglevel_Debug__c, Loglevel_Error__c, Loglevel_Warning__c, Loglevel_Info__c  FROM SystemSettings__c LIMIT 1 ];

        setting.Loglevel_Debug__c = false;
        setting.Loglevel_Error__c = false;
        setting.Loglevel_Warning__c = false;
        setting.Loglevel_Info__c = false;

        update setting;

        //Throw an exception to capture the object used to create the error
        Exception accountError;

        try {
            Account noFieldsAccount = new Account();
            insert noFieldsAccount;
        } catch (Exception e) {
            accountError = e;
        }

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Error', 'AccountManagement', 'createAccount()', '', '', '', '', accountError, 3000);

        //the log record should NOT have been created as the system preference is set to FALSE above
        List<Application_Log__c> applicationLogRecords = [SELECT Id FROM Application_Log__c];

        system.assertEquals(0, applicationLogRecords.size(),
                'GlobalUtility_logMessages_systemPreferencesOff : error message should not be recorded when Error level is off in system settings');

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Debug', 'AccountManagement', 'createAccount()', '', '', 'Debug message for testing', '', null, 3000);

        //the account should NOT have been created as the system preference is set to FALSE above
        applicationLogRecords = [SELECT Id FROM Application_Log__c];

        system.assertEquals(0, applicationLogRecords.size(),
                'GlobalUtility_logMessages_systemPreferencesOff : debug message should not be recorded when Debug level is off in system settings');

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Info', 'AccountManagement', 'createAccount()', '', '', 'Info message for testing', '', null, 3000);

        //the account should NOT have been created as the system preference is set to FALSE above
        applicationLogRecords = [SELECT Id FROM Application_Log__c];

        system.assertEquals(0, applicationLogRecords.size(),
                'GlobalUtility_logMessages_systemPreferencesOff : info message should not be recorded when Info level is off in system settings');

        //Create the parameters mimicking an actual scenario
        GlobalUtility.logMessage('Warning', 'AccountManagement', 'createAccount()', '', '', 'Info message for testing', '', null, 3000);

        //the log entry should NOT have been created as the system preference is set to FALSE above
        applicationLogRecords = [SELECT Id FROM Application_Log__c];

        system.assertEquals(0, applicationLogRecords.size(),
                'GlobalUtility_logMessages_systemPreferencesOff : warning message should not be recorded when Warning level is off in system settings');

    }

}