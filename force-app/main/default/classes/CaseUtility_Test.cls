/*************************************************************************************
Description:    Test class to cover CaseUtility functionality
History:
--------------------------------------------------------------------------------------
2014-07-16  yuanyuan.zhang@bluewolf.com  Created
2016-09-20  david.e.catindoy@accenture.com  Added a new test method to cover
            closeRelatedTasksAndWFEmails method in Case Utility.
2018-06-25  TDO-67 rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added tests for setting of articles to subscribed, closing of child cases
            and to assign Facility to Case.
2018-07-02  disha.kariya@auspost.com.au	Removed NPSTagDate__c to delete the field and Commented call to checkOriginChangeForNPS as this method is commented in CaseUtility Class
2019-10-02  disha.kariya@auspost.com.au Commented code as CaseUtility is not used.
**************************************************************************************/
@isTest
private class CaseUtility_Test {
    /*****************************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    *      Contacts, Cases, Articles are inserted in test methods to handle specific scenarios.
    ******************************************************************************************/
    // @testSetup
    // static void createTestData(){
    //     //Create a profile.
    //     Profile testProfile = [SELECT Id
    //     FROM Profile
    //     WHERE Name='StarTrack Support'];

    //     //Create a role.
    //     UserRole testRole = [SELECT Id
    //     FROM UserRole
    //     WHERE Name = 'CEO/Reporting'];

    //     //Create a user.
    //     User supportUser = new User(Alias = 'spUser', Email='user1@testorg.a', EmailEncodingKey='UTF-8',
    //             LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US',
    //             ProfileId = testProfile.Id, UserRoleId = testRole.Id,
    //             TimeZoneSidKey='America/Los_Angeles',UserName='user1@testorg.a');
    //     insert supportUser;
    // }
    static testmethod void testCreateAccounts () {
        test.startTest();
        CaseUtility.getRecordTypesWithDevNameContains('SSSW');
        CaseUtility.getRecordIdWithDevName('SSSW');
        test.stopTest();
    }
    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the creation of accounts and Signature Attachments.
    // ******************************************************************************************/
    // static testmethod void testCreateAccounts () {
    //     test.startTest();

    //     CaseUtility cu = new CaseUtility();
    //     String rtDevName = '';
    //     for (RecordType rt : [SELECT Id, DeveloperName
    //     FROM RecordType
    //     WHERE Sobjecttype = 'case'
    //     LIMIT 1]) {
    //         rtDevName = rt.DeveloperName;
    //     }
    //     //Fetch the record types with Developer Name.
    //     CaseUtility.getRecordTypesWithDevNameContains(rtDevName);
    //     CaseUtility.getRecordIdWithDevName(rtDevName);

    //     //Create a Contact.
    //     Contact testContact = TestDataProvider.createTestContact();
    //     insert testContact;

    //     //Create a Article.
    //     Article__c testArticle = new Article__c();
    //     testArticle.Name = '123';
    //     testArticle.ArticleLodgementDate__c = date.today();
    //     testArticle.SenderPostcode__c = '123';
    //     testArticle.ReceiverPostcode__c = '3002';
    //     testArticle.ArticleType__c = 'Regular Parcel';
    //     insert testArticle;

    //     //Create second Article.
    //     Article__c testArticle1 = new Article__c();
    //     testArticle1.Name = '345';
    //     testArticle1.ArticleLodgementDate__c = date.today();
    //     testArticle1.SenderPostcode__c = '345';
    //     testArticle1.ReceiverPostcode__c = '5005';
    //     testArticle1.ArticleType__c = 'Regular Parcel';
    //     insert testArticle1;

    //     RecordType rt;

    //     for (RecordType ret : [SELECT Id, Name, DeveloperName
    //     FROM RecordType
    //     WHERE sobjecttype = 'case']) {
    //         if (!ret.DeveloperName.contains('SSSW')) {
    //             rt = ret;
    //             break;
    //         }
    //     }

    //     //Create a Case.
    //     Case testCase1 = new Case();
    //     testCase1.ContactId = testContact.Id;
    //     testCase1.Type = 'Feedback';
    //     testCase1.Subject = 'Newsdd';
    //     testCase1.Status = 'Network Responded';
    //     testCase1.ProductCategory__c = 'Travel & ID';
    //     testCase1.EnquirySubType__c = 'Product Support';
    //     testCase1.ProductSubCategory__c = 'KeyPass';
    //     testCase1.ArticleTest__c = testArticle.Id;
    //     testCase1.SuppliedEmail = 'test@salesforce.com';
    //     testCase1.First_Name__c = 'test';
    //     testCase1.Last_Name__c = 'test';
    //     if (rt != null) testCase1.RecordTypeId = rt.Id;
    //     insert testCase1;

    //     //Clone a Case.
    //     Case testCase2 = testCase1.clone(true, true, false, false);
    //     testCase2.ArticleTest__c = testArticle1.Id;

    //     Map<Id, Case> newCases = new Map<Id, Case>();
    //     newCases.put(testCase2.Id, testCase2);
    //     Map<Id, Case> oldCases = new Map<Id, Case>();
    //     oldCases.put(testCase1.Id, testCase1);

    //     //Create a Event Message.
    //     EventMessage__c testEventMessage = new EventMessage__c();
    //     testEventMessage.Article__c = testArticle.Id;
    //     testEventMessage.SenderID__c = 'bg';
    //     testEventMessage.ActualDateTime__c = date.today() + 1;
    //     testEventMessage.EventType__c = 'DD-ER13';
    //     testEventMessage.SignatureXString__c = '1';
    //     insert testEventMessage;

    //     CaseUtilityWithoutSharing.createSignatureAttachmentsAfterUpdate(newCases, oldCases);

    //     //Create a Account.
    //     Account testAccount = new Account();
    //     testAccount.PersonEmail = 'test@salesforce.com';
    //     testAccount.FirstName = 'test';
    //     testAccount.LastName = 'test';
    //     CaseUtility.createAccounts(new List<Account>{testAccount}, new List<Case>{testCase1});

    //     test.stopTest();

    //     Account newAccount = [SELECT PersonEmail, FirstName, LastName FROM Account];

    //     System.assertEquals('test', newAccount.FirstName,
    //             'CaseUtility_Test_testCreateAccounts : Account with first name should be created');

    //     System.assertEquals('test@salesforce.com', newAccount.PersonEmail,
    //             'CaseUtility_Test_testCreateAccounts : Account with email should be created');

    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the assignment of Contact ID to Case.
    // ******************************************************************************************/
    // static testmethod void testAssignContactIDToCase () {
    //     test.startTest();

    //     //Create a contact.
    //     Contact testContact = TestDataProvider.createTestContact();
    //     insert testContact;

    //     //Create a Article.
    //     Article__c testArticle = new Article__c();
    //     testArticle.Name = '123';
    //     testArticle.ArticleLodgementDate__c = date.today();
    //     testArticle.SenderPostcode__c = '123';
    //     testArticle.ReceiverPostcode__c = '3002';
    //     testArticle.ArticleType__c = 'Regular Parcel';
    //     insert testArticle;

    //     //Create second Article.
    //     Article__c testArticle1 = new Article__c();
    //     testArticle1.Name = '345';
    //     testArticle1.ArticleLodgementDate__c = date.today();
    //     testArticle1.SenderPostcode__c = '345';
    //     testArticle1.ReceiverPostcode__c = '5005';
    //     testArticle1.ArticleType__c = 'Regular Parcel';
    //     insert testArticle1;

    //     //Create a Case.
    //     Case testCase1 = new Case();
    //     //case1.ContactId = con.Id;
    //     testCase1.Type = 'Feedback';
    //     testCase1.Subject = 'Newsdd';
    //     testCase1.Status = 'Network Responded';
    //     testCase1.ProductCategory__c = 'Travel & ID';
    //     testCase1.EnquirySubType__c = 'Product Support';
    //     testCase1.ProductSubCategory__c = 'KeyPass';
    //     testCase1.ArticleTest__c = testArticle.Id;
    //     testCase1.SuppliedEmail = 'test@salesforce.com';
    //     testCase1.First_Name__c = 'test';
    //     testCase1.Last_Name__c = 'test';
    //     insert testCase1;

    //     CaseUtility.assignContactIDToCase(new List<Case>{testCase1});
    //     testCase1.NPSScheduledDate__c = system.now();
    //     update testCase1;

    //     test.stopTest();

    //     Account newAccount = [SELECT PersonEmail, FirstName, LastName FROM Account];

    //     System.assertEquals('test', newAccount.FirstName,
    //             'CaseUtility_Test_testAssignContactIDToCase : Account with first name should be assigned');

    //     System.assertEquals('test@salesforce.com', newAccount.PersonEmail,
    //             'CaseUtility_Test_testAssignContactIDToCase : Account with email should be assigned');
    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the Child Case for AutoClose
    // ******************************************************************************************/
    // static testmethod void testChildCaseAutoClose() {
    //     //Create a parent Case.
    //     Case parent = TestDataProvider.createAndSaveCase('subject', 'description', 'SSSWGeneralEnquiry');
    //     //Create a child Case.
    //     Case child1 = TestDataProvider.createCase('subject', 'description', 'SSSWGeneralEnquiry');
    //     child1.ParentId = parent.Id;
    //     child1.RelatedCase__c = parent.Id;

    //     //Create a second child Case.
    //     Case child2 = TestDataProvider.createCase('subject', 'description', 'SSSWGeneralEnquiry');
    //     child2.ParentId = parent.Id;
    //     child2.RelatedCase__c = parent.Id;

    //     //Create a third child Case.
    //     Case child3 = TestDataProvider.createCase('subject', 'description', 'SSSWGeneralEnquiry');
    //     child3.ParentId = parent.Id;
    //     child3.RelatedCase__c = parent.Id;

    //     //Create a fourth child Case.
    //     Case child4 = TestDataProvider.createCase('subject', 'description', 'SSSWGeneralEnquiry');
    //     child4.ParentId = parent.Id;
    //     child4.RelatedCase__c = parent.Id;

    //     Test.startTest();

    //     insert new List<Case> {child1, child2, child3, child4};
    //     Map<Id,Case> childQ = new Map<Id,Case>();
    //     child4.AllocateToQueue__c = true;
    //     childQ.put(child1.Id, child1);
    //     childQ.put(child2.Id, child2);
    //     childQ.put(child3.Id, child3);
    //     childQ.put(child4.Id, child4);

    //     CaseChildQueueManagement.updateParentCase(childQ);

    //     parent.ResolutionCode__c = 'FCR';
    //     parent.Status = 'Closed';
    //     update parent;

    //     Test.stopTest();

    //     for (Case c : [SELECT Status
    //     FROM Case
    //     WHERE ParentId = :parent.Id]) {

    //         System.assertEquals('Closed', c.Status,
    //                 'CaseUtility_Test_testChildCaseAutoClose : Cases should be closed.');
    //     }

    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the close of bulk tasks.
    // ******************************************************************************************/
    // static testmethod void testCloseBulkTasks() {
    //     //Fetch the user.
    //     User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName
    //     FROM User
    //     WHERE Alias = 'spUser'
    //     LIMIT 1];

    //     System.runAs(supportUser){
    //         //Query for delivery enquiry record type
    //         Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
    //         //Create sample delivery enquiry case.
    //         Case testCase = TestDataProvider.createTestCase();
    //         testCase.RecordTypeId = deliveryRecType;
    //         testCase.Call_Purpose__c = 'Late Delivery';
    //         testCase.Subject = 'Sample Case';
    //         testCase.Origin = 'Phone';
    //         testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
    //         testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
    //         Database.insert(testCase);

    //         //Create child tasks.
    //         List<Task> newTasks = new List<Task>();
    //         newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(),
    //                 Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING));
    //         newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(),
    //                 Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING));
    //         Database.insert(newTasks);

    //         //Create child workflow emails.
    //         List<workflow_Email__c> newWFs = new List<workflow_Email__c>();
    //         newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id,
    //                 Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING));
    //         newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id,
    //                 Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING));
    //         Database.insert(newWFs);

    //         Test.startTest();

    //         Case caseRec = [SELECT Id, Status, ResolutionCode__c, Close_Bulk_Tasks__c FROM Case WHERE Id =: testCase.Id];
    //         caseRec.Close_Bulk_Tasks__c = true;
    //         Database.update(caseRec);

    //         caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
    //         caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
    //         Database.update(caseRec);

    //         Test.stopTest();

    //         Boolean testTask = [SELECT Id, Status
    //         FROM Task
    //         WHERE Status != :StarTrack_Constants.TASK_STATUS_FINISHED
    //         AND WhatId = :testCase.Id].isEmpty();

    //         Boolean testWorkFlowEmail = [SELECT Id, Status__c
    //         FROM workflow_Email__c
    //         WHERE Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE
    //         AND Case__c = :testCase.Id].isEmpty();

    //         System.assertEquals(true, testTask,
    //                 'CaseUtility_Test_testCloseBulkTasks : Status should be closed.');

    //         System.assertEquals(true, testWorkFlowEmail,
    //                 'CaseUtility_Test_testCloseBulkTasks : Status should be closed.');
    //     }
    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the NPS Schedule Date.
    // *      Since CaseUtility is an old class, most of it's functions are not used.
    // *      Most of the Case tests now make use of CaseCommonUtility through triggers...
    // *      This add some coverage for the CaseUtility class.
    // ******************************************************************************************/
    // public static testMethod void testNPSScheduleDate() {
    //     test.startTest();
    //     //Fetch bsp Profile Id
    //     Id bspProfileId = [SELECT Id
    //     FROM Profile
    //     WHERE Name = 'BSP Community User'].Id;

    //     //Fetch ddc Profile Id
    //     Id ddcProfileId = [SELECT Id
    //     FROM Profile
    //     WHERE Name = 'DDC Consumer Community User'].Id;

    //     UniqueCaseTrigger__c continueTrigger = new UniqueCaseTrigger__c();
    //     continueTrigger.ProfileIds__c = '{\'' + bspProfileId + '\',\'' + ddcProfileId + '\'}';
    //     continueTrigger.CaseLocality__c = 'International';
    //     continueTrigger.Enabled__c = true;
    //     insert continueTrigger;

    //     //Create Enquiry subtypes
    //     EnquirySubTypes__c subType = new EnquirySubTypes__c();
    //     subType.AvoidCustomerClose__c = true;
    //     subType.Name = 'Damaged/Missing contents';
    //     insert subType;

    //     //Create a Contact.
    //     Contact testContact = TestDataProvider.createTestContact();
    //     insert testContact;

    //     //Create a Article.
    //     Article__c testArticle = TestDataProvider.createTestArticle();
    //     testArticle.Name = '1234';
    //     insert testArticle;

    //     //Create second Article.
    //     Article__c testArticle2 = TestDataProvider.createTestArticle();
    //     testArticle2.Name = '12345';
    //     insert testArticle2;

    //     Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
    //     //Create a Case.
    //     Case case1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     insert case1;

    //     case1.ResolutionCode__c = 'Actioned';
    //     case1.Status = 'Closed';
    //     update case1;

    //     //Create second Case.
    //     Case case2 = case1.clone(true);

    //     Case_Entitlement_Status__c ces = new Case_Entitlement_Status__c(name='test',
    //             Internal__c='In Progress,Awaiting Information',
    //             Facility__c='Awaiting Facility Response',
    //             Customer__c='Awaiting Customer Response');
    //     insert ces;

    //     Map<Id, Case> mapNew = new Map<Id, Case>();
    //     Map<Id, Case> mapOld = new Map<Id, Case>();

    //     mapNew.put(case1.Id, case1);
    //     mapOld.put(case1.Id, case2);

    //     case1.NPSScheduledDate__c = System.Today();
    //     case2.NPSScheduledDate__c = System.Today()-1;

    //     CaseUtility.setNPSScheduleDate(mapNew, mapOld);

    //     Contact updContact = [SELECT LastNPSDate__c FROM Contact];

    //     System.assertEquals(case1.NPSScheduledDate__c, updContact.LastNPSDate__c,
    //             'CaseUtility_Test_testNPSScheduleDate : Last NPD Date should be NPS Schedule Date.');

    //     case1.Origin = 'Social';
    //     case2.Origin = 'Phone';
    //     case1.NPSTagDate__c = null;
    //     case2.NPSTagDate__c = null;

    //     CaseUtility.checkOriginChangeForNPS(mapNew, mapOld);

    //     SpamEmail__c spam = TestUtility.createSpamEmail('dsf@df.com');
    //     Database.insert(spam);

    //     //Call detectPermanentSpam for code test coverage.
    //     case1.SuppliedEmail = 'dsf@df.com';
    //     CaseUtility.detectPermanentSpam(new List<Case>{case1});

    //     //Call getRecordTypesWithDevNameContainsIncludingDirectEmail for code test coverage.
    //     Set<id> moreRecordTypes = CaseUtility.getRecordTypesWithDevNameContainsIncludingDirectEmail('SSSW');

    //     //Call getRecordIdWithDevName for code test coverage.
    //     Id anotherRecordType = CaseUtility.getRecordIdWithDevName('SSSWGeneralEnquiry');

    //     //Create a Case.
    //     Case case3 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     case3.ProductCategory__c='test';
    //     case3.ProductSubCategory__c='subtest';
    //     insert case3;

    //     Group backOfQueue = [SELECT Id,DeveloperName
    //     FROM Group
    //     WHERE Type = 'Queue'
    //     AND DeveloperName = 'SSSWBusinessBackOffice'
    //     LIMIT 1];

    //     //Create SSSWRouting
    //     SSSWRouting__c testRouting = TestUtility.createSSSWRouting('test',
    //             'subtest',
    //             'General Enquiry',
    //             null,
    //             '',
    //             '');
    //     testRouting.IsNew__c = false;
    //     testRouting.ExcludeFromNPS__c = false;
    //     testRouting.Queue_ID__c = backOfQueue.Id;

    //     insert testRouting;

    //     //Call assignFacilityToCase for code test coverage.
    //     case3.AllocateToQueue__c = true;
    //     CaseUtility.assignFacilityToCase(new List<Case>{case3}, true);

    //     case1.ContactId = null;
    //     case1.SuppliedEmail = 'dsf@df.com';
    //     case1.First_Name__c = 's';
    //     case1.Last_Name__c = 'dsf';
    //     CaseUtility.assignContactIDToCase(new List<Case>{case1});

    //     Integer accCount = [SELECT count() FROM Account];

    //     System.assertEquals(0, accCount,
    //             'CaseUtility_Test_testNPSScheduleDate : Account should not be assigned');

    //     case1.Origin = 'Email';
    //     case1.SuppliedEmail = 'dsf@df.com';
    //     CaseUtility.assignContactIDToCase(new List<Case>{case1});

    //     System.assertEquals(0, accCount,
    //             'CaseUtility_Test_testNPSScheduleDate : Account should not be assigned');

    //     CaseUtility.validateCase(new List<Case>{case1});

    //     List<Group> groups = CaseUtility.queueGroups;

    //     //Call isUserId for code test coverage.
    //     CaseUtility.isUserId(UserInfo.getUserId());

    //     //Call setOwnerToCurrentUser for code test coverage.
    //     case1.Status = 'In Progress,Awaiting Information';
    //     CaseUtility.setOwnerToCurrentUser(mapNew, mapOld);

    //     //Call avoidCustomerClose for code test coverage.
    //     case1.Customer_Milestones_Violated__c = 4;
    //     case1.Status = 'Closed';
    //     case1.ClosedBySystem__c = true;
    //     case1.EnquirySubType__c = 'Damaged/Missing contents';
    //     CaseUtility.avoidCustomerClose(mapNew, mapOld);

    //     //Call assignCharterTarget for code test coverage.
    //     CaseUtility.assignCharterTarget(new List<Case>{case1});

    //     case1.ContactId = testContact.Id;
    //     case1.ArticleTest__c = null;
    //     case1.ReferenceID__c = '1234';

    //     //Call linkCaseToArticles for code test coverage.
    //     case1.Origin = 'Social';
    //     CaseUtility.linkCaseToArticles(mapNew);

    //     //Call validateCase for code test coverage.
    //     CaseUtility.validateCase(new List<Case>{case1});
    //     CaseUtility.validateCase(mapNew);

    //     //Call avoidUserToUserOwnerChangeFromFillInbox for code test coverage.
    //     CaseUtility.avoidUserToUserOwnerChangeFromFillInbox(mapNew, mapOld);

    //     test.stopTest();
    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the setting of articles to subscribed.
    // ******************************************************************************************/
    // static testmethod void testArticlesSubscribed () {
    //     test.startTest();

    //     //Create a Contact.
    //     Contact testContact = TestDataProvider.createTestContact();
    //     insert testContact;

    //     Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
    //     //Create a Case.
    //     Case case1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     insert case1;

    //     //Create second Case.
    //     Case case2 = case1.clone(true);

    //     Map<Id, Case> mapNew = new Map<Id, Case>();
    //     Map<Id, Case> mapOld = new Map<Id, Case>();

    //     mapNew.put(case1.Id, case1);
    //     mapOld.put(case1.Id, case2);

    //     //Create a Article.
    //     Article__c testArticle = TestDataProvider.createTestArticle();
    //     testArticle.Name = '1234';
    //     insert testArticle;

    //     case1.ArticleTest__c = testArticle.Id;
    //     case1.Subscribed__c = true;
    //     CaseUtility.setArticlesSubscribed(mapNew, mapOld);

    //     test.stopTest();

    //     Article__c updArticle = [SELECT Subscribed__c FROM Article__c];

    //     System.assertEquals(true, updArticle.Subscribed__c,
    //             'CaseUtility_Test_testArticlesSubscribed : Article should be subscribed.');
    // }

    // /*****************************************************************************************
    // *  Scenario:
    // *      Test the closing of child cases.
    // ******************************************************************************************/
    // static testmethod void testCloseChildCases () {
    //     test.startTest();

    //     //Create a Contact.
    //     Contact testContact = TestDataProvider.createTestContact();
    //     insert testContact;

    //     Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
    //     //Create a Case.
    //     Case case1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     insert case1;

    //     case1.ResolutionCode__c = 'Actioned';
    //     case1.Status = 'Closed';
    //     update case1;

    //     //Create second Case.
    //     Case case2 = case1.clone(true);

    //     Map<Id, Case> mapNew = new Map<Id, Case>();
    //     Map<Id, Case> mapOld = new Map<Id, Case>();

    //     mapNew.put(case1.Id, case1);
    //     mapOld.put(case1.Id, case2);

    //     CaseUtility.closeChildCases(mapNew, mapOld);
    //     CaseUtility.closeChildCases(mapNew);

    //     Case updCase = [SELECT Status, ResolutionCode__c, Parent.ResolutionCode__c FROM Case];

    //     System.assertEquals('Actioned', updCase.ResolutionCode__c,
    //             'CaseUtility_Test_testCloseChildCases : Child cases should be closed.');

    //     //Create third Case for code test coverage.
    //     Case case3 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     insert case3;

    //     //Create fourth Case for code test coverage.
    //     Case case4 = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,testContact.Id,
    //             caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
    //     case4.ParentId=case3.Id;
    //     insert case4;

    //     case3.ResolutionCode__c = '';
    //     case3.Status = 'New';
    //     update case3;
    //     mapNew.put(case3.Id, case3);

    //     Set<Id> parentCaseIds = new Set<Id>();
    //     for (Case newCase : mapNew.values()) {
    //         parentCaseIds.add(newCase.Id);
    //     }

    //     //Call closeChildCases for code test coverage.
    //     CaseUtility.closeChildCases(parentCaseIds);

    //     test.stopTest();
    // }
}