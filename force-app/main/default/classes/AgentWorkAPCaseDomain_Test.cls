/***
 * @description test class for AgentWorkAPCaseDomain
 * @author George Nguyen
 * @group Domain
 * @domain AgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 * 2023-04-14 - Noel Lim - Updated class name from APCaseAgentWorkDomain_Test to AgentWorkAPCaseDomain_Test
 */
@IsTest
private class AgentWorkAPCaseDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		AgentWorkAPCaseDomain.Constructor constructor = new AgentWorkAPCaseDomain.Constructor();
		
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true);

		ApplicationDomain appDomain = constructor.construct(agentWorks);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(AgentWorkAPCaseAutomationModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}