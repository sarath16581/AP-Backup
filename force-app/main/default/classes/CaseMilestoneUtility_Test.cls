/**
 * @author	   : nandan.narasappa@auspost.com.au
 * @date		 : 15/10/2015
 * @description  : Test Class for CaseMilestoneUtility
 * @changelog
 * 14/05/2019		  gunith.devasurendra@auspost.com.au		  Fixed issue where Network Escalation emails don't have email addresses set (INC1370890)
 * 09/07/2019		  gunith.devasurendra@auspost.com.au		  Set Network Email 1 to Case Network Escalation Email in Level 1 (INC1370890)
 * 07/10/2021		  naveen.rajanna@auspost.com.au			   REQ2616056 Changed api version to 52
 * 2022-02-17 - Nathan Franklin - copied test for BGS entitlement assignment from another class
 * 2022-11-24	Noel Lim - updated testInternalEscalationScenario(), assert for taskCount from 1 to 2 as a temporary fix. Refer to assert for reasoning and technical details.
 * 2023-06-05	Mahesh Parvathaneni - Added tests testTransportEnquiryApplyDefaultEntitlement
 */
@isTest
private with sharing class CaseMilestoneUtility_Test {
	
	@testSetup static void testDataCreate() {
		insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
	}
	
	// Constants
	private static final String ADMIN_PROFILE = 'System Administrator';
	private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
	private static final String ENTITLEMENT_ACC = 'SSSW Entitlements';

	@IsTest
	static void testInitialisation() {
		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(1, true));
		SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess WHERE IsVersionDefault = true AND Name =: SSSWConstants.UNIFIED_ENTITLEMENTS LIMIT 1 ];
		List<Entitlement> entitlements = new List<Entitlement>(ApplicationTestDataFactory.getEntitlements(1, true,SSSWConstants.UNIFIED_ENTITLEMENTS,sla.Id,orgAaccounts[0].Id));
		EntitlementsSelector mockEntitlementSelector = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		RecordTypesSelector mockRecordTypesSelector = (RecordTypesSelector)MockUtility.mockSelector(RecordTypesSelector.class);
		Id expectedRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME).getRecordTypeId();
		Map<Id, RecordType> expectedRecordTypeIds = new Map<Id, RecordType>{
			expectedRecordTypeId => new RecordType(Id = expectedRecordTypeId, DeveloperName = SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME)
		};
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEntitlementSelector.selectByNameAndAccountName((Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}))).thenReturn(entitlements);
		MockUtility.Mocks.when(mockRecordTypesSelector.selectByDeveloperName(fflib_Match.eqString(String.valueOf(Case.getsObjectType())), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME}))).thenReturn(expectedRecordTypeIds);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();		
		CaseMilestoneUtility.initialiseStaticVariables();
		Test.stopTest();

		((EntitlementsSelector)MockUtility.Mocks.verify(mockEntitlementSelector, MockUtility.Mocks.times(1))).selectByNameAndAccountName((Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_ENTITLEMENTS}));
		System.assertEquals(entitlements[0].Id, CaseMilestoneUtility.UNIFIED_ENTITLEMENT_ID, 'should return the correct entitlement id');

		((RecordTypesSelector)MockUtility.Mocks.verify(mockRecordTypesSelector, MockUtility.Mocks.times(1))).selectByDeveloperName((String)fflib_Match.eqString(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME), (Set<String>)fflib_Match.eq(new Set<String>{SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME}));
		System.assertEquals(CaseMilestoneUtility.unifiedRecordTypes.contains(expectedRecordTypeId), true, 'Should contain the expected record type id');
	}	
	
	/**
	  * @description	   This method tests scenario of associating entitlement to case to trigger milestones
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testInsertMilestones(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Integer cs = [SELECT Count() FROM CaseMileStone WHERE CaseId =: csRec.Id];
			csRec = [SELECT SLATargetDate__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assert(cs > 0);
			System.assert(csRec.SLATargetDate__c != null);
		}
	}

	/**
	  * This method tests scenario of associating entitlement to case for Service Advisor BGS cases types
	  * NOTE: Given this is existing class, Mocks were not considered.
	  */
	@IsTest
	private static void testBGSApplyDefaultEntitlement(){

		TestUtility.createBGSDefaultEntitlementProcessData();

		List<Entitlement> entitlementList = EntitlementsSelector.newInstance().selectByNameAndAccountName(new Set<String>{BGSConstants.BGS_ENTITLEMENT_VIC}, new Set<String>{BGSConstants.BGS_ENTITLEMENT_STANDARD});

		List<RecordType> accountRecordTypes = RecordTypesSelector.newInstance().selectByName('Account', new Set<String>{'Organisation'}).values();
		List<RecordType> serviceAdvisorRecordTypes = RecordTypesSelector.newInstance().selectByName('Case', new Set<String>{BGSConstants.SERVICE_DELIVERY_NAME}).values();

		Account acc = TestUtility.createBusinessAccount('Wayne Enterprises', accountRecordTypes[0].Id);
		Database.insert(acc);

		Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.Id);
		Database.insert(con);

		Test.startTest();
		Case csRec = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', acc.Id, con.Id, serviceAdvisorRecordTypes[0].Id);
		Database.insert(csRec);
		Test.stopTest();

		csRec = [SELECT EntitlementId, BusinessHoursId FROM Case WHERE Id =: csRec.Id LIMIT 1];
		System.assertEquals(csRec.EntitlementId, entitlementList[0].Id, 'Entitlement Id was not applied to case');
		System.assertEquals(csRec.BusinessHoursId, entitlementList[0].BusinessHoursId, 'Business Hours Id was not applied to case');

	}
	
	/**
	  * @description	   This method tests scenario of associating entitlement to case to trigger milestones with default timezone
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testInsertMilestonesDefTimeZone(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		User runningUser = TestUtility.createUser('Wayne',prof.id,null);
		runningUser.timezonesidkey = SSSWConstants.DEF_TZKEY;
		System.runAs(runningUser){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Integer cs = [SELECT Count() FROM CaseMileStone WHERE CaseId =: csRec.Id];
			csRec = [SELECT SLATargetDate__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assert(cs > 0);
			System.assert(csRec.SLATargetDate__c != null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating entitlement to case to trigger milestones
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testOwnerChangeEscalationScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		User newOwner = TestUtility.createUser('NewOwner',prof.id,null);
		newOwner.ManagerId = UserInfo.getUserId();
		Database.Insert(newOwner);
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			Test.startTest();
				csRec.OwnerId = newOwner.Id;
				Database.update(csRec);
			Test.stopTest();
			
		}
		// assert is placed outside runAs as case is not visible to agent & criteria based sharing rules can't be tested.
		Case cs = [SELECT Internal_Tier_Escalation_Email__c FROM Case WHERE Id =: csRec.Id];
		System.assert(cs.Internal_Tier_Escalation_Email__c != null);
		System.assertEquals(cs.Internal_Tier_Escalation_Email__c,UserInfo.getUserEmail());
	}
	
	/**
	  * @description	   This method tests scenario of charter milestone when case is closed
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCloseCaseScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.SLATargetDate__c = Date.Today() + 10;
			Database.insert(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			CaseMilestoneUtility.isCaseSLASet = false;
			Test.startTest();				
				csRec.Status = SSSWConstants.STAT_CLOSED ;
				csRec.ResolutionCode__c = 'Actioned';
				Database.update(csRec);
			Test.stopTest();
			
			//CH 14 Jan 2016 - updated to handle multiple milestones
			//List<CaseMileStone> milestones = [SELECT CompletionDate FROM CaseMileStone WHERE CaseId =: csRec.Id];
			//System.assert(milestone.CompletionDate != null);
			for(CaseMileStone milestone : [SELECT CompletionDate FROM CaseMileStone WHERE CaseId =: csRec.Id AND MilestoneType.name =: SSSWConstants.Charter_Milestone LIMIT 1]) {
			  System.assert(milestone.CompletionDate != null);
			}
		}
	}
	
	/**
	  * @description	   This method tests scenario of updating customer SLA for case when expecting
						   response from customer
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testAwaitingCRScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.SLATargetDate__c = Date.Today() + 10;
			Database.insert(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			CaseMilestoneUtility.isCaseSLASet = false;
			Test.startTest();
				csRec.Customer_Milestones_Violated__c = 1;
				csRec.Status = SSSWConstants.STAT_AWAITING_CUST_RESPONSE;
				Database.update(csRec);
			Test.stopTest();
			Case cs = [SELECT CustomerTierSLA__c FROM Case WHERE Id =: csRec.Id];
			System.debug('**'+ cs);
			System.assert(cs.CustomerTierSLA__c != null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of updating customer SLA for case when expecting
						   response from customer
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testAwaitingCRScenario_futureTargetDate(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.Previous_Milestone_Time__c = Date.Today() - 40;
			Database.insert(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			CaseMilestoneUtility.isCaseSLASet = false;
			csRec.Status = SSSWConstants.STAT_AWAITING_CUST_RESPONSE;
			Database.update(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			CaseMilestoneUtility.isCaseSLASet = false;
			Test.startTest();
				csRec.Customer_Milestones_Violated__c = 3;  // escalated to tier 3
				Database.update(csRec);
			Test.stopTest();
			StatusTracking__c tracking = [SELECT Case__c,EscalationTier__c FROM StatusTracking__c 
										WHERE Case__c =: csRec.Id ORDER BY Case__c,StartDate__c DESC LIMIT 1];
			Integer taskCount = [SELECT Count() FROM Task WHERE WhatId =: csRec.Id];
			System.assertEquals(3,tracking.EscalationTier__c);
			System.assertEquals(1,taskCount);
		}
	}
	
	/**
	  * @description	   This method tests scenario of updating customer SLA for case when expecting
						   response from customer
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testNetworkEscalationScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			
			Map<String,Schema.RecordTypeInfo> ntwrkRecTypeMap = Schema.Sobjecttype.Network__c.getRecordTypeInfosByName();
			Network__c ntwrk = TestUtility.createNetwork('Melbourne Bourke Street',
																ntwrkRecTypeMap.get('Retail').getRecordTypeId(),'test@test.com.au');
			Database.insert(ntwrk);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			csRec.Network__c = ntwrk.Id;
			csRec.Status = SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE;
			Database.update(csRec);
			CaseMilestoneUtility.isMilestoneUpdated = false;
			Test.startTest();
				csRec.Facility_Milestones_Violated__c = 5;  // escalated to tier 5
				Database.update(csRec);
			Test.stopTest();
			StatusTracking__c tracking = [SELECT Case__c,EscalationTier__c FROM StatusTracking__c 
										WHERE Case__c =: csRec.Id ORDER BY Case__c,StartDate__c DESC LIMIT 1];
			Integer taskCount = [SELECT Count() FROM Task WHERE WhatId =: csRec.Id];
			System.assertEquals(5,tracking.EscalationTier__c);
			System.assertEquals(1,taskCount);
		}
	}
	
	/**
	  * @description	   This method tests scenario of updating customer SLA for case when expecting
						   response from customer
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testInternalEscalationScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.Status = SSSWConstants.STAT_ON_HOLD;
			Database.insert(csRec);			
			CaseMilestoneUtility.isMilestoneUpdated = false;
			Test.startTest();
				csRec.Internal_Milestones_Violated__c = 3;  // escalated to tier 3
				Database.update(csRec);
			Test.stopTest();
			StatusTracking__c tracking = [SELECT Case__c,EscalationTier__c FROM StatusTracking__c 
										WHERE Case__c =: csRec.Id ORDER BY Case__c,StartDate__c DESC LIMIT 1];
			Integer taskCount = [SELECT Count() FROM Task WHERE WhatId =: csRec.Id];
			System.assertEquals(3,tracking.EscalationTier__c);

			//===== SUMMARY =====
			//The assertEquals below has been changed from 1 to 2 as a temporary fix.
			//The assertEquals was passing for 1 due to a bug that prevented CaseMilestonesUtility.updateMilestones() in the Workflow Case DML's trigger execution to be called.
			//A fix introduced on 2022-11-13 now means the CaseMilestonesUtility.updateMilestones() is called during the aforementioned Workflow Case DML, and a 2nd Task is created, hence assertEquals() should be 2.
			//===== TECHNICAL DETAILS =====
			//The bug is due to:
			// 1) CaseTriggerHelper.processHLCCases() called in AfterUpdate context, which in most scenarios needlessly fired a Case DML (lets call this AfterUpdate Case DML) to fire in CaseTriggerHelper.updateHLC(). 
			// 2) In the trigger execution from the Case DML, CaseMilestonesUtility.updateMilestones() would execute, and set isMilestoneUpdated to true to prevent recursion. This before the Workflow Case DML. 
			// 3) When the Workflow Rules run and performs a Case DML (Workflow Case DML), the trigger execution not run CaseMilestonesUtility.updateMilestones() because isMilestoneUpdated = true 
			// 4) A fix introduced on 2022-11-13 means the Case DML in Step 1 only fires if the Case is a HLC or CR, which means for most Cases the 2nd Task is being created. Hence the assertEquals below needs to be 2.
			//===== WHAT TO FIX =====
			// The following areas need to be assessed to resolve the above bug
			// - recursion check in CaseMilestonesUtility.cls via the flag isMilestoneUpdated
			// - CaseTriggerHelper.updateHLC() and CaseTriggerHelper.processHLCCases() - does it need to perform the current Case DML or can it be deferred 
			// - CaseTriggerHandler.cls that orchestrates CaseMilestonesUtility.cls and CaseTriggerHelper.updateHLC()
			System.assertEquals(2,taskCount); 
		}
	}

	/**
	 * Generate an ID for an Object based on SObjectType
	 *
	 * @param sot SObjectType
	 * @param seed Nth ID to generate
	 *
	 * @return The Id
	 */
	private static String makeFakeId(Schema.SObjectType sot, Integer seed)
	{
		String result = String.valueOf(seed);
		return sot.getDescribe().getKeyPrefix() +
				'0'.repeat(12-result.length()) + result;
	}

	/**
	  * @description	   This method tests scenario of updating customer SLA for case when expecting
						   response from customer
	  * @param			 NA
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testUpdateNetworkEscalationEmails(){

		Map<String,Schema.RecordTypeInfo> networkRecTypeMap = Schema.SObjectType.Network__c.getRecordTypeInfosByName();
		Network__c network = TestUtility.createNetwork('Melbourne Bourke Street',
				networkRecTypeMap.get('Retail').getRecordTypeId(),'test@test.com.au');
		network.Email_1__c = 'escalationlvl1@auspost.com.au';
		network.Email_2__c = 'escalationlvl2@auspost.com.au';
		network.Email_3__c = 'escalationlvl3@auspost.com.au';
		network.Email_4__c = 'escalationlvl4@auspost.com.au';
		network.Email_5__c = 'escalationlvl5@auspost.com.au';

		insert network;

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id ssswDeliveryRecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();

		Case caseBefore = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', null, null, ssswDeliveryRecordTypeId);
		caseBefore.Id = makeFakeId(Case.SObjectType, 1);
		caseBefore.Network__c = network.Id;
		Map<Id,Case> oldMap = new Map<Id, Case>();
		oldMap.put(caseBefore.Id, caseBefore);

		Case caseAfter = TestUtility.createCase('Enquiry','In Progress','General Enquiry', null, null, ssswDeliveryRecordTypeId);
		caseAfter.Id = makeFakeId(Case.SObjectType, 1);
		caseAfter.Network__c = network.Id;
		List<Case> casesUpdated = new List<Case>{ caseAfter };

		CaseMilestoneUtility milestoneUtility = new CaseMilestoneUtility();

		// When no escalation level is set, Facility_Tier_Escalation_Email__c = null
		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(null, caseAfter.Facility_Tier_Escalation_Email__c,
				'When no escalation level is set, Facility_Tier_Escalation_Email__c = null');

		// When no escalation level is set but escalated, Facility_Tier_Escalation_Email__c = null
		caseBefore.IsEscalated = false;
		caseAfter.IsEscalated = true;
		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(null, caseAfter.Facility_Tier_Escalation_Email__c,
				'When no escalation level is set but escalated, Facility_Tier_Escalation_Email__c = null');

		// When escalation level is 1, Facility_Tier_Escalation_Email__c = Network.Email_1__c
		caseAfter.Facility_Milestones_Violated__c = 1;
		caseBefore.Facility_Milestones_Violated__c = null;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_1__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 1, Facility_Tier_Escalation_Email__c = Network.Email_1__c');

		// When escalation level is 2, Facility_Tier_Escalation_Email__c = Network.Email_1__c
		caseAfter.Facility_Milestones_Violated__c = 2;
		caseBefore.Facility_Milestones_Violated__c = 1;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_1__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 2, Facility_Tier_Escalation_Email__c = Network.Email_1__c');

		// When escalation level is 3, Facility_Tier_Escalation_Email__c = Network.Email_2__c
		caseAfter.Facility_Milestones_Violated__c = 3;
		caseBefore.Facility_Milestones_Violated__c = 2;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_2__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 3, Facility_Tier_Escalation_Email__c = Network.Email_2__c');

		// When escalation level is 4, Facility_Tier_Escalation_Email__c = Network.Email_3__c
		caseAfter.Facility_Milestones_Violated__c = 4;
		caseBefore.Facility_Milestones_Violated__c = 3;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_3__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 4, Facility_Tier_Escalation_Email__c = Network.Email_3__c');

		// When escalation level is 5, Facility_Tier_Escalation_Email__c = Network.Email_4__c
		caseAfter.Facility_Milestones_Violated__c = 5;
		caseBefore.Facility_Milestones_Violated__c = 4;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_4__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 5, Facility_Tier_Escalation_Email__c = Network.Email_4__c');

		// When escalation level is 6, Facility_Tier_Escalation_Email__c = Network.Email_5__c
		caseAfter.Facility_Milestones_Violated__c = 6;
		caseBefore.Facility_Milestones_Violated__c = 5;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_5__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is 6, Facility_Tier_Escalation_Email__c = Network.Email_5__c');

		// When escalation level is made 1 again, Facility_Tier_Escalation_Email__c = Network.Email_1__c again
		caseAfter.Facility_Milestones_Violated__c = 1;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_1__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When escalation level is made 1 again, Facility_Tier_Escalation_Email__c = Network.Email_1__c again');

		// When Network is null, Facility_Tier_Escalation_Email__c retained
		caseAfter.Network__c = null;

		milestoneUtility.updateNetworkEscalationEmails(casesUpdated, oldMap);
		System.assertEquals(network.Email_1__c, caseAfter.Facility_Tier_Escalation_Email__c,
				'When Network is null, Facility_Tier_Escalation_Email__c retained');
	}

	/**
	 * This method tests scenario of associating entitlement to case for transport enquiry cases types
	*/
	@IsTest
	private static void testTransportEnquiryApplyDefaultEntitlement(){
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> orgAaccounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Entitlement> entitlements = ApplicationTestDataFactory.getEntitlements(1, true, TransportEnquiryCaseService.TRANSPORT_ENQUIRY_ENTITLEMENT, null, orgAaccounts[0].Id);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		RecordType transportEnquiryRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'Transport_Enquiry').values()[0];
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'RecordTypeId' => transportEnquiryRecordType.Id});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{'RecordTypeId' => transportEnquiryRecordType.Id});


		// =====================================
		// Stubbing
		// =====================================
		TransportEnquiryCaseService mockService = (TransportEnquiryCaseService)MockUtility.mockUtility(TransportEnquiryCaseService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getTransportEnquiryEntitlementId()).thenReturn(entitlements[0].Id);
		MockUtility.Mocks.when(mockService.getTransportEnquiryRecordTypeId()).thenReturn(transportEnquiryRecordType.Id);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMilestoneUtility util = new CaseMilestoneUtility();
		util.insertMilestones(cases);

		// make sure the entitlement has been populated
		Assert.areEqual(cases[0].EntitlementId, entitlements[0].Id, 'Entitlement Id was not applied to case');
		Assert.areEqual(cases[1].EntitlementId, entitlements[0].Id, 'Entitlement Id was not applied to case');

		Test.stopTest();
	}

}