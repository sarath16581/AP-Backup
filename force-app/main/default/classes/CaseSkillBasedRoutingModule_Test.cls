/*** 
 * @author Noel Lim
 * @date 2022-09-23
 * @group Domain
 * @domain Routing 
 * @description Test class for CaseSkillBasedRoutingModule
 * @changelog
 * 2022-09-23 - Noel Lim - Created
 * 2022-12-06 - Noel Lim - added test method for testAssignToPreferredAgent
 * 2022-02-01 - Noel Lim - update test method for testAssignToPreferredAgent, remove criteria that checks if case is from an omni queue
 */
@IsTest
private class CaseSkillBasedRoutingModule_Test {
	/**
	 * Check that the Case field values are updated based on Account field values
	 * Check that Case fields values are updated only when the Case Account changes
	 */
	@IsTest
	static void checkCaseSLABasedOnAccount() { 
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		Id userId = users[0].Id;


		//Generate Accounts with different SLA values
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(3, true);

		Account accountNoServiceSLA = accounts[0];
		accountNoServiceSLA.ServiceSLA__c = null;

		Account accountWithServiceSLASMB = accounts[1];
		accountWithServiceSLASMB.ServiceSLA__c = 'SMB';

		Account accountWithServiceSLAGold = accounts[2];
		accountWithServiceSLAGold.ServiceSLA__c = 'Gold';

		//Generate Contacts and link to Accounts
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(4, accountWithServiceSLASMB.id, true);		
		
		
		Contact contactNoServiceSLA = contacts[0];
		contactNoServiceSLA.account = accountNoServiceSLA;
		
		Contact contactWithServiceSLASMB = contacts[1];
		contactWithServiceSLASMB.account = accountWithServiceSLASMB;
		
		Contact contactWithServiceSLAGold = contacts[2];
		contactWithServiceSLAGold.account = accountWithServiceSLAGold;
		
		Contact contactWithoutAccount = contacts[3];
		contactWithoutAccount.account = null;
		
		//Generate Cases with Account data
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);	
		
		for(Case tempCase : cases){
			tempCase.OwnerId = userId;
		}

		Case c1 = cases[0]; 
		c1.ContactId = contactNoServiceSLA.Id; 
		
		Case c2 = cases[1];
		c2.ContactId = contactNoServiceSLA.Id; 
		
		Case c3 = cases[2];
		c3.ContactId = contactWithServiceSLASMB.Id; 
		
		Case c4 = cases[3];
		c4.ContactId = contactWithServiceSLAGold.Id; 
		
		Case c5 = cases[4];
		c5.ContactId = contactWithServiceSLASMB.Id; 

		Case c6 = null;

		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		if(ssswRecTypes.size()>0){
			Id recTypeId = ssswRecTypes.iterator().next(); 
			c1.recordTypeId = recTypeId;
			c2.recordTypeId = recTypeId;
			c3.recordTypeId = recTypeId;
			c4.recordTypeId = recTypeId;
			c5.recordTypeId = recTypeId;
		}

		List<Case> casesInsert = new List<Case>();
		casesInsert.add(c1);
		casesInsert.add(c2);
		casesInsert.add(c3);

		
		Set<Id> nonSSSWRecTypes = Utility.searchRecordTypes(String.valueOf(Case.getsObjectType()),'StarTrack','DeveloperName');
		if(nonSSSWRecTypes.size()>0){ //Case with non-SSSW recordtype
			c6 = cases[5];
			c6.RecordTypeId = nonSSSWRecTypes.iterator().next(); 
			casesInsert.add(c6);
		}


		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true),
			cases[5].clone(true)
		};

		oldCases[0].ContactId = contactWithServiceSLASMB.Id; //Contact change: no Account
		oldCases[1].ContactId = contactWithServiceSLASMB.Id; //Contact change: With SLA > No SLA
		oldCases[2].ContactId = contactNoServiceSLA.Id; //Contact change: No SLA > With SLA
		oldCases[3].ContactId = contactWithServiceSLASMB.Id; //Contact change: With SLA > With different SLA (SMB > Gold)
		oldCases[4].ContactId = contactWithServiceSLASMB.Id; //Contact NOT changed
		oldCases[5].ContactId = contactWithServiceSLASMB.Id; //Case is not SSSW

		// =====================================
		// Stubbing
		// =====================================
		

		ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Contact>(contacts));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();

		module.onBeforeInsert((List<SObject>) casesInsert, mockUow);
		module.onBeforeUpdate((List<SObject>) cases, new Map<Id, Case>(oldCases), mockUow);

		Test.stopTest();

		//Asserts for Insert
		System.assertEquals(CaseSkillBasedRoutingModule.SERVICESLA_CONSUMER, c1.CustomerQueueType__c, 'The expected CustomerQueueType for Cases without an Account is incorrect');
		System.assertEquals(CaseSkillBasedRoutingModule.SERVICESLA_CONSUMER, c2.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account without ServiceSLA is incorrect');
		System.assertEquals('SMB', c3.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account with ServiceSLA is incorrect');
		if(c6 != null){
			System.assertEquals(null, c6.CustomerQueueType__c, 'The expected CustomerQueueType for non-SSSW Cases is incorrect');
		}

		//Asserts for Update		
		System.assertEquals('Consumer',c1.CustomerQueueType__c, 'The expected CustomerQueueType for Cases without an Account is incorrect');
		System.assertEquals('Consumer',c2.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account without ServiceSLA is incorrect');
		System.assertEquals('SMB',c3.CustomerQueueType__c, 'The expected CustomerQueueType for Cases updated to an Account with ServiceSLA is incorrect');
		System.assertEquals('Gold',c4.CustomerQueueType__c,'The expected CustomerQueueType for Cases updated to an Account with different ServiceSLA is incorrect');
		System.assertEquals(null,c5.CustomerQueueType__c, 'Cases where AccountId does not change should have no change to its CustomerQueueType');

	}

	/**
	 * test the Exception handling on the module onBeforeInsert and onBeforeUpdate methods
	 */
	@isTest
	static void testExceptionHandling(){

		// =====================================
		// Data Preparation
		// =====================================
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		 // =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();
		module.onBeforeInsert(null,null);
		module.onBeforeUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert and onBeforeUpdate
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 2)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}


	/**
	 * Tests the logic in method CaseSkillBasedRoutingModule.assignToPreferredAgent.
	 * Scenarios:
	 * a) PSR inserted with correct PreferredUserId
	 * b) PSR not inserted - no AgentWork exists
	 * c) PSR not inserted - BypassPreferredAgent is true
	 * d) PSR not inserted - PreferredAgentExpiry is blank
	 * 
	 */
	@isTest
	static void assignToPreferredAgent(){

		//Queues
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject preferredAgentQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Preferred_Agent_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.PreferredAgentQueueId__c = preferredAgentQueue.QueueId;
		Insert custSetting;
		Id preferredAgentQueueId = preferredAgentQueue.QueueId;

		Group omniQueue = OmniChannelService.Cache.queuesWithRoutingConfig.values()[0].queue;		

		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		users[0].IsActive = true;	
		
		//DateTime
		DateTime oneHourFromNow = DateTime.now().addHours(1);

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(4, true);	
		Map<Id, Case> allCases = new Map<Id, Case>(cases);

		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		if(ssswRecTypes.size()>0){
			Id recTypeId = ssswRecTypes.iterator().next(); 
			cases[0].recordTypeId = recTypeId;
			cases[1].recordTypeId = recTypeId;
			cases[2].recordTypeId = recTypeId;
			cases[3].recordTypeId = recTypeId;
		}

		cases[0].OwnerId = omniQueue.Id; //a) PSR inserted with correct PreferredUserId
		cases[0].Priority = 'Low';
		cases[0].BypassPreferredAgent__c = false;
		cases[0].PreferredAgentExpiry__c = oneHourFromNow;

		cases[1].OwnerId = omniQueue.Id; //b) PSR not inserted - no Accepted Agent Work exists
		cases[1].BypassPreferredAgent__c = false;
		cases[1].PreferredAgentExpiry__c = oneHourFromNow;

		cases[2].OwnerId = omniQueue.Id; //c) PSR not inserted - BypassPreferredAgent is true
		cases[2].BypassPreferredAgent__c = true;
		cases[2].PreferredAgentExpiry__c = oneHourFromNow;

		cases[3].OwnerId = omniQueue.Id; //d) PSR not inserted - PreferredAgentExpiry is blank
		cases[3].BypassPreferredAgent__c = false;
		cases[3].PreferredAgentExpiry__c = null;

		

		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true)
		};
		for(Case tempCase : oldCases){
			tempCase.OwnerId = users[0].Id;
		}

		//AgentWorks
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(3, users[0].Id, new Set<Id>{cases[0].Id, cases[2].Id, cases[3].Id}, true);

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector) MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWorkWithActiveUser(
			(Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id,cases[1].Id})
		)).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );

		MockUtility.Mocks.when(mockUow.registerNew(
			(List<PendingServiceRouting>)fflib_Match.anyList()
		)).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();		
		module.onBeforeUpdate(cases, new Map<Id,Case>(oldCases), mockUow);

		Test.stopTest();

		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1)))
			.registerNew((List<PendingServiceRouting>)fflib_Match.anyList());

		// PMD warning
		System.assertEquals(preferredAgentQueueId, cases[0].OwnerId, 'Case should be assigned to Preferred Agent Queue');
		System.assertEquals(omniQueue.Id, cases[1].OwnerId, 'Case without accepted AgentWork should be assigned to Omni Queue');
		System.assertEquals(users[0].Id, ((PendingServiceRouting)MockUtility.mockUnitOfWorkDMLs[0]).PreferredUserId, 'Inserted PSR should have the correct PreferredUserId assigned');
	}

}