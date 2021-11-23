/**************************************************
Description:    NPS Utility Test class
History:
--------------------------------------------------
2018-07-10  nathan.franklin@auspost.com.au  Created
**************************************************/
@isTest
public class NPSSurveyUtil_Test {

	@testSetup
	private static void testSetup() {

		AusPostSettings__c npsSettings = new AusPostSettings__c(Name = SSSWConstants.NPS_CUTOFF_CUST_SETTING, Number1__c = SSSWConstants.NPS_CUTOFF_DAYS);
		insert npsSettings;

		// create account and contact
		Contact contact = TestDataProvider.createContact();
		insert contact;

		Account personAccount = TestDataProvider.createPersonAccount();
		insert personAccount;

		// standard shipping product rule... should never be triggered
		List<SSSWRouting__c> routings = new List<SSSWRouting__c>();
		SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Standard','General Enquiry',null,'','Web','All',SSSWConstants.RECTYPENPS);
		routing.IsNew__c = true;
		routing.NPS_criteria__c = 'Include';
		routing.IsActive__c = true;
		routing.Sequence__c = 1;
		routings.add(routing);

		//Routing of type ANY 
		SSSWRouting__c routing1 = TestUtility.createSSSWRouting(null,'Unaddressed Mail',null,null,null,null,'Any',SSSWConstants.RECTYPENPS);
		routing1.IsNew__c = true;
		routing1.NPS_criteria__c = 'Include';
		routing1.IsActive__c = true;
		routing1.Sequence__c = 2;
		routings.add(routing1);

		// social rule
		SSSWRouting__c routing2 = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'','Social','All',SSSWConstants.RECTYPENPS);
		routing2.IsNew__c = true;
		routing2.NPS_criteria__c = 'Include';
		routing2.IsActive__c = true;
		routing2.Sequence__c = 3;
		routings.add(routing2);

		// web/express/exclusion rule
		SSSWRouting__c routing3 = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'','Web','All',SSSWConstants.RECTYPENPS);
		routing3.IsNew__c = true;
		routing3.NPS_criteria__c = 'Exclude';
		routing3.IsActive__c = true;
		routing3.Sequence__c = 4;
		routings.add(routing3);

		// web/standard product rule
		SSSWRouting__c routing4 = TestUtility.createSSSWRouting('Domestic Parcels','Standard','General Enquiry',null,'','Web','All',SSSWConstants.RECTYPENPS);
		routing4.IsNew__c = true;
		routing4.NPS_criteria__c = 'Include';
		routing4.IsActive__c = true;
		routing4.Sequence__c = 5;
		routings.add(routing4);

		Database.insert(routings, false);

		List<NPS_Case_Email_Exclusion__c> exclusions = new List<NPS_Case_Email_Exclusion__c>();

		// valid email-to-case exclusion rule
		exclusions.add(new NPS_Case_Email_Exclusion__c(Name = 'test@test.com', Email_Address_Formula__c = 'test@test.com', Rule_Type__c = 1, Target_Case_Record_Type_Prefix__c = 'SSSW'));

		// invalid error, would cause an exception
		exclusions.add(new NPS_Case_Email_Exclusion__c(Name = 'test@$[%^&*(@test.com', Email_Address_Formula__c = 'test@$[%^&*(@test.com', Rule_Type__c = 1, Target_Case_Record_Type_Prefix__c = 'SSSW'));

		// valid contact exclusion rule
		exclusions.add(new NPS_Case_Email_Exclusion__c(Name = '@auspost.com.au', Email_Address_Formula__c = '*@auspost.com.au', Rule_Type__c = 2, Target_Case_Record_Type_Prefix__c = 'SSSW'));

		insert exclusions;
	}

	/**
	 * Scenario:
	 *      A case is triggers which hits an 'inclusion' rule in the NPS configuration. This should set the NPS config values
	 */
	@isTest
	public static void testNPSCaseAssignment() {

		// get the person account
		Account acc = [Select Id, PersonContactId From Account Where IsPersonAccount = true];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure the NPS rule is triggered
		// should cause Rule sequence 2 to trigger which should include this case from NPS
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, acc.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.Origin = 'Social';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Express';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		System.assertEquals(UserInfo.getUserId(), csRec1.NPSAgent__c);
		System.assertNotEquals(null, csRec1.NPSScheduledDate__c);

	}


	/**
	 * Scenario:
	 *      A case is triggers which hits an 'exclusion' rule in the NPS configuration. This *shouldnt* set the NPS config values
	 */
	@isTest
	public static void testNPSCaseRuleExclusion() {

		// get the person account
		Account acc = [Select Id, PersonContactId From Account Where IsPersonAccount = true];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure the NPS rule is triggered
		// should cause Rule sequence 3 to trigger which should exclude this case from NPS
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, acc.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.Origin = 'Web';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Express';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		// make sure NPS settings where not trigger
		System.assertEquals(null, csRec1.NPSAgent__c);
		System.assertEquals(null, csRec1.NPSScheduledDate__c);

	}

	/**
	 * Scenario:
	 *      A case is created with an email-to-case emailaddress which should exclude flagging cases for NPS
	 */
	@isTest
	public static void testNPSCaseEmailExclusion() {

		// get the person account
		Account acc = [Select Id, PersonContactId From Account Where IsPersonAccount = true];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure the NPS rule is triggered
		// should cause Rule sequence 2 to trigger which normally should include this case from NPS
		//      however, because the EmailToCaseAddress__c os populated with an exclusion address the NPS values shouldn't be populated
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, acc.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.EmailToCaseAddress__c = 'test@test.com';
		csRec1.Origin = 'Social';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Express';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		System.assertEquals(null, csRec1.NPSAgent__c);
		System.assertEquals(null, csRec1.NPSScheduledDate__c);


	}

	/**
	 * Scenario:
	 *      A case is created with a contact emailaddress which should exclude flagging cases for NPS
	 */
	@isTest
	public static void testNPSCaseContactEmailExclusion() {

		Account personAccount = TestDataProvider.createPersonAccount();
		personAccount.PersonEmail = 'nathan.franklin@auspost.com.au';
		insert personAccount;

		personAccount = [Select Id, PersonContactId From Account Where Id = :personAccount.Id];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure the NPS rule is triggered
		// should cause Rule sequence 2 to trigger which normally should include this case from NPS
		//      however, because the contact email is populated with an exclusion address the NPS values shouldn't be populated
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, personAccount.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.Origin = 'Social';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Express';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		System.assertEquals(null, csRec1.NPSAgent__c);
		System.assertEquals(null, csRec1.NPSScheduledDate__c);

	}

    /**
     * SCENARIO: 
     *      A case is triggers which hits an 'inclusion' rule in the NPS configuration. This *should* set the NPS config values
    **/
	@isTest
	public static void testNPSCaseRuleAnyInclusion() {

		// get the person account
		Account acc = [Select Id, PersonContactId From Account Where IsPersonAccount = true];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure the NPS rule is triggered
		// should cause Rule sequence 3 to trigger which should exclude this case from NPS
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, acc.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.Origin = 'Email';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Unaddressed Mail';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		// make sure NPS settings where not trigger
		System.assertEquals(UserInfo.getUserId(), csRec1.NPSAgent__c);
		System.assertNotEquals(null, csRec1.NPSScheduledDate__c);

	}

    /**
     * SCENARIO: 
     *      A case is triggers which hits an 'no' rule in the NPS configuration. This *should* set the Default NPS config values
    **/
	@isTest
	public static void testNPSCaseRuleDefault() {

		// get the person account
		Account acc = [Select Id, PersonContactId From Account Where IsPersonAccount = true];

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		// create a case with the right options to ensure no NPS rule is triggered
		// should cause Default value to be added
		Case csRec1 = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, acc.PersonContactId, caseRecTypeMap.get('SSSW General Enquiry').getRecordTypeId());
		csRec1.Origin = 'BSP';
		csRec1.Status = 'New';
		csRec1.ProductCategory__c = 'Domestic Parcels';
		csRec1.ProductSubCategory__c = 'Business Post';
		csRec1.Address2__c  = '111 Bourke Street';
		csRec1.ResolutionCode__c = 'Actioned';
		insert csRec1;

		Test.startTest();

		csRec1.Status = 'Closed';
		update csRec1;

		Test.stopTest();

		csRec1 = [Select Id, NPSAgent__c, NPSScheduledDate__c From Case Where Id = :csRec1.Id];

		// make sure NPS settings where not trigger
		System.assertEquals(UserInfo.getUserId(), csRec1.NPSAgent__c);
		System.assertNotEquals(null, csRec1.NPSScheduledDate__c);

	}

}