/**
 * @description Test class to cover CaseRoutingService
 * @author Nathan Franklin
 * @date 2023-05-26
 * @changelog
 * 2024-07-19 - Ranjeewa Silva - Added tests to verify routing and preferred agent override logic for Unified cases.
 * 2024-09-10 - Ranjeewa Silva - New test to verify moving unified cases in monitoring queue to closed cases queue on closure.
 */
@IsTest
private class CaseRoutingService_Test {

	private static final String ADMIN_PROFILE = 'System Administrator';
	private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';

	private static Map<String, Id> queues {
		get {
			if(queues == null) {
				queues = new Map<String, Id>();
				Set<String> queueNames = new Set<String>{
					'SSSW_BOH_Group_4', 'SSSW_Routing_Holding_Queue', 'SSSW_Closed_Omnichannel_Cases', 
					'SSSW_Routing_Preferred_Agent_Queue', 'SSSW_FOH_Group_1', 'SSSW_BOH_Group_1', 'SSSW_BOH_Group_2', 'SSSW_BOH_Group_4', 'SSSW_BOH_Group_3',
					'UnifiedCustomerServiceCaseQueue', 'UnifiedCustomerServiceMonitoringQueue'
				};

				List<QueueSObject> records = [SELECT QueueId, Queue.DeveloperName FROM QueueSobject WHERE Queue.DeveloperName IN :queueNames AND SobjectType = 'Case'];
				for(QueueSObject record : records) {
					queues.put(record.Queue.DeveloperName, record.QueueId);
				}
			}
			return queues;
		}
		private set;
	}

	private static Id routingRuleRecordTypeId {
		get {
			if(routingRuleRecordTypeId == null) {
				routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
			}
			return routingRuleRecordTypeId;
		}
		private set;
	}

	private static Id descriptionRuleRecordTypeId {
		get {
			if(descriptionRuleRecordTypeId == null) {
				descriptionRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWDescription'].Id;
			}
			return descriptionRuleRecordTypeId;
		}
		private set;
	}

	private static Id unifiedRoutingRuleRecordTypeId {
		get {
			if(unifiedRoutingRuleRecordTypeId == null) {
				unifiedRoutingRuleRecordTypeId = SObjectType.SSSWRouting__c.getRecordTypeInfosByDeveloperName().get(SSSWConstants.SSSWROUTING_RECTYPE_UNIFIEDROUTING).getRecordTypeId();
			}
			return unifiedRoutingRuleRecordTypeId;
		}
		private set;
	}

	@TestSetup
	public static void setup() {
		//For tests where cases are put in a holding queue to fetch articles and re-route the case asyncronously
		QM__c custSetting = QM__c.getOrgDefaults();

		custSetting.HoldingQueueId__c = queues.get('SSSW_Routing_Holding_Queue');
		custSetting.DefaultOmniQueueId__c = queues.get('SSSW_BOH_Group_4');
		custSetting.ClosedQueueId__c = queues.get('SSSW_Closed_Omnichannel_Cases');
		custSetting.PreferredAgentQueueId__c = queues.get('SSSW_Routing_Preferred_Agent_Queue');
		custSetting.PreferredAgentSkillDeveloperNames__c = 'BOH';
		custSetting.UnifiedDefaultOmniQueueId__c = queues.get('UnifiedCustomerServiceCaseQueue');
		custSetting.UnifiedDefaultMonitoringQueueId__c = queues.get('UnifiedCustomerServiceMonitoringQueue');
		custSetting.UnifiedPreferredAgentExpiry__c = 1;
		insert custSetting;

		List<SSSWRouting__c> insertable = new List<SSSWRouting__c>();

		insertable.add(new SSSWRouting__c(RecordTypeId = routingRuleRecordTypeId, Match_Rules_On__c = 'All', Origin__c = 'Email', 
											CaseType__c = 'Investigation', IsActive__c = true, Queue_ID__c = queues.get('SSSW_FOH_Group_1'), Sequence__c = 1));

		insertable.add(new SSSWRouting__c(RecordTypeId = routingRuleRecordTypeId, Match_Rules_On__c = 'All', Origin__c = 'Phone', 
											CaseType__c = 'Investigation', IsActive__c = true, Queue_ID__c = queues.get('SSSW_BOH_Group_2'), Sequence__c = 2));

		insertable.add(new SSSWRouting__c(RecordTypeId = routingRuleRecordTypeId, Match_Rules_On__c = 'All', Origin__c = 'Social',
											SocialPostTags__c = 'post tag1;post tag2', IsActive__c = true, Queue_ID__c = queues.get('SSSW_BOH_Group_3'), Sequence__c = 3));

		insertable.add(new SSSWRouting__c(RecordTypeId = descriptionRuleRecordTypeId, Match_Rules_On__c = 'All', Origin__c = 'Phone', 
											CaseType__c = 'Investigation', IsActive__c = true, DefaultCaseDetails__c = 'Testing 123', Sequence__c = 1));
											//caseSSSWDeliveryRecordType caseSSSWGeneralEnquiryRecordType

		// currently, for H1, we only have one unified case queue enabled for omni channel. this is configured as the default queue
		// in custom setting QM__c.UnifiedDefaultOmniQueueId__c. setting a non-omni queue here for the rule for testing.
		insertable.add(new SSSWRouting__c(RecordTypeId = unifiedRoutingRuleRecordTypeId, Match_Rules_On__c = 'All', Origin__c = 'Phone',
				CaseType__c = 'Investigation', IsActive__c = true, Queue_ID__c = queues.get('UnifiedCustomerServiceMonitoringQueue'), Sequence__c = 1));

		insert insertable;
	}

	/**
	 * Scenario: Ensures a case is routed correctly when it has been flagged for routing
	 */
	@isTest
	public static void testEnsureCaseIsRoutedHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;

		cases[1].OwnerId = UserInfo.getUserId();
		cases[1].Status = 'New';
		cases[1].Type = 'Investigation';
		cases[1].Origin = 'Phone';
		cases[1].Comment__c = '';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[1].AllocateToQueue__c = true;

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;
		casesOld[1].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(false, cases[0].Comment__c.contains('routing bypassed'));
		System.assertEquals(false, cases[0].Comment__c.contains('routing forced'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[0].OwnerId);

		System.assertEquals(false, cases[1].AllocateToQueue__c);
		System.assertEquals(false, cases[1].Comment__c.contains('routing bypassed'));
		System.assertEquals(false, cases[1].Comment__c.contains('routing forced'));
		System.assertEquals(queues.get('SSSW_BOH_Group_2'), cases[1].OwnerId);
		
	}

	/**
	 * Scenario: Ensures a case description is populated when empty
	 */
	@isTest
	public static void testDescriptionHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].Description = '';
		cases[0].Origin = 'Phone';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = false;

		cases[1].OwnerId = UserInfo.getUserId();
		cases[1].Status = 'New';
		cases[1].Type = 'Investigation';
		cases[1].Description = '';
		cases[1].Origin = 'Email';
		cases[1].Comment__c = '';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[1].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, null, true);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(UserInfo.getUserId(), cases[0].OwnerId);
		System.assertEquals('Testing 123', cases[0].Description);

		System.assertEquals(false, cases[1].AllocateToQueue__c);
		System.assertEquals(UserInfo.getUserId(), cases[1].OwnerId);
		System.assertEquals('', cases[1].Description);
		
	}

	/**
	 * Scenario: Ensures that the default owner is set when there no match with the routing rules
	 */
	@isTest
	public static void testEnsureDefaultOwnerIsSetWhenNoRuleWasMatched() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Feedback';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Chat';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(false, cases[0].Comment__c.contains('routing bypassed'));
		System.assertEquals(false, cases[0].Comment__c.contains('routing forced'));
		System.assertEquals(true, cases[0].Comment__c.contains('default routing rule hit'));
		System.assertEquals(queues.get('SSSW_BOH_Group_4'), cases[0].OwnerId);
		
	}

	/**
	 * Scenario: Ensures case routing is bypassed when needed
	 */
	@isTest
	public static void testEnsureCaseRoutingIsByPassedWhenNeeded() {

		// =====================================
		// Data Preparation
		// =====================================
		User ssswAgent = [Select Id From User Where Profile.Name = 'SSSW - Service Agent' And IsActive = true LIMIT 1];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		cases.add(cases[0].clone());
		cases.add(cases[0].clone());
		cases.add(cases[0].clone());
		cases.add(cases[0].clone());
		cases.add(cases[0].clone());
		cases.add(cases[0].clone());

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[2].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[3].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[4].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[5].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[6].Id = fflib_IDGenerator.generate(Case.SObjectType);

		cases[5].AllocateToQueue__c = false;
		cases[6].AllocateToQueue__c = false;

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true), cases[3].clone(true), cases[4].clone(true), cases[5].clone(true), cases[6].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;
		casesOld[1].AllocateToQueue__c = false;
		casesOld[2].AllocateToQueue__c = false;
		casesOld[3].AllocateToQueue__c = false;
		casesOld[4].AllocateToQueue__c = false;

		// set up specific scenario data

		// bypass routing since preferred agent routing hasn't expired
		cases[0].OwnerId = queues.get('SSSW_Routing_Preferred_Agent_Queue');
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);

		// case is permanently closed
		cases[1].Permanent_Close__c = true;
		cases[1].Status = 'Closed';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true});

		// case is in holding queue meaning it's currently waiting for a previous routing request to resolve
		cases[2].OwnerId = queues.get('SSSW_Routing_Holding_Queue');

		// case is owned by contact centre agent and case is opened
		// (no case stealing allowed)
		cases[3].OwnerId = ssswAgent.Id;
		cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[3], new Map<String, Object>{'Case_Owner_User_Profile_Name__c' => 'SSSW - Service Agent'});

		// case was just closed and was owner by an omni queue
		// move the case out to the closed omni cases queue
		cases[4].OwnerId = queues.get('SSSW_BOH_Group_2');
		cases[4].Status = 'Closed';
		cases[4] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[4], new Map<String, Object>{'IsClosed' => true});
		
		// case was closed and now it's opened... force routing to occur
		cases[5].OwnerId = queues.get('SSSW_Closed_Omnichannel_Cases');
		casesOld[5].OwnerId = queues.get('SSSW_Closed_Omnichannel_Cases');
		casesOld[5].Status = 'Closed';
		casesOld[5] = (Case)ApplicationTestDataFactory.setUnwritableFields(casesOld[5], new Map<String, Object>{'IsClosed' => true});

		// case was moved to a New status
		casesOld[6].Status = 'In Progress';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(true, cases[0].Comment__c.contains('routing bypassed'));
		System.assertEquals(queues.get('SSSW_Routing_Preferred_Agent_Queue'), cases[0].OwnerId);

		System.assertEquals(false, cases[1].AllocateToQueue__c);
		System.assertEquals(true, cases[1].Comment__c.contains('routing bypassed'));
		System.assertEquals(UserInfo.getUserId(), cases[1].OwnerId);

		System.assertEquals(false, cases[2].AllocateToQueue__c);
		System.assertEquals(true, cases[2].Comment__c.contains('routing bypassed'));
		System.assertEquals(queues.get('SSSW_Routing_Holding_Queue'), cases[2].OwnerId);

		System.assertEquals(false, cases[3].AllocateToQueue__c);
		System.assertEquals(true, cases[3].Comment__c.contains('routing bypassed'));
		System.assertEquals(ssswAgent.Id, cases[3].OwnerId);

		System.assertEquals(false, cases[4].AllocateToQueue__c);
		System.assertEquals(true, cases[4].Comment__c.contains('routing bypassed'));
		System.assertEquals(queues.get('SSSW_Closed_Omnichannel_Cases'), cases[4].OwnerId);

		// case should have been routed
		System.assertEquals(false, cases[5].AllocateToQueue__c);
		System.assertEquals(true, cases[5].Comment__c.contains('routing initiated'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[5].OwnerId);

		// case should have been routed
		System.assertEquals(false, cases[6].AllocateToQueue__c);
		System.assertEquals(true, cases[6].Comment__c.contains('rerouting case moved to New'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[6].OwnerId);
		
	}

	/**
	 * Scenario: Ensures case routing bypasses are ignored if we are force routing a case
	 */
	@isTest
	public static void testEnsureCaseRoutingBypassesAreIgnoredWhenNeeded() {

		// =====================================
		// Data Preparation
		// =====================================
		User ssswAgent = [Select Id From User Where Profile.Name = 'SSSW - Service Agent' And IsActive = true LIMIT 1];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		cases.add(cases[0].clone());
		cases.add(cases[0].clone());
		cases.add(cases[0].clone());

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[2].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[3].Id = fflib_IDGenerator.generate(Case.SObjectType);

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true), cases[3].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;
		casesOld[1].AllocateToQueue__c = false;
		casesOld[2].AllocateToQueue__c = false;
		casesOld[3].AllocateToQueue__c = false;

		// set up specific scenario data

		// preferred agent routing hasn't expired
		CaseRoutingService.getInstance().addCaseBypassToRoutingEligibility(cases[0].Id, 'Just because1');
		cases[0].OwnerId = queues.get('SSSW_Routing_Preferred_Agent_Queue');
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);

		// case is permanently closed
		CaseRoutingService.getInstance().addCaseBypassToRoutingEligibility(cases[1].Id, 'Just because2');
		cases[1].Permanent_Close__c = true;
		cases[1].Status = 'Closed';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true});

		// case is in holding queue meaning it's currently waiting for a previous routing request to resolve
		CaseRoutingService.getInstance().addCaseBypassToRoutingEligibility(cases[2].Id, 'Just because3');
		cases[2].OwnerId = queues.get('SSSW_Routing_Holding_Queue');

		// case is owned by contact centre agent and case is opened
		// (no case stealing allowed)
		CaseRoutingService.getInstance().addCaseBypassToRoutingEligibility(cases[3].Id, 'Just because4');
		cases[3].OwnerId = ssswAgent.Id;
		cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[3], new Map<String, Object>{'Case_Owner_User_Profile_Name__c' => 'SSSW - Service Agent'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(true, cases[0].Comment__c.contains('routing forced'));
		System.assertEquals(true, cases[0].Comment__c.contains('Just because1'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[0].OwnerId);

		System.assertEquals(false, cases[1].AllocateToQueue__c);
		System.assertEquals(true, cases[1].Comment__c.contains('routing forced'));
		System.assertEquals(true, cases[1].Comment__c.contains('Just because2'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[1].OwnerId);

		System.assertEquals(false, cases[2].AllocateToQueue__c);
		System.assertEquals(true, cases[2].Comment__c.contains('routing forced'));
		System.assertEquals(true, cases[2].Comment__c.contains('Just because3'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[2].OwnerId);

		System.assertEquals(false, cases[3].AllocateToQueue__c);
		System.assertEquals(true, cases[3].Comment__c.contains('routing forced'));
		System.assertEquals(true, cases[3].Comment__c.contains('Just because4'));
		System.assertEquals(queues.get('SSSW_FOH_Group_1'), cases[3].OwnerId);
		
	}

	/**
	 * Scenario: When bypass routing rules on creation field is set then routing rules should be ignored
	 */
	@isTest
	public static void testEnsureCaseRoutingRulesAreByPassedOnCreationWhenNeeded() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].ByPassRoutingRulesOnCreation__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, null, true);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(true, cases[0].Comment__c.contains('routing bypassed'));
		System.assertEquals(UserInfo.getUserId(), cases[0].OwnerId);
		
	}

	/**
	 * Scenario: When a case is closed and sits in an Omni queue, we move it to a generic close cases queue to stop it popping up on agents
	 */
	@isTest
	public static void testEnsureCaseIsMovedToOmniClosedCaseOnClosure() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_BOH_Group_1');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case is closed
		cases[0].Status = 'Closed';
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'IsClosed' => true});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeMoveClosedOmniCases(cases, casesOldMap);

		Test.stopTest();

		System.assertEquals(queues.get('SSSW_Closed_Omnichannel_Cases'), cases[0].OwnerId);
		
	}

	/**
	 * Scenario: When the case owner is changed and the current owner is not preferred agent queue, then we need to make sure the pendingservicerouting record is tidied up
	 * 				The record should only exist if the case was previously in preferred agent queue, however, we put a check in to always make sure as a general tidyup
	 */
	@isTest
	public static void testEnsurePSRRecordsAreClearedWhenTheyNeedToBe() {

		// =====================================
		// Data Preparation
		// =====================================
		ServiceChannel serviceChannelRecord = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'Case'][0];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_BOH_Group_1');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		cases.add(cases[0].clone());

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case belonged to prefer agent queue
		casesOld[0].OwnerId = queues.get('SSSW_Routing_Preferred_Agent_Queue');

		// case was closed
		cases[1].Status = 'Closed';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true});

		List<PendingServiceRouting> psrRecords = ApplicationTestDataFactoryCase.getPendingServiceRoutings(2, serviceChannelRecord.Id, queues.get('SSSW_Routing_Preferred_Agent_Queue'), new List<Id>{cases[0].Id, cases[1].Id}, true);

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(psrRecords);
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRemovePendingServiceRoutingPreferredAgentRecords(cases, casesOldMap, false);

		Test.stopTest();

		// make sure that our search method was called
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), fflib_Match.anyBoolean());
		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(new Set<Id>{cases[0].Id, cases[1].Id}, searchParams.get('workItemIds'));
		System.assertEquals(true, searchParams.get('isPreferredUserRequiredOnly'));

		fflib_ArgumentCaptor deleteCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)deleteCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> deletedRecords = (List<SObject>)deleteCaptor.getValue();
		System.assertEquals(psrRecords[0].Id, deletedRecords[0].Id);
		System.assertEquals(psrRecords[1].Id, deletedRecords[1].Id);
	}

	/**
	 * Scenario: Ensures secondary priority is calculated when needed to
	 */
	@isTest
	public static void testEnsureSecondaryRoutingPriorityIsCalculated() {

		// =====================================
		// Data Preparation
		// =====================================
		ServiceChannel serviceChannelRecord = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'Case'][0];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_BOH_Group_1');
		cases[0].Status = 'New';
		cases[0].Priority = 'High';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;

		cases.add(cases[0].clone());

		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'CreatedDate' => Datetime.now()});

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'CreatedDate' => Datetime.now()});

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].OwnerId = queues.get('SSSW_Routing_Preferred_Agent_Queue');
		casesOld[1].Priority = 'Medium';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRecalculateSecondaryRoutingPriority(cases, casesOldMap);

		Test.stopTest();

		System.assert(!String.isEmpty(cases[0].OmniRoutingSecondaryPriority__c), 'Case: ' + cases[0]);
		System.assert(!String.isEmpty(cases[1].OmniRoutingSecondaryPriority__c), 'Case: ' + cases[1]);
	}

	/**
	 * Scenario: When a case is routed to an omni queue, we perform a check to see whether the case could be assigned to a specific agent
	 * 				This ensures that check occurs
	 */
	@isTest
	public static void testEnsurePreferredAgentQueueOverridesOmniQueueWhenNeeded() {

		// =====================================
		// Data Preparation
		// =====================================
		User ssswAgent = [Select Id From User Where Profile.Name = 'SSSW - Service Agent' And IsActive = true LIMIT 1];

		ServiceChannel serviceChannelRecord = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'Case'][0];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_BOH_Group_1');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);
		cases[0].BypassPreferredAgent__c = false;

		cases.add(cases[0].clone());
		cases.add(cases[0].clone());

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[2].Id = fflib_IDGenerator.generate(Case.SObjectType);

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case changed owner to omni queue
		casesOld[0].OwnerId = UserInfo.getUserId();

		// case was closed - bypassed
		cases[1].Status = 'Closed';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true, 'CreatedDate' => Datetime.now()});

		// case is enforcing a bypass on preferred agent
		casesOld[2].OwnerId = UserInfo.getUserId();
		cases[2].BypassPreferredAgent__c = true;

		List<AgentWork> agentWorks = ApplicationTestDataFactoryCase.getAgentWorks(1, ssswAgent.Id, new Set<Id>{cases[0].Id}, true);

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWork((Map<Id, SObject>)fflib_Match.eq(new Map<Id, Case>{cases[0].Id => cases[0]}), fflib_Match.eqBoolean(true))).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );
		MockUtility.Mocks.when(mockOmniChannelService.verifyEligibilityForOmniChannelQueues((Map<Id, Set<Id>>)fflib_Match.eq(new Map<Id, Set<Id>>{cases[0].OwnerId => new Set<Id>{ssswAgent.Id}}))).thenReturn(new Map<Id, Set<Id>>{cases[0].OwnerId => new Set<Id>{ssswAgent.Id}});
		MockUtility.Mocks.when(mockSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>()); // return nothing
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeOverrideWithPreferredAgentRouting(cases, casesOldMap);

		Test.stopTest();

		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		fflib_ArgumentCaptor insertCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)insertCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> insertedRecords = (List<SObject>)insertCaptor.getValue();

		PendingServiceRouting insertedPsrRecord = (PendingServiceRouting)insertedRecords[0];

		System.assertEquals(cases[0].Id, insertedPsrRecord.WorkItemId);
		System.assertEquals(ssswAgent.Id, insertedPsrRecord.PreferredUserId);
		System.assertEquals(true, cases[0].Comment__c.contains('preferred agent queue assigned'));
		System.assertEquals(1, insertedRecords.size());
	}

	/**
	 * Scenario: If the old owner was preferred agent routing and now it's changed or if the case is closed, then we need to ensure the preferred agent flags are reset so that our other logic will work as expected
	 */
	@isTest
	public static void testEnsurePreferredAgentBypassesAreReset() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_BOH_Group_1');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);
		cases[0].BypassPreferredAgent__c = true;

		cases.add(cases[0].clone());
		cases.add(cases[0].clone());

		cases[1].Id = fflib_IDGenerator.generate(Case.SObjectType);
		cases[2].Id = fflib_IDGenerator.generate(Case.SObjectType);

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// bypasses should be reset
		casesOld[0].OwnerId = queues.get('SSSW_Routing_Preferred_Agent_Queue');

		// bypasses should be reset
		cases[1].Status = 'Closed';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true, 'CreatedDate' => Datetime.now()});

		// this one shoudl be ignored
		casesOld[2].OwnerId = UserInfo.getUserId();
		cases[2].BypassPreferredAgent__c = true;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeResetPreferredAgentBypasses(cases, casesOldMap);

		Test.stopTest();

		System.assertEquals(false, cases[0].BypassPreferredAgent__c);
		System.assertEquals(null, cases[0].PreferredAgentExpiry__c);

		System.assertEquals(false, cases[1].BypassPreferredAgent__c);
		System.assertEquals(null, cases[1].PreferredAgentExpiry__c);

		System.assertEquals(true, cases[2].BypassPreferredAgent__c);
		System.assertNotEquals(null, cases[2].PreferredAgentExpiry__c);
	}

	/**
	 * Scenario: 1. Route case (we are moving from a closed case to an open case)
	 * 			2. Force the case to go to preferred agent
	 */
	@isTest
	public static void testEnsureEndToEndWithPreferredAgentOverride() {

		// =====================================
		// Data Preparation
		// =====================================
		User ssswAgent = [Select Id From User Where Profile.Name = 'SSSW - Service Agent' And IsActive = true LIMIT 1];

		ServiceChannel serviceChannelRecord = [SELECT Id FROM ServiceChannel WHERE RelatedEntity = 'Case'][0];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_Closed_Omnichannel_Cases');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);
		cases[0].BypassPreferredAgent__c = false;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'CreatedDate' => Datetime.now()});

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case was closed
		casesOld[0].Status = 'Closed';
		casesOld[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(casesOld[0], new Map<String, Object>{'IsClosed' => true});

		List<AgentWork> agentWorks = ApplicationTestDataFactoryCase.getAgentWorks(1, ssswAgent.Id, new Set<Id>{cases[0].Id}, true);

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWork((Map<Id, SObject>)fflib_Match.eq(new Map<Id, Case>(cases)), fflib_Match.eqBoolean(true))).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );
		MockUtility.Mocks.when(mockOmniChannelService.verifyEligibilityForOmniChannelQueues((Map<Id, Set<Id>>)fflib_Match.eq(new Map<Id, Set<Id>>{queues.get('SSSW_FOH_Group_1') => new Set<Id>{ssswAgent.Id}}))).thenReturn(new Map<Id, Set<Id>>{queues.get('SSSW_FOH_Group_1') => new Set<Id>{ssswAgent.Id}});
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<PendingServiceRouting>());
		MockUtility.Mocks.when(mockSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>()); // return nothing
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().routeCase(cases, casesOldMap, false);

		Test.stopTest();

		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		fflib_ArgumentCaptor insertCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)insertCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> insertedRecords = (List<SObject>)insertCaptor.getValue();

		PendingServiceRouting insertedPsrRecord = (PendingServiceRouting)insertedRecords[0];

		// check to make sure case was routed
		System.assertEquals(true, cases[0].Comment__c.contains('routed:'));

		// check to make sure case was assigned to preferred agent queue
		System.assertEquals(true, cases[0].Comment__c.contains('preferred agent queue assigned'));

		System.assertEquals(cases[0].Id, insertedPsrRecord.WorkItemId);
		System.assertEquals(queues.get('SSSW_Routing_Preferred_Agent_Queue'), cases[0].OwnerId);
		System.assertEquals(ssswAgent.Id, insertedPsrRecord.PreferredUserId);
		System.assertEquals(1, insertedRecords.size());
	}

	/**
	 * Scenario: Ensures a social case is routed correctly when it has been flagged for routing
	 */
	@isTest
	public static void testEnsureSocialCaseIsRoutedHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].SocialPostTags__c = 'post tag1';
		cases[0].Type = 'Feedback';
		cases[0].Origin = 'Social';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = true;

		cases[1].OwnerId = UserInfo.getUserId();
		cases[1].Status = 'New';
		cases[1].Type = 'Feedback';
		cases[1].SocialPostTags__c = 'post tag2';
		cases[1].Origin = 'Social';
		cases[1].Comment__c = '';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[1].AllocateToQueue__c = true;

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;
		casesOld[1].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(false, cases[0].AllocateToQueue__c);
		System.assertEquals(false, cases[0].Comment__c.contains('routing bypassed'));
		System.assertEquals(false, cases[0].Comment__c.contains('routing forced'));
		System.assertEquals(queues.get('SSSW_BOH_Group_3'), cases[0].OwnerId);

		System.assertEquals(false, cases[1].AllocateToQueue__c);
		System.assertEquals(false, cases[1].Comment__c.contains('routing bypassed'));
		System.assertEquals(false, cases[1].Comment__c.contains('routing forced'));
		System.assertEquals(queues.get('SSSW_BOH_Group_3'), cases[1].OwnerId);
		
	}

	/**
	 * Scenario: Makes sure that routing is triggered for a parent case when the child case receives an update
	 */
	@isTest
	public static void testEnsureParentCaseIsUpdatedWhenChildCaseIsUpdated() {

		// =====================================
		// Data Preparation
		// =====================================
		Case parentCase = ApplicationTestDataFactory.getCases(1, true)[0];
		
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].ParentId = parentCase.Id;
		cases[0].Status = SSSWConstants.STAT_NETWORK_RESPONDED;
		cases[0].Type = 'Investigation';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[0].AllocateToQueue__c = false;

		cases[1].OwnerId = UserInfo.getUserId();
		cases[1].Status = SSSWConstants.STAT_NETWORK_RESPONDED;
		cases[1].Type = 'Investigation';
		cases[1].Origin = 'Phone';
		cases[1].Comment__c = '';
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		cases[1].AllocateToQueue__c = false;

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].Status = 'New';
		casesOld[1].Status = 'New';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().updateParentForRouting(cases, casesOldMap);

		Test.stopTest();

		fflib_ArgumentCaptor updateRecordsCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)updateRecordsCaptor.capture());
		List<SObject> updatedRecords = (List<SObject>)updateRecordsCaptor.getValue();
		
		System.assertEquals(1, updatedRecords.size());

		Case updatedParentCase = (Case)updatedRecords[0];
		System.assertEquals(parentCase.Id, updatedParentCase.Id);
		System.assertEquals(SSSWConstants.STAT_CHILD_CASE_UPDATE, updatedParentCase.Status);
		System.assertEquals(true, updatedParentCase.AllocateToQueue__c);
		
	}

	/**
	 * Scenario: Ensures a unified case is routed correctly when it has been flagged for routing
	 */
	@isTest
	public static void testEnsureUnifiedCaseIsRoutedHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].Origin = 'Phone';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[0].AllocateToQueue__c = true;

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		Assert.isFalse(cases[0].AllocateToQueue__c);
		Assert.isFalse(cases[0].Comment__c.contains('routing bypassed'));
		Assert.isFalse(cases[0].Comment__c.contains('routing forced'));
		Assert.areEqual(queues.get('UnifiedCustomerServiceMonitoringQueue'), cases[0].OwnerId);
	}

	/**
	 * Scenario: Ensures that the default owner is set on a unified case when there is no match with the routing rules
	 */
	@isTest
	public static void testEnsureUnifiedCaseDefaultOwnerIsSetWhenNoRuleWasMatched() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = UserInfo.getUserId();
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[0].AllocateToQueue__c = true;

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		casesOld[0].AllocateToQueue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		Assert.isFalse(cases[0].AllocateToQueue__c);
		Assert.isFalse(cases[0].Comment__c.contains('routing bypassed'));
		Assert.isFalse(cases[0].Comment__c.contains('routing forced'));
		Assert.isTrue(cases[0].Comment__c.contains('default routing rule hit'));
		Assert.areEqual(queues.get('UnifiedCustomerServiceCaseQueue'), cases[0].OwnerId);

	}

	/**
	 * Scenario: When a unified case is routed to an omni queue, we perform a check to see whether the case could be assigned
	 *			  to a specific agent. This ensures that check occurs for a unified case.
	 */
	@IsTest
	public static void testEnsureUnifiedCasePreferredAgentQueueOverridesOmniQueueWhenNeeded() {

		// =====================================
		// Data Preparation
		// =====================================
		User unifiedAgent = [SELECT Id FROM User WHERE Profile.Name = :SSSWConstants.UNIFIED_AGENT_PROFILE AND IsActive = TRUE LIMIT 1];

		List<Case> cases = ApplicationTestDataFactory.getCases(4, true);
		for (Case caseRecord: cases) {
			caseRecord.OwnerId = queues.get('UnifiedCustomerServiceCaseQueue');
			caseRecord.Status = 'New';
			caseRecord.Type = 'Investigation';
			caseRecord.ProductCategory__c = 'Domestic Parcels';
			caseRecord.ProductSubCategory__c = 'Express';
			caseRecord.EnquirySubType__c = 'Carding issue';
			caseRecord.Origin = 'Email';
			caseRecord.Comment__c = '';
			caseRecord.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
			caseRecord.AllocateToQueue__c = true;
			caseRecord.IsCR__c = false;
			caseRecord.IsHLC__c = false;
			caseRecord.PreferredAgentExpiry__c = Datetime.now().addDays(1);
			caseRecord.BypassPreferredAgent__c = false;
		}

		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'CreatedById' => unifiedAgent.Id});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'CreatedById' => unifiedAgent.Id});
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object>{'CreatedById' => unifiedAgent.Id});
		cases[3] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[3], new Map<String, Object>{'CreatedById' => unifiedAgent.Id});

		List<Case> casesOld = new List<Case>{cases[0].clone(true), cases[1].clone(true), cases[2].clone(true), cases[3].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case changed owner to omni queue, case has prior AgentWork.
		casesOld[0].OwnerId = UserInfo.getUserId();

		// case changed owner to omni queue, with no previous AgentWork. should still be routed to case creator as the preferred agent.
		casesOld[1].OwnerId = UserInfo.getUserId();

		// case was closed - bypassed
		cases[2].Status = 'Closed';
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'IsClosed' => true, 'CreatedDate' => Datetime.now()});

		// case is enforcing a bypass on preferred agent
		casesOld[3].OwnerId = UserInfo.getUserId();
		cases[3].BypassPreferredAgent__c = true;

		List<AgentWork> agentWorks = ApplicationTestDataFactoryCase.getAgentWorks(1, unifiedAgent.Id, new Set<Id>{cases[0].Id}, true);

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWork((Map<Id, SObject>)fflib_Match.eq(new Map<Id, Case>{cases[0].Id => cases[0], cases[1].Id => cases[1]}), fflib_Match.eqBoolean(true))).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );
		MockUtility.Mocks.when(mockOmniChannelService.verifyEligibilityForOmniChannelQueues((Map<Id, Set<Id>>)fflib_Match.eq(new Map<Id, Set<Id>>{queues.get('UnifiedCustomerServiceCaseQueue') => new Set<Id>{unifiedAgent.Id}}))).thenReturn(new Map<Id, Set<Id>>{queues.get('UnifiedCustomerServiceCaseQueue') => new Set<Id>{unifiedAgent.Id}});
		MockUtility.Mocks.when(mockSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>()); // return nothing
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeOverrideWithPreferredAgentRouting(cases, casesOldMap);

		Test.stopTest();

		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		fflib_ArgumentCaptor insertCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)insertCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> insertedRecords = (List<SObject>)insertCaptor.getValue();

		Assert.areEqual(2, insertedRecords.size());

		List<PendingServiceRouting> insertedPsrRecords = (List<PendingServiceRouting>)insertedRecords;
		Assert.areEqual(cases[0].Id, insertedPsrRecords[0].WorkItemId);
		Assert.areEqual(unifiedAgent.Id, insertedPsrRecords[0].PreferredUserId);
		Assert.isTrue(cases[0].Comment__c.contains('preferred agent queue assigned'));

		Assert.areEqual(cases[1].Id, insertedPsrRecords[1].WorkItemId);
		Assert.areEqual(unifiedAgent.Id, insertedPsrRecords[1].PreferredUserId);
		Assert.isTrue(cases[1].Comment__c.contains('preferred agent queue assigned'));

	}

	/**
	 * Scenario: When a unified case is closed and sits in monitoring queue, we move it to a generic close cases queue
	 */
	@isTest
	public static void testEnsureUnifiedCaseInMonitoringQueueIsMovedToOmniClosedCaseOnClosure() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0].OwnerId = queues.get('UnifiedCustomerServiceMonitoringQueue');
		cases[0].Status = 'Monitoring';
		cases[0].Type = 'Investigation';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case is closed
		cases[0].Status = 'Closed';
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'IsClosed' => true});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().maybeRouteCase(cases, casesOldMap, false);

		Test.stopTest();

		System.assertEquals(queues.get('SSSW_Closed_Omnichannel_Cases'), cases[0].OwnerId);

	}

	/**
	 * Scenario: 1. Route Unified case (we are moving from a closed case to an open case)
	 * 			2. Force the case to go to preferred agent
	 */
	@IsTest
	public static void testEnsureUnifiedCaseRoutingEndToEndWithPreferredAgentOverride() {

		// =====================================
		// Data Preparation
		// =====================================
		User unifiedAgent = [SELECT Id FROM User WHERE Profile.Name = :SSSWConstants.UNIFIED_AGENT_PROFILE AND IsActive = TRUE LIMIT 1];

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].OwnerId = queues.get('SSSW_Closed_Omnichannel_Cases');
		cases[0].Status = 'New';
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0].ProductSubCategory__c = 'Express';
		cases[0].EnquirySubType__c = 'Carding issue';
		cases[0].Origin = 'Email';
		cases[0].Comment__c = '';
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[0].AllocateToQueue__c = true;
		cases[0].IsCR__c = false;
		cases[0].IsHLC__c = false;
		cases[0].PreferredAgentExpiry__c = Datetime.now().addDays(1);
		cases[0].BypassPreferredAgent__c = false;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'CreatedDate' => Datetime.now()});

		List<Case> casesOld = new List<Case>{cases[0].clone(true)};
		Map<Id, Case> casesOldMap = new Map<Id, Case>(casesOld);

		// case was closed
		casesOld[0].Status = 'Closed';
		casesOld[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(casesOld[0], new Map<String, Object>{'IsClosed' => true});

		List<AgentWork> agentWorks = ApplicationTestDataFactoryCase.getAgentWorks(1, unifiedAgent.Id, new Set<Id>{cases[0].Id}, true);

		// =====================================
		// Stubbing
		// =====================================
		PendingServiceRoutingSelector mockSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWork((Map<Id, SObject>)fflib_Match.eq(new Map<Id, Case>(cases)), fflib_Match.eqBoolean(true))).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );
		MockUtility.Mocks.when(mockOmniChannelService.verifyEligibilityForOmniChannelQueues((Map<Id, Set<Id>>)fflib_Match.eq(new Map<Id, Set<Id>>{queues.get('UnifiedCustomerServiceCaseQueue') => new Set<Id>{unifiedAgent.Id}}))).thenReturn(new Map<Id, Set<Id>>{queues.get('UnifiedCustomerServiceCaseQueue') => new Set<Id>{unifiedAgent.Id}});
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<PendingServiceRouting>());
		MockUtility.Mocks.when(mockSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>()); // return nothing
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseRoutingService.getInstance().routeCase(cases, casesOldMap, false);

		Test.stopTest();

		((PendingServiceRoutingSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		fflib_ArgumentCaptor insertCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)insertCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> insertedRecords = (List<SObject>)insertCaptor.getValue();

		PendingServiceRouting insertedPsrRecord = (PendingServiceRouting)insertedRecords[0];

		// check to make sure case was routed
		Assert.isTrue(cases[0].Comment__c.contains('routed:'));

		// check to make sure case was assigned to preferred agent queue
		Assert.isTrue(cases[0].Comment__c.contains('preferred agent queue assigned'));

		Assert.areEqual(cases[0].Id, insertedPsrRecord.WorkItemId);
		Assert.areEqual(queues.get('SSSW_Routing_Preferred_Agent_Queue'), cases[0].OwnerId);
		Assert.areEqual(unifiedAgent.Id, insertedPsrRecord.PreferredUserId);
		Assert.areEqual(1, insertedRecords.size());
	}

}