/*** 
 * @author Noel Lim
 * @date 2022-09-23
 * @group Domain
 * @domain Routing 
 * @description Test class for CaseSkillBasedRoutingModule
 * @changelog
 * 2022-09-23 - Noel Lim - Created
 * 2022-02-08 - Noel Lim - Updated checkCaseSLABasedOnAccount() to assign case.OwnerIds, added method checkCaseAgentType 
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
	 * Check that the Case AgentType field is updated or cleared based on the Queue OwnerId having an AgentType mapping
	 */
	@IsTest
	static void checkCaseAgentType() { 
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		//OwnerIds
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		Id userId = users[0].Id;
		Id queueWithAgentTypeId;
		String agentType;
		
		//necessary for when the Org does not have any Custom Metadata records yet. This Custom Metadata relies on QueueId so it cannot be deployed via metadata
		if(OmnichannelService.Cache.QueuesToAgentType.isEmpty()){
			
			Group queueRec = ApplicationTestDataFactory.getGroups(1, true)[0];
			Schema.DescribeFieldResult agentTypeField = Case.AgentType__c.getDescribe();
			List<Schema.PicklistEntry> agentTypePickvals = agentTypeField.getPicklistValues();
			String agentTypeVal;
			for(Schema.PicklistEntry pe : agentTypePickvals){
				if(pe.IsActive()){
					agentTypeVal = pe.getValue();
					break;
				}
			}

			queueWithAgentTypeId = queueRec.Id;
			agentType = agentTypeVal;
			CacheManager.put('QUEUES_TO_AGENT_TYPE', new Map<String, String>{queueRec.Id => agentTypeVal});
		} else {
			queueWithAgentTypeId = OmniChannelService.Cache.queuesToAgentType.keySet().iterator().next();
			agentType = OmniChannelService.Cache.queuesToAgentType.get(queueWithAgentTypeId);
		}	

		
		
		//Generate Cases 
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);	

		cases[0].OwnerId = queueWithAgentTypeId;//set AgentType
		cases[1].OwnerId = userId; 				//no change
		cases[2].OwnerId = queueWithAgentTypeId;//set AgentType
		cases[3].OwnerId = userId; 				//clear AgentType
		cases[4].OwnerId = queueWithAgentTypeId; //no change

		List<Case> casesInsert = new List<Case>{cases[0], cases[1]};
		List<Case> casesUpdate = new List<Case>{cases[2], cases[3], cases[4]};


		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		if(ssswRecTypes.size()>0){
			Id recTypeId = ssswRecTypes.iterator().next(); 
			for(Case cs : cases){
				cs.RecordTypeId = recTypeId;
			}
		}


		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true)
		};

		oldCases[0].OwnerId = userId; 
		oldCases[1].OwnerId = queueWithAgentTypeId;
		oldCases[1].AgentType__c = agentType;
		oldCases[2].OwnerId = queueWithAgentTypeId;


		// =====================================
		// Stubbing
		// =====================================
		

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();

		module.onBeforeInsert((List<SObject>) casesInsert, mockUow);
		module.onBeforeUpdate((List<SObject>) casesUpdate, new Map<Id, Case>(oldCases), mockUow);

		Test.stopTest();

		//Asserts for Insert
		System.assertEquals(agentType, cases[0].AgentType__c, 'The AgentType is incorrect');
		System.assertEquals(null, cases[1].AgentType__c, 'The AgentType should be blank ');

		//Asserts for Update		
		System.assertEquals(agentType, cases[2].AgentType__c, 'The AgentType is incorrect');
		System.assertEquals(null, cases[3].AgentType__c, 'The AgentType should be blank ');
		System.assertEquals(null, cases[4].AgentType__c, 'The AgentType should have remained blank ');
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

}