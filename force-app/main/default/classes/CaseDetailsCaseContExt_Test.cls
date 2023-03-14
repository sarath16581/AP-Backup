/*************************************************************************************
Description:    Test class to cover CaseDetailsCaseContExt functionality
History:
--------------------------------------------------------------------------------------
2014-06-24  di.chen@bluewolf.com  Created
2015-12-01  Kalpita T  Updated to add method to cover new case reassign functionality
2017-04-21  dion.gunn@auspost.com.au  Only 30% test coverage. System.assert(true) was
            used to fake tests. Ditched the whole class and started from scratch.
2018-06-20  TDO-64 rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added tests for success/error PageMessages, added new callType to test the
            maxDateString condition.
2020-06-19 - Dheeraj - Added Test Method to Check Duplicates Method
2020-08-20 - Nathan Franklin - Fixed test class failure due to refactoring
2021-09-06 - seth.heang@auspost.com.au - Uplift SF API version to 52
**************************************************************************************/
@isTest
global class CaseDetailsCaseContExt_Test {

	@testSetup
	static void createTestData() {

		//Create AusPostSettings
		AusPostSettings__c aps = TestDataProvider.createTestAusPostSettings3();

		Group backOfQueue = [
				SELECT Id,DeveloperName
				FROM Group
				WHERE Type = 'Queue'
				AND DeveloperName = 'SSSW_BOH_Group_3'
				LIMIT 1
		];

		//Create SSSWRouting
		SSSWRouting__c testRouting = TestUtility.createSSSWRouting('Domestic Parcels',
				'Express',
				'Investigation',
				null,
				'Consumer',
				'Email',
				'Any',
				SSSWConstants.RECTYPEROUTING);
		testRouting.IsActive__c = True;
		testRouting.IsNew__c = true;
		testRouting.ExcludeFromNPS__c = true;
		testRouting.Queue_ID__c = backOfQueue.Id;

		Database.insert(testRouting);

		//Create Article
		Article__c testArticle = new Article__c();
		testArticle.Name = '123';
		testArticle.ArticleID__c = '123';
		testArticle.TrackingID__c = '123';
		testArticle.Subscribed__c = true;
		testArticle.ArticleLodgementDate__c = date.today();
		testArticle.SenderPostcode__c = '123';
		testArticle.ReceiverPostcode__c = '3002';
		testArticle.ArticleType__c = 'Regular Parcel';
		insert testArticle;

		//Create EventMessage
		EventMessage__c testEventMessage = new EventMessage__c (EventDescription__c = 'test',
				eventType__c = 'test',
				CommentText__c = 'delayed',
				Article__c = testArticle.id);
		insert testEventMessage;

		Map<String, Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();

		//Create Account
		Account testAccount = TestUtility.createBusinessAccount('Wayne Enterprises',
				accRecTypeMap.get('Organisation').getRecordTypeId());
		Database.insert(testAccount);

		//Create Contact
		Contact testContact = TestUtility.createContact('Bruce',
				'Wayne',
				'bruce@wayne.com',
				testAccount.id);
		Database.insert(testContact);

		Map<String, Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		//Create Case
		Case testCase = TestUtility.createCase('Enquiry',
				'In Progress',
				'Investigation',
				testAccount.Id,
				testContact.Id,
				caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
		testCase.Origin = 'Email';
		testCase.ProductCategory__c = 'Domestic Parcels';
		testCase.ProductSubCategory__c = 'Express';
		testCase.ReferenceId__c = '123'; //'12345TestDataSetup';
		testCase.Address2__c = '111 Bourke Street';
		testCase.IsNewForRouting__c = true;
		testCase.AllocateToQueue__c = true;
		testCase.EnquirySubType__c = 'Damages in transit';
		testCase.DatePosted__c = system.today();
		testCase.Address1Postcode__c = '3000';
		testCase.Address2Postcode__c = '3000';
		testCase.Status = 'Awaiting Customer Response';

		Database.insert(testCase);
	}

	@IsTest
	static void ensureAssignCaseChecksForSkills() {
		Map<String, Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		MockUtility.disableTriggerExecution();
		List<User> agents = ApplicationTestDataFactory.getUsers(1, true);
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		testCase.OwnerId = agents[0].Id;
		testCase.Origin = 'Email';
		testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id; //required when routing engine SSSW_Routing.assignCasesAndDescription() is called

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
		CaseDetailsCaseContExt controller = new CaseDetailsCaseContExt(sc);
		controller.reassignCase = testCase; // TODO: clean up these silly business
		controller.myCase = testCase; // TODO: clean up these silly business
		controller.remediationAvailable = false; // skipping article fetch


		//Update SSSWRouting from TestSetup to Omni Queue
		SSSWRouting__c testRouting = [SELECT Id,Queue_ID__c FROM SSSWRouting__c LIMIT 1];
		testRouting.Queue_ID__c = OmniChannelService.Cache.queuesWithRoutingConfig.keySet().iterator().next(); 
		Database.update(testRouting);

		List<ServiceChannel> serviceChannels = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true);
		Map<Id, PendingServiceRouting> psrs = new Map<Id, PendingServiceRouting>(OmniChannelTestDataFactory.getPendingServiceRoutings(1, serviceChannels[0].Id, new Set<Id>{testCase.Id}, true));

		Map<Id, Skill> skills = new Map<Id, Skill>(OmniChannelTestDataFactory.getSkills(1, true));
		List<SkillRequirement> skillsRequirements = OmniChannelTestDataFactory.getSkillRequirements(1, skills.keySet(), psrs.keySet(), true);

		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(OmniChannelTestDataFactory.getServiceResources(1, 'A', true));
		List<ServiceResourceSkill> serviceResourceSkills = OmniChannelTestDataFactory.getServiceResourceSkills(1, skills.keySet(), serviceResources.keySet(), true);

		//mock selectors
		PendingServiceRoutingSelector pendingServiceRoutingSelector = (PendingServiceRoutingSelector) MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		SkillRequirementSelector skillRequirementSelector = (SkillRequirementSelector) MockUtility.mockSelector(SkillRequirementSelector.class);
		ServiceResourceSkillSelector serviceResourceSkillSelector = (ServiceResourceSkillSelector) MockUtility.mockSelector(ServiceResourceSkillSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(pendingServiceRoutingSelector.selectByWorkItemId(
									(Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }),
									(Set<Object>) fflib_Match.eq(new Set<Object>())
								)).thenReturn(psrs.values());

		MockUtility.Mocks.when(skillRequirementSelector.selectByRelatedRecordIds(
									(Set<Id>) fflib_Match.eq(psrs.keySet()),
									(Set<Object>) fflib_Match.eq(new Set<Object>())
								)).thenReturn(skillsRequirements);
		
		MockUtility.Mocks.when(serviceResourceSkillSelector.selectByActiveServiceResourceRelatedRecordIds(
									(Set<Id>) fflib_Match.eq(new Set<Id>{testCase.OwnerId}),
									(Set<Object>) fflib_Match.eq(new Set<Object>())
								)).thenReturn(serviceResourceSkills);

		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlRollback((Savepoint)fflib_Match.anyObject())).thenReturn(true);
						
		MockUtility.Mocks.stopStubbing();

		//test start and stop
		Test.startTest();

		controller.assignCase();

		Test.stopTest();

		System.assertEquals(true, controller.myCase.BypassPreferredAgent__c, 'Should flag Bypass Preferred Agent if reassigning to an Omni queue');
		System.assertEquals(true, controller.notAllowedToReassign, 'Should not allow user to reassign case');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to call remote action method to get the recordTypeId.
	******************************************************************************************/
	static testmethod void testGetRecordTypeId() {
		//Create Person Account
		Account testPersonAccount = TestDataProvider.createAndSavePersonAccount();

		Test.startTest();

		//Create Case
		Case caseForRollback = TestDataProvider.createAndSaveCase('General Enquiry', 'Domestic Parcels', 'SSSW General Enquiry');

		caseForRollback.referenceID__c = 'SSSWCase';
		update caseForRollback;

		String rTypeId = CaseDetailsCaseContExt.getRecordTypeId('General Enquiry', 'Domestic Parcels', 'eParcel- Express');

		Test.stopTest();

		List<RecordType> rType = new List<RecordType>([
				SELECT Id, sObjectType,Name
				FROM RecordType
				WHERE Id = :rTypeId
		]);

		System.assertNotEquals(null, rType.isEmpty(),
				'CaseDetailsCaseContExt_Test_testGetRecordTypeId : recordType should be retrieved.');

		System.assertEquals('SSSW General Enquiry', rType[0].Name,
				'CaseDetailsCaseContExt_Test_testGetRecordTypeId : recordTypeId should be retrieved.');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to return the child case id if it exists.
	******************************************************************************************/
	static testmethod void testGetChildCaseId() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		Test.startTest();

		String caseId = CaseDetailsCaseContExt.getChildCaseId(testCase.Id);

		Test.stopTest();

		System.assertEquals(caseId, CaseDetailsCaseContExt.childCase.Id,
				'CaseDetailsCaseContExt_Test_testGetChildCaseId : Child case id should be retrieved.');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to clone the case and redirect to cloned case.
	******************************************************************************************/
	static testmethod void testGetClonedCaseId() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		Test.startTest();

		String caseId = CaseDetailsCaseContExt.getClonedCaseId(testCase.Id);

		Test.stopTest();

		System.assertEquals(caseId, CaseDetailsCaseContExt.clonedCase.Id,
				'CaseDetailsCaseContExt_Test_testGetChildCaseId : Case should be cloned and retrieved.');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to call on page load to set the values and to save the case record.
	******************************************************************************************/
	static testmethod void testInitAndSavePage() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);

		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		Test.startTest();

		//Set mock callout class.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('CaseDescribe'));
		//Call initializePage on page load to set the values.
		cdcc.initializePage();

		cdcc.relatedArticle.mls_Remediate_Article__c = true;
		cdcc.relatedArticle.mls_AddressLine1__c = '111 Bourke Street';
		cdcc.relatedArticle.mls_Suburb__c = 'Melbourne';
		cdcc.relatedArticle.mls_Postcode__c = '3000';
		cdcc.relatedArticle.mls_State__c = 'VIC';
		cdcc.relatedArticle.mls_Instructions__c = 'Leave at front door';
		cdcc.relatedArticle.mls_Description__c = 'Big red box';

		//Set mock callout class with call type as respond200.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('respond200'));
		//Call doCalculate to calculate EDD when data is filled in.
		cdcc.doCalculate();

		//Set mock callout class with call type as respond400.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('respond400'));
		//Call doCalculate to calculate EDD when data is filled in.
		cdcc.doCalculate();

		//Call doNothing for test code coverage.
		cdcc.doNothing();
		//Call checkValidation to validate the case update.
		cdcc.checkValidation();
		//Call closepopup to hide the popup window for duplicates.
		cdcc.closepopup();
		//Call save method to save the case record.
		cdcc.save();
		//Call assignCase to check the new case assign logic and based on routing rules, assign case to respective owner.
		cdcc.assignCase();
		//Call close method to close the case record.
		cdcc.close();

		Test.stopTest();

		Article__c testArticle = [
				SELECT Remediation_TimeStamp__c
				FROM Article__c
				WHERE Id = :cdcc.relatedArticle.Id
		];

		System.assertNotEquals(null, cdcc.myCase.id,
				'CaseDetailsCaseContExt_Test_testInitAndSavePage : Case should be retrieved.');

		//Fails in Dev Sandbox as "Send Remediation Event to SAP" workflow on Article__c is not active
		System.assertNotEquals(null, testArticle.Remediation_TimeStamp__c,
				'CaseDetailsCaseContExt_Test_testInitAndSavePage : Remediation TimeStamp should be retrieved.');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to call on page load to set the values and to save the case record.
	******************************************************************************************/
	static testmethod void testInitAndSavePageMessages() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);

		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		Test.startTest();

		//Set mock callout class.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('CaseDescribe'));
		//Call initializePage on page load to set the values.
		cdcc.initializePage();

		cdcc.relatedArticle.mls_Remediate_Article__c = false;
		cdcc.relatedArticle.mls_AddressLine1__c = '';
		cdcc.relatedArticle.mls_Suburb__c = '';
		cdcc.relatedArticle.mls_Postcode__c = '';
		cdcc.relatedArticle.mls_State__c = '';
		cdcc.relatedArticle.mls_Instructions__c = '';
		cdcc.relatedArticle.mls_Description__c = '';

		//Call save method to save the case record.
		cdcc.save();
		//Call assignCase to check the new case assign logic and based on routing rules, assign case to respective owner.
		cdcc.assignCase();
		//Call close method to close the case record.
		cdcc.close();

		Test.stopTest();

		//Check that the expected message is in pageMessages.
		ApexPages.Message[] pageMessages = ApexPages.getMessages();

		System.assertNotEquals(0, pageMessages.size(),
				'CaseDetailsCaseContExt_testInitAndSavePage : pageMessages size should not be zero');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to call on page load to set the values and to save the case record.
	******************************************************************************************/
	static testmethod void testInitAndSaveInvalidPageMessages() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);

		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		//Set mock callout class.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('CaseDescribe'));
		//Call initializePage on page load to set the values.
		cdcc.initializePage();

		cdcc.relatedArticle.mls_Remediate_Article__c = false;
		cdcc.relatedArticle.mls_AddressLine1__c = '';
		cdcc.relatedArticle.mls_Suburb__c = '';
		cdcc.relatedArticle.mls_Postcode__c = '123456';
		cdcc.relatedArticle.mls_State__c = 'XXX';
		cdcc.relatedArticle.mls_Instructions__c = '';
		cdcc.relatedArticle.mls_Description__c = '';

		//Set mock callout class with call type as respond600.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('respond600'));
		//Call doCalculate to calculate EDD when data is filled in.
		cdcc.doCalculate();

		//Set mock callout class with call type as respond800.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('respond800'));
		//Call doCalculate to calculate EDD when data is filled in.
		cdcc.doCalculate();

		//Call save method to save the case record.
		cdcc.save();
		//Call assignCase to check the new case assign logic and based on routing rules, assign case to respective owner.
		cdcc.assignCase();
		//Call close method to close the case record.
		cdcc.close();

		Test.stopTest();

		//Check that the expected message is in pageMessages.
		ApexPages.Message[] pageMessages = ApexPages.getMessages();

		System.assertNotEquals(0, pageMessages.size(),
				'CaseDetailsCaseContExt_Test_testInitAndSaveInvalidPageMessages : pageMessages size should not be zero');
	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to call on page load to set the values and test the Consignment Validation.
	******************************************************************************************/
	static testmethod void testConsignmentValidation() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];
		testCase.ReferenceId__c = 'conArticle';
		update testCase;


		//Fetch a Record Type
		//RecordType conRtype = [SELECT id FROM RecordType WHERE sObjectType = 'Article__c'AND Name = 'Consignment' LIMIT 1];
		//Id conRtype = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();

		Test.startTest();

		//Create a Article
		/* Article__c testArticle1 = new Article__c();
		 testArticle1.Name = 'conArticle';
		 testArticle1.RecordTypeId = conRtype;
		 testArticle1.ArticleLodgementDate__c = date.today();
		 testArticle1.SenderPostcode__c = '123';
		 testArticle1.ReceiverPostcode__c = '3002';
		 testArticle1.ArticleType__c = 'Regular Parcel';
		 insert testArticle1;*/

		//Create Article
		/*Article__c testArticle = new Article__c();
		testArticle.Name = '123';
		testArticle.ArticleLodgementDate__c = date.today();
		testArticle.SenderPostcode__c = '123';
		testArticle.ReceiverPostcode__c = '3002';
		testArticle.ArticleType__c = 'Regular Parcel';
		insert testArticle;

		testArticle.Consignment__c = testArticle1.Id;
		update testArticle;*/


		//Fetch a Article
		/*Article__c articleArt = [SELECT Consignment__c
		FROM Article__c
		WHERE Name = '123'
		LIMIT 1];
		articleArt.Consignment__c = testArticle1.Id;
		update articleArt;*/


		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		//Set mock callout class.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('CaseDescribe'));
		//Call initializePage on page load to set the values.
		cdcc.initializePage();

		cdcc.relatedArticle.mls_Remediate_Article__c = true;
		cdcc.relatedArticle.mls_AddressLine1__c = '111 Bourke Street';
		cdcc.relatedArticle.mls_Suburb__c = 'Melbourne';
		cdcc.relatedArticle.mls_Postcode__c = '3000';
		cdcc.relatedArticle.mls_State__c = 'VIC';
		cdcc.relatedArticle.mls_Instructions__c = 'Leave at front door';
		cdcc.relatedArticle.mls_Description__c = 'Big red box';

		//Call save method to save the case record.
		cdcc.save();

		Test.stopTest();

		/*Article__c testArticle2 = [SELECT Remediation_TimeStamp__c
		FROM Article__c
		WHERE Id =: cdcc.relatedArticle.Id]; */

		System.assertNotEquals(null, cdcc.myCase.id,
				'CaseDetailsCaseContExt_Test_testConsignmentValidation : Case should be retrieved.');

		/*System.assertEquals(testArticle1.Id, testArticle1.Consignment__c,
				'CaseDetailsCaseContExt_Test_testConsignmentValidation : Article should be retrieved.');*/
	}

	/*****************************************************************************************
   *  Scenario:
   *      Test to test the Consignment Validation.
   ******************************************************************************************/
	static testmethod void testConsignmentValidation1() {

		//Fetch a Record Type
		//RecordType conRtype = [SELECT id FROM RecordType WHERE sObjectType = 'Article__c'AND Name = 'Consignment' LIMIT 1];
		Id conRtype = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId();
		Test.startTest();

		//Create a Article
		Article__c testArticle1 = new Article__c();
		testArticle1.Name = 'conArticle';
		testArticle1.RecordTypeId = conRtype;
		testArticle1.ArticleLodgementDate__c = date.today();
		testArticle1.SenderPostcode__c = '123';
		testArticle1.ReceiverPostcode__c = '3002';
		testArticle1.ArticleType__c = 'Regular Parcel';
		insert testArticle1;
		//Fetch a Article
		Article__c articleArt = [
				SELECT Consignment__c
				FROM Article__c
				WHERE Name = '123'
				LIMIT 1
		];
		articleArt.Consignment__c = testArticle1.Id;
		update articleArt;

		Test.stopTest();

		System.assertEquals(testArticle1.Id, articleArt.Consignment__c,
				'CaseDetailsCaseContExt_Test_testConsignmentValidation : Article should be retrieved.');

	}

	/*****************************************************************************************
	*  Scenario:
	*      Test to check if it's a working day.
	******************************************************************************************/
	static testmethod void testCheckWorkingDay() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		//Create a Holiday
		Holiday testHoliday = new Holiday();
		testHoliday.IsAllDay = true;
		testHoliday.ActivityDate = Date.newInstance(2017, 12, 25);
		testHoliday.Name = 'Christmas Day';
		insert testHoliday;

		Test.startTest();

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		//Set mock callout class.
		Test.setMock(HttpCalloutMock.class, new InitPageMock('CaseDescribe'));
		//Call initializePage on page load to set the values.
		cdcc.initializePage();

		Boolean weekend = cdcc.checkifItisWorkingDay(Date.newInstance(2017, 05, 14));
		Boolean holiday = cdcc.checkifItisWorkingDay(Date.newInstance(2017, 12, 25));
		Boolean workday = cdcc.checkifItisWorkingDay(Date.newInstance(2017, 05, 17));

		Test.stopTest();

		System.assertEquals(false, weekend,
				'CaseDetailsCaseContExt_Test_testCheckWorkingDay : Weekend should be retrieved.');

		System.assertEquals(false, holiday,
				'CaseDetailsCaseContExt_Test_testCheckWorkingDay : Holiday should be retrieved.');

		System.assertEquals(true, workday,
				'CaseDetailsCaseContExt_Test_testCheckWorkingDay : Workday should be retrieved.');
	}

	/***********************************************************************************************
	*      InitPageMock is a mock class to get the fake response for testing CaseDetailsCaseContExt.
	************************************************************************************************/
	public class InitPageMock implements HttpCalloutMock {
		private string endpoint;
		private string callMethod;
		private string callType;
		private Integer statusType;

		//Constructor to help switch out the endpoint/method
		public InitPageMock(String callType) {
			this.callType = callType;
			if (callType.equals('CaseDescribe')) {
				this.callMethod = 'GET';
				this.statusType = 200;
			} else if (callType.equals('respond400')) {
				this.callMethod = 'GET';
				this.statusType = 400;
			} else if (callType.equals('respond200')) {
				this.callMethod = 'GET';
				this.statusType = 200;
			} else if (callType.equals('respond600')) {
				this.callMethod = 'GET';
				this.statusType = 200;
			} else if (callType.equals('respond800')) {
				this.callMethod = 'GET';
				this.statusType = 800;
			}
		}

		public HTTPResponse respond(HTTPRequest req) {
			//Create a fake response
			HttpResponse res = new HttpResponse();
			if (callType.equals('CaseDescribe')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"detailLayoutSections":[{"columns":2,"heading":"Case Summary","layoutRows":[{"layoutItems":[{"editableForUpdate":false,"label":"Case Number","layoutComponents":[{"details":{"autoNumber":true,"byteLength":90,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":false,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":false,"htmlFormatted":false,"idLookup":true,"inlineHelpText":null,"label":"Case Number","length":30,"name":"CaseNumber","nameField":true,"namePointing":false,"nillable":false,"permissionable":false,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":false,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":1,"type":"Field","value":"CaseNumber"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Reference ID","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":true,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":true,"inlineHelpText":"The Reference ID for this Case. i.e Article ID or MRS CRN.","label":"Reference ID","length":255,"name":"ReferenceID__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":2,"type":"Field","value":"ReferenceID__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Status","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Status","length":40,"name":"Status","nameField":false,"namePointing":false,"nillable":true,"permissionable":false,"picklistValues":[{"active":true,"defaultValue":true,"label":"New","validFor":null,"value":"New"},{"active":true,"defaultValue":false,"label":"On Hold","validFor":null,"value":"On Hold"},{"active":true,"defaultValue":false,"label":"Network Responded","validFor":null,"value":"Network Responded"},{"active":true,"defaultValue":false,"label":"Customer Responded","validFor":null,"value":"Customer Responded"},{"active":true,"defaultValue":false,"label":"Closed","validFor":null,"value":"Closed"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":3,"type":"Field","value":"Status"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Priority","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Priority","length":40,"name":"Priority","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"High","validFor":null,"value":"High"},{"active":true,"defaultValue":false,"label":"Medium","validFor":null,"value":"Medium"},{"active":true,"defaultValue":true,"label":"Low","validFor":null,"value":"Low"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":4,"type":"Field","value":"Priority"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Description","layoutComponents":[{"details":{"autoNumber":false,"byteLength":96000,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":false,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Description","length":32000,"name":"Description","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":false,"type":"textarea","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":4,"tabOrder":5,"type":"Field","value":"Description"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Type","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Type","length":40,"name":"Type","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"General Enquiry","validFor":null,"value":"General Enquiry"},{"active":true,"defaultValue":false,"label":"Feedback","validFor":null,"value":"Feedback"},{"active":true,"defaultValue":false,"label":"Investigation","validFor":null,"value":"Investigation"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":6,"type":"Field","value":"Type"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Product Category","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Product Category","length":255,"name":"ProductCategory__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Domestic Parcels","validFor":null,"value":"Domestic Parcels"},{"active":true,"defaultValue":false,"label":"International Parcels","validFor":null,"value":"International Parcels"},{"active":true,"defaultValue":false,"label":"Domestic Letters","validFor":null,"value":"Domestic Letters"},{"active":true,"defaultValue":false,"label":"International Letters","validFor":null,"value":"International Letters"},{"active":true,"defaultValue":false,"label":"Money & Insurance","validFor":null,"value":"Money & Insurance"},{"active":true,"defaultValue":false,"label":"Post Office & Business Hub Services","validFor":null,"value":"Post Office & Business Hub Services"},{"active":true,"defaultValue":false,"label":"Travel & ID","validFor":null,"value":"Travel & ID"},{"active":true,"defaultValue":false,"label":"Web & Apps","validFor":null,"value":"Web & Apps"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":7,"type":"Field","value":"ProductCategory__c"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Enquiry Sub Type","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":"Type_and_Product__c","createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":true,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Enquiry Sub Type","length":255,"name":"EnquirySubType__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Address Correction","validFor":"AAAAAAAAAAAAAAAD////wAf9/wAA","value":"Address Correction"},{"active":true,"defaultValue":false,"label":"Address not in NAF","validFor":"","value":"Address not in NAF"},{"active":true,"defaultValue":false,"label":"All Other","validFor":"","value":"All Other"},{"active":true,"defaultValue":false,"label":"AP Digital Mailbox","validFor":"","value":"AP Digital Mailbox"},{"active":true,"defaultValue":false,"label":"Appointment Booking","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA","value":"Appointment Booking"},{"active":true,"defaultValue":false,"label":"Article carded - no card left","validFor":"","value":"Article carded - no card left"},{"active":true,"defaultValue":false,"label":"Article carded - no delivery attempt","validFor":"AAAAAD8f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Article carded - no delivery attempt"},{"active":true,"defaultValue":false,"label":"Article safe dropped - no delivery attempt","validFor":"AAAAAACA","value":"Article safe dropped - no delivery attempt"},{"active":true,"defaultValue":false,"label":"Article safe dropped - not located","validFor":"","value":"Article safe dropped - not located"},{"active":true,"defaultValue":false,"label":"Article safe dropped unsafe location","validFor":"","value":"Article safe dropped unsafe location"},{"active":true,"defaultValue":false,"label":"Booking amendment","validFor":"AAAAAAAAAAAIBAAA","value":"Booking amendment"},{"active":true,"defaultValue":false,"label":"Booking cancellation","validFor":"AAAAAAAAAAAIBAAA","value":"Booking cancellation"},{"active":true,"defaultValue":false,"label":"Cancel scheduled pick up","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAABAE","value":"Cancel scheduled pick up"},{"active":true,"defaultValue":false,"label":"Carding issue","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Carding issue"},{"active":true,"defaultValue":false,"label":"Change address","validFor":"","value":"Change address"},{"active":true,"defaultValue":false,"label":"Complaint","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//z//","value":"Complaint"},{"active":true,"defaultValue":false,"label":"Complaint referred to issuer","validFor":"AAAAAEAAAAAAAAAEAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAIAAA","value":"Complaint referred to issuer"},{"active":true,"defaultValue":false,"label":"Compliment","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//z//","value":"Compliment"},{"active":true,"defaultValue":false,"label":"Credit Account Enquiry","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAQA","value":"Credit Account Enquiry"},{"active":true,"defaultValue":false,"label":"Damaged/Missing contents","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damaged/Missing contents"},{"active":true,"defaultValue":false,"label":"Damages In Transit","validFor":"","value":"Damages In Transit"},{"active":true,"defaultValue":false,"label":"Damage to property","validFor":"AAAAAD+f4AP5/AAD////wAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damage to property"},{"active":true,"defaultValue":false,"label":"Damage to vehicle","validFor":"AAAAAD+f4AP5/AAD////wAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damage to vehicle"},{"active":true,"defaultValue":false,"label":"Delayed delivery","validFor":"AAAAAD+f4AP5/AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Delayed delivery"},{"active":true,"defaultValue":false,"label":"Delayed - inside network","validFor":"","value":"Delayed - inside network"},{"active":true,"defaultValue":false,"label":"Delayed - outside network","validFor":"","value":"Delayed - outside network"},{"active":true,"defaultValue":false,"label":"Delivered to no junk mail address","validFor":"AAAAAAAAAAAIBAAA","value":"Delivered to no junk mail address"},{"active":true,"defaultValue":false,"label":"Delivery complaint","validFor":"AAAAAD+f4AP5/AAD////wAf9/wAA","value":"Delivery complaint"},{"active":true,"defaultValue":false,"label":"Direct marketing opt out","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Direct marketing opt out"},{"active":true,"defaultValue":false,"label":"Disputed delivery scan","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Disputed delivery scan"},{"active":true,"defaultValue":false,"label":"Domestic Letters - Other","validFor":"","value":"Domestic Letters - Other"},{"active":true,"defaultValue":false,"label":"Domestic Parcels - Other","validFor":"","value":"Domestic Parcels - Other"},{"active":true,"defaultValue":false,"label":"Express Guarantee Failure","validFor":"AAAAAAGAYAAQCAAAAeAHgAAcBwAA","value":"Express Guarantee Failure"},{"active":true,"defaultValue":false,"label":"Facility reported damages","validFor":"AAAAAD+f4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Facility reported damages"},{"active":true,"defaultValue":false,"label":"FOI request","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"FOI request"},{"active":true,"defaultValue":false,"label":"Inbound tracking","validFor":"AAAAAAAAAAAAAP/8AAAAH/AA","value":"Inbound tracking"},{"active":true,"defaultValue":false,"label":"Incorrect mail being redirected/held","validFor":"","value":"Incorrect mail being redirected/held"},{"active":true,"defaultValue":false,"label":"Incorrect or missing order","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAwCAAAAP8P8AAAAAAAAAEAAQAAA","value":"Incorrect or missing order"},{"active":true,"defaultValue":false,"label":"Interception request","validFor":"","value":"Interception request"},{"active":true,"defaultValue":false,"label":"International Letters - Other","validFor":"","value":"International Letters - Other"},{"active":true,"defaultValue":false,"label":"International Parcels - Other","validFor":"","value":"International Parcels - Other"},{"active":true,"defaultValue":false,"label":"Item transfer","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Item transfer"},{"active":true,"defaultValue":false,"label":"Locations & hours of operation","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAADiQA","value":"Locations & hours of operation"},{"active":true,"defaultValue":false,"label":"Lodgement issue","validFor":"AAAAAAAAAAAIBAAA","value":"Lodgement issue"},{"active":true,"defaultValue":false,"label":"Mail not being redirected/held","validFor":"","value":"Mail not being redirected/held"},{"active":true,"defaultValue":false,"label":"Missed/Late Pickup","validFor":"","value":"Missed/Late Pickup"},{"active":true,"defaultValue":false,"label":"Missing Item","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Missing Item"},{"active":true,"defaultValue":false,"label":"Mobile website","validFor":"AAAAAAAI","value":"Mobile website"},{"active":true,"defaultValue":false,"label":"Money & Insurance  - Other","validFor":"","value":"Money & Insurance  - Other"},{"active":true,"defaultValue":false,"label":"MRSO issue","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAgAAA","value":"MRSO issue"},{"active":true,"defaultValue":false,"label":"MyPost balance request","validFor":"","value":"MyPost balance request"},{"active":true,"defaultValue":false,"label":"New booking","validFor":"AAAAAAAAAAAIBAAA","value":"New booking"},{"active":true,"defaultValue":false,"label":"New pick up request","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAABAE","value":"New pick up request"},{"active":true,"defaultValue":false,"label":"Outbound tracking","validFor":"AAAAAAAAAAAAAP/8AAAAH/AA","value":"Outbound tracking"},{"active":true,"defaultValue":false,"label":"Pick up issue","validFor":"","value":"Pick up issue"},{"active":true,"defaultValue":false,"label":"POD request","validFor":"AAAA/kAAB+AAAP/8AAAAH/AAAAAAAAAAAAAAAAAAAAAAAAAAIAAA","value":"POD request"},{"active":true,"defaultValue":false,"label":"Post Office & Hub  - Other","validFor":"","value":"Post Office & Hub  - Other"},{"active":true,"defaultValue":false,"label":"Pricing","validFor":"AAAA/8AAB/wAAP/8AAAAP/AAAAAAAAAAAAAAAAAAP/+AAAAAIAAA","value":"Pricing"},{"active":true,"defaultValue":false,"label":"Pricing enquiry","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/wAAAPwAA","value":"Pricing enquiry"},{"active":true,"defaultValue":false,"label":"Privacy breach","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Privacy breach"},{"active":true,"defaultValue":false,"label":"Product & service information","validFor":"AAAA/8AAB/wAAP/8AAAAP/AAAAAAD///wAAAP8AAP//AAAAAIAAA","value":"Product & service information"},{"active":true,"defaultValue":false,"label":"Product issue","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAO+74AAA","value":"Product issue"},{"active":true,"defaultValue":false,"label":"Product Order","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAMAAAMAAAAB8","value":"Product Order"},{"active":true,"defaultValue":false,"label":"Product support","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAC47gAAAP/+DwD//wAA//z//","value":"Product support"},{"active":true,"defaultValue":false,"label":"Queue times","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAOB5EAAA","value":"Queue times"},{"active":true,"defaultValue":false,"label":"Redirection Failure","validFor":"AAAAAABgGAAGAwAAAAAAAAgC","value":"Redirection Failure"},{"active":true,"defaultValue":false,"label":"Reissue MyPost card","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwAAA","value":"Reissue MyPost card"},{"active":true,"defaultValue":false,"label":"Remittance not received","validFor":"","value":"Remittance not received"},{"active":true,"defaultValue":false,"label":"Renewal/Payment","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAIAgAAA","value":"Renewal/Payment"},{"active":true,"defaultValue":false,"label":"Request for personal information","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Request for personal information"},{"active":true,"defaultValue":false,"label":"RTS request","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"RTS request"},{"active":true,"defaultValue":false,"label":"Safety issue","validFor":"AAAAAD+f4AP5/AAD////wAf9////8AAAAAAAAAAAAAAAAAAAHAAA","value":"Safety issue"},{"active":true,"defaultValue":false,"label":"Self-service support","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//A","value":"Self-service support"},{"active":true,"defaultValue":false,"label":"Service availability","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8","value":"Service availability"},{"active":true,"defaultValue":false,"label":"SPB – Graffiti/Damage/New","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAAA","value":"SPB – Graffiti/Damage/New"},{"active":true,"defaultValue":false,"label":"SPB – Request removal/relocation","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAAA","value":"SPB – Request removal/relocation"},{"active":true,"defaultValue":false,"label":"Staff Complaint","validFor":"AAAAAD+f4AP5/AAD////wAAAAP//8AAAAAAAAAAAAAAAAAAAHAAA","value":"Staff Complaint"},{"active":true,"defaultValue":false,"label":"Staff Compliment","validFor":"AAAAAD+f4AP5/AAD////wAAAAP//8AAAAAAAAAAAAAAAAAAAHAAA","value":"Staff Compliment"},{"active":true,"defaultValue":false,"label":"Tracking","validFor":"AAAA/kAAB/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAA","value":"Tracking"},{"active":true,"defaultValue":false,"label":"Travel & ID - Other","validFor":"","value":"Travel & ID - Other"},{"active":true,"defaultValue":false,"label":"UMCS booking amendment","validFor":"","value":"UMCS booking amendment"},{"active":true,"defaultValue":false,"label":"UMCS delivery issue","validFor":"","value":"UMCS delivery issue"},{"active":true,"defaultValue":false,"label":"UMCS label issue","validFor":"","value":"UMCS label issue"},{"active":true,"defaultValue":false,"label":"UMCS new booking","validFor":"","value":"UMCS new booking"},{"active":true,"defaultValue":false,"label":"UMCS registration/access","validFor":"","value":"UMCS registration/access"},{"active":true,"defaultValue":false,"label":"Unaddressed mail booking service","validFor":"","value":"Unaddressed mail booking service"},{"active":true,"defaultValue":false,"label":"Unauthorised Hold/Redirection application","validFor":"","value":"Unauthorised Hold/Redirection application"},{"active":true,"defaultValue":false,"label":"Unauthorised MRS application","validFor":"AAAAAABgGAAGAwAAAAAAAAgC","value":"Unauthorised MRS application"},{"active":true,"defaultValue":false,"label":"Unauthorised Safe Drop","validFor":"","value":"Unauthorised Safe Drop"},{"active":true,"defaultValue":false,"label":"Web & Apps - Other","validFor":"","value":"Web & Apps - Other"},{"active":true,"defaultValue":false,"label":"Website/app technical issues","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////wAAA","value":"Website/app technical issues"},{"active":true,"defaultValue":false,"label":"Withdrawal from post","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAABAAA","value":"Withdrawal from post"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":8,"type":"Field","value":"EnquirySubType__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Product Sub Category","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":"ProductCategory__c","createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":true,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Product Sub Category","length":255,"name":"ProductSubCategory__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Airmail over 2kg","validFor":"QAAA","value":"Airmail over 2kg"},{"active":true,"defaultValue":false,"label":"Airmail under 2kg","validFor":"UAAA","value":"Airmail under 2kg"},{"active":true,"defaultValue":false,"label":"All Other ID&V services","validFor":"","value":"All Other ID&V services"},{"active":true,"defaultValue":false,"label":"Amex","validFor":"","value":"Amex"},{"active":true,"defaultValue":false,"label":"Article Collection","validFor":"","value":"Article Collection"},{"active":true,"defaultValue":false,"label":"Bank@Post","validFor":"CAAA","value":"Bank@Post"},{"active":true,"defaultValue":false,"label":"Business Letters","validFor":"IAAA","value":"Business Letters"},{"active":true,"defaultValue":false,"label":"Car Insurance","validFor":"CAAA","value":"Car Insurance"},{"active":true,"defaultValue":false,"label":"Cash on Delivery","validFor":"oAAA","value":"Cash on Delivery"},{"active":true,"defaultValue":false,"label":"Change of Address Online","validFor":"","value":"Change of Address Online"},{"active":true,"defaultValue":false,"label":"Click & Send","validFor":"AQAA","value":"Click & Send"},{"active":true,"defaultValue":false,"label":"Concession stamps","validFor":"","value":"Concession stamps"},{"active":true,"defaultValue":false,"label":"Courier Post","validFor":"gAAA","value":"Courier Post"},{"active":true,"defaultValue":false,"label":"Delivery Choices","validFor":"","value":"Delivery Choices"},{"active":true,"defaultValue":false,"label":"eBay Store","validFor":"AQAA","value":"eBay Store"},{"active":true,"defaultValue":false,"label":"ECI","validFor":"UAAA","value":"ECI"},{"active":true,"defaultValue":false,"label":"ECI Platinum","validFor":"UAAA","value":"ECI Platinum"},{"active":true,"defaultValue":false,"label":"Economy Air under 2kg","validFor":"QAAA","value":"Economy Air under 2kg"},{"active":true,"defaultValue":false,"label":"Economy Air under 500g","validFor":"EAAA","value":"Economy Air under 500g"},{"active":true,"defaultValue":false,"label":"Economy Sea over 2kg","validFor":"QAAA","value":"Economy Sea over 2kg"},{"active":true,"defaultValue":false,"label":"eParcel- Express","validFor":"gAAA","value":"eParcel- Express"},{"active":true,"defaultValue":false,"label":"eParcel Online","validFor":"AQAA","value":"eParcel Online"},{"active":true,"defaultValue":false,"label":"eParcel- Regular","validFor":"gAAA","value":"eParcel- Regular"},{"active":true,"defaultValue":false,"label":"Express","validFor":"gAAA","value":"Express"},{"active":true,"defaultValue":false,"label":"Express Platinum","validFor":"gAAA","value":"Express Platinum"},{"active":true,"defaultValue":false,"label":"Express Post","validFor":"IAAA","value":"Express Post"},{"active":true,"defaultValue":false,"label":"Express Post International","validFor":"UAAA","value":"Express Post International"},{"active":true,"defaultValue":false,"label":"Farmhouse Direct","validFor":"","value":"Farmhouse Direct"},{"active":true,"defaultValue":false,"label":"Foreign Currency","validFor":"CAAA","value":"Foreign Currency"},{"active":true,"defaultValue":false,"label":"General merchandise","validFor":"BAAA","value":"General merchandise"},{"active":true,"defaultValue":false,"label":"Gift cards","validFor":"CAAA","value":"Gift cards"},{"active":true,"defaultValue":false,"label":"ID check - other","validFor":"","value":"ID check - other"},{"active":true,"defaultValue":false,"label":"International Courier","validFor":"UAAA","value":"International Courier"},{"active":true,"defaultValue":false,"label":"International Express","validFor":"UAAA","value":"International Express"},{"active":true,"defaultValue":false,"label":"International Standard","validFor":"QAAA","value":"International Standard"},{"active":true,"defaultValue":false,"label":"Item Transfer","validFor":"","value":"Item Transfer"},{"active":true,"defaultValue":false,"label":"KeyPass","validFor":"AgAA","value":"KeyPass"},{"active":true,"defaultValue":false,"label":"Load & Go","validFor":"CAAA","value":"Load & Go"},{"active":true,"defaultValue":false,"label":"Mail hold","validFor":"pAAA","value":"Mail hold"},{"active":true,"defaultValue":false,"label":"Mail Pick up","validFor":"BAAA","value":"Mail Pick up"},{"active":true,"defaultValue":false,"label":"Mail redirection","validFor":"tAAA","value":"Mail redirection"},{"active":true,"defaultValue":false,"label":"Messenger Post","validFor":"","value":"Messenger Post"},{"active":true,"defaultValue":false,"label":"Mobile apps","validFor":"AQAA","value":"Mobile apps"},{"active":true,"defaultValue":false,"label":"Mobile products","validFor":"BAAA","value":"Mobile products"},{"active":true,"defaultValue":false,"label":"Money Orders","validFor":"CAAA","value":"Money Orders"},{"active":true,"defaultValue":false,"label":"MRS Online","validFor":"AQAA","value":"MRS Online"},{"active":true,"defaultValue":false,"label":"Multi-Currency Cash Passport","validFor":"CAAA","value":"Multi-Currency Cash Passport"},{"active":true,"defaultValue":false,"label":"MyAccount","validFor":"","value":"MyAccount"},{"active":true,"defaultValue":false,"label":"MyPost Business App","validFor":"AQAA","value":"MyPost Business App"},{"active":true,"defaultValue":false,"label":"MyPost Concession Card","validFor":"AgAA","value":"MyPost Concession Card"},{"active":true,"defaultValue":false,"label":"MyPost Digital Mailbox","validFor":"AQAA","value":"MyPost Digital Mailbox"},{"active":true,"defaultValue":false,"label":"My Post ID card","validFor":"AgAA","value":"My Post ID card"},{"active":true,"defaultValue":false,"label":"Online Returns Portal","validFor":"AQAA","value":"Online Returns Portal"},{"active":true,"defaultValue":false,"label":"Ordinary mail","validFor":"","value":"Ordinary mail"},{"active":true,"defaultValue":false,"label":"Other domestic letters","validFor":"","value":"Other domestic letters"},{"active":true,"defaultValue":false,"label":"Other Domestic Parcels","validFor":"","value":"Other Domestic Parcels"},{"active":true,"defaultValue":false,"label":"Other Financial Services","validFor":"","value":"Other Financial Services"},{"active":true,"defaultValue":false,"label":"Other Insurance","validFor":"","value":"Other Insurance"},{"active":true,"defaultValue":false,"label":"Other international letters","validFor":"","value":"Other international letters"},{"active":true,"defaultValue":false,"label":"Other international Parcels","validFor":"","value":"Other international Parcels"},{"active":true,"defaultValue":false,"label":"Other Technology products","validFor":"","value":"Other Technology products"},{"active":true,"defaultValue":false,"label":"Other Web & Apps","validFor":"","value":"Other Web & Apps"},{"active":true,"defaultValue":false,"label":"Pack & Track International","validFor":"","value":"Pack & Track International"},{"active":true,"defaultValue":false,"label":"Pack and Track International","validFor":"UAAA","value":"Pack and Track International"},{"active":true,"defaultValue":false,"label":"Parcel Collect","validFor":"AQAA","value":"Parcel Collect"},{"active":true,"defaultValue":false,"label":"Parcel Lockers","validFor":"AQAA","value":"Parcel Lockers"},{"active":true,"defaultValue":false,"label":"Parcel Post","validFor":"gAAA","value":"Parcel Post"},{"active":true,"defaultValue":false,"label":"Parcel Send App","validFor":"","value":"Parcel Send App"},{"active":true,"defaultValue":false,"label":"Passport","validFor":"AgAA","value":"Passport"},{"active":true,"defaultValue":false,"label":"Passport & ID Photos","validFor":"BAAA","value":"Passport & ID Photos"},{"active":true,"defaultValue":false,"label":"Philatelic (stamps)","validFor":"BAAA","value":"Philatelic (stamps)"},{"active":true,"defaultValue":false,"label":"PO Boxes & Bags","validFor":"BAAA","value":"PO Boxes & Bags"},{"active":true,"defaultValue":false,"label":"Post BillPay","validFor":"CAAA","value":"Post BillPay"},{"active":true,"defaultValue":false,"label":"Postcard App","validFor":"","value":"Postcard App"},{"active":true,"defaultValue":false,"label":"Post office locator","validFor":"BAAA","value":"Post office locator"},{"active":true,"defaultValue":false,"label":"Priority Mail","validFor":"IAAA","value":"Priority Mail"},{"active":true,"defaultValue":false,"label":"Registered Post","validFor":"IAAA","value":"Registered Post"},{"active":true,"defaultValue":false,"label":"Registered Post International","validFor":"UAAA","value":"Registered Post International"},{"active":true,"defaultValue":false,"label":"Registered Post International Prepaid","validFor":"","value":"Registered Post International Prepaid"},{"active":true,"defaultValue":false,"label":"Regular Mail","validFor":"IAAA","value":"Regular Mail"},{"active":true,"defaultValue":false,"label":"Risk & Compliance","validFor":"","value":"Risk & Compliance"},{"active":true,"defaultValue":false,"label":"Sea Mail","validFor":"QAAA","value":"Sea Mail"},{"active":true,"defaultValue":false,"label":"SecurePay","validFor":"","value":"SecurePay"},{"active":true,"defaultValue":false,"label":"Send a Parcel","validFor":"AQAA","value":"Send a Parcel"},{"active":true,"defaultValue":false,"label":"shop.auspost.com.au","validFor":"","value":"shop.auspost.com.au"},{"active":true,"defaultValue":false,"label":"Shopmate","validFor":"AQAA","value":"Shopmate"},{"active":true,"defaultValue":false,"label":"StarTrack (Next Flight Premium & Express)","validFor":"gAAA","value":"StarTrack (Next Flight Premium & Express)"},{"active":true,"defaultValue":false,"label":"StarTrack Courier","validFor":"gAAA","value":"StarTrack Courier"},{"active":true,"defaultValue":false,"label":"StarTrack International","validFor":"QAAA","value":"StarTrack International"},{"active":true,"defaultValue":false,"label":"Stationery and packaging","validFor":"BAAA","value":"Stationery and packaging"},{"active":true,"defaultValue":false,"label":"Superannuation","validFor":"CAAA","value":"Superannuation"},{"active":true,"defaultValue":false,"label":"Tax file number","validFor":"AgAA","value":"Tax file number"},{"active":true,"defaultValue":false,"label":"Travel Insurance","validFor":"CAAA","value":"Travel Insurance"},{"active":true,"defaultValue":false,"label":"UMCS","validFor":"AQAA","value":"UMCS"},{"active":true,"defaultValue":false,"label":"Unaddressed Mail","validFor":"IAAA","value":"Unaddressed Mail"},{"active":true,"defaultValue":false,"label":"Video Stamp","validFor":"","value":"Video Stamp"},{"active":true,"defaultValue":false,"label":"Website","validFor":"AQAA","value":"Website"},{"active":true,"defaultValue":false,"label":"Western Union","validFor":"CAAA","value":"Western Union"},{"active":true,"defaultValue":false,"label":"Working with children check","validFor":"AgAA","value":"Working with children check"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":9,"type":"Field","value":"ProductSubCategory__c"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Customer Type","layoutComponents":[{"details":{"autoNumber":false,"byteLength":3900,"calculated":true,"calculatedFormula":"TEXT(Account.ServiceSLA__c)","cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":false,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Customer Type","length":1300,"name":"Customer_Type__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":false,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":10,"type":"Field","value":"Customer_Type__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Case Origin","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Origin","length":40,"name":"Origin","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":true,"label":"Phone","validFor":null,"value":"Phone"},{"active":true,"defaultValue":false,"label":"Web","validFor":null,"value":"Web"},{"active":true,"defaultValue":false,"label":"AP Retail (PM26)","validFor":null,"value":"AP Retail (PM26)"},{"active":true,"defaultValue":false,"label":"Bulk Upload","validFor":null,"value":"Bulk Upload"},{"active":true,"defaultValue":false,"label":"CN08 - Post","validFor":null,"value":"CN08 - Post"},{"active":true,"defaultValue":false,"label":"Social","validFor":null,"value":"Social"},{"active":true,"defaultValue":false,"label":"IBIS","validFor":null,"value":"IBIS"},{"active":true,"defaultValue":false,"label":"Prime","validFor":null,"value":"Prime"},{"active":true,"defaultValue":false,"label":"Apple GCRM","validFor":null,"value":"Apple GCRM"},{"active":true,"defaultValue":false,"label":"BSP","validFor":null,"value":"BSP"},{"active":true,"defaultValue":false,"label":"Portal","validFor":null,"value":"Portal"},{"active":true,"defaultValue":false,"label":"CN08 - Email","validFor":null,"value":"CN08 - Email"},{"active":true,"defaultValue":false,"label":"Rugby","validFor":null,"value":"Rugby"},{"active":true,"defaultValue":false,"label":"Cricket","validFor":null,"value":"Cricket"},{"active":true,"defaultValue":false,"label":"White mail","validFor":null,"value":"White mail"},{"active":true,"defaultValue":false,"label":"Fax","validFor":null,"value":"Fax"},{"active":true,"defaultValue":false,"label":"High Level Complaint","validFor":null,"value":"High Level Complaint"},{"active":true,"defaultValue":false,"label":"MyPost Business","validFor":null,"value":"MyPost Business"},{"active":true,"defaultValue":false,"label":"Vendor","validFor":null,"value":"Vendor"},{"active":true,"defaultValue":false,"label":"Chat","validFor":null,"value":"Chat"},{"active":true,"defaultValue":false,"label":"Snap It","validFor":null,"value":"Snap It"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":11,"type":"Field","value":"Origin"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Case Locality","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Locality","length":255,"name":"CaseLocality__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":true,"label":"Domestic","validFor":null,"value":"Domestic"},{"active":true,"defaultValue":false,"label":"International","validFor":null,"value":"International"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":12,"type":"Field","value":"CaseLocality__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Resolution Code","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Resolution Code","length":255,"name":"ResolutionCode__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Assistance provided","validFor":null,"value":"Assistance provided"},{"active":true,"defaultValue":false,"label":"Customer – no response","validFor":null,"value":"Customer – no response"},{"active":true,"defaultValue":false,"label":"Customer – response, no further action","validFor":null,"value":"Customer – response, no further action"},{"active":true,"defaultValue":false,"label":"Customer – Self service","validFor":null,"value":"Customer – Self service"},{"active":true,"defaultValue":false,"label":"FCR","validFor":null,"value":"FCR"},{"active":true,"defaultValue":false,"label":"Feedback (Issue captured and logged)","validFor":null,"value":"Feedback (Issue captured and logged)"},{"active":true,"defaultValue":false,"label":"Network resolution","validFor":null,"value":"Network resolution"},{"active":true,"defaultValue":false,"label":"Other","validFor":null,"value":"Other"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":13,"type":"Field","value":"ResolutionCode__c"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Case Reopen Date","layoutComponents":[{"details":{"autoNumber":false,"byteLength":0,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Reopen Date","length":0,"name":"Case_Reopen_Date__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:dateTime","sortable":true,"type":"datetime","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":14,"type":"Field","value":"Case_Reopen_Date__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"Bypass Data enforcement?","layoutComponents":[{"details":{"autoNumber":false,"byteLength":0,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Bypass Data enforcement?","length":0,"name":"Bypass_Data_enforcement__c","nameField":false,"namePointing":false,"nillable":false,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:boolean","sortable":true,"type":"boolean","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":15,"type":"Field","value":"Bypass_Data_enforcement__c"}],"placeholder":false,"required":false},{"editableForUpdate":false,"label":"Related Case","layoutComponents":[{"details":{"autoNumber":false,"byteLength":18,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Related Case","length":18,"name":"RelatedCase__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":["Case"],"relationshipName":"RelatedCase__r","relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"tns:ID","sortable":true,"type":"reference","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":16,"type":"Field","value":"RelatedCase__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"","layoutComponents":[],"placeholder":true,"required":false},{"editableForUpdate":false,"label":"Article Event Codes","layoutComponents":[{"details":{"autoNumber":false,"byteLength":98304,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":false,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Article Event Codes","length":32768,"name":"Article_Event_Codes__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":false,"type":"textarea","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":3,"tabOrder":17,"type":"Field","value":"Article_Event_Codes__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"","layoutComponents":[],"placeholder":true,"required":false},{"editableForUpdate":false,"label":"Your Reference","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Your Reference","length":40,"name":"CCUYourReference__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":18,"type":"Field","value":"CCUYourReference__c"}],"placeholder":false,"required":false}],"numItems":2}],"rows":10,"useCollapsibleSection":true,"useHeading":true}],"editLayoutSections":[{"columns":2,"heading":"Case Summary","layoutRows":[{"layoutItems":[{"editableForUpdate":false,"label":"Case Number","layoutComponents":[{"details":{"autoNumber":true,"byteLength":90,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":false,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":false,"htmlFormatted":false,"idLookup":true,"inlineHelpText":null,"label":"Case Number","length":30,"name":"CaseNumber","nameField":true,"namePointing":false,"nillable":false,"permissionable":false,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":false,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":19,"type":"Field","value":"CaseNumber"}],"placeholder":false,"required":false},{"editableForUpdate":true,"label":"Reference ID","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":true,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":true,"inlineHelpText":"The Reference ID for this Case. i.e Article ID or MRS CRN.","label":"Reference ID","length":255,"name":"ReferenceID__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":20,"type":"Field","value":"ReferenceID__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Status","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Status","length":40,"name":"Status","nameField":false,"namePointing":false,"nillable":true,"permissionable":false,"picklistValues":[{"active":true,"defaultValue":true,"label":"New","validFor":null,"value":"New"},{"active":true,"defaultValue":false,"label":"On Hold","validFor":null,"value":"On Hold"},{"active":true,"defaultValue":false,"label":"Network Responded","validFor":null,"value":"Network Responded"},{"active":true,"defaultValue":false,"label":"Customer Responded","validFor":null,"value":"Customer Responded"},{"active":true,"defaultValue":false,"label":"Closed","validFor":null,"value":"Closed"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":21,"type":"Field","value":"Status"}],"placeholder":false,"required":true},{"editableForUpdate":true,"label":"Priority","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Priority","length":40,"name":"Priority","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"High","validFor":null,"value":"High"},{"active":true,"defaultValue":false,"label":"Medium","validFor":null,"value":"Medium"},{"active":true,"defaultValue":true,"label":"Low","validFor":null,"value":"Low"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":22,"type":"Field","value":"Priority"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Description","layoutComponents":[{"details":{"autoNumber":false,"byteLength":96000,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":false,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Description","length":32000,"name":"Description","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":false,"type":"textarea","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":4,"tabOrder":23,"type":"Field","value":"Description"}],"placeholder":false,"required":false},{"editableForUpdate":true,"label":"Type","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Type","length":40,"name":"Type","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"General Enquiry","validFor":null,"value":"General Enquiry"},{"active":true,"defaultValue":false,"label":"Feedback","validFor":null,"value":"Feedback"},{"active":true,"defaultValue":false,"label":"Investigation","validFor":null,"value":"Investigation"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":24,"type":"Field","value":"Type"}],"placeholder":false,"required":true}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Product Category","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Product Category","length":255,"name":"ProductCategory__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Domestic Parcels","validFor":null,"value":"Domestic Parcels"},{"active":true,"defaultValue":false,"label":"International Parcels","validFor":null,"value":"International Parcels"},{"active":true,"defaultValue":false,"label":"Domestic Letters","validFor":null,"value":"Domestic Letters"},{"active":true,"defaultValue":false,"label":"International Letters","validFor":null,"value":"International Letters"},{"active":true,"defaultValue":false,"label":"Money & Insurance","validFor":null,"value":"Money & Insurance"},{"active":true,"defaultValue":false,"label":"Post Office & Business Hub Services","validFor":null,"value":"Post Office & Business Hub Services"},{"active":true,"defaultValue":false,"label":"Travel & ID","validFor":null,"value":"Travel & ID"},{"active":true,"defaultValue":false,"label":"Web & Apps","validFor":null,"value":"Web & Apps"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":25,"type":"Field","value":"ProductCategory__c"}],"placeholder":false,"required":true},{"editableForUpdate":true,"label":"Enquiry Sub Type","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":"Type_and_Product__c","createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":true,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Enquiry Sub Type","length":255,"name":"EnquirySubType__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Address Correction","validFor":"AAAAAAAAAAAAAAAD////wAf9/wAA","value":"Address Correction"},{"active":true,"defaultValue":false,"label":"Address not in NAF","validFor":"","value":"Address not in NAF"},{"active":true,"defaultValue":false,"label":"All Other","validFor":"","value":"All Other"},{"active":true,"defaultValue":false,"label":"AP Digital Mailbox","validFor":"","value":"AP Digital Mailbox"},{"active":true,"defaultValue":false,"label":"Appointment Booking","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA","value":"Appointment Booking"},{"active":true,"defaultValue":false,"label":"Article carded - no card left","validFor":"","value":"Article carded - no card left"},{"active":true,"defaultValue":false,"label":"Article carded - no delivery attempt","validFor":"AAAAAD8f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Article carded - no delivery attempt"},{"active":true,"defaultValue":false,"label":"Article safe dropped - no delivery attempt","validFor":"AAAAAACA","value":"Article safe dropped - no delivery attempt"},{"active":true,"defaultValue":false,"label":"Article safe dropped - not located","validFor":"","value":"Article safe dropped - not located"},{"active":true,"defaultValue":false,"label":"Article safe dropped unsafe location","validFor":"","value":"Article safe dropped unsafe location"},{"active":true,"defaultValue":false,"label":"Booking amendment","validFor":"AAAAAAAAAAAIBAAA","value":"Booking amendment"},{"active":true,"defaultValue":false,"label":"Booking cancellation","validFor":"AAAAAAAAAAAIBAAA","value":"Booking cancellation"},{"active":true,"defaultValue":false,"label":"Cancel scheduled pick up","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAABAE","value":"Cancel scheduled pick up"},{"active":true,"defaultValue":false,"label":"Carding issue","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Carding issue"},{"active":true,"defaultValue":false,"label":"Change address","validFor":"","value":"Change address"},{"active":true,"defaultValue":false,"label":"Complaint","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//z//","value":"Complaint"},{"active":true,"defaultValue":false,"label":"Complaint referred to issuer","validFor":"AAAAAEAAAAAAAAAEAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAIAAA","value":"Complaint referred to issuer"},{"active":true,"defaultValue":false,"label":"Compliment","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//z//","value":"Compliment"},{"active":true,"defaultValue":false,"label":"Credit Account Enquiry","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAQA","value":"Credit Account Enquiry"},{"active":true,"defaultValue":false,"label":"Damaged/Missing contents","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damaged/Missing contents"},{"active":true,"defaultValue":false,"label":"Damages In Transit","validFor":"","value":"Damages In Transit"},{"active":true,"defaultValue":false,"label":"Damage to property","validFor":"AAAAAD+f4AP5/AAD////wAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damage to property"},{"active":true,"defaultValue":false,"label":"Damage to vehicle","validFor":"AAAAAD+f4AP5/AAD////wAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Damage to vehicle"},{"active":true,"defaultValue":false,"label":"Delayed delivery","validFor":"AAAAAD+f4AP5/AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Delayed delivery"},{"active":true,"defaultValue":false,"label":"Delayed - inside network","validFor":"","value":"Delayed - inside network"},{"active":true,"defaultValue":false,"label":"Delayed - outside network","validFor":"","value":"Delayed - outside network"},{"active":true,"defaultValue":false,"label":"Delivered to no junk mail address","validFor":"AAAAAAAAAAAIBAAA","value":"Delivered to no junk mail address"},{"active":true,"defaultValue":false,"label":"Delivery complaint","validFor":"AAAAAD+f4AP5/AAD////wAf9/wAA","value":"Delivery complaint"},{"active":true,"defaultValue":false,"label":"Direct marketing opt out","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Direct marketing opt out"},{"active":true,"defaultValue":false,"label":"Disputed delivery scan","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Disputed delivery scan"},{"active":true,"defaultValue":false,"label":"Domestic Letters - Other","validFor":"","value":"Domestic Letters - Other"},{"active":true,"defaultValue":false,"label":"Domestic Parcels - Other","validFor":"","value":"Domestic Parcels - Other"},{"active":true,"defaultValue":false,"label":"Express Guarantee Failure","validFor":"AAAAAAGAYAAQCAAAAeAHgAAcBwAA","value":"Express Guarantee Failure"},{"active":true,"defaultValue":false,"label":"Facility reported damages","validFor":"AAAAAD+f4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Facility reported damages"},{"active":true,"defaultValue":false,"label":"FOI request","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"FOI request"},{"active":true,"defaultValue":false,"label":"Inbound tracking","validFor":"AAAAAAAAAAAAAP/8AAAAH/AA","value":"Inbound tracking"},{"active":true,"defaultValue":false,"label":"Incorrect mail being redirected/held","validFor":"","value":"Incorrect mail being redirected/held"},{"active":true,"defaultValue":false,"label":"Incorrect or missing order","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAwCAAAAP8P8AAAAAAAAAEAAQAAA","value":"Incorrect or missing order"},{"active":true,"defaultValue":false,"label":"Interception request","validFor":"","value":"Interception request"},{"active":true,"defaultValue":false,"label":"International Letters - Other","validFor":"","value":"International Letters - Other"},{"active":true,"defaultValue":false,"label":"International Parcels - Other","validFor":"","value":"International Parcels - Other"},{"active":true,"defaultValue":false,"label":"Item transfer","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Item transfer"},{"active":true,"defaultValue":false,"label":"Locations & hours of operation","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAADiQA","value":"Locations & hours of operation"},{"active":true,"defaultValue":false,"label":"Lodgement issue","validFor":"AAAAAAAAAAAIBAAA","value":"Lodgement issue"},{"active":true,"defaultValue":false,"label":"Mail not being redirected/held","validFor":"","value":"Mail not being redirected/held"},{"active":true,"defaultValue":false,"label":"Missed/Late Pickup","validFor":"","value":"Missed/Late Pickup"},{"active":true,"defaultValue":false,"label":"Missing Item","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"Missing Item"},{"active":true,"defaultValue":false,"label":"Mobile website","validFor":"AAAAAAAI","value":"Mobile website"},{"active":true,"defaultValue":false,"label":"Money & Insurance  - Other","validFor":"","value":"Money & Insurance  - Other"},{"active":true,"defaultValue":false,"label":"MRSO issue","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAgAAA","value":"MRSO issue"},{"active":true,"defaultValue":false,"label":"MyPost balance request","validFor":"","value":"MyPost balance request"},{"active":true,"defaultValue":false,"label":"New booking","validFor":"AAAAAAAAAAAIBAAA","value":"New booking"},{"active":true,"defaultValue":false,"label":"New pick up request","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAABAE","value":"New pick up request"},{"active":true,"defaultValue":false,"label":"Outbound tracking","validFor":"AAAAAAAAAAAAAP/8AAAAH/AA","value":"Outbound tracking"},{"active":true,"defaultValue":false,"label":"Pick up issue","validFor":"","value":"Pick up issue"},{"active":true,"defaultValue":false,"label":"POD request","validFor":"AAAA/kAAB+AAAP/8AAAAH/AAAAAAAAAAAAAAAAAAAAAAAAAAIAAA","value":"POD request"},{"active":true,"defaultValue":false,"label":"Post Office & Hub  - Other","validFor":"","value":"Post Office & Hub  - Other"},{"active":true,"defaultValue":false,"label":"Pricing","validFor":"AAAA/8AAB/wAAP/8AAAAP/AAAAAAAAAAAAAAAAAAP/+AAAAAIAAA","value":"Pricing"},{"active":true,"defaultValue":false,"label":"Pricing enquiry","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/wAAAPwAA","value":"Pricing enquiry"},{"active":true,"defaultValue":false,"label":"Privacy breach","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Privacy breach"},{"active":true,"defaultValue":false,"label":"Product & service information","validFor":"AAAA/8AAB/wAAP/8AAAAP/AAAAAAD///wAAAP8AAP//AAAAAIAAA","value":"Product & service information"},{"active":true,"defaultValue":false,"label":"Product issue","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAO+74AAA","value":"Product issue"},{"active":true,"defaultValue":false,"label":"Product Order","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAMAAAMAAAAB8","value":"Product Order"},{"active":true,"defaultValue":false,"label":"Product support","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAC47gAAAP/+DwD//wAA//z//","value":"Product support"},{"active":true,"defaultValue":false,"label":"Queue times","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAOB5EAAA","value":"Queue times"},{"active":true,"defaultValue":false,"label":"Redirection Failure","validFor":"AAAAAABgGAAGAwAAAAAAAAgC","value":"Redirection Failure"},{"active":true,"defaultValue":false,"label":"Reissue MyPost card","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwAAA","value":"Reissue MyPost card"},{"active":true,"defaultValue":false,"label":"Remittance not received","validFor":"","value":"Remittance not received"},{"active":true,"defaultValue":false,"label":"Renewal/Payment","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAIAgAAA","value":"Renewal/Payment"},{"active":true,"defaultValue":false,"label":"Request for personal information","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwAAA","value":"Request for personal information"},{"active":true,"defaultValue":false,"label":"RTS request","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAAHAAA","value":"RTS request"},{"active":true,"defaultValue":false,"label":"Safety issue","validFor":"AAAAAD+f4AP5/AAD////wAf9////8AAAAAAAAAAAAAAAAAAAHAAA","value":"Safety issue"},{"active":true,"defaultValue":false,"label":"Self-service support","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//A","value":"Self-service support"},{"active":true,"defaultValue":false,"label":"Service availability","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8","value":"Service availability"},{"active":true,"defaultValue":false,"label":"SPB – Graffiti/Damage/New","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAAA","value":"SPB – Graffiti/Damage/New"},{"active":true,"defaultValue":false,"label":"SPB – Request removal/relocation","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAABAEAAA","value":"SPB – Request removal/relocation"},{"active":true,"defaultValue":false,"label":"Staff Complaint","validFor":"AAAAAD+f4AP5/AAD////wAAAAP//8AAAAAAAAAAAAAAAAAAAHAAA","value":"Staff Complaint"},{"active":true,"defaultValue":false,"label":"Staff Compliment","validFor":"AAAAAD+f4AP5/AAD////wAAAAP//8AAAAAAAAAAAAAAAAAAAHAAA","value":"Staff Compliment"},{"active":true,"defaultValue":false,"label":"Tracking","validFor":"AAAA/kAAB/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAA","value":"Tracking"},{"active":true,"defaultValue":false,"label":"Travel & ID - Other","validFor":"","value":"Travel & ID - Other"},{"active":true,"defaultValue":false,"label":"UMCS booking amendment","validFor":"","value":"UMCS booking amendment"},{"active":true,"defaultValue":false,"label":"UMCS delivery issue","validFor":"","value":"UMCS delivery issue"},{"active":true,"defaultValue":false,"label":"UMCS label issue","validFor":"","value":"UMCS label issue"},{"active":true,"defaultValue":false,"label":"UMCS new booking","validFor":"","value":"UMCS new booking"},{"active":true,"defaultValue":false,"label":"UMCS registration/access","validFor":"","value":"UMCS registration/access"},{"active":true,"defaultValue":false,"label":"Unaddressed mail booking service","validFor":"","value":"Unaddressed mail booking service"},{"active":true,"defaultValue":false,"label":"Unauthorised Hold/Redirection application","validFor":"","value":"Unauthorised Hold/Redirection application"},{"active":true,"defaultValue":false,"label":"Unauthorised MRS application","validFor":"AAAAAABgGAAGAwAAAAAAAAgC","value":"Unauthorised MRS application"},{"active":true,"defaultValue":false,"label":"Unauthorised Safe Drop","validFor":"","value":"Unauthorised Safe Drop"},{"active":true,"defaultValue":false,"label":"Web & Apps - Other","validFor":"","value":"Web & Apps - Other"},{"active":true,"defaultValue":false,"label":"Website/app technical issues","validFor":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////wAAA","value":"Website/app technical issues"},{"active":true,"defaultValue":false,"label":"Withdrawal from post","validFor":"AAAAAD+f4APx+AAD////wAf9/wAAAAAAAAAAAAAAAAAAAAAABAAA","value":"Withdrawal from post"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":26,"type":"Field","value":"EnquirySubType__c"}],"placeholder":false,"required":true}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Product Sub Category","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":"ProductCategory__c","createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":true,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Product Sub Category","length":255,"name":"ProductSubCategory__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Airmail over 2kg","validFor":"QAAA","value":"Airmail over 2kg"},{"active":true,"defaultValue":false,"label":"Airmail under 2kg","validFor":"UAAA","value":"Airmail under 2kg"},{"active":true,"defaultValue":false,"label":"All Other ID&V services","validFor":"","value":"All Other ID&V services"},{"active":true,"defaultValue":false,"label":"Amex","validFor":"","value":"Amex"},{"active":true,"defaultValue":false,"label":"Article Collection","validFor":"","value":"Article Collection"},{"active":true,"defaultValue":false,"label":"Bank@Post","validFor":"CAAA","value":"Bank@Post"},{"active":true,"defaultValue":false,"label":"Business Letters","validFor":"IAAA","value":"Business Letters"},{"active":true,"defaultValue":false,"label":"Car Insurance","validFor":"CAAA","value":"Car Insurance"},{"active":true,"defaultValue":false,"label":"Cash on Delivery","validFor":"oAAA","value":"Cash on Delivery"},{"active":true,"defaultValue":false,"label":"Change of Address Online","validFor":"","value":"Change of Address Online"},{"active":true,"defaultValue":false,"label":"Click & Send","validFor":"AQAA","value":"Click & Send"},{"active":true,"defaultValue":false,"label":"Concession stamps","validFor":"","value":"Concession stamps"},{"active":true,"defaultValue":false,"label":"Courier Post","validFor":"gAAA","value":"Courier Post"},{"active":true,"defaultValue":false,"label":"Delivery Choices","validFor":"","value":"Delivery Choices"},{"active":true,"defaultValue":false,"label":"eBay Store","validFor":"AQAA","value":"eBay Store"},{"active":true,"defaultValue":false,"label":"ECI","validFor":"UAAA","value":"ECI"},{"active":true,"defaultValue":false,"label":"ECI Platinum","validFor":"UAAA","value":"ECI Platinum"},{"active":true,"defaultValue":false,"label":"Economy Air under 2kg","validFor":"QAAA","value":"Economy Air under 2kg"},{"active":true,"defaultValue":false,"label":"Economy Air under 500g","validFor":"EAAA","value":"Economy Air under 500g"},{"active":true,"defaultValue":false,"label":"Economy Sea over 2kg","validFor":"QAAA","value":"Economy Sea over 2kg"},{"active":true,"defaultValue":false,"label":"eParcel- Express","validFor":"gAAA","value":"eParcel- Express"},{"active":true,"defaultValue":false,"label":"eParcel Online","validFor":"AQAA","value":"eParcel Online"},{"active":true,"defaultValue":false,"label":"eParcel- Regular","validFor":"gAAA","value":"eParcel- Regular"},{"active":true,"defaultValue":false,"label":"Express","validFor":"gAAA","value":"Express"},{"active":true,"defaultValue":false,"label":"Express Platinum","validFor":"gAAA","value":"Express Platinum"},{"active":true,"defaultValue":false,"label":"Express Post","validFor":"IAAA","value":"Express Post"},{"active":true,"defaultValue":false,"label":"Express Post International","validFor":"UAAA","value":"Express Post International"},{"active":true,"defaultValue":false,"label":"Farmhouse Direct","validFor":"","value":"Farmhouse Direct"},{"active":true,"defaultValue":false,"label":"Foreign Currency","validFor":"CAAA","value":"Foreign Currency"},{"active":true,"defaultValue":false,"label":"General merchandise","validFor":"BAAA","value":"General merchandise"},{"active":true,"defaultValue":false,"label":"Gift cards","validFor":"CAAA","value":"Gift cards"},{"active":true,"defaultValue":false,"label":"ID check - other","validFor":"","value":"ID check - other"},{"active":true,"defaultValue":false,"label":"International Courier","validFor":"UAAA","value":"International Courier"},{"active":true,"defaultValue":false,"label":"International Express","validFor":"UAAA","value":"International Express"},{"active":true,"defaultValue":false,"label":"International Standard","validFor":"QAAA","value":"International Standard"},{"active":true,"defaultValue":false,"label":"Item Transfer","validFor":"","value":"Item Transfer"},{"active":true,"defaultValue":false,"label":"KeyPass","validFor":"AgAA","value":"KeyPass"},{"active":true,"defaultValue":false,"label":"Load & Go","validFor":"CAAA","value":"Load & Go"},{"active":true,"defaultValue":false,"label":"Mail hold","validFor":"pAAA","value":"Mail hold"},{"active":true,"defaultValue":false,"label":"Mail Pick up","validFor":"BAAA","value":"Mail Pick up"},{"active":true,"defaultValue":false,"label":"Mail redirection","validFor":"tAAA","value":"Mail redirection"},{"active":true,"defaultValue":false,"label":"Messenger Post","validFor":"","value":"Messenger Post"},{"active":true,"defaultValue":false,"label":"Mobile apps","validFor":"AQAA","value":"Mobile apps"},{"active":true,"defaultValue":false,"label":"Mobile products","validFor":"BAAA","value":"Mobile products"},{"active":true,"defaultValue":false,"label":"Money Orders","validFor":"CAAA","value":"Money Orders"},{"active":true,"defaultValue":false,"label":"MRS Online","validFor":"AQAA","value":"MRS Online"},{"active":true,"defaultValue":false,"label":"Multi-Currency Cash Passport","validFor":"CAAA","value":"Multi-Currency Cash Passport"},{"active":true,"defaultValue":false,"label":"MyAccount","validFor":"","value":"MyAccount"},{"active":true,"defaultValue":false,"label":"MyPost Business App","validFor":"AQAA","value":"MyPost Business App"},{"active":true,"defaultValue":false,"label":"MyPost Concession Card","validFor":"AgAA","value":"MyPost Concession Card"},{"active":true,"defaultValue":false,"label":"MyPost Digital Mailbox","validFor":"AQAA","value":"MyPost Digital Mailbox"},{"active":true,"defaultValue":false,"label":"My Post ID card","validFor":"AgAA","value":"My Post ID card"},{"active":true,"defaultValue":false,"label":"Online Returns Portal","validFor":"AQAA","value":"Online Returns Portal"},{"active":true,"defaultValue":false,"label":"Ordinary mail","validFor":"","value":"Ordinary mail"},{"active":true,"defaultValue":false,"label":"Other domestic letters","validFor":"","value":"Other domestic letters"},{"active":true,"defaultValue":false,"label":"Other Domestic Parcels","validFor":"","value":"Other Domestic Parcels"},{"active":true,"defaultValue":false,"label":"Other Financial Services","validFor":"","value":"Other Financial Services"},{"active":true,"defaultValue":false,"label":"Other Insurance","validFor":"","value":"Other Insurance"},{"active":true,"defaultValue":false,"label":"Other international letters","validFor":"","value":"Other international letters"},{"active":true,"defaultValue":false,"label":"Other international Parcels","validFor":"","value":"Other international Parcels"},{"active":true,"defaultValue":false,"label":"Other Technology products","validFor":"","value":"Other Technology products"},{"active":true,"defaultValue":false,"label":"Other Web & Apps","validFor":"","value":"Other Web & Apps"},{"active":true,"defaultValue":false,"label":"Pack & Track International","validFor":"","value":"Pack & Track International"},{"active":true,"defaultValue":false,"label":"Pack and Track International","validFor":"UAAA","value":"Pack and Track International"},{"active":true,"defaultValue":false,"label":"Parcel Collect","validFor":"AQAA","value":"Parcel Collect"},{"active":true,"defaultValue":false,"label":"Parcel Lockers","validFor":"AQAA","value":"Parcel Lockers"},{"active":true,"defaultValue":false,"label":"Parcel Post","validFor":"gAAA","value":"Parcel Post"},{"active":true,"defaultValue":false,"label":"Parcel Send App","validFor":"","value":"Parcel Send App"},{"active":true,"defaultValue":false,"label":"Passport","validFor":"AgAA","value":"Passport"},{"active":true,"defaultValue":false,"label":"Passport & ID Photos","validFor":"BAAA","value":"Passport & ID Photos"},{"active":true,"defaultValue":false,"label":"Philatelic (stamps)","validFor":"BAAA","value":"Philatelic (stamps)"},{"active":true,"defaultValue":false,"label":"PO Boxes & Bags","validFor":"BAAA","value":"PO Boxes & Bags"},{"active":true,"defaultValue":false,"label":"Post BillPay","validFor":"CAAA","value":"Post BillPay"},{"active":true,"defaultValue":false,"label":"Postcard App","validFor":"","value":"Postcard App"},{"active":true,"defaultValue":false,"label":"Post office locator","validFor":"BAAA","value":"Post office locator"},{"active":true,"defaultValue":false,"label":"Priority Mail","validFor":"IAAA","value":"Priority Mail"},{"active":true,"defaultValue":false,"label":"Registered Post","validFor":"IAAA","value":"Registered Post"},{"active":true,"defaultValue":false,"label":"Registered Post International","validFor":"UAAA","value":"Registered Post International"},{"active":true,"defaultValue":false,"label":"Registered Post International Prepaid","validFor":"","value":"Registered Post International Prepaid"},{"active":true,"defaultValue":false,"label":"Regular Mail","validFor":"IAAA","value":"Regular Mail"},{"active":true,"defaultValue":false,"label":"Risk & Compliance","validFor":"","value":"Risk & Compliance"},{"active":true,"defaultValue":false,"label":"Sea Mail","validFor":"QAAA","value":"Sea Mail"},{"active":true,"defaultValue":false,"label":"SecurePay","validFor":"","value":"SecurePay"},{"active":true,"defaultValue":false,"label":"Send a Parcel","validFor":"AQAA","value":"Send a Parcel"},{"active":true,"defaultValue":false,"label":"shop.auspost.com.au","validFor":"","value":"shop.auspost.com.au"},{"active":true,"defaultValue":false,"label":"Shopmate","validFor":"AQAA","value":"Shopmate"},{"active":true,"defaultValue":false,"label":"StarTrack (Next Flight Premium & Express)","validFor":"gAAA","value":"StarTrack (Next Flight Premium & Express)"},{"active":true,"defaultValue":false,"label":"StarTrack Courier","validFor":"gAAA","value":"StarTrack Courier"},{"active":true,"defaultValue":false,"label":"StarTrack International","validFor":"QAAA","value":"StarTrack International"},{"active":true,"defaultValue":false,"label":"Stationery and packaging","validFor":"BAAA","value":"Stationery and packaging"},{"active":true,"defaultValue":false,"label":"Superannuation","validFor":"CAAA","value":"Superannuation"},{"active":true,"defaultValue":false,"label":"Tax file number","validFor":"AgAA","value":"Tax file number"},{"active":true,"defaultValue":false,"label":"Travel Insurance","validFor":"CAAA","value":"Travel Insurance"},{"active":true,"defaultValue":false,"label":"UMCS","validFor":"AQAA","value":"UMCS"},{"active":true,"defaultValue":false,"label":"Unaddressed Mail","validFor":"IAAA","value":"Unaddressed Mail"},{"active":true,"defaultValue":false,"label":"Video Stamp","validFor":"","value":"Video Stamp"},{"active":true,"defaultValue":false,"label":"Website","validFor":"AQAA","value":"Website"},{"active":true,"defaultValue":false,"label":"Western Union","validFor":"CAAA","value":"Western Union"},{"active":true,"defaultValue":false,"label":"Working with children check","validFor":"AgAA","value":"Working with children check"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":27,"type":"Field","value":"ProductSubCategory__c"}],"placeholder":false,"required":true},{"editableForUpdate":true,"label":"Case Locality","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Locality","length":255,"name":"CaseLocality__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":true,"label":"Domestic","validFor":null,"value":"Domestic"},{"active":true,"defaultValue":false,"label":"International","validFor":null,"value":"International"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":28,"type":"Field","value":"CaseLocality__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Case Origin","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":false,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Origin","length":40,"name":"Origin","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":true,"label":"Phone","validFor":null,"value":"Phone"},{"active":true,"defaultValue":false,"label":"Web","validFor":null,"value":"Web"},{"active":true,"defaultValue":false,"label":"AP Retail (PM26)","validFor":null,"value":"AP Retail (PM26)"},{"active":true,"defaultValue":false,"label":"Bulk Upload","validFor":null,"value":"Bulk Upload"},{"active":true,"defaultValue":false,"label":"CN08 - Post","validFor":null,"value":"CN08 - Post"},{"active":true,"defaultValue":false,"label":"Social","validFor":null,"value":"Social"},{"active":true,"defaultValue":false,"label":"IBIS","validFor":null,"value":"IBIS"},{"active":true,"defaultValue":false,"label":"Prime","validFor":null,"value":"Prime"},{"active":true,"defaultValue":false,"label":"Apple GCRM","validFor":null,"value":"Apple GCRM"},{"active":true,"defaultValue":false,"label":"BSP","validFor":null,"value":"BSP"},{"active":true,"defaultValue":false,"label":"Portal","validFor":null,"value":"Portal"},{"active":true,"defaultValue":false,"label":"CN08 - Email","validFor":null,"value":"CN08 - Email"},{"active":true,"defaultValue":false,"label":"Rugby","validFor":null,"value":"Rugby"},{"active":true,"defaultValue":false,"label":"Cricket","validFor":null,"value":"Cricket"},{"active":true,"defaultValue":false,"label":"White mail","validFor":null,"value":"White mail"},{"active":true,"defaultValue":false,"label":"Fax","validFor":null,"value":"Fax"},{"active":true,"defaultValue":false,"label":"High Level Complaint","validFor":null,"value":"High Level Complaint"},{"active":true,"defaultValue":false,"label":"MyPost Business","validFor":null,"value":"MyPost Business"},{"active":true,"defaultValue":false,"label":"Vendor","validFor":null,"value":"Vendor"},{"active":true,"defaultValue":false,"label":"Chat","validFor":null,"value":"Chat"},{"active":true,"defaultValue":false,"label":"Snap It","validFor":null,"value":"Snap It"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":29,"type":"Field","value":"Origin"}],"placeholder":false,"required":true},{"editableForUpdate":true,"label":"Case Reopen Date","layoutComponents":[{"details":{"autoNumber":false,"byteLength":0,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Case Reopen Date","length":0,"name":"Case_Reopen_Date__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:dateTime","sortable":true,"type":"datetime","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":30,"type":"Field","value":"Case_Reopen_Date__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Resolution Code","layoutComponents":[{"details":{"autoNumber":false,"byteLength":765,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Resolution Code","length":255,"name":"ResolutionCode__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[{"active":true,"defaultValue":false,"label":"Assistance provided","validFor":null,"value":"Assistance provided"},{"active":true,"defaultValue":false,"label":"Customer – no response","validFor":null,"value":"Customer – no response"},{"active":true,"defaultValue":false,"label":"Customer – response, no further action","validFor":null,"value":"Customer – response, no further action"},{"active":true,"defaultValue":false,"label":"Customer – Self service","validFor":null,"value":"Customer – Self service"},{"active":true,"defaultValue":false,"label":"FCR","validFor":null,"value":"FCR"},{"active":true,"defaultValue":false,"label":"Feedback (Issue captured and logged)","validFor":null,"value":"Feedback (Issue captured and logged)"},{"active":true,"defaultValue":false,"label":"Network resolution","validFor":null,"value":"Network resolution"},{"active":true,"defaultValue":false,"label":"Other","validFor":null,"value":"Other"}],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"picklist","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":31,"type":"Field","value":"ResolutionCode__c"}],"placeholder":false,"required":false},{"editableForUpdate":true,"label":"Related Case","layoutComponents":[{"details":{"autoNumber":false,"byteLength":18,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Related Case","length":18,"name":"RelatedCase__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":["Case"],"relationshipName":"RelatedCase__r","relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"tns:ID","sortable":true,"type":"reference","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":32,"type":"Field","value":"RelatedCase__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":true,"label":"Bypass Data enforcement?","layoutComponents":[{"details":{"autoNumber":false,"byteLength":0,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":true,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Bypass Data enforcement?","length":0,"name":"Bypass_Data_enforcement__c","nameField":false,"namePointing":false,"nillable":false,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:boolean","sortable":true,"type":"boolean","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":33,"type":"Field","value":"Bypass_Data_enforcement__c"}],"placeholder":false,"required":false},{"editableForUpdate":true,"label":"Article Event Codes","layoutComponents":[{"details":{"autoNumber":false,"byteLength":98304,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":false,"groupable":false,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Article Event Codes","length":32768,"name":"Article_Event_Codes__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":false,"type":"textarea","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":3,"tabOrder":34,"type":"Field","value":"Article_Event_Codes__c"}],"placeholder":false,"required":false}],"numItems":2},{"layoutItems":[{"editableForUpdate":false,"label":"","layoutComponents":[],"placeholder":true,"required":false},{"editableForUpdate":true,"label":"Your Reference","layoutComponents":[{"details":{"autoNumber":false,"byteLength":120,"calculated":false,"calculatedFormula":null,"cascadeDelete":false,"caseSensitive":false,"controllerName":null,"createable":true,"custom":true,"defaultValue":null,"defaultValueFormula":null,"defaultedOnCreate":false,"dependentPicklist":false,"deprecatedAndHidden":false,"digits":0,"displayLocationInDecimal":false,"externalId":false,"filterable":true,"groupable":true,"htmlFormatted":false,"idLookup":false,"inlineHelpText":null,"label":"Your Reference","length":40,"name":"CCUYourReference__c","nameField":false,"namePointing":false,"nillable":true,"permissionable":true,"picklistValues":[],"precision":0,"referenceTo":[],"relationshipName":null,"relationshipOrder":null,"restrictedDelete":false,"restrictedPicklist":false,"scale":0,"soapType":"xsd:string","sortable":true,"type":"string","unique":false,"updateable":true,"writeRequiresMasterRead":false},"displayLines":1,"tabOrder":35,"type":"Field","value":"CCUYourReference__c"}],"placeholder":false,"required":false}],"numItems":2}],"rows":9,"useCollapsibleSection":false,"useHeading":true}],"id":"00h9000000QvSgGAAV"}');
				res.setStatusCode(statusType);
			} else if (callType.equals('respond400')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"ha":"ha","regular":{"code":1,"description":"test"}}');
				res.setStatusCode(statusType);
			} else if (callType.equals('respond200')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"ha":"ha","regular":{"serviceType":"regular","min":10,"max":20,"sla":"sla"}}');
				res.setStatusCode(statusType);
			} else if (callType.equals('respond600')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"ha":"ha","regular":{"serviceType":"regular","min":10,"max":20012018,"sla":"sla"}}');
				res.setStatusCode(statusType);
			} else if (callType.equals('respond800')) {
				res.setHeader('Content-Type', 'application/json');
				res.setBody('{"ha":"ha","regular":{"serviceType":"regular","min":10,"max":20012018,"sla":"sla"}}');
				res.setStatusCode(statusType);
			}
			return res;
		}
	}

	/*****************************************************************************************
   *  Scenario:
   *      Test to validate Check duplicates method
   ******************************************************************************************/
	static testmethod void testcheckDuplicates() {
		//Fetch a Case
		Case testCase = [SELECT id,ReferenceId__c FROM Case LIMIT 1];

		ApexPages.StandardController sc = new ApexPages.StandardController(testCase);

		CaseDetailsCaseContExt cdcc = new CaseDetailsCaseContExt(sc);

		Test.startTest();

		//Call checkDuplicates method.
		cdcc.checkDuplicates();

		Test.stopTest();
	}
}