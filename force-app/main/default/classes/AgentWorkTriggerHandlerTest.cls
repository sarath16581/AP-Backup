/***
 * @author George Nguyen
 * @domain Core
 * @description Test class for AgentWorkTriggerHandler 
 * @changelog
 * 2023-02-16 - George Nguyen - this class was created a long time ago. I have refactor it to use our framework.
 * 2024-07-22 - Ranjeewa Silva - Test class updates after uplifting Trigger Handler class to new domain less trigger dispatch framework.
 */
@IsTest
public class AgentWorkTriggerHandlerTest {

	@IsTest
	private static void main() {

		AgentWorkTriggerHandler handler = new AgentWorkTriggerHandler();
		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(AgentWork.SObjectType, handler.getSObjectType(), 'Expected the correct sobject type');
		System.assert(AgentWorkTriggerHandler.getUnitOfWorkSObjectTypes().contains(AgentWork.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AgentWorkTriggerHandler.getUnitOfWorkSObjectTypes().contains(Case.SObjectType), 'Expected valid list of sobject types to be returned');

	}

	/**
	 * Ensure AgentWork record filters are applied as expected.
	 */
	@IsTest
	private static void testPrimeRecordFilters() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		Callback_Request__c callbackRequest = new Callback_Request__c(Id=fflib_IDGenerator.generate(Callback_Request__c.SObjectType));

		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(3, UserInfo.getUserId(), new List<Id>{cases[0].Id, cases[1].Id, callbackRequest.Id}, true);
		// AgentWork related to cases
		agentWork[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[0], new Map<String, Object>{'WorkItemId' => cases[0].Id});
		agentWork[1] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[1], new Map<String, Object>{'WorkItemId' => cases[1].Id});
		// AgentWork related to callback request
		agentWork[2] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[2], new Map<String, Object>{'WorkItemId' => callbackRequest.Id});

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		Map<String, List<SObject>> filteredRecords = new AgentWorkTriggerHandler().primeRecordFilters(agentWork);

		Test.stopTest();

		Assert.areEqual(2, filteredRecords.size());

		Assert.areEqual(2, filteredRecords.get('filterCaseWorkItems').size());
		Assert.areEqual(agentWork[0].Id, filteredRecords.get('filterCaseWorkItems')[0].Id);
		Assert.areEqual(agentWork[1].Id, filteredRecords.get('filterCaseWorkItems')[1].Id);

		Assert.areEqual(1, filteredRecords.get('filterCallbackRequestWorkItems').size());
		Assert.areEqual(agentWork[2].Id, filteredRecords.get('filterCallbackRequestWorkItems')[0].Id);
	}
}