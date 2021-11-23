/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 09/01/2017
  * @description  : Test Class for CaseCommentTrigger

******************************  History ************************************************
2017-10-16  nathan.franklin@auspost.com.au  Adding new conditions to assert NPS details only when cases are closed.
2018-07-02  disha.kariya@auspost.com.au     Removed NPS Tag Date and commneted Asserts as CaseComment will not set NPS.
2018-07-13  nathan.franklin@auspost.com.au     Removed NPS Testing methods
2018-12-19  rahul.kapoor@auspost.com.au     Added test method to send email notification on child case comment insert/update.
*******************************  History ************************************************/
@isTest
private with sharing class CaseCommentTrigger_Test {

    // Variables
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';

    @testSetup
    private static void testDataSetup(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile agentprof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        User admin = TestUtility.createUser('Wayne',prof.id,null);
        User ssswAgent = TestUtility.createUser('SAgent',agentprof.id,null);
        Database.insert(new List<User>{ssswAgent,admin});

        TestUtility.createTestEntitlementProcessData();

        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.MailingState = 'Vic';
        Database.insert(con);

        Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ReferenceID__c = '1234567';
        csRec.ProductCategory__c = 'Domestic Letters';
        csRec.Origin = 'Email';

        Case csRecWithEvent = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRecWithEvent.ReferenceID__c = '12345';
        csRecWithEvent.ProductCategory__c = 'Domestic Parcels';

        Case lettersWithEvent = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        lettersWithEvent.ReferenceID__c = '123456';
        lettersWithEvent.ProductCategory__c = 'Domestic Letters';

        List<Case> caseList = new List<Case>();
        caseList.add(csRec);
        caseList.add(csRecWithEvent);
        caseList.add(lettersWithEvent);
        Database.insert(caseList);

        List<CaseShare> caseShareList = new List<CaseShare>();
        for(Case rec : caseList){
            CaseShare shareRec = new CaseShare(CaseId = rec.Id,CaseAccessLevel = 'Edit',RowCause = 'Manual',UserOrGroupId = ssswAgent.Id);
            caseShareList.add(shareRec);
        }
        Database.insert(caseShareList);

        //Fetch the profile.
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        //Create a user.
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com', Work_Center_Code__c='123456');

        insert testUser;

        //Fetch the record type.
        Id sourceRecordTypeId = schema.sobjecttype.case.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();
        Id targetRecordTypeId = schema.sobjecttype.case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();

        //Set values and create a new case.
        Case testCase = new Case();
        //Set the Subject.
        testCase.Subject = 'Subject for inserting Service Delivery Case';
        //Set the Description.
        testCase.Description = 'Description for inserting Service Delivery Case';
        //Set the Reference Id.
        testCase.ReferenceID__c = '1234597';
        //Set the source Record Type Id.
        testCase.RecordTypeId= sourceRecordTypeId;
        //Set AccountId
        testCase.AccountId = acc.Id;
        //Set Contact Id
        testCase.contactId= con.Id;
        //Set the Owner Id.
        testCase.OwnerId = testUser.Id;
        insert testCase;

        //Set values and create a new case.
        Case testCase1 = new Case();
        //Set the Subject.
        testCase1.Subject = 'Subject for inserting Report Request Case';
        //Set the Description.
        testCase1.Description = 'Description for inserting Report Request Case';
        //Set the Reference Id.
        testCase1.ReferenceID__c = '1234598';
        //Set the source Record Type Id.
        testCase1.RecordTypeId= targetRecordTypeId;
        //Set the Owner Id.
        testCase1.OwnerId = testUser.Id;
        //Set the Parent Id.
        testCase1.ParentId = testCase.Id;
        insert testCase1;
    }

    /**
      * @description       This method tests scenario of NPS check & FCR closure
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCheckFCR(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: SSSW_AGENT_PROFILE AND LastName = 'SAgent' LIMIT 1];
        Case csRec = [SELECT Id,CaseNumber,Description,Type,ProductCategory__c,ProductSubCategory__c,EnquirySubType__c,ReferenceID__c
        FROM Case WHERE ReferenceID__c = '1234567' LIMIT 1];

        System.runAs(runningUser){
            CaseComment csComment = new CaseComment(ParentId = csRec.Id,IsPublished = true);
            Test.startTest();
            Database.insert(csComment);
            Test.stopTest();
        }

        Integer count = [SELECT count() FROM CaseMilestone WHERE CaseId =: csRec.Id];
        CaseMilestone fcrMilestone = [SELECT CompletionDate FROM CaseMilestone
        WHERE MileStoneType.Name =: SSSWConstants.FIRST_CUSTOMER_RESPONSE
        AND CaseId =: csRec.Id LIMIT 1];
        System.assert(fcrMilestone.CompletionDate != null,count);
    }

    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCompleteFCRScenario(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: SSSW_AGENT_PROFILE AND LastName = 'SAgent' LIMIT 1];
        System.runAs(runningUser){
            TestUtility.severityLevelValue();
            CaseCommentTriggerHelper helper = new CaseCommentTriggerHelper();
            Test.startTest();
            helper.completeFirstCustomerResponse(new Map<Id,CaseComment>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }

    /**
      * @description       Test method to validate deletion and undelete of Case Comment
                           Scenario is not part of requirement, created for code coverage purpose only
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseCommentDeleteUndelete(){
        User runningUser = [SELECT Id FROM User WHERE Profile.Name =: SSSW_AGENT_PROFILE AND LastName = 'SAgent' LIMIT 1];
        Case csRec = [SELECT Id,CaseNumber,Description,Type,ProductCategory__c,ProductSubCategory__c,EnquirySubType__c,ReferenceID__c
        FROM Case WHERE ReferenceID__c = '1234567' LIMIT 1];
        CaseComment csComment = new CaseComment(ParentId = csRec.Id,IsPublished = true);
        Database.insert(csComment);
        Database.delete(csComment);
        Test.startTest();
        Database.undelete(csComment);
        Test.stopTest();
    }

    /*****************************************************************************************
    *  Scenario:
    *      Test to send email notification on child case comment insert/update.
    ******************************************************************************************/
    private static testMethod void testSendCaseCommentsNotification() {
        //Retrieve the case with reference id.
        Case csRec = [SELECT Id,CaseNumber,Description,Subject,ReferenceID__c
                      FROM Case
                      WHERE ReferenceID__c = '1234598'
                      LIMIT 1];

        //Create a new case comment for the case.
        CaseComment csComment = new CaseComment(ParentId = csRec.Id,IsPublished = true,CommentBody='Test for comment body');

        Test.startTest();
        //Insert a new case comment for the case.
        Database.insert(csComment);
        csComment.CommentBody = 'TestComment updated.';
        Database.update(csComment);
        Test.stopTest();

    }
}