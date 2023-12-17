/**************************************************
Type:       SSSWRoutingController_Test
History:
--------------------------------------------------
Jun-2014:  di.chen@bluewolf.com  Created - Test coverage
Jun-2018:  TDO-215 : hector.huang@coroma.com.au Unit tests re-written with scenario based tests.
Jul-2018:  disha.kariya@auspost.com.au Updated class to adopt to new SSSW Routing table
2020-11-18 - Ranjeewa Silva - Added test method for checking duplicate rules based on post tags
**************************************************/
@isTest
private class SSSWRoutingController_Test {

	@TestSetup
	static void testSetup() {
		// create a new Case for testing getRecordTypeId static method
		Case testCase = TestDataProvider.createTestCase();
		testCase.ReferenceID__c = 'SSSWCase';
		insert testCase;

		// create a new SSSWRouting for testing class methods
		SSSWRouting__c sswrou = new SSSWRouting__c();
		RecordType recordType = [SELECT Id FROM RecordType LIMIT 1];
		sswrou.CaseType__c = 'CRM Query';
		sswrou.ProductCategory__c = 'test';
		sswrou.ProductSubCategory__c = 'sub test';
		sswrou.CustomerQueueType__c = 'norm';
		sswrou.EnquirySubType__c = 'enq';
		sswrou.Queue_ID__c = recordType.Id;
		insert sswrou;
	}

	@isTest
	/**
	 * SCENARIO: Record Type Id of a case with SSSWCase Reference ID is returned
	 **/
	// static void SSSWRoutingController_Test_getRecordTypeId_got() {
	//     Test.startTest();

	//     // verify if any Record Type Id has been return by calling the static method
	//     System.assertEquals(false, String.isBlank(SSSWRoutingController.getRecordTypeId('A', 'B')),
	//             'SSSWRoutingController_Test_getRecordTypeId_got: no record type Id relevant to SSSWCase has been returned');

	//     Test.stopTest();
	// }

	/**
	 * SCENARIO: Group information of a SSSWRoutingController is fetched successfully
	**/
	static void SSSWRoutingController_Test_getQueueIDs_got() {
		Test.startTest();

		// get the SSSWRouting inserted during setup
		SSSWRouting__c routing = [SELECT Id FROM SSSWRouting__c LIMIT 1];
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(routing);
		SSSWRoutingController ext = new SSSWRoutingController(stdCtl);

		// call getQueueIDs and verify the group result
		SelectOption queueID = ext.getQueueIDs().get(0);
		System.assertEquals(true, queueID.getLabel().contains('SSSW'),
				'SSSWRoutingController_Test_getQueueIDs_got: fails to get the group info of the SSSWRoutingController');

		Test.stopTest();
	}

	@isTest
	/**
	 * SCENARIO: Email template of a SSSWRoutingController is fetched successfully
	 **/
	// static void SSSWRoutingController_Test_getTemplateIDs_got() {
	//     Test.startTest();

	//     // get the SSSWRouting inserted during setup
	//     SSSWRouting__c routing = [SELECT Id FROM SSSWRouting__c LIMIT 1];
	//     ApexPages.StandardController stdCtl = new ApexPages.StandardController(routing);
	//     SSSWRoutingController ext = new SSSWRoutingController(stdCtl);

	//     // call getTemplateIDs and verify the Email Template result
	//     SelectOption templateID = ext.getTemplateIDs().get(0);
	//     System.assertEquals(true, templateID.getLabel().contains('SSSW'),
	//             'SSSWRoutingController_Test_getTemplateIDs_got: fails to get the Email Template of the SSSWRoutingController');

	//     Test.stopTest();
	// }

	
	/**
	 * SCENARIO: There's no existing routing and proxy case of a SSSWRoutingController is created successfully by calling checkExisting
	 **/
	static void SSSWRoutingController_Test_checkExisting_notExist() {
		Test.startTest();

		// get the SSSWRouting inserted during setup
		SSSWRouting__c routing = [
				SELECT Id, ProductCategory__c, ProductSubCategory__c, CaseType__c,
						CustomerQueueType__c, EnquirySubType__c, Queue_ID__c
				FROM SSSWRouting__c
				LIMIT 1
		];
		routing.SocialPostTags__c = 'w2423423asdfsadfsa'; // making it unique
		update routing;
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(routing);
		SSSWRoutingController ext = new SSSWRoutingController(stdCtl);

		// link the routing attributes to SSWRoutingController
		ext.productCategory = routing.ProductCategory__c.split(SSSWRoutingController.MULTI_SELECT_DELIM);
		ext.productSubCategory = routing.ProductSubCategory__c.split(SSSWRoutingController.MULTI_SELECT_DELIM);
		ext.customerQueueType = routing.CustomerQueueType__c.split(SSSWRoutingController.MULTI_SELECT_DELIM);
		ext.enquirySubType = routing.EnquirySubType__c.split(SSSWRoutingController.MULTI_SELECT_DELIM);
		ext.queueID = routing.Queue_ID__c;

		ext.checkExisting();

		// get the existing routings after call checkExisting method and verify the result
		List<SSSWRouting__c> routings = ext.existingRoutings;
		System.assertEquals(true, routings.isEmpty(), 'SSSWRouting__c should not exist');

		Test.stopTest();
	}

	@isTest
	/**
	 * SCENARIO: New SSSWRouting is saved and updated successfully
	 **/
	static void SSSWRoutingController_Test_save_success() {
		Test.startTest();

		// get the SSSWRouting inserted during setup
		SSSWRouting__c routing = [
				SELECT Id, ProductCategory__c, ProductSubCategory__c, CaseType__c,
						CustomerQueueType__c, EnquirySubType__c
				FROM SSSWRouting__c
				LIMIT 1
		];
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(routing);
		SSSWRoutingController ext = new SSSWRoutingController(stdCtl);
		//ext.enquirySubType='TestingSave';
		ext.enquirySubType= new List<String>{'TestingSave'};
		ext.changeRecordType();
		ext.save();
		// get new SSSWRouting after save
		SSSWRouting__c newRouting = [SELECT CaseKey__c,EnquirySubType__c FROM SSSWRouting__c LIMIT 1];

		// verify if the updated SSSWRouting has right Case Type, Category, CustomerQueueType, Enquire Type
		System.assertEquals('TestingSave', newRouting.EnquirySubType__c,
				'SSSWRoutingController_Test_save_success: fails to update SSSWRouting');


		Test.stopTest();
	}

	@isTest
	static void testIsSamePostTags() {
		// get the SSSWRouting inserted during setup
		SSSWRouting__c routing = [
				SELECT Id, ProductCategory__c, ProductSubCategory__c, CaseType__c,
						CustomerQueueType__c, EnquirySubType__c
				FROM SSSWRouting__c
				LIMIT 1
		];
		ApexPages.StandardController stdCtl = new ApexPages.StandardController(routing);
		SSSWRoutingController ext = new SSSWRoutingController(stdCtl);

		Test.startTest();
		System.assert(ext.isSamePostTags(null, null), 'Expected to return true if post tags are null');
		System.assert(ext.isSamePostTags('', ''), 'Expected to return true if post tags are blank');
		System.assert(ext.isSamePostTags(' ', ' '), 'Expected to return true if post tags are blank');
		System.assert(ext.isSamePostTags(' ', null), 'Expected to return true if post tags are blank or null');
		System.assert(!ext.isSamePostTags('pt1', null), 'Expected to return false if post tags are specified in new rule but blank on existing rule');
		System.assert(!ext.isSamePostTags(null, 'pt1'), 'Expected to return false if post tags are not specified in new rule but specified in the existing rule');
		System.assert(!ext.isSamePostTags('pt1', 'pt2'), 'Expected to return false when post tags differ');
		System.assert(!ext.isSamePostTags('pt1;pt2', 'pt2'), 'Expected to return false when post tags differ');
		System.assert(ext.isSamePostTags('pt1;pt2', 'pt2;pt1'), 'Expected to return true when post tags match irrespective of the order');
		System.assert(ext.isSamePostTags('pt1;pt2', 'pT1;Pt2'), 'Expected to return true when post tags match irrespective of case');
		Test.stopTest();
	}

}