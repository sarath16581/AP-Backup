/**
 * @description
 * @author Thang Nguyen
 * @date 27-11-2023
 * @changelog
 */
@IsTest
public class CreditDisputeClaimCaseModule_Test {

	@IsTest
	public static void testCoverageOnly() {
		// =====================================
		// Data Preparation
		// =====================================
		Id apCreditDisputeQueueId = new GroupsSelector().selectByDeveloperName(new Set<String>{
				'Australia_Post_Credit_Disputes_Queue'
		}).values()[0].Id;
		Id stCreditDisputeQueueId = new GroupsSelector().selectByDeveloperName(new Set<String>{
				'StarTrack_Credit_Claims_Queue'
		}).values()[0].Id;

		MockUtility.disableTriggerExecution();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		//insert case with queue as owner
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = apCreditDisputeQueueId;
		cases[1].OwnerId = stCreditDisputeQueueId;

		// =====================================
		// Stubbing
		// =====================================

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.stopStubbing();
		
		Test.startTest();
		
		CreditDisputeClaimCaseModule module = CreditDisputeClaimCaseModule.newInstance();
		module.onBeforeInsert((List<SObject>) cases, uow);
		
		System.assertEquals(
			'Australia Post',
			cases[0].Business_Unit__c,
			'Business Unit must be Australia Post'
		);

		System.assertEquals(
			'StarTrack',
			cases[1].Business_Unit__c,
			'StarTrack'
		);

		Test.stopTest();

	}
}