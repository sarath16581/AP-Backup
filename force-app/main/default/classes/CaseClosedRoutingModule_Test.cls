/*** 
 * @author Noel Lim
 * @date 2022-10-17
 * @group Utility
 * @domain Routing 
 * @description Test class for the CaseClosedRoutingModule class
 * @changelog
 * 2022-11-22 - Noel Lim - Created
 */
@IsTest
private class CaseClosedRoutingModule_Test {

    /**
	 * Test logic in both onBeforeUpdate() and onBeforeInsert() that moves closed Cases to the Closed Omni queue
	 * 
	 * Covers the following positive test scenarios:
	 * a) Closed Case status changed from Open => Close
	 * b) Closed Case Owner changed 
	 * c) Closed Case is inserted
	 * 
	 * Covers the following test scenarios (negative testing):
	 * a) Closed Case in a Queue without Routing config
	 * b) Case not in a Closed Status
	 * c) Case with no change in Status
	 * 
	 */
    @IsTest
    static void ensureClosedCasesReassigned(){

        //Queues
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject closedOmniqueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Closed_Omnichannel_Cases' AND SobjectType = 'Case' LIMIT 1];
		custSetting.ClosedQueueId__c = closedOmniqueue.QueueId;
		Insert custSetting;
		Id closedCaseQueueId = closedOmniqueue.QueueId;

		QueueRoutingConfig qrc = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));	
		Group omniQueue = queues.values()[0];
		omniQueue.QueueRoutingConfigId = qrc.Id;
		Group nonOmniQueue = queues.values()[1];

		//Case Status
		CacheManager.settings.CacheEnabled__c = true;

		List<CaseStatus> caseStatuses = ApplicationTestDataFactory.getCaseStatuses(2, false);
		CaseStatus closedStatus = caseStatuses[0];
		closedStatus = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(closedStatus, new Map<String, Object>{'IsClosed' => true});
		CaseStatus nonClosedStatus = caseStatuses[1];
		nonClosedStatus = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(nonClosedStatus, new Map<String, Object>{'IsClosed' => false});

		Set<String> closedCaseStatuses = new Set<String>{closedStatus.MasterLabel};
		CacheManager.put('CASE_CLOSED_STATUSES',closedCaseStatuses );
		
		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		for(Case cs: cases){
			cs.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		}

		//positive scenarios 
		Map<Id, Case> validCases = new Map<Id, Case>();
		Map<Id, Case> validCasesInsert = new Map<Id, Case>();

		cases[0].OwnerId = omniQueue.Id;
		cases[0].Status = closedStatus.MasterLabel;
		validCases.put(cases[0].id, cases[0]); //Closed Case status changed from Open => Close

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Status = closedStatus.MasterLabel;
		validCases.put(cases[1].id, cases[1]); //Closed Case Owner changed 

		cases[5].OwnerId = omniQueue.Id;
		cases[5].Status = closedStatus.MasterLabel;
		validCasesInsert.put(cases[5].id, cases[5]); //Inserted

		
		//negative scenarios 
		cases[2].OwnerId = nonOmniQueue.Id; //Closed Case in a Queue without Routing config
		cases[2].Status = closedStatus.MasterLabel;

		cases[3].OwnerId = omniQueue.Id; //Case not in a Closed Status
		cases[3].Status = nonClosedStatus.MasterLabel;

		cases[4].OwnerId = omniQueue.Id; //Case with no change in both Status and OwnerId
		cases[4].Status = closedStatus.MasterLabel;

		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true)
		};
		oldCases[0].Status = nonClosedStatus.MasterLabel;
		oldcases[1].Status = closedStatus.MasterLabel;
		oldcases[1].OwnerId = UserInfo.getUserId();
		oldcases[2].Status = nonClosedStatus.MasterLabel;
		oldcases[3].Status = nonClosedStatus.MasterLabel;
		oldcases[4].Status = closedStatus.MasterLabel;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);	 
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectOmniQueues(new Set<Object>())).thenReturn(new Map<Id,Group>{omniQueue.Id => omniQueue}); //only queues of cases that fit the criteria are queried

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseCommonUtility helper = new CaseCommonUtility();			
		helper.routeCase(validCases.values(),new Map<Id,Case>(oldCases),false);
		helper.routeCase(validCasesInsert.values(),null,true);

		CaseClosedRoutingModule module = CaseClosedRoutingModule.newInstance();       
        module.onBeforeUpdate(validCases.values(),new Map<Id,Case>(oldCases), mockUow);
		module.onBeforeInsert(validCasesInsert.values(), mockUow);

		Test.stopTest();

		System.assert(cases[0].OwnerId == closedCaseQueueId, 'Closed Case status changed from Open to Close => moved to Closed Case Queue');
		System.assert(cases[1].OwnerId == closedCaseQueueId, 'Closed Case Owner changed  => moved to Closed Case Queue');
		System.assert(cases[5].OwnerId == closedCaseQueueId, 'Closed Case inserted  => moved to Closed Case Queue');
		System.assert(cases[2].OwnerId != closedCaseQueueId, 'Closed Case in a Queue without Routing config => not in Closed Case Queue');
		System.assert(cases[3].OwnerId != closedCaseQueueId, 'Case not in a Closed Status => not in Closed Case Queue');
		System.assert(cases[4].OwnerId != closedCaseQueueId, 'Case with no change in Status => not in Closed Case Queue');
    }
}