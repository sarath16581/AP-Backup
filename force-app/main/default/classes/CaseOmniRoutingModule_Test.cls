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
 */
@IsTest
public with sharing class CaseOmniRoutingModule_Test {
   
	@IsTest
	static void onBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(5, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = ''; // invalid case

		cases[3].OwnerId = omniQueue.Id;
		cases[3].Priority = 'Low';

		cases[4].OwnerId = omniQueue.Id;
		cases[4].Priority = 'Low'; // invalid case - recordtype


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
				cases[4].recordTypeId = recTypeId;
				break;
			}
		}

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

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

	@IsTest
	static void onBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		List<Case> cases = ApplicationTestDataFactory.getCases(4, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = 'High';

		cases[3].OwnerId = omniQueue.Id; 
		cases[3].Priority = 'High';

		List<Case> oldCases = cases.deepClone(true, false, false);
		oldCases[0].OwnerId = omniQueue.Id; // invalid case
		oldCases[0].Priority = 'High';

		oldCases[1].OwnerId = UserInfo.getUserId();
		oldCases[1].Priority = 'Low';

		oldCases[2].OwnerId = omniQueue.Id; 
		oldCases[2].Priority = ''; 

		oldCases[3].OwnerId = UserInfo.getUserId();
		oldCases[3].Priority = ''; 


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



		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		CaseOmniRoutingModule.newInstance().onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1], cases[2], cases[3] }), 
																								(Boolean)fflib_Match.eq(false)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}
	
}