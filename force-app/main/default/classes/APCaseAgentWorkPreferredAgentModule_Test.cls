/***
 * @author George Nguyen
 * @domain Core
 * @description Test class for APCaseAgentWorkPreferredAgentModule 
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 */
@IsTest
class APCaseAgentWorkPreferredAgentModule_Test {
   
	@IsTest
	static void resetPreferredAgentBypassFlag() {
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		cases.values()[0].BypassPreferredAgent__c = true;
		cases.values()[1].BypassPreferredAgent__c = true;

		List<AgentWork> records = OmniChannelTestDataFactory.getAgentWorks(2, UserInfo.getUserId(), cases.keySet(), true);
		records[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object> { 'Status' => 'Opened'});
		records[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object> { 'Status' => 'Assigned'});

		List<AgentWork> existingRecords = records.deepClone(true, true, true);
		existingRecords[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[0], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[1], new Map<String, Object> { 'Status' => 'Assigned'});

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		APCaseAgentWorkPreferredAgentModule.newInstance().onAfterUpdate(records, new Map<Id, AgentWork>(existingRecords), mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{new Case(Id = records[0].WorkItemId, BypassPreferredAgent__c = false)}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.BypassPreferredAgent__c }),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(APCaseAgentWorkPreferredAgentModule.class.getName())
		);
	}
}
