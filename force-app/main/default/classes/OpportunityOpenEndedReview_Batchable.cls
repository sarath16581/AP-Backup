/**************************************************
Type:       Apex Batchable Job Class for Opportunity Open Ended Contract Reviews (OOER)
Purpose:    Based on the Contract Review Date, Review Opportunities will be created 90 days before the date
            and assigned to the Account Manager (Account Owner).
            The Review Opportunity serves as an audit trail of sorts indicating when reviews occurred,
            however the initial 'root' Opportunity will always be the record that users interact with.  
            Removes the Review Date Changed flag from the original record as part of the clone so not reprocessed
            until Contract Review Date updated by Ariba at later point (and Review Date Changed is set to true).
            Errors emailed to Custom Setting email address, which should be a salesforce user to avoid daily email limits when sending via code.

            CURRENT GOVERNOR LIMITS (API Version 27):
                - Maximum of 50 million records can be returned in the Database.QueryLocator object.
                - Total number of DML statements issued: 150
                - Total number of records processed as a result of DML statements, Approval.process, or database.emptyRecycleBin: 10,000
            NOTE: Optional scope is used to reduce risk of exceeding "Total number of records processed as a result of DML statements" Governor Limit.
Used By:    
History:
/*******************************  History ************************************************
28-Feb-2013 Manu Erwin (Salesforce.com)     Created as part of Phase 3 ECLM
01-Mar-2013 Manu Erwin (Salesforce.com)     Updated: now solely focused on Opportunities where the Review Date has a value
11-Mar-2013 Manu Erwin (Salesforce.com)     Fix: Review Date (ECLM_Review_Date__c) of cloned Opportunity set to blank
                                            Improve error notification information
                                            Fix: Ensure Opportunity Line Revenue Start and End dates blanked
                                            Fix: Clone still created if no Opportunity Line Items exist
                                            Fix: Clone Opportunity always created and set so will not re-process. 
9-Oct-2015 Kalpita Talwadekar               Updated the null values of revenue start and end date to match same as 
                                            the cloned opportunityLineItem. Also added exception handling framework                                            
**************************************************/
global without sharing class OpportunityOpenEndedReview_Batchable implements Database.Batchable<SObject> {

    /* CONSTANTS */
    static final Decimal DAYS_BEFORE_END_DATE = BatchJobSettings__c.getInstance().OOER_Days_Before_End_Date__c;
    static final Id HOLDING_USER = ConfigSetting__c.getInstance().Holding_UserID__c;
    static final String ERROR_EMAIL = BatchJobSettings__c.getInstance().OOER_Error_Email__c;
    static final String OPPTY_LINES_MISSING_ERROR = 'Review not performed for this Opportunity as there are no Opportunity Line Items: ';
    private static final String METHOD_NAME = 'execute';
    private static final String CLASS_NAME = 'OpportunityOpenEndedReview_Batchable';

    /* PUBLIC VARIABLES */

    /* PRIVATE VARIABLES */
    private String query;

    /* CONSTRUCTOR */
    global OpportunityOpenEndedReview_Batchable(Boolean testRun) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: Constructor');
        System.assert(DAYS_BEFORE_END_DATE != null, 'The DAYS_BEFORE_END_DATE constant cannot be null');
        System.assert(HOLDING_USER != null, 'The HOLDING_USER constant cannot be null');
        System.assert(ERROR_EMAIL != null, 'The ERROR_EMAIL constant cannot be null');
        Date reviewDate = System.today().addDays(DAYS_BEFORE_END_DATE.intValue());
        Integer year = reviewDate.year();
        String month;
        if (reviewDate.month() < 10) {
            month = '0' + reviewDate.month();
        } else {
            month = reviewDate.month().format();
        }
        String day;
        if (reviewDate.day() < 10) {
            day = '0' + reviewDate.day();
        } else {
            day = reviewDate.day().format();
        }
        String reviewDateString = year +'-'+ month +'-'+ day;
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: CONSTRUCTOR - reviewDateString: ' + reviewDateString);

        // Dynamically build query string for ALL Opportunity fields
        List<String> opptyFields = new List<String>();
        opptyFields.addAll( Opportunity.sObjectType.getDescribe().fields.getMap().keySet() );
        query = 'SELECT ' + opptyFields.get(0); 
        for (Integer fieldCounter=1 ; fieldCounter < opptyFields.size() ; fieldCounter++){
            query += ', ' + opptyFields.get(fieldCounter);
        }
        // Add additional account owner field needed for processing
        query +=', Account.OwnerId, ';
        // Dynamically build query string for ALL Opportunity Line Item fields
        List<String> opptyLineFields = new List<String>();
        opptyLineFields.addAll( OpportunityLineItem.sObjectType.getDescribe().fields.getMap().keySet() );
        query += '(SELECT ' + opptyLineFields.get(0);
        for (Integer fieldCounter=1 ; fieldCounter < opptyLineFields.size() ; fieldCounter++){
            // Cannot specify both UnitPrice and TotalPrice so do not include TotalPrice
            if (opptyLineFields.get(fieldCounter) != 'TotalPrice') {
                query += ', ' + opptyLineFields.get(fieldCounter);
            }
        }
        // Close out the Oppty Line fields, add search criteria and test situation
        query +=' FROM OpportunityLineItems) ' +
                'FROM Opportunity ' +
                'WHERE ECLM_IsReview__c = false ' +
                'AND ECLM_Review_Date__c <= ' + reviewDateString;

        if (testRun) {
            query += ' AND Account.Name LIKE \'OOER TEST%\' LIMIT 200';
        }
        else {
            // Only process records where Review Date has changed.
            // This criteria is not used on test records as there is a workflow which blanks this value for new records.
            // All test records are assumed to have this value.
            query += ' AND ECLM_Review_Date_Changed__c = true';
        }        

    }

    /* START */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: START - query: ' + query);
        return Database.getQueryLocator(query);
    }
    /* EXECUTE */
    global void execute(Database.BatchableContext BC, List<Opportunity> opptys) {
        try {
            System.debug(System.LoggingLevel.DEBUG, '##DEBUG: execute begin');
            List<String> opptyInsertErrors = new List<String>();
            List<String> opptyLineInsertErrors = new List<String>();
            List<String> originalOpptyUpdateErrors = new List<String>();
            Set<Opportunity> setOrigOpptysForUpdate = new Set<Opportunity>();

            List<Opportunity> opptysForInsert = new List<Opportunity>();
            Map<Id, Opportunity> origOppIdToOrigOpp = new Map<Id, Opportunity>();
            // Loop through the List collection of Opportunities
            for (Opportunity opp : opptys) {
                // Add the original Opportunity to Map collection of Original Opportunity Id to Original Opportunity
                origOppIdToOrigOpp.put(opp.Id, opp);

                // Deep clone the Opportunity but don't keep the id, timestamps or autonumbers
                Opportunity cloneOpp = opp.clone(false, true, false, false);
                // Set field values per functional design
                cloneOpp.Type = 'Existing Customer';
                cloneOpp.CloseDate = opp.ECLM_Review_Date__c;
                cloneOpp.ECLM_IsReview__c = true;
                cloneOpp.ECLM_Original_Opportunity_No__c = opp.Id;
                cloneOpp.Name = 'Review: ' + opp.Name;
                cloneOpp.OwnerId = opp.Account.OwnerId;
                cloneOpp.ECLM_Review_Date__c = null;
                // Add to List collection for insert
                opptysForInsert.add(cloneOpp);
            }

            List<OpportunityLineItem> opptyLinesForInsert = new List<OpportunityLineItem>();
            Map<Id, Opportunity> cloneOpptyIdToCloneOppty = new Map<Id, Opportunity>();
            // Database Insert the List of Opportunities, allowing all records to process in the event of failure.
            List<Database.SaveResult> oppsSaveResults = Database.insert(opptysForInsert, false);
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logDmlResults(oppsSaveResults,null,opptysForInsert, SSSWConstants.SSSW_APP, 
                                                    CLASS_NAME, METHOD_NAME, 
                                                    null, LoggingLevel.ERROR);
            // Loop through the List of SaveResults
            for (Integer counter = 0; counter < oppsSaveResults.size(); counter++) {
                Database.SaveResult oppSaveResult = oppsSaveResults[counter];
                // If errors exist, add to a List collection for later notification to admin
                if (!oppSaveResult.isSuccess()) {
                    System.debug(System.LoggingLevel.DEBUG, '##DEBUG: errors for this opptySave: ' + oppSaveResult);
                    Opportunity cloneOppty = opptysForInsert[counter];
                    Opportunity origOppty = origOppIdToOrigOpp.get(cloneOppty.ECLM_Original_Opportunity_No__c);
                    for (Database.Error error : oppSaveResult.getErrors()) {
                        String errorMessageAndCode = 'Opportunity Save Errors for original Opportunity: ' + origOppty.Id + ': ';
                        errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                        opptyInsertErrors.add(errorMessageAndCode);
                    }
                } else {
                    // Success occurred, obtain and loop through the original Opportunity’s child Opportunity Line Items (if they exist)
                    System.debug(System.LoggingLevel.DEBUG, '##DEBUG: success for this opptySave: ' + oppSaveResult);
                    Opportunity cloneOppty = opptysForInsert[counter];
                    // Add the clone oppty to a map for later use
                    cloneOpptyIdToCloneOppty.put(cloneOppty.Id, cloneOppty);
                    Opportunity origOppty = origOppIdToOrigOpp.get(cloneOppty.ECLM_Original_Opportunity_No__c);
                    // add original opportunity to collection for later update
                    origOppty.ECLM_Review_Date_Changed__c = false;
                    setOrigOpptysForUpdate.add(origOppty);
                    List<OpportunityLineItem> opptyLines = origOppty.OpportunityLineItems;
                    // Only clone if oppty lines exist for parent
                    if (!opptyLines.isEmpty()) {
                        for (OpportunityLineItem oppLine : opptyLines) {
                            // Deep clone the Opportunity Line Item but don't keep the id, timestamps or autonumbers
                            OpportunityLineItem cloneOppLine = oppLine.clone(false, true, false, false);
                            // Associate to the parent oppty
                            cloneOppLine.OpportunityId = cloneOppty.Id;
                            cloneOppLine.Contract_Start_Date__c = oppLine.Contract_Start_Date__c;
                            cloneOppLine.Contract_End_Date__c = oppLine.Contract_End_Date__c;
                            cloneOppLine.ProdClassFieldUpdate__c = null;
                            cloneOppLine.Classification__c = 'Renewal';
                            // Add to a List collection for insert
                            opptyLinesForInsert.add(cloneOppLine);
                        }
                    }
                }
            }

            if (!opptyLinesForInsert.isEmpty()) {
                // Database Insert the List of Opportunity Line Items, allowing all records to process in the event of failure.
                List<Database.SaveResult> oppLinesSaveResults = Database.insert(opptyLinesForInsert, false);
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logDmlResults(oppLinesSaveResults,null,opptyLinesForInsert, SSSWConstants.SSSW_APP, 
                                                        CLASS_NAME, METHOD_NAME, 
                                                        null, LoggingLevel.ERROR);
                // Loop through the List of SaveResults:
                for (Integer counter = 0; counter < oppLinesSaveResults.size(); counter++) {
                    Database.SaveResult oppLineSaveResult = oppLinesSaveResults[counter];
                    // If errors exist, add to a List collection for later notification to admin
                    if (!oppLineSaveResult.isSuccess()) {
                        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: errors for this opptyLineSave: ' + oppLineSaveResult);
                        OpportunityLineItem cloneOpptyLine = opptyLinesForInsert[counter];
                        Id cloneOpptyId = cloneOpptyLine.OpportunityId;
                        Opportunity cloneOppty = cloneOpptyIdToCloneOppty.get(cloneOpptyId);
                        for (Database.Error error : oppLineSaveResult.getErrors()) {
                            String errorMessageAndCode = 'Opportunity Line Save Errors for clone Opportunity: ' + cloneOppty.Id + ': ';
                            errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                            opptyLineInsertErrors.add(errorMessageAndCode);
                        }
                    }
                }
            }

            // Database Update the List of original Opportunity, allowing all records to process in the event of failure.
            List<Opportunity> listOrigOpptysForUpdate = new List<Opportunity>();
            listOrigOpptysForUpdate.addAll(setOrigOpptysForUpdate);
            List<Database.SaveResult> origOpptySaveResults = Database.update(listOrigOpptysForUpdate, false);
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logDmlResults(origOpptySaveResults,null,listOrigOpptysForUpdate, SSSWConstants.SSSW_APP, 
                                                    CLASS_NAME, METHOD_NAME, 
                                                    null, LoggingLevel.ERROR);
            // Loop through the List of SaveResults
            for (Integer counter = 0; counter < origOpptySaveResults.size(); counter++) {
                Database.SaveResult origOpptySaveResult = origOpptySaveResults[counter];
                // If errors exist, add to a List collection for later notification to admin
                if (!origOpptySaveResult.isSuccess()) {
                    System.debug(System.LoggingLevel.DEBUG, '##DEBUG: errors for this origOpptySave: ' + origOpptySaveResult);
                    for (Database.Error error : origOpptySaveResult.getErrors()) {
                        String errorMessageAndCode = 'Opportunity Update Errors for original Opportunity: ' + listOrigOpptysForUpdate[counter].Id + ': ';
                        errorMessageAndCode += error.getStatusCode() +':'+ error.getMessage();
                        originalOpptyUpdateErrors.add(errorMessageAndCode);
                    }
                }
            }
            
            if (!opptyInsertErrors.isEmpty() || !opptyLineInsertErrors.isEmpty() || !originalOpptyUpdateErrors.isEmpty()) {
                // Errors exist so send an email to notify system admin
                System.debug('##DEBUG: end of execute: opptyInsertErrors: ' + opptyInsertErrors);
                System.debug('##DEBUG: end of execute: opptyLineInsertErrors: ' + opptyLineInsertErrors);
                System.debug('##DEBUG: end of execute: originalOpptyUpdateErrors: ' + originalOpptyUpdateErrors);
        
                // Send an email to the Custom Setting email address notifying of errors in batch.
                // Note: the email address should be a Salesforce user to avoid the daily limits on sending email from code.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {ERROR_EMAIL};
                mail.setToAddresses(toAddresses);
                mail.setSubject('Opportunity Open Ended Review Batch Errors: ' + System.now() + ' :Batch Job Id: ' + BC.getJobId());
                String messageHtmlBody = '<h2>Opportunity Insert Errors</h2> <br/>';
                for (String opptyInsertError : opptyInsertErrors) {
                    messageHtmlBody += opptyInsertError + '<br/>';
                }
                messageHtmlBody += '<h2>Opportunity Line Item Insert Errors</h2> <br/>';
                for (String opptyLineInsertError : opptyLineInsertErrors) {
                    messageHtmlBody += opptyLineInsertError + '<br/>';
                }
                messageHtmlBody += '<h2>Original Opportunity Update Errors</h2> <br/>';
                for (String originalOpptyUpdateError : originalOpptyUpdateErrors) {
                    messageHtmlBody += originalOpptyUpdateError + '<br/>';
                }
                mail.setHtmlBody ('<p>The Opportunity Open Ended Review batch Apex job ' + BC.getJobId() +
                    ' had the following errors:</p>' + messageHtmlBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }

            System.debug(System.LoggingLevel.DEBUG, '##DEBUG: execute end');
        }
        catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    CLASS_NAME, METHOD_NAME, 
                                                    null, LoggingLevel.ERROR);
        }
    }
    /* FINISH */
    global void finish(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: finish');
    }

    /* TEST METHODS - Note: (SeeAllData=TRUE) is used as interacting with PriceBooks */
    @isTest (SeeAllData=TRUE) static void endDateInFutureTest() {
        // Review Date Changed is TRUE and Review Date further in future than current Custom Setting
        Account acc = TestingUtil.accountOrg('OOER TEST - endDateInFutureTest');
        insert acc;
        Opportunity oppty = TestingUtil.opportunity(acc.Id, 'OOER TEST');
        oppty.ECLM_Review_Date_Changed__c = true;
        oppty.Contract_End_Date__c = System.today().addDays(OpportunityOpenEndedReview_Batchable.DAYS_BEFORE_END_DATE.intValue() * 2);
        insert oppty;
        Pricebook2 priceBook = [select id from Pricebook2 where IsStandard = true];
        Product2 product = TestingUtil.product('TEST', 'TEST');
        insert product;
        PricebookEntry priceBookEntry = TestingUtil.priceBookEntry(priceBook.Id, product.Id);
        insert priceBookEntry;
        OpportunityLineItem opptyLine = TestingUtil.opptyLine(oppty.Id, priceBookEntry.Id);
        insert opptyLine;

        Test.startTest();
            OpportunityOpenEndedReview_Batchable batch = new OpportunityOpenEndedReview_Batchable(true);
            ID batchprocessid = Database.executeBatch(batch, 50);
        Test.stopTest();

        // Assert Opportunity not cloned as “Review fixed term”
        Integer numReviewOpptys = [SELECT count() FROM Opportunity WHERE ECLM_Original_Opportunity_No__c = :oppty.Id];
        System.assert(numReviewOpptys == 0, 'There should NOT be a Review oppty created for this Opportunity');
    }
    @isTest (SeeAllData=TRUE) static void endDateMeansProcessingTest() {
        // Review Date Changed is TRUE and also 40 records where Review Date is:
        //  - exactly Today + Custom Setting i.e., on the boundary
        //  - within Custom Setting range i.e., within the boundary
        //  - today
        //  - in the past
        // Note: the reason for 40 records x 4 is to ensure greater than 150 records are processed
        // to test the “Total Number of DML Statements Issued” Governor Limit.

        Integer numberOfRecords = 40;
        List<Account> accounts = new List<Account>();
        List<Product2> products = new List<Product2>();
        for (Integer counter = 0; counter < numberOfRecords*4; counter++) {
            Account acc = TestingUtil.accountOrg('OOER TEST:' + counter);
            accounts.add(acc);

            Product2 prod = TestingUtil.product('TEST' + counter, 'TEST');
            products.add(prod);
        }
        insert accounts;
        insert products;
        
        List<Opportunity> opptys = new List<Opportunity>();
        for (Integer counter = 0; counter < numberOfRecords; counter++) {
            // Records altered slightly to avoid unique field constraint
            Opportunity opptyTodayPlusCustomSetting = TestingUtil.opportunity(accounts[counter].Id, 'OOER TEST');
            opptyTodayPlusCustomSetting.ECLM_Review_Date_Changed__c = true;
            opptyTodayPlusCustomSetting.ECLM_Review_Date__c = System.today().addDays(OpportunityOpenEndedReview_Batchable.DAYS_BEFORE_END_DATE.intValue());
            opptys.add(opptyTodayPlusCustomSetting);
            Opportunity opptyWithinCustomSettingRange = TestingUtil.opportunity(accounts[counter].Id, 'OOER TEST');
            opptyWithinCustomSettingRange.ECLM_Review_Date_Changed__c = true;
            opptyWithinCustomSettingRange.ECLM_Review_Date__c = System.today().addDays(OpportunityOpenEndedReview_Batchable.DAYS_BEFORE_END_DATE.intValue() - 10);
            opptys.add(opptyWithinCustomSettingRange);
            Opportunity opptyToday = TestingUtil.opportunity(accounts[counter].Id, 'OOER TEST');
            opptyToday.ECLM_Review_Date_Changed__c = true;
            opptyToday.ECLM_Review_Date__c = System.today();
            opptys.add(opptyToday);
            Opportunity opptyPast = TestingUtil.opportunity(accounts[counter].Id, 'OOER TEST');
            opptyPast.ECLM_Review_Date_Changed__c = true;
            opptyPast.ECLM_Review_Date__c = System.today().addDays(-1 -counter);
            opptys.add(opptyPast);
        }
        insert opptys;
        Pricebook2 priceBook = [select id from Pricebook2 where IsStandard = true];
        List<PriceBookEntry> priceBookEntries = new List<PriceBookEntry>();
        for (Integer counter = 0; counter < numberOfRecords*4; counter++) {
            PricebookEntry priceBookEntry = TestingUtil.priceBookEntry(priceBook.Id, products[counter].Id);
            priceBookEntries.add(priceBookEntry);
        }
        insert priceBookEntries;
        List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();
        for (Integer counter = 0; counter < numberOfRecords*4; counter++) {
            OpportunityLineItem opptyLine = TestingUtil.opptyLine(opptys[counter].Id, priceBookEntries[counter].Id);
            oppLines.add(opptyLine);
        }
        insert oppLines;

        Test.startTest();
            OpportunityOpenEndedReview_Batchable batch = new OpportunityOpenEndedReview_Batchable(true);
            // Set batch to 200 to process all test records, knowing that test data does NOT have large number of child oppty line items.
            ID batchprocessid = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert each Opportunity cloned as “Review fixed term”. 
        Integer numReviewOpptys = [SELECT count() FROM Opportunity WHERE ECLM_Original_Opportunity_No__c = :opptys];
        System.assert(numReviewOpptys == opptys.size(), 'There SHOULD be a Review oppty for every original Opportunity');
    }
}