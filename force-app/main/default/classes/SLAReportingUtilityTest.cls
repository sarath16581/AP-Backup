/**************************************************
Description:    Test class to cover SLAReportingUtility functionality.
History:
--------------------------------------------------
2018-12-01  John.Mapanao@auspost.com.au  created
2018-12-18  nathan.franklin@auspost.com.au  Additional test methods and some refactoring
**************************************************/
@isTest
private class SLAReportingUtilityTest {

    @testSetup
    public static void setup() {
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'StarTrackSLAReporting'];

        // create the correct custom setting configuration
        List<CaseActivityValidTypeSettings__c> settings = new List<CaseActivityValidTypeSettings__c>{
            new CaseActivityValidTypeSettings__c(Name = 'StarTrack_PUD_Enquiry', BusinessHours__c = bh.Id),
            new CaseActivityValidTypeSettings__c(Name = 'StarTrack_Pickup_Booking_Enquiry', BusinessHours__c = 'Case')
        };
        insert settings;

        //Create an Account.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        accounts[0].ServiceSLA__c = 'Enterprise';
        insert accounts;

        //Create a Contact
        Contact cont = TestDataProvider.createTestContact();
        cont.MobilePhone = '1234';
        cont.Email = 'test@xyz.org';
        insert cont;

        //Create a Case
        Case testCase = TestDataProvider.createCase('Test', 'test description', 'Delivery Enquiry');
        testCase.ContactId = cont.Id;
        testCase.AccountId = accounts[0].Id;
        testCase.BusinessHoursId = bh.Id;
        insert testCase;

        AuthorisedContacts__c authContact = new AuthorisedContacts__c(Case__c = testCase.Id, Contact_Email__c = 'test123@abc.com');
        insert authContact;

    }

    /**********************************************************************
    *   Scenario:
    *       Log a CaseActivity record when new Email Message has been
    *       inserted on case (agent send an email to the customer)
    *
    *       This will also ensure email messages are excluded from agent activity when
    *           the toaddress is not in one of the contacts connected to the Case
    ***********************************************************************/
    @isTest
    public static void testEmailMessage() {
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'StarTrackSLAReporting'];
        List<Case> caseList = [SELECT Id, CreatedDate FROM Case];

        Test.startTest();

        //Insert emailmessage for case
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = false;
        email.ToAddress = 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseList[0].Id;
        insert email;

        // grab the created date from the inserted task
        email = [Select Id, CreatedDate From EmailMessage];

        Decimal businessHoursDiff = BusinessHours.diff(bh.Id, caseList[0].CreatedDate, email.CreatedDate);

        //Verify that same count of queried case has been generated for Case Activity
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c, IsAgentFirstResponse__c, IsCaseFirstResponse__c FROM CaseActivity__c];
        System.assertEquals(1, caList.size());
        System.assertEquals(caList[0].Case__c, caseList[0].Id);
        System.assertEquals(caList[0].Category__c, SLAReportingUtility.CHANNEL_EMAIL);
        System.assertEquals(caList[0].IsAgentFirstResponse__c, true);
        System.assertEquals(caList[0].IsCaseFirstResponse__c, true);
        System.assertEquals(caList[0].TotalBusinessDurationMilliseconds__c, businessHoursDiff);

        // add an email message where toaddress is the same as one of the contacts in the Authorised_Contacts__r records related to case
        // a new agent case activity record should be created since test123@abc.com is in Authorised_Contacts__c object
        email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = false;
        email.ToAddress = 'test123@abc.com';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseList[0].Id;
        insert email;

        // make sure an additional agent case activity was created
        caList = [SELECT Id FROM CaseActivity__c Where Category__c = 'Email'];
        System.assertEquals(2, caList.size());

        // add an email message where toaddress is not in the list of any of the case emails
        // a new agent case activity record should NOT be created in this case
        email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = false;
        email.ToAddress = 'nonexistentemail@abc.com';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = caseList[0].Id;
        insert email;

        // make sure an additional agent case activity was created
        caList = [SELECT Id FROM CaseActivity__c Where Category__c = 'Email'];
        System.assertEquals(2, caList.size());


        Test.stopTest();
    }

    /**********************************************************************
    *   Scenario:
    *       Log a CaseActivity record when new Outbound task has been
    *       inserted on case (agent did outbound call to customer)
    *
    *       Test also ensures a test that is Inbound is not logged as an agent activity
    ***********************************************************************/
    @isTest
    public static void testOutboundCall() {
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'StarTrackSLAReporting'];
        List<Case> caseList = [SELECT Id, ContactId, CreatedDate FROM Case];

        Test.startTest();

        //Insert outbound task for case
        List<Task> tasks = new List<Task>();

        Task testTask = TestDataProvider.createTask(caseList[0].Id, caseList[0].ContactId, 'Delivery Enquiry');
        testTask.Subject = 'Test';
        testTask.Type = 'Phone Call';
        testTask.Direction__c = 'Outbound'; // only Outbound calls are logged
        tasks.add(testTask);

        Task testTask2 = TestDataProvider.createTask(caseList[0].Id, caseList[0].ContactId, 'Delivery Enquiry');
        testTask2.Subject = 'Test';
        testTask2.Type = 'Phone Call';
        testTask2.Direction__c = 'Inbound';
        tasks.add(testTask2);

        insert tasks;

        Test.stopTest();

        // grab the created date from the inserted task
        testTask = [Select Id, CreatedDate From Task Where Direction__c = 'Outbound'];

        Decimal businessHoursDiff = BusinessHours.diff(bh.Id, caseList[0].CreatedDate, testTask.CreatedDate);

        //Verify that same count of queried case has been generated for Case Activity
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c, IsAgentFirstResponse__c, IsCaseFirstResponse__c FROM CaseActivity__c];
        System.Debug(caList);
        System.assertEquals(1, caList.size());
        System.assertEquals(caList[0].Case__c, caseList[0].Id);
        System.assertEquals(caList[0].Category__c, SLAReportingUtility.CHANNEL_CALL_LOG);
        System.assertEquals(caList[0].IsAgentFirstResponse__c, true);
        System.assertEquals(caList[0].IsCaseFirstResponse__c, true);
        System.assertEquals(caList[0].TotalBusinessDurationMilliseconds__c, businessHoursDiff);
    }

    /**********************************************************************
    *   Scenario:
    *       Log a CaseActivity record when new case comment has been
    *       inserted on case (agent added case comment)
    ***********************************************************************/
    @isTest
    public static void testCaseComment() {
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'StarTrackSLAReporting'];
        List<Case> caseList = [SELECT Id, ContactId, CreatedDate FROM Case];

        Test.startTest();

        //Insert case comment for case
        CaseComment csComment = new CaseComment(ParentId = caseList[0].Id, CommentBody = 'aaa', IsPublished = true);
        insert csComment;

        Test.stopTest();

        // grab the created date from the inserted case comment
        csComment = [Select Id, CreatedDate From CaseComment];

        Decimal businessHoursDiff = BusinessHours.diff(bh.Id, caseList[0].CreatedDate, csComment.CreatedDate);

        //Verify that same count of queried case has been generated for Case Activity
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c, IsAgentFirstResponse__c, IsCaseFirstResponse__c FROM CaseActivity__c];
        System.assertEquals(1, caList.size());
        System.assertEquals(caList[0].Case__c, caseList[0].Id);
        System.assertEquals(caList[0].Category__c, SLAReportingUtility.CHANNEL_CASECOMMENT);
        System.assertEquals(caList[0].IsAgentFirstResponse__c, true);
        System.assertEquals(caList[0].IsCaseFirstResponse__c, true);
        System.assertEquals(caList[0].TotalBusinessDurationMilliseconds__c, businessHoursDiff);
    }

    /**********************************************************************
    *   Scenario:
    *       Test when using CaseActivityValidTypeSettings__c with a business hours of 'Case'
    *       This ensures that the correct business hours are pulled from the case and calculate correctly.
    ***********************************************************************/
    @isTest
    public static void testCaseBusinessHours() {

        Account acc = [Select Id From Account Limit 1];
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'SSSWSydney'];

        //Create a Case
        Case testCase = TestDataProvider.createCase('Test', 'test description', 'Pickup Booking Enquiry');
        testCase.AccountId = acc.Id;
        testCase.BusinessHoursId = bh.Id;
        insert testCase;

        Test.startTest();

        //Insert case comment for case
        CaseComment csComment = new CaseComment(ParentId = testCase.Id, CommentBody = 'aaa', IsPublished = true);
        insert csComment;

        Test.stopTest();

        // grab the created date from the inserted case comment
        csComment = [Select Id, CreatedDate From CaseComment];
        testCase = [Select Id, CreatedDate From Case Where Id = :testCase.Id];

        Decimal businessHoursDiff = BusinessHours.diff(bh.Id, testCase.CreatedDate, csComment.CreatedDate);

        //Verify that same count of queried case has been generated for Case Activity
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c, IsAgentFirstResponse__c, IsCaseFirstResponse__c FROM CaseActivity__c];
        System.assertEquals(1, caList.size());
        System.assertEquals(caList[0].Case__c, testCase.Id);
        System.assertEquals(caList[0].Category__c, SLAReportingUtility.CHANNEL_CASECOMMENT);
        System.assertEquals(caList[0].IsAgentFirstResponse__c, true);
        System.assertEquals(caList[0].IsCaseFirstResponse__c, true);
        System.assertEquals(caList[0].TotalBusinessDurationMilliseconds__c, businessHoursDiff);
    }

    /**********************************************************************
    *   Scenario:
    *       This will ensure the first response values are being set correctly when multiple records are inserted for the same parent case in the same transaction
    ***********************************************************************/
    @isTest
    public static void testFirstResponseReportingMultiple() {

        List<Case> caseList = [SELECT Id, ContactId, CreatedDate FROM Case];

        Test.startTest();

        //Insert case comment for case
        List<CaseComment> caseComments = new List<CaseComment>{
                new CaseComment(ParentId = caseList[0].Id, CommentBody = 'aaa', IsPublished = true),
                new CaseComment(ParentId = caseList[0].Id, CommentBody = 'bbb', IsPublished = true)
        };
        insert caseComments;

        //Insert case comment for case
        CaseComment additionalCaseComment = new CaseComment(ParentId = caseList[0].Id, CommentBody = 'bbb', IsPublished = true);
        insert additionalCaseComment;

        Test.stopTest();

        //Verify that same count of queried case has been generated for Case Activity
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c, IsAgentFirstResponse__c, IsCaseFirstResponse__c FROM CaseActivity__c Order By Id];
        System.assertEquals(3, caList.size());

        System.assertEquals(caList[0].IsAgentFirstResponse__c, true);
        System.assertEquals(caList[0].IsCaseFirstResponse__c, true);

        System.assertEquals(caList[1].IsAgentFirstResponse__c, false);
        System.assertEquals(caList[1].IsCaseFirstResponse__c, false);

        // additonalCaseComment record
        System.assertEquals(caList[2].IsAgentFirstResponse__c, false);
        System.assertEquals(caList[2].IsCaseFirstResponse__c, false);

    }


    /**********************************************************************
    *   Scenario:
    *       This is to test to ensure that a case that is not a part of the record type configuration will not store Case Activities
    ***********************************************************************/
    @isTest
    public static void testCaseActivityExclusion() {

        Account acc = [Select Id From Account Limit 1];
        BusinessHours bh = [Select Id From BusinessHours Where Name = 'SSSWSydney'];
        Map<String, RecordTypeInfo> recordTypes = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName();

        //Create a Case
        // this record type is not in CaseActivityValidTypeSettings__c settings so it should be excluded from having a case activity generated
        Case testCase = new Case(RecordTypeId = recordTypes.get('SSSWGeneralEnquiry').recordTypeId,
                                    Subject = 'Test', Description = 'test description',
                                    AccountId = acc.Id,
                                    BusinessHoursId = bh.Id,
                                    Type = 'General Enquiry');
        insert testCase;

        Test.startTest();

        //Insert case comment for case
        CaseComment csComment = new CaseComment(ParentId = testCase.Id, CommentBody = 'aaa', IsPublished = true);
        insert csComment;

        Test.stopTest();

        //Verify that ther weren't any case activities generated as there is no configuration entry in CaseActivityValidTypeSettings__c for SSSWGeneralEnquiry
        List<CaseActivity__c> caList = [SELECT Id, Case__c, Agent__c, Category__c, TotalBusinessDurationMilliseconds__c FROM CaseActivity__c];
        System.assertEquals(0, caList.size());
    }

    /**********************************************************************
    *   Scenario:
    *       This is to test to ensure that a startrack case closed with FCR checked will create a case activity record
    ***********************************************************************/
    @isTest
    public static void testCaseActivityByCaseClosure() {

        BusinessHours bh = [Select Id From BusinessHours Where Name = 'StarTrackSLAReporting'];
        Contact con = [Select Id From Contact];
        Account acc = [Select Id From Account];

        //Create a Case specific for this test for Case based business hour calculation
        Case testCase = TestDataProvider.createCase('Test', 'test description', 'Pickup Booking Enquiry');
        testCase.ContactId = con.Id;
        testCase.AccountId = acc.Id;
        testCase.BusinessHoursId = bh.Id;
        testCase.Initial_Caller_Email__c = 'test@test.com';
        testCase.Initial_Caller_Phone_Number__c = '0400000000';
        insert testCase;

        Test.startTest();

        //close the case wiith FCR checked
        testCase.Status = 'Closed';
        testCase.FCR__c = true;
        testCase.ResolutionCode__c = 'Acknowledge Feedback';
        update testCase;

        Test.stopTest();

        List<CaseActivity__c> caseActivityList = [SELECT Id, Category__c FROM CaseActivity__c];
        System.assertEquals(1,caseActivityList.size());

        // the FCR category is tagged as Inbound Call
        System.assertEquals('Inbound Call',caseActivityList[0].Category__c);
    }
}