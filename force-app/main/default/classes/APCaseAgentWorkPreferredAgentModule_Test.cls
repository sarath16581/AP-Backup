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
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(5, true));
		for(Case csRec : cases.values()){
			csRec.BypassPreferredAgent__c = true;
			csRec.PreferredAgentExpiry__c = Datetime.now();
		}

		List<AgentWork> records = OmniChannelTestDataFactory.getAgentWorks(5, UserInfo.getUserId(), cases.keySet(), true);
		records[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object> { 'Status' => 'Opened'});
		records[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object> { 'Status' => 'Assigned'});
		records[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object> { 'Status' => 'Declined'});
		records[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[3], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => UserInfo.getUserId() });
		records[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[4], new Map<String, Object> { 'Status' => 'DeclinedOnPushTimeout', 'PreferredUserId' => UserInfo.getUserId() });

		List<AgentWork> existingRecords = records.deepClone(true, true, true);
		existingRecords[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[0], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[1], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[2], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[3], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[4], new Map<String, Object> { 'Status' => 'Assigned'});

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		APCaseAgentWorkPreferredAgentModule.newInstance().onAfterUpdate(records, new Map<Id, AgentWork>(existingRecords), mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = records[0].WorkItemId, BypassPreferredAgent__c = false, AllocateToQueue__c = false, PreferredAgentExpiry__c = null),
				new Case(Id = records[3].WorkItemId, BypassPreferredAgent__c = true, AllocateToQueue__c = true, PreferredAgentExpiry__c = null),
				new Case(Id = records[4].WorkItemId, BypassPreferredAgent__c = true, AllocateToQueue__c = true, PreferredAgentExpiry__c = null)
			}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.AllocateToQueue__c, Case.PreferredAgentExpiry__c }),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(APCaseAgentWorkPreferredAgentModule.class.getName())
		);
	}
}
