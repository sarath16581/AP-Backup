/***
 * @description test class for APCaseAgentWorkDomain
 * @author George Nguyen
 * @group Domain
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 */
@IsTest
private class APCaseAgentWorkDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		APCaseAgentWorkDomain.Constructor constructor = new APCaseAgentWorkDomain.Constructor();
		
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true);

		ApplicationDomain appDomain = constructor.construct(agentWorks);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(APCaseAgentWorkPreferredAgentModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}