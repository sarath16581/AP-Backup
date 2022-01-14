/**
* @author Ashapriya Gadi
* @date 2021-11-23
* @group Tests
* @tag module
* @tag emailmessage
* @domain EmailMessageDomain
* @description Test class covering EmailMessagesModule
* @changelog
* 2021-11-23 - Ashapriya Gadi - Created
*/
@IsTest
private class ServiceAdvisorEmailEntitlementModuleTest {
	/**
		 * Test:
		 *  When a Emailmessage is inserted for a service delivery emailtocase, then assign entitlement and business hours
	**/
	@IsTest
	private static void testEnsureAfterInsertAssignEntitlements() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		//get the business hours from the org
		List<BusinessHours> stdBusinessHours = [SELECT Id,Name FROM BusinessHours where Name = 'Service Delivery VIC'];
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(EmailMessageTriggerHandler.getUnitOfWorkSObjectTypes());
		//insert entitlement
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name ='Standard Entitlement BGS - VIC' LIMIT 1 ];
		List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(2, true,'BGS Entitlement Standard - VIC',sla.Id,orgAaccounts[0].Id));
		//insert case and emailmessages
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseServiceDeliveryRecordType;
		List<EmailMessage> emailMessages = new List<EmailMessage>(ApplicationTestDataFactory.getEmailMessages(2, true,true,'test@test.com','amazonstrategicsupport@auspost.com.au','Inbound Email',cases[0].Id));
		//insert custom setting
		User uRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		ConfigSetting__c configSetting = new ConfigSetting__c(AutomatedCaseUser__c = uRecord.Id);
		insert configSetting;
		// =====================================
		// Stubbing
		// =====================================
		EntitlementsSelector mockEntitlementSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		BusinessHoursSelector mockBusinessHoursSelector = (BusinessHoursSelector)MockUtility.mockSelector(BusinessHoursSelector.class);
		ServiceAdvisorsCasesSelector mockServiceDeliveryCasesSelector = (ServiceAdvisorsCasesSelector)MockUtility.mockSelector(ServiceAdvisorsCasesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Case caseWithEmailMessages = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0],new Map<String,List<SObject>>{'EmailMessages'=>emailmessages});
		List<Case> caseList = new List<Case>{caseWithEmailMessages};
		MockUtility.Mocks.when(mockEntitlementSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(entitlements);
		MockUtility.Mocks.when(mockBusinessHoursSelector.selectByName((Set<String>)fflib_Match.anyObject())).thenReturn(stdBusinessHours);
		MockUtility.Mocks.when(mockServiceDeliveryCasesSelector.selectByIdsAndEntitlementIdAndCreatedBy((Set<Id>)fflib_Match.anyObject(),(String)fflib_Match.isNull(),fflib_Match.anyString(),(Set<Object>)fflib_Match.anyObject())).thenReturn(caseList);
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ServiceAdvisorEmailMesEntitlementsModule module = ServiceAdvisorEmailMesEntitlementsModule.newInstance();
		module.onAfterInsert( (List<SObject>)emailMessages, uow);
		Test.stopTest();
		((ServiceAdvisorsCasesSelector)MockUtility.Mocks.verify(mockServiceDeliveryCasesSelector, MockUtility.Mocks.times(1))).selectByIdsAndEntitlementIdAndCreatedBy((Set<Id>)fflib_Match.anyObject(),(String)fflib_Match.isNull(),fflib_Match.anyString() ,(Set<Object>)fflib_Match.anyObject());
		((EntitlementsSelector)MockUtility.Mocks.verify(mockEntitlementSelector, MockUtility.Mocks.times(1))).selectByName((Set<String>)fflib_Match.anyObject());
		((BusinessHoursSelector)MockUtility.Mocks.verify(mockBusinessHoursSelector, MockUtility.Mocks.times(1))).selectByName((Set<String>)fflib_Match.anyObject());
	}

}