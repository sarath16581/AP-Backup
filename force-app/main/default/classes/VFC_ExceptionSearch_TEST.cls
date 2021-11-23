/**
  * @author        Urmi Chatterjee
  * @date          18/10/2013
  * @description   Test Class for VFC_ExceptionSearch class.
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
private class VFC_ExceptionSearch_TEST{
    
    // Start of Constants for Test Methods
    
    private static final String ALIAS = 'excp';
    private static final Integer NUM = 1;
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String APP_NAME = 'TestException';
    private static final String CLASS_NAME = 'TestExceptionClass';
    private static final String DATE_ONE = '10/02/2013';
    private static final String DATE_TWO = '10/10/2013';
    private static final String CUSTOM_SETTING_RECORD = 'ExceptionSearch';
    private static final String CSV_LINK = 'System.PageReference[/apex/VFP_ExportToCSV]';
    
    // End of Constants for Test Methods
    
    /**
      * @description       Method to create ExceptionLog__c test data.
      * @param             applicationName Name of the Application
      * @param             className Name of the Class
      * @return            ExceptionLog__c
      * @throws            NA
      */
    private static ExceptionLog__c createExceptionData(String applicationName, String className){
        ExceptionLog__c excObj = new ExceptionLog__c();
        excObj.Application__c = applicationName;
        excObj.ClassName__c = className;
        insert excObj;
        return excObj;
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
      * @description       This Test Method is to verify that search method in VFC_ExceptionSearch class 
                           fetches ExceptionLog__c records within the provided Start Date and End Date. 
      * @param             NA
      * @return            void
      * @throws            NA
      */   
    private static testMethod void testExceptionSearchResult(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        createExceptionData(APP_NAME+NUM , CLASS_NAME+NUM);
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch ();
        excpSearch.wrapVar.startDate = Date.parse(DATE_ONE);
        excpSearch.wrapVar.endDate = Date.Today()+3;
        Test.startTest();
        System.runAs(runUser){                          
            excpSearch.search();               
        }
        Test.stopTest(); 
        System.assertEquals(excpSearch.wrapVar.exceptionList.size()>0, true);       
    }
   
    /**
      * @description       This Test Method is to verify that search method in VFC_ExceptionSearch class 
                           returns the expected error message when no Start Date and End Date is provided. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testExceptionSearchNoDates(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+1 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        createExceptionData(APP_NAME+NUM+1 , CLASS_NAME+NUM+1);
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch ();
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.search();    
        }
        Test.stopTest();    
        System.assertEquals(excpSearch.errorMsg, UTIL_ErrorConstants.DATE_NULL_ERROR_MESSAGE);
    }
    
    /**
      * @description       This Test Method is to verify that search method in VFC_ExceptionSearch class 
                           returns the expected error message when the Start Date is a date after today. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testExceptionSearchStartDateExcp(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+2 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        createExceptionData(APP_NAME+NUM+2 , CLASS_NAME+NUM+2);
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch ();
        excpSearch.wrapVar.startDate = Date.Today()+3;
        excpSearch.wrapVar.endDate = Date.Today()+10;
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.search();    
        }
        Test.stopTest();    
        System.assertEquals(excpSearch.errorMsg, UTIL_ErrorConstants.START_DATE_AFTER_TODAY_MESSAGE );
    }
    
    /**
      * @description       This Test Method is to verify that search method in VFC_ExceptionSearch class 
                           returns the expected error message when the End Date is before the Start Date. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testExceptionSearchEndDateExcp(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+3 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        createExceptionData(APP_NAME+NUM+3 , CLASS_NAME+NUM+3);
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch ();
        excpSearch.wrapVar.startDate = Date.parse(DATE_TWO);
        excpSearch.wrapVar.endDate = Date.parse(DATE_ONE);
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.search();    
        }
        Test.stopTest();    
        System.assertEquals(excpSearch.errorMsg, UTIL_ErrorConstants.START_DATE_GREATER_MESSAGE);
    }
    
    /**
      * @description       This Test Method is to verify that search method in VFC_ExceptionSearch class throws an exception
                           and returns the expected error message when the List <ExceptionLog__c> type variable defined in
                           the ExceptionDisplayWrapper inner class is assigned a null value and clear function is performed 
                           on this list. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testExceptionSearchExcp(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+4, SYSTEM_ADMIN);   
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch ();
        excpSearch.wrapVar.exceptionList = null;
        excpSearch.wrapVar.startDate = Date.parse(DATE_ONE);
        excpSearch.wrapVar.endDate = Date.parse(DATE_TWO);
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.search();    
        }
        Test.stopTest();    
        System.assertEquals(excpSearch.errorMsg, UTIL_ErrorConstants.GENERIC_ERROR_MESSAGE);
    }
    
    /**
      * @description       This Test Method is to verify that convertToCSV method in VFC_ExceptionSearch class 
                           returns the pageReference value for VFP_ConvertToCSV visualforce page. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testConvertCsv(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+5 , SYSTEM_ADMIN);  
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj6 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj6[i] = createExceptionData(APP_NAME+i,CLASS_NAME+i);            
        }      
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();          
        for(ExceptionLog__c excp: excObj6){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, true);
        } 
        PageReference pgRef = null;       
        Test.startTest();
        System.runAs(runUser){ 
            pgRef = excpSearch.convertToCSV();    
        }
        Test.stopTest();
        System.assertEquals(String.valueOf(pgRef), CSV_LINK);
    }
    
    /**
      * @description       This Test Method is to verify that convertToCSV method in VFC_ExceptionSearch class 
                           returns the pageReference value for VFP_ConvertToCSV visualforce page when no records
                           are slected. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testConvertCsvNoRecs(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+5 , SYSTEM_ADMIN);  
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj6 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj6[i] = createExceptionData(APP_NAME+i,CLASS_NAME+i);            
        }      
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();          
        for(ExceptionLog__c excp: excObj6){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, false);
        } 
        PageReference pgRef = null;       
        Test.startTest();
        System.runAs(runUser){ 
            pgRef = excpSearch.convertToCSV();    
        }
        Test.stopTest();
        System.assertEquals(String.valueOf(pgRef), CSV_LINK);
    }
    
    /**
      * @description       This Test Method is to verify that deleteException method in VFC_ExceptionSearch class 
                           deletes the ExceptionLog__c records selected when 'deleteException' value is assigned
                           to the variable, whose value is to be set when User clicks on OK on the pop-up to delete
                           the selected deleteException records when performing convert to defect functionality. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    /*
    private static testMethod void testDeleteException(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+6 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj7 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj7[i] = createExceptionData(APP_NAME+i, CLASS_NAME+i);
        }
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();        
        for(ExceptionLog__c excp: excObj7){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, true);
        } 
        excpSearch.wrapVar.delException = UTIL_ErrorConstants.DELETE_EXCEPTION;      
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.deleteException();    
        }
        Test.stopTest();   
        Integer defectCount = [SELECT COUNT() FROM Defect__c];
        Integer excpCount = [SELECT COUNT() FROM ExceptionLog__c];
        System.assertEquals(defectCount, 7);
        System.assertEquals(excpCount, 0);
    }
    */
    /**
      * @description       This Test Method is to verify that deleteException method in VFC_ExceptionSearch class 
                           does not delete the ExceptionLog__c records selected when 'convertException' value is assigned
                           to the variable, whose value is to be set when User clicks on Cancel on the pop-up to delete
                           the selected ExceptionLog__c records when performing convert to defect functionality.
                           Also to verify that the ConvertedToDefect__c checkbox value in the respective records
                           is set to true. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    /*
    private static testMethod void testConvertException(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+7 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj8 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj8[i] = createExceptionData(APP_NAME+i, CLASS_NAME+i);
        }
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();        
        for(ExceptionLog__c excp: excObj8){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, true);
        } 
        excpSearch.wrapVar.delException = UTIL_ErrorConstants.CONVERT_EXCEPTION ;      
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.deleteException();    
        }
        Test.stopTest();   
        Integer excpCount = [SELECT COUNT() FROM ExceptionLog__c];
        ExceptionLog__c excpRec = [SELECT ConvertedToDefect__c FROM ExceptionLog__c WHERE Application__c=:APP_NAME+NUM LIMIT 1];
        
        System.assertEquals(excpRec.ConvertedToDefect__c, true);
        System.assertEquals(excpCount, 7);
    }
    */
    /**
      * @description       This Test Method is to verify that deleteException method in VFC_ExceptionSearch class 
                           throws a Handled Exception when the List<ExceptionLog__c> variable of the 
                           ExceptionDisplayWrapper inner class is set as null. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    /*
    private static testMethod void testDefectException(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+8 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch(); 
        excpSearch.wrapVar.exceptionList = null;
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.deleteException();    
        }
        Test.stopTest();   
        System.assertEquals(excpSearch.errorMsg, UTIL_ErrorConstants.GENERIC_ERROR_MESSAGE);
    }
    */
    /**
      * @description       This Test Method is to verify that next method in VFC_ExceptionSearch class 
                           refreshes the list of ExceptionLog__c records to be displayed to contain
                           the last 2 records of the list of ExceptionLog__c records in the 
                           ExceptionDisplayWrapper inner class variable. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testPaginationNext(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+9 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj10 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj10[i] = createExceptionData(APP_NAME+i, CLASS_NAME+i);
        }
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();        
        for(ExceptionLog__c excp: excObj10){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, false);
        }      
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.next();    
        }
        Test.stopTest();   
        System.assertEquals(excpSearch.showExceptionList.size(), 2);
    }
    
    /**
      * @description       This Test Method is to verify that next method in VFC_ExceptionSearch class 
                           refreshes the list of ExceptionLog__c records to be displayed to contain
                           the first 5 records of the list of ExceptionLog__c records in the 
                           ExceptionDisplayWrapper inner class variable. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void testPaginationPrevious(){
        
        User runUser = UTIL_TestMethods.runningUser(ALIAS+NUM+10 , SYSTEM_ADMIN);
        UTIL_TestMethods.createCustomSetting(CUSTOM_SETTING_RECORD, 5);
        severityLevelValue();
        
        ExceptionLog__c[] excObj11 = new ExceptionLog__c[7];
        for(Integer i=0; i<=6; i++){
            excObj11[i] = createExceptionData(APP_NAME+i, CLASS_NAME+i);
        }
        VFC_ExceptionSearch excpSearch = new VFC_ExceptionSearch();       
        for(ExceptionLog__c excp: excObj11){
            excpSearch.wrapVar.exceptionList.add(excp);
            excpSearch.wrapVar.selected.put(excp.Id, true);
        }  
        excpSearch.next();
        Test.startTest();
        System.runAs(runUser){ 
            excpSearch.previous();    
        }
        Test.stopTest();   
        System.assertEquals(excpSearch.showExceptionList.size(),5);
    }
}