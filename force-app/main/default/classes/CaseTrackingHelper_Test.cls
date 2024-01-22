/**
  * @author		: nandan.narasappa@auspost.com.au
  * @date		 : 03/11/2015
  * @description  : Test Class for CaseTrackingHelper
  *
  * @changelog
  * 2015-03-11 - Nandan Narasappa - Created
  * 2023-04-20 - Noel Lim - Added testClassVariables method
  */
@isTest
private with sharing class CaseTrackingHelper_Test {
	
	// Constants
	private static final String ADMIN_PROFILE = 'System Administrator';
	private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
	
	/**
	  * @description	This method tests scenario of defaulting last status change & time spent by
							support & customer on case and creation of status tracking
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testInsertStatusTracking(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Time_With_Customer__c,Time_With_Support__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(1,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);
		}	
	}
	
	/**
	  * @description	This method tests scenario of defaulting last status change & time spent by
							support & customer on case and creation of status tracking
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testInsertStatusTrackingSydneyTZ(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		User runningUser = TestUtility.createUser('Wayne',prof.id,null);
		runningUser.timezonesidkey = SSSWConstants.DEF_TZKEY;
		System.runAs(runningUser){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Time_With_Customer__c,Time_With_Support__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(1,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);
		}
	}
	
	/**
	  * @description	This method tests scenario of case tracking for a status change
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testUpdateCaseStatusTracking(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			CaseTrackingHelper.isUpdateStatusTrackRecursive = false;
			Test.startTest();
				csRec.Status = SSSWConstants.STAT_ON_HOLD;
				Database.update(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Time_With_Customer__c,Time_With_Support__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(2,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);
		}
	}
	
	/**
	  * @description	This method tests scenario of case tracking for a status change
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testUpdateCaseStatusTrackingWOBusinessHour(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			StatusTracking__c tracking = [SELECT BusinessHours__c FROM StatusTracking__c WHERE Case__c =: csRec.Id LIMIT 1];
			tracking.BusinessHours__c = null;
			Database.update(tracking);
			CaseTrackingHelper.isUpdateStatusTrackRecursive = false;
			Test.startTest();
				csRec.Status = SSSWConstants.STAT_ON_HOLD;
				Database.update(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Time_With_Customer__c,Time_With_Support__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(2,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);
		}
	}
	
	 /**
	  * @description	This method tests scenario of status tracking creation for owner change of case
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testOwnerChangeScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		User newOwner = TestUtility.createUser('NewOwner',prof.id,null);
		newOwner.ManagerId = UserInfo.getUserId();
		Database.Insert(newOwner);
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			//Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			//Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,null,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.OwnerId = UserInfo.getUserId();
			Database.insert(csRec);
			CaseTrackingHelper.isUpdateStatusTrackRecursive = false;
			Group backOfficeQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'SSSW_BOH_Group_3' LIMIT 1];
			Test.startTest();
				csRec.Status = 'On Hold';
				csRec.OwnerId = backOfficeQueue.Id;
				Database.update(csRec);
			Test.stopTest();
		}
		// assert is placed outside runAs as case is not visible to agent & criteria based sharing rules can't be tested.
		Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
		Case cs = [SELECT OwnerId,Last_Status_Change__c,Time_With_Customer__c,Time_With_Support__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
		System.debug('** Case in Test Method ==>'+cs);
		System.assertEquals(2,count);
		System.assertEquals(0,cs.Time_With_Customer__c);
		System.assertEquals(0,cs.Time_With_Support__c);
	}
	
	/**
	  * @description	This method tests scenario of detecting cases from spam email
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testCloseCase(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
			TestUtility.createTestEntitlementProcessData();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Article__c article = TestUtility.createArticle('12345',1,'Bruce','Peter','International Letters');
			Database.insert(article);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			
			Test.startTest();
				csRec.Status =  'Closed';
				csRec.ResolutionCode__c = 'Actioned';
				csRec.Customer_Milestones_Violated__c = 4;
				csRec.ClosedBySystem__c = true;
				Database.update(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Case_Age_In_Business_Hours__c,Time_With_Customer__c,Time_With_Support__c 
						FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(2,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);					
			System.assertEquals(0,csRec.Case_Age_In_Business_Hours__c);					
		}
	}
	
	/**
	  * @description	This method tests scenario of updating customer SLA for case when expecting
							response from customer
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testAwaitingNetworkResponseScenario(){
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
			
			Test.startTest();
				csRec.Network__c = ntwrk.Id;
				csRec.Status = SSSWConstants.STAT_AWAITING_NTWRK_RESPONSE;
				Database.update(csRec);
			Test.stopTest();
			StatusTracking__c tracking = [SELECT Case__c,EscalationTier__c,Network__c FROM StatusTracking__c 
										WHERE Case__c =: csRec.Id ORDER BY Case__c,StartDate__c DESC LIMIT 1];
			System.assert(tracking.Network__c != null);
		}
	}
	
	/**
	  * @description	This method tests scenario of deleting fax case and associating with parent case
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testDeleteFaxCase(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);

			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			Database.insert(csRec);
			
			Case childCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
													caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
												
			childCase.ParentId = csRec.Id;
			Database.insert(childCase);
			
			Fax__c childFax = TestUtility.createFax(childCase.Id,'test@test.com','test@test.com','Test','Test');
			Database.insert(childFax);
			
			Test.startTest();
				childCase.RecordTypeId = caseRecTypeMap.get(SSSWConstants.RECTYPE_CASE_FAX).getRecordTypeId();
				childCase.Description = 'Description updated';
				Database.update(childCase);
			Test.stopTest();
			Fax__c faxRec = [SELECT Id,Case__c FROM Fax__c WHERE Id =: childFax.Id];
			System.assertEquals(csRec.Id,faxRec.Case__c);
		}
	}
	
	/**
	  * @description	This method tests scenario of updating time case is with customer
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testAwaitingCRScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			TestUtility.createUniqueCaseCustomSetting();
			TestUtility.createStatTrackingCustomSetting();
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
			CaseTrackingHelper.isSetStatusTrackRecursive = false;
			
			csRec.Status = SSSWConstants.STAT_AWAITING_CUST_RESPONSE;
			Database.update(csRec);
			
			Test.startTest();
				CaseTrackingHelper.isSetStatusTrackRecursive = false;
				csRec.Customer_Milestones_Violated__c = 4;
				csRec.Status = 'Closed';
				csRec.ResolutionCode__c = 'Other';
				Database.update(csRec);
			Test.stopTest();
			Integer count = [SELECT count() FROM StatusTracking__c WHERE Case__c =: csRec.Id];
			csRec = [SELECT Last_Status_Change__c,Case_Age_In_Business_Hours__c,Time_With_Customer__c,Time_With_Support__c 
						FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(2,count);
			System.assertEquals(0,csRec.Time_With_Customer__c);
			System.assertEquals(0,csRec.Time_With_Support__c);					
			System.assertEquals(0,csRec.Case_Age_In_Business_Hours__c); 
		}
	}
	
	/**
	  * @description	This method is for covering exception and not a valid business scenario
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testDeleteFaxCaseExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseTrackingHelper helper = new CaseTrackingHelper();
			Test.startTest();
				helper.deleteCaseForFax(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	This method is for covering exception and not a valid business scenario
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testSetLastStatChangeExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseTrackingHelper helper = new CaseTrackingHelper();
			Test.startTest();
				helper.setLastStatusChange(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	This method is for covering exception and not a valid business scenario
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testInsertCaseTrackingExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseTrackingHelper helper = new CaseTrackingHelper();
			Test.startTest();
				helper.insertCaseStatusTracking(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	This method is for covering exception and not a valid business scenario
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testupdateCaseTrackingExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseTrackingHelper helper = new CaseTrackingHelper();
			Test.startTest();
				helper.updateCaseStatusTracking(new List<Case>{null},new Map<Id,Case>{null => null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	This method is for covering exception and not a valid business scenario
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	@IsTest
	static void testSetStatusTrackingExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseTrackingHelper helper = new CaseTrackingHelper();
			Test.startTest();
				helper.setStatusTracking(new List<Case>{null},new Map<Id,Case>{null => null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}


	/**
	  * @description	This method is for covering class variables
	  * @param			NA	 
	  * @return			Void
	  * @throws			NA
	  */
	  @IsTest
	  static void testClassVariables(){
		
		Set<SObjectField> caseFieldsForTracking = CaseTrackingHelper.caseFieldsForTracking;

		System.assertEquals(6, caseFieldsForTracking.size(),'There should be 6 SObjectFields in the caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.OwnerId),'OwnerId field should be in caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.Status),'Status field should be in caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.RecordTypeId),'RecordTypeId field should be in caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.Network__c),'NetworkComments__c field should be in caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.NetworkComments__c),'NetworkComments__c field should be in caseFieldsForTracking class variable');
		System.assertEquals(true, caseFieldsForTracking.contains(Case.Network_Response__c),'Network_Response__c field should be in caseFieldsForTracking class variable');
	}
}