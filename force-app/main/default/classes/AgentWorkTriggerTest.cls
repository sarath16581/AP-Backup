/*
 * @author: Rajesh P. (Mav3rik)
 * @description: This class created to have coverage for AgentWork Trigger
 *			   We cannot create new AgentWork records on the fly as at least one user must be online which creates dependency.
 * @history:22-OCT-2019, class created.
 * 2023-02-16	George 		updated to unit test against the framework
 * 2024-07-22 - Ranjeewa Silva - Refactored the test so it doesn't rely on existing data any more.
*/
@isTest
public class AgentWorkTriggerTest {

	/**
	 * AgentWork trigger does not have any logic to test. We just need a single test for coverage !
	 */
	@IsTest
	static void testForCoverage() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(1, UserInfo.getUserId(), cases[0].Id, false);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			// insert will always fail as we aren't using a logged in agent or even an inserted case.
			// ensure the trigger gets invoked on insert and provides coverage for the trigger!
			Database.insert(agentWork);
		} catch (Exception e) {
			// expected
			Assert.isInstanceOfType(e, DmlException.class);
		}

		Test.stopTest();
	}
}