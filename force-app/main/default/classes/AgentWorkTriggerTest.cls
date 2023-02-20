/*
 * @author: Rajesh P. (Mav3rik)
 * @description: This class created to have converage for AgentWork Trigger
 * @description: Also, there is limitation; there must be at least one record to run this test class.
 * @description: We cannot create new record on the fly as at least one user must be online which creates dependency.
 * @description: Please make sure, you have a record for AgentWork object before executing/testing this class.
 * @history:22-OCT-2019, class created.
 * 2023-02-16	George 		updated to unit test against the framework
*/
@isTest(SeeAllData=true)
public class AgentWorkTriggerTest {

	@IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        AgentWorkTriggerHandler mock = (AgentWorkTriggerHandler)MockUtility.mockUtility(AgentWorkTriggerHandler.class);

		update [SELECT Id FROM AgentWork LIMIT 1]; // triggering the AgentWorkTrigger

        ((AgentWorkTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();
        
        // PMD Warning
		System.assert(true);
    }
}