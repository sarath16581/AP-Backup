/**
 * @author George Nguyen
 * @group Tests
 * @tag CaseOmniRoutingModule
 * @domain MyCustomer
 * @description Test class for CaseOmniRoutingModule
 * 
 * @changelog
 * 2022-11-03	George Nguyen	Created
 * 2023-01-25	Noel Lim		Updated - add logic to assign and test for SSSW and StarTrack recordtypes
 * 2023-02-06	Noel Lim		Updated - added clearPreferredAgentPSRs() to clear PSRs that were manually inserted for Preferred Agent 
 */

/**
	 * Tests the logic in method CaseOmniRoutingModule.onBeforeInsert()
	 * Scenarios:
	 * a) Case secondary priority updated - Case has priority, and correct recordtype
	 * b) Case secondary priority not updated - Case not in Omni queue
	 * c) Case secondary priority not updated - incorrect recordtype
	 * d) Case secondary priority not updated - Case is coming from an Omni queue
	 * 
	 */
@IsTest
public with sharing class CaseOmniRoutingModule_Test {
   
	@IsTest
	static void onBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();

		//Omni queue
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(5, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case - not going to an Omni queue
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = ''; // invalid case - no Priority

		cases[3].OwnerId = omniQueue.Id;
		cases[3].Priority = 'Low';

		cases[4].OwnerId = omniQueue.Id;
		cases[4].Priority = 'Low'; // invalid case - incorrect recordtype


		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		Id recTypeId;
		if(ssswRecTypes.size()>0){
			recTypeId = ssswRecTypes.iterator().next(); 
			cases[0].recordTypeId = recTypeId;
			cases[1].recordTypeId = recTypeId;
			cases[2].recordTypeId = recTypeId;
		}

		Set<Id> starTrackRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
		if(starTrackRecordTypes.size()>0){
			recTypeId = starTrackRecordTypes.iterator().next(); 
			cases[3].recordTypeId = recTypeId;
		}

		Map<Id,String> caseRecordTypes = Utility.getsObjectRecordTypeNames('Case');
		for(Id tempRtypeId : caseRecordTypes.keySet()){
			if(ssswRecTypes.contains(tempRTypeId) == false &&
			starTrackRecordTypes.contains(tempRtypeId) == false){
				cases[4].recordTypeId = tempRtypeId;
				break;
			}
		}

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseOmniRoutingModule.newInstance().onBeforeInsert(cases, uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1],cases[3]}), 
																								(Boolean)fflib_Match.eq(true)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	 * Tests the logic in method CaseOmniRoutingModule.onBeforeUpdate()
	 * Scenarios:
	 * a) Case secondary priority updated - Case has priority, and correct recordtype
	 * b) Case secondary priority not updated - Case not in Omni queue
	 * c) Case secondary priority not updated - incorrect recordtype
	 * d) Case secondary priority not updated - Case is coming from an Omni queue
	 * e) Case's preferred agent PSR deleted  - Case is being routed from the Preferred Agent holding queue
	 * 
	 */
	@IsTest
	static void onBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();

		//Omni queue
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		//Preferred Agent holding queue
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject preferredAgentQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Preferred_Agent_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.PreferredAgentQueueId__c = preferredAgentQueue.QueueId;
		Insert custSetting;
		Id preferredAgentQueueId = preferredAgentQueue.QueueId;

		//Agent User
		List<User> agents = ApplicationTestDataFactory.getUsers(1, true);

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case - not going to an Omni queue
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = 'High';

		cases[3].OwnerId = omniQueue.Id; 
		cases[3].Priority = 'High';

		cases[4].OwnerId = omniQueue.Id; 
		cases[4].Priority = 'High'; // invalid case - incorrect recordtype

		cases[5].OwnerId = agents[0].Id; //clear preferred Agent PSRs


		List<Case> oldCases = cases.deepClone(true, false, false);
		oldCases[0].OwnerId = omniQueue.Id; // invalid case
		oldCases[0].Priority = 'High';

		oldCases[1].OwnerId = UserInfo.getUserId();
		oldCases[1].Priority = 'Low';

		oldCases[2].OwnerId = omniQueue.Id; 
		oldCases[2].Priority = ''; 

		oldCases[3].OwnerId = UserInfo.getUserId();
		oldCases[3].Priority = ''; 

		oldCases[4].OwnerId = UserInfo.getUserId();
		oldCases[4].Priority = ''; 

		oldCases[5].OwnerId = preferredAgentQueueId;


		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		Id recTypeId;
		if(ssswRecTypes.size()>0){
			recTypeId = ssswRecTypes.iterator().next(); 
			cases[0].recordTypeId = recTypeId;
			cases[1].recordTypeId = recTypeId;
			cases[2].recordTypeId = recTypeId;
			cases[5].recordTypeId = recTypeId;
		}

		Set<Id> starTrackRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
		if(starTrackRecordTypes.size()>0){
			recTypeId = starTrackRecordTypes.iterator().next(); 
			cases[3].recordTypeId = recTypeId;
		}

		Map<Id,String> caseRecordTypes = Utility.getsObjectRecordTypeNames('Case');
		for(Id tempRtypeId : caseRecordTypes.keySet()){
			if(ssswRecTypes.contains(tempRTypeId) == false &&
			starTrackRecordTypes.contains(tempRtypeId) == false){
				cases[4].recordTypeId = tempRtypeId;
				break;
			}
		}

		//PSR
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(1, serviceChannelId, new Set<Id>{ cases[5].Id }, true);

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		PendingServiceRoutingSelector pendingServiceRoutingSelector = (PendingServiceRoutingSelector) MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues(
			(Set<Object>)fflib_Match.eq(new Set<Object>())
		)).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.when(pendingServiceRoutingSelector.selectByWorkItemId(
			(Set<Id>) fflib_Match.eq(new Set<Id>{ cases[5].Id }),
			(Set<Object>) fflib_Match.eq(new Set<Object>())
		)).thenReturn(psrs);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseOmniRoutingModule.newInstance().onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1], cases[2], cases[3] }), 
																								(Boolean)fflib_Match.eq(false)
																							);
		
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1)))
																							.registerDeleted((List<PendingServiceRouting>)fflib_Match.eq(psrs));
											
		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}
	
}