/**
 * @description Test class covering APRModule
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Tests
 * @tag module
 * @tag APR__c
 * @domain StarTrackAPRDomain
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 * 2023-08-18 Jacob Isaac REQ3267427
 */

@IsTest
private class StarTrackAPRAutomationModule_Test {

	@IsTest
	private static void testOnBeforeInsertUpdatesAPRFields() {
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(APRTriggerHandler.getUnitOfWorkSObjectTypes());
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c bAcc = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', true)[0];
		List<APR__c> aprList = ApplicationTestDataFactory.getAPRs(4, bAcc.Id, 'StarTrack APR', true);

		aprList[0].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		aprList[0].Entered_in_Team_PeopleSoft__c = true;
		aprList[0].Communicated_to_customer__c = true;
		//aprList[0].Status__c = APRConstants.STATUS_ACCEPTED;
		aprList[0].Status__c = APRConstants.STATUS_ACCOUNTLOST;
		aprList[0].Published_Date__c = System.today();
		
		// aprList[1].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		// aprList[1].Status__c = APRConstants.STATUS_OPEN;

		//aprList[2].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		//aprList[2].Status__c = APRConstants.STATUS_EXEMPTION;

		aprList[3].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		aprList[3].Published_Rate__c = 3.5;
		aprList[3].Status__c = APRConstants.STATUS_ACCOUNTLOST;

		Test.startTest();
			StarTrackAPRAutomationModule module = StarTrackAPRAutomationModule.newInstance();
			module.onBeforeInsert(aprList, uow);
		Test.stopTest();

		System.assert(aprList[0].Processed_Date__c != null, 'Expected Processed Date to be set');
		System.assert(aprList[0].Communicated_to_customer_Date__c != null, 'Expected Communicated to customer Date to be set');
		//System.assert(aprList[0].Confirmed_Date__c != null, 'Expected Confirmed Date to be set');
		//System.assert(aprList[0].Conclusion_Date__c != null, 'Expected Conclusion Date to be set');
		System.assertEquals(aprList[0].Conclusion_Date__c, date.valueOf((aprList[0].Published_Date__c.year() + 1) + '-10-31'), 'Conclusion Date is not set correctly');
		System.assertEquals(aprList[0].Confirmed_Date__c, aprList[0].Published_Date__c, 'Confirmed Date is not set correctly');
		
		// System.assert(aprList[1].Confirmed_Date__c == null, 'Expected Confirmed Date to be null');
		// System.assert(aprList[1].Confirmed_Rate__c == null, 'Expected Confirmed Rate to be null');
		// System.assert(aprList[1].Conclusion_Date__c == null, 'Expected Conclusion Date to be null');
		
		//System.assert(aprList[2].Confirmed_Rate__c == 0, 'Expected Confirmed Rate to be 0');

		System.assertEquals(aprList[3].Published_Rate__c, aprList[3].Confirmed_Rate__c, 'Expected Confirmed rate to be set to Published rate');
	}

	@IsTest
	private static void testOnBeforeUpdateUpdatesAPRFields() {
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(APRTriggerHandler.getUnitOfWorkSObjectTypes());
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c bAcc = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', true)[0];
		List<APR__c> aprList = ApplicationTestDataFactory.getAPRs(4, bAcc.Id, 'StarTrack APR', true);
		List<APR__c> oldAPRList = new List<APR__c>{ aprList[0].clone(true), aprList[1].clone(true), aprList[2].clone(true) };

		aprList[0].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		aprList[0].Entered_in_Team_PeopleSoft__c = true;
		aprList[0].Communicated_to_customer__c = true;
		aprList[0].Published_Rate__c = 79;	
		//aprList[0].Status__c = APRConstants.STATUS_ACCEPTED;
		aprList[0].Status__c = APRConstants.STATUS_ACCOUNTLOST;
		aprList[0].Published_Date__c = System.today();

		// aprList[1].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		// aprList[1].Status__c = APRConstants.STATUS_OPEN;

		//aprList[2].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		//aprList[2].Status__c = APRConstants.STATUS_EXEMPTION;

		aprList[3].RecordTypeId = APRConstants.RECTYPE_ID_STARTRACK;
		aprList[3].Status__c = APRConstants.STATUS_ACCOUNTLOST;

		Test.startTest();
			StarTrackAPRAutomationModule module = StarTrackAPRAutomationModule.newInstance();
			module.onBeforeUpdate(aprList, new Map<Id, APR__c>(oldAprList), uow);
		Test.stopTest();

		System.assert(aprList[0].Processed_Date__c != null, 'Expected Processed Date to be set');
		System.assert(aprList[0].Communicated_to_customer_Date__c != null, 'Expected Communicated to customer Date to be set');
		//System.assert(aprList[0].Confirmed_Date__c != null, 'Expected Confirmed Date to be set');
		//System.assert(aprList[0].Conclusion_Date__c != null, 'Expected Conclusion Date to be set');
		System.assertEquals(aprList[0].Conclusion_Date__c, date.valueOf((aprList[0].Published_Date__c.year() + 1) + '-10-31'), 'Conclusion Date is not set correctly');
		System.assertEquals(aprList[0].Confirmed_Date__c, aprList[0].Published_Date__c, 'Confirmed Date is not set correctly');
		
		// System.assert(aprList[1].Confirmed_Date__c == null, 'Expected Confirmed Date to be null');
		// System.assert(aprList[1].Confirmed_Rate__c == null, 'Expected Confirmed Rate to be null');
		// System.assert(aprList[1].Conclusion_Date__c == null, 'Expected Conclusion Date to be null');
		
		//System.assert(aprList[2].Confirmed_Rate__c == 0, 'Expected Confirmed Rate to be 0');

		System.assertEquals(aprList[3].Published_Rate__c, aprList[3].Confirmed_Rate__c, 'Expected Confirmed rate to be set to Published rate');
	}

	@IsTest
	private static void testOnBeforeInsertException() {
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(APRTriggerHandler.getUnitOfWorkSObjectTypes());

		Test.startTest();
			try {
				StarTrackAPRAutomationModule module = StarTrackAPRAutomationModule.newInstance();
				module.onBeforeInsert(null, uow);
			} catch (Exception e) {
				System.assert(true, 'Expected Exception to be thrown');
			}
		Test.stopTest();
	}

	@IsTest
	private static void testOnBeforeUpdateException() {
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(APRTriggerHandler.getUnitOfWorkSObjectTypes());

		Test.startTest();
			try {
				StarTrackAPRAutomationModule module = StarTrackAPRAutomationModule.newInstance();
				module.onBeforeUpdate(null, null, uow);
			} catch (Exception e) {
				System.assert(true, 'Expected Exception to be thrown');
			}
		Test.stopTest();
	}
}