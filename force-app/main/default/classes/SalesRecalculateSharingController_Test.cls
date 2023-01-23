/**
 * @author Ranjeewa Silva
 * @date 2023-01-23
 * @group Controller
 * @tag Controller
 * @domain Sales
 * @description  Test Class for RecalculateSharingController
 * @changelog
 * 2023-01-23- Ranjeewa Silva - Created
 */

@IsTest
private class SalesRecalculateSharingController_Test {

	/**
	 * Ensure enqueueing queueable job to recalculate sharing is delegated to SalesRecordSharingService and account id
	 * is passed in as an argument.
	 */
	@IsTest
	static void testRecalculateSalesTeamSharing() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockSharingService = (SalesRecordSharingService)MockUtility.mockUtility(SalesRecordSharingService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockSharingService)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesRecalculateSharingController.recalculateSalesTeamSharing(parentAccount.Id);

		Test.stopTest();

		// verify service method is called with expected parameters
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockSharingService, 1)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)sobjectCapture.capture());
		Set<Id> enqueuedAccountIds = (Set<Id>) sobjectCapture.getValue();

		System.assertEquals(1, enqueuedAccountIds.size(), 'Sharing service method must be called passing in the account id.');
		System.assertEquals(parentAccount.Id, enqueuedAccountIds.iterator().next(), 'Sharing service method must be called passing in the account id.');
	}

	/**
	 * Ensure enqueueing queueable job to recalculate sharing is delegated to SalesRecordSharingService and account id
	 * is passed in as an argument.
	 */
	@IsTest
	static void testRecalculateSalesTeamSharingWhenServicethrowsException() {
		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockSharingService = (SalesRecordSharingService)MockUtility.mockUtility(SalesRecordSharingService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		//((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockSharingService)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());
		((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new ThrowSalesRecordSharingServiceExceptionAnswer(), mockSharingService)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());
		//MockUtility.Mocks.when(mockSharingService.enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject())).thenThrow(new MockException('test'));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			SalesRecalculateSharingController.recalculateSalesTeamSharing(parentAccount.Id);
			System.assert(false, 'Expected to throw AuraHandledException but not thrown.');
		} catch (AuraHandledException ahe) {
			// expected
		} catch (Exception ex) {
			System.assert(false, 'Expected to throw AuraHandledException but got some other type : ' + ex.getTypeName());
		}

		Test.stopTest();
	}

	public class ThrowSalesRecordSharingServiceExceptionAnswer implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation)
		{
			throw new SalesRecordSharingService.SalesRecordSharingException();
		}
	}

}