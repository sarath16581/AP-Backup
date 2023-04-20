/**************************************************
Description:	Test Class for CaseCommonUtility
History:
--------------------------------------------------
26.09.2017	kalpita.talwadekar@auspost.com.au	updated test class for coverage on SOQL FIX Updates
2017-10-05	nathan.franklin@auspost.com.au	Removed an old test that tests links to article functionality
2017-10-16	nathan.franklin@auspost.com.au	Adding new conditions to assert NPS details only when cases are closed.
2018-06-25	disha.kariya@auspost.com.au	   Removed NPSRequired__c and NPSTagDate__c field.
2018-07-10	nathan.franklin@auspost.com.au  Removed all NPS test methods. These are now covered in NPSSurveyUtil_Test
2019-03-18	gunith.devasurendra@auspost.com.au	Removed deprecated changes.
2019-05-06	gunith.devasurendra@auspost.com.au	Convert Workflow logic to route Cases when state is 'new'ed
2019-05-08	seth.p.heang@accenture.com			Adding test class to assert 'CAR' Case requestor field is populated with current user if left empty upon case creation
2020-11-17 - Ranjeewa Silva - Added test casses to verify Social Case routing behaviour
16.05.2022   SaiSwetha Pingali  Removed snapIt logic as it is no longer required.
2022-11-18	 Noel Lim - added test method routeReopenedCases()
2023-02-14	 Noel Lim - added test method assignToPreferredAgent()
2023-03-08	 Noel Lim - update test method testAssignToPreferredAgent() for Release 2 TEMPORARY FIX
2023-03-17	 Noel Lim - update test method closedCasesToClosedQueue() to include new logic that prevents routing from AllocateToQueue = true based on Case Owner. Update existing test methods that simulate portal or Social Case creation to use the correct Profile
2023-04-19	 George Nguyen - updated to check for qualify Preferred Agent based on skill setting in custom settings
**************************************************/
@isTest
private with sharing class CaseCommonUtility_Test {
	
	@testSetup 
	static void testDataCreate() {
		insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
    }
	
	// Constants
	private static final String ADMIN_PROFILE = 'System Administrator';
	private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';

	/**
	 * For the purpose of testing a deprecated class
	 * This can be removed in JUL-2022 with a destructive change to CaseUtilityWithoutSharing
	 */
	@IsTest
	private static void testNothingFromCaseUtilityWithoutSharing() {
		CaseUtilityWithoutSharing cls = new CaseUtilityWithoutSharing();
	}

	/**
	  * @description	   This method tests scenario of associating case with contact with
							no contacts with email provided
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testContactAssignmentEmailOrigin_NoContact(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(null,cs.ContactId);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating case with contact
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testContactAssignmentEmailOriginContact(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',null);
			Database.insert(con);
			Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry',ContactId=con.Id);
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(con.Id,cs.ContactId);
		}
	}
	/**
	  * @description	   This method tests scenario of associating Portal cases from HS forms in the un-authenticated context
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testContactAssignmentPortalNocontact(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Portal',Type = 'General Enquiry'
								  ,First_Name__c='Bruce',Last_Name__c='Wayne',CHASEnquiryType__c='Delivery issue');
			Case csRecBSP = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'BSP',Type = 'Investigation'
								  ,First_Name__c='Bruce',Last_Name__c='Wayne',CHASEnquiryType__c='',EnquirySubType__c='Delivery complaint');

			Test.startTest();
				Database.insert(csRec);
				Database.insert(csRecBSP);
			Test.stopTest();
	}
	}

	
	/**
	  * @description	   This method tests scenario of associating case with contact 
							for origin other than portal & email, with contact details in case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkContactShortListedCases(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
						
			Account acc = TestUtility.createPersonAccount('Wayne',accRecTypeMap.get('Consumer').getRecordTypeId());
			acc.FirstName = 'Bruce';
			acc.PersonEmail = 'bruce@wayne.com';
			Database.insert(acc);
			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',null);
			Database.insert(con);

			Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
									First_Name__c = 'Bruce',Last_Name__c = 'Wayne',ContactId=con.Id);
			
			Test.startTest();
			Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			Account consumer = [SELECT PersonContactId FROM Account WHERE Id =: acc.Id LIMIT 1];
			//System.assertEquals(consumer.PersonContactId,cs.ContactId);
			System.assertNotEquals(consumer.PersonContactId,null);
			System.assertNotEquals(cs.ContactId,null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating case with contact 
							for origin other than portal & email, with contact details in case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkBusinessContact(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Account acc;
		Billing_Account__c billAcc;
		Contact con;
		System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			
			List<Account> accList = new List<Account>();
			// Creating temporary account used by Billing Account Trigger
			Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			tempAcc.LEGACY_ID__c = '60000000';
			accList.add(tempAcc);
			acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			acc.LEGACY_ID__c = '12345';
			accList.add(acc);
			Database.insert(accList);
			
			tempAcc.LEGACY_ID__c = '60000000';
			Database.update(tempAcc);
			
			
			billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
			Database.insert(billAcc);
			billAcc = [SELECT Customer_Number__c FROM Billing_Account__c WHERE Id =: billAcc.Id LIMIT 1];
			con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			con.BillingAccount__c = billAcc.Id;
			Database.insert(con);
		}
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
									First_Name__c = 'Bruce',Last_Name__c = 'Wayne',Billing_Number__c = billAcc.Customer_Number__c,ContactId=con.Id);
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(con.Id,cs.ContactId);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating case with contact 
							for origin other than portal & email, with contact details in case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkBusinessDiffContact(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Account acc;
		System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			
			List<Account> accList = new List<Account>();
			// Creating temporary account used by Billing Account Trigger
			Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			tempAcc.LEGACY_ID__c = '60000000';
			accList.add(tempAcc);
			acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			acc.LEGACY_ID__c = '12345';
			accList.add(acc);
			Database.insert(accList);
			
			tempAcc.LEGACY_ID__c = '60000000';
			Database.update(tempAcc);
			
			System.debug('** Billing Account ==>'+[SELECT Id,Legacy_Id__c FROM Account]);
			Billing_Account__c billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
			Database.insert(billAcc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			con.BillingAccount__c = billAcc.Id;
			Database.insert(con);
		}
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
									First_Name__c = 'Bruce',Last_Name__c = 'Wayne',Billing_Number__c = '12346');
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(null,cs.ContactId);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating case with contact 
							for origin other than portal & email, with contact details in case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkBusinessNoContact(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Account acc;
		System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			
			List<Account> accList = new List<Account>();
			// Creating temporary account used by Billing Account Trigger
			Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			tempAcc.LEGACY_ID__c = '60000000';
			accList.add(tempAcc);
			acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			acc.LEGACY_ID__c = '12345';
			accList.add(acc);
			Database.insert(accList);
			
			tempAcc.LEGACY_ID__c = '60000000';
			Database.update(tempAcc);
			
			System.debug('** Billing Account ==>'+[SELECT Id,Legacy_Id__c FROM Account]);
			Billing_Account__c billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
			Database.insert(billAcc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			con.BillingAccount__c = billAcc.Id;
			Database.insert(con);
		}
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
									First_Name__c = 'Bruce',Last_Name__c = 'Wayne');
			
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			//System.assert(cs.ContactId != null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of detecting cases from spam email
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testDetectSpamCase(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			SpamEmail__c spam = TestUtility.createSpamEmail('test@test.com');
			Database.insert(spam);
			
			Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT Prevent_Email__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(true,cs.Prevent_Email__c);
		}
	}
	
	/**
	  * @description	   This method tests scenario of detecting cases from email not in spam table
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testDetectNoSpamCase(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			SpamEmail__c spam = TestUtility.createSpamEmail('test1@test.com');
			Database.insert(spam);
			
			Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			Case cs = [SELECT Prevent_Email__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(false,cs.Prevent_Email__c);
		}
	}
	
	/**
	  * @description	   This method tests scenario of detecting cases from spam email
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testOnHoldCase(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		List<User> userList = new List<User>();
		User caseOwner = TestUtility.createUser('Peter',adminProf.id,null);
		User runningUser = TestUtility.createUser('Wayne',prof.id,null);
		userList.add(caseOwner);
		userList.add(runningUser);
		Database.insert(userList);
		
		System.runAs(caseOwner){	// running with admin as Case OWD is private & criteria-based sharing rule cannot be tested in apex
			SpamEmail__c spam = TestUtility.createSpamEmail('test@test.com');
			Database.insert(spam);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry',
									OwnerId = runningUser.Id);
			csRec.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
			Database.insert(csRec);
			Test.startTest();
				csRec.Status = SSSWConstants.STAT_ON_HOLD;
				Database.update(csRec);
			Test.stopTest();
			Case cs = [SELECT OwnerId FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(caseOwner.Id,cs.OwnerId);
		}
	}
	
	/**
	  * @description	   This method tests scenario of preventing duplicate case for DDC user
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	/*
	private static testMethod void testValidateCaseDDC(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Profile ddcProf = [SELECT Id,Name FROM profile where Name = 'DDC Consumer Community User' LIMIT 1];
		UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account acc = TestUtility.createPersonAccount('Peter',accRecTypeMap.get('Consumer').getRecordTypeId());
		acc.FirstName = 'Parker';
		acc.PersonEmail = 'peter@wayne.com';
		Database.insert(acc);
		acc = [SELECT PersonContactId FROM Account WHERE Id =: acc.Id LIMIT 1];
		User ddcUser = TestUtility.createPortalUser('Wayne',ddcProf.id,acc.PersonContactId);
		
		User admin = TestUtility.createUser('Peter',adminProf.id,null);
		System.runAs(admin){
			TestUtility.createUniqueCaseCustomSetting();
		}
		
		System.runAs(ddcUser){
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,ddcUser.ContactId,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.ProductCategory__c = 'International Letters';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			Database.insert(csRec);
			
			Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,ddcUser.ContactId,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			dupeCase.ProductCategory__c = 'International Letters';
			dupeCase.ReferenceId__c = '12345';
			dupeCase.Address2__c  = '111 Bourke Street';
			Test.startTest();
				try{
					Database.insert(dupeCase);
				}
				catch(Exception exp){
					 System.assertEquals('System.DmlException',exp.getTypeName());
					 System.assert(exp.getMessage().contains(Label.DUPE_CASE_ERR_MSG));
				}
			Test.stopTest();
			System.assert(dupeCase.Id != null);
		}
	} */
	
	/**
	  * @description	   This method tests scenario of preventing duplicate case for BSP user
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testValidateCaseBSP(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Profile bspProf = [SELECT Id,Name FROM profile where Name = 'BSP Community User' LIMIT 1];
		
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
														accRecTypeMap.get('Organisation').getRecordTypeId());
		Database.insert(acc);

		Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
		Database.insert(con);

		User bspUser = TestUtility.createPortalUser('Wayne',bspProf.Id,con.Id);
		User admin = TestUtility.createUser('Peter',adminProf.id,null);
		System.runAs(admin){
			TestUtility.createUniqueCaseCustomSetting();
		}
		
		System.runAs(bspUser){
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,bspUser.ContactId,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.ProductCategory__c = 'International Letters';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			Database.insert(csRec);
			
			Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,bspUser.ContactId,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			dupeCase.ProductCategory__c = 'International Letters';
			dupeCase.ReferenceId__c = '12345';
			dupeCase.Address2__c  = '111 Bourke Street';
			Test.startTest();
				try{
					Database.insert(dupeCase);
				}
				catch(Exception exp){
					 System.assertEquals('System.DmlException',exp.getTypeName());
					 System.assert(exp.getMessage().contains(Label.DUPE_CASE_ERR_MSG));
				}
			Test.stopTest();
			//System.assert(dupeCase.Id == null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of preventing duplicate cases as agent
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testValidateCaseAgent(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createUniqueCaseCustomSetting();
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.ProductCategory__c = 'International Letters';
			csRec.ProductSubCategory__c ='International Courier';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			Database.insert(csRec);
			
			Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			dupeCase.ProductCategory__c = 'International Letters';
			dupeCase.ProductSubCategory__c ='International Courier';

			dupeCase.ReferenceId__c = '12345';
			dupeCase.Address2__c  = '111 Bourke Street';
			Test.startTest();
				Database.insert(dupeCase);
			Test.stopTest();
			System.assert(dupeCase.Id != null);
			Map<Id, Case> casesToCheck = new Map<Id, Case>([SELECT CaseLocality__c,Id FROM Case WHERE Id =: csRec.Id OR Id =: dupeCase.Id]);
			
//			csRec = [SELECT CaseLocality__c,Id FROM Case WHERE Id =: csRec.Id LIMIT 1];
//			dupeCase = [SELECT CaseLocality__c,Id FROM Case WHERE Id =: dupeCase.Id LIMIT 1];
		   // System.debug('** dupeCase ==>'+ dupeCase);
			//System.assertEquals('International',dupeCase.CaseLocality__c);
//			System.assertEquals(csRec.CaseLocality__c, dupeCase.CaseLocality__c);
			System.assertEquals(casesToCheck.get(csRec.Id).CaseLocality__c, casesToCheck.get(dupeCase.Id).CaseLocality__c);
		}
	}
	
	/**
	  * @description	   This method tests scenario of associating article to case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkArticle(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createUniqueCaseCustomSetting();
			// This causes a mock response to be generated
			Test.setMock(WebServiceMock.class, new AuspostTrackEventServiceMockImpl());
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.ProductCategory__c = 'International Letters';
			csRec.ReferenceId__c = '12345';
			csRec.Origin = 'Email';
			csRec.Address2__c  = '111 Bourke Street';
			csRec.Bypass_Data_enforcement__c = true;

			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();
			csRec = [SELECT ArticleTest__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assert(csRec.ArticleTest__c != null);
		}
	}
	
	/**
	  * @description	   This method tests scenario of case queue allocation
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testAllocateToQueue(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		Case csRec;
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.createUniqueCaseCustomSetting();
			// This causes a mock response to be generated
			Test.setMock(WebServiceMock.class, new AuspostTrackEventServiceMockImpl());
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.AllocateToQueue__c = true;
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();			
		}
		csRec = [SELECT AllocateToQueue__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
		System.assertEquals(false,csRec.AllocateToQueue__c);
	}
	
//  Can be removed NOV-2020
//	/**
//	  * @description	   This method tests scenario of associating article to case
//	  * @param			 NA
//	  * @return			Void
//	  * @throws			NA
//	  */
//	private static testMethod void testSubscribeArticle(){
//		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
//		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
//			TestUtility.createUniqueCaseCustomSetting();
//
//			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
//			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
//															accRecTypeMap.get('Organisation').getRecordTypeId());
//			Database.insert(acc);
//
//			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
//			Database.insert(con);
//
//			Article__c article = TestUtility.createArticle('12345',1,'Bruce','Peter','International Letters');
//			Database.insert(article);
//
//			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
//			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
//												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
//			csRec.ProductCategory__c = 'International Letters';
//			csRec.ReferenceId__c = '12345';
//			csRec.Origin = 'Email';
//			csRec.Address2__c  = '111 Bourke Street';
//			csRec.ArticleTest__c  = article.Id;
//			Database.insert(csRec);
//
//			Test.startTest();
//				csRec.Subscribed__c = true;
//				Database.update(csRec);
//			Test.stopTest();
//			article = [SELECT Subscribed__c FROM Article__c WHERE Id =: article.Id LIMIT 1];
//			System.assert(article.Subscribed__c);
//		}
//	}
	
	/**
	  * @description	   This method tests scenario of detecting cases from spam email
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCloseChildCases(){
		Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		List<User> userList = new List<User>();
		User caseOwner = TestUtility.createUser('Peter',adminProf.id,null);
		User runningUser = TestUtility.createUser('Wayne',prof.id,null);
		userList.add(caseOwner);
		userList.add(runningUser);
		Database.insert(userList);
		
		System.runAs(caseOwner){	// running with admin as Case OWD is private & criteria-based sharing rule cannot be tested in apex
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
			
			List<Case> childCases = new List<Case>();
			Case childCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			childCase.ParentId = csRec.Id;
			
			Case childClosedCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			childClosedCase.ParentId = csRec.Id;
			childClosedCase.Status =  'Closed';
			childClosedCase.ResolutionCode__c = 'Actioned';
			
			Case childCaseTwo = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			childCaseTwo.ParentId = csRec.Id;
			
			childCases.add(childCase);
			childCases.add(childClosedCase);
			childCases.add(childCaseTwo);
			
			Test.startTest();
				Database.insert(childCases);
			
				csRec.Status =  'Closed';
				csRec.ResolutionCode__c = 'Actioned';
				Database.update(csRec);
			Test.stopTest();
			Case cs = [SELECT Status FROM Case WHERE Id =: childCase.Id LIMIT 1];
			System.assertEquals('Closed',cs.Status);
		}
	}
	
	/**
	  * @description	   This method tests scenario of detecting cases from spam email
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testAvoidCustomerCloseCase(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
			TestUtility.createEnquirySubTypeCustomSetting();
			
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
			csRec.EnquirySubType__c = 'Damaged/Missing contents';
			Database.insert(csRec);
			
			Test.startTest();
				csRec.Status =  'Closed';
				csRec.ResolutionCode__c = 'Actioned';
				csRec.Customer_Milestones_Violated__c = 4;
				csRec.ClosedBySystem__c = true;
				Database.update(csRec);
			Test.stopTest();
			Case cs = [SELECT Status,ResolutionCode__c,ClosedBySystem__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
			System.assertEquals(false,cs.ClosedBySystem__c);
			System.assertEquals(null,cs.ResolutionCode__c);
			System.assertEquals('In Progress',cs.Status);			
		}
	}
	
	/**
	  * @description	   This method tests scenario of routing case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCaseRouting(){
		Profile bspProf = [SELECT Id,Name FROM profile where Name =: SSSWConstants.SSSW_BSP_COMMUNITY_USER_PROFILE LIMIT 1]; //new cases created for routing will come from Portal
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account bspAcc = TestUtility.createBusinessAccount('BSP Account',
														accRecTypeMap.get('Organisation').getRecordTypeId());
		Database.insert(bspAcc);
		Contact bspCon = TestUtility.createContact('BSP','User','bspuser@test.com',bspAcc.id);
		Database.insert(bspCon);

		System.runAs(TestUtility.createPortalUser('Wayne',bspProf.Id,bspCon.Id)){ 
			Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSW_BOH_Group_2' LIMIT 1];
			SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'Consumer','Portal','Any',SSSWConstants.RECTYPEROUTING);
			routing.IsNew__c = true;
			routing.ExcludeFromNPS__c = true;
			routing.IsActive__c = True;
			routing.Queue_ID__c = backOfcQueue.Id;
			Database.insert(routing);
			System.debug('Routing4--->'+routing);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,bspCon.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.Origin = 'Portal';
			csRec.ProductCategory__c = 'Domestic Parcels';
			csRec.ProductSubCategory__c = 'Express';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			csRec.IsNewForRouting__c  = true;
			csRec.AllocateToQueue__c = true;
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();			
		}
		Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
		System.assertEquals(false,cs.AllocateToQueue__c);
		System.assertEquals(Group.sObjectType,cs.OwnerId.getSObjectType());
	}

	private static testMethod void testSocialCaseRouting(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSWConstants.SSSW_SOCIAL_INTEGRATION_PROFILE LIMIT 1];

		//Setup default Omni queue
		QM__c custSetting = QM__c.getOrgDefaults();
		Group defaultOmnniQueue =  [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'SSSW_BOH_Group_4' LIMIT 1];
		custSetting.DefaultOmniQueueId__c = defaultOmnniQueue.Id;
		Insert custSetting;

		//Cases
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		Case socialCase1 = TestUtility.createCase('Social Post','New',null, null, null, caseRecTypeMap.get('Social Record Type').getRecordTypeId());
		socialCase1.Origin = 'Social';
		socialCase1.IsNewForRouting__c  = true;
		socialCase1.AllocateToQueue__c = true;
		socialCase1.SocialPostTags__c = 'post tag1';//Ensure the social post tags on case match SSSW routing rule

		Case socialCase2 = TestUtility.createCase('Social Post','New',null, null, null, caseRecTypeMap.get('Social Record Type').getRecordTypeId());
		socialCase2.Origin = 'Social';
		socialCase2.IsNewForRouting__c  = true;
		socialCase2.AllocateToQueue__c = true;
		socialCase2.SocialPostTags__c = 'post';//Ensure the social post tags on case does not match SSSW routing rule

		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSW_BOH_Group_2' LIMIT 1];
			SSSWRouting__c routing = TestUtility.createSSSWRouting(null,null,null,null,null,'Social','All',SSSWConstants.RECTYPEROUTING);
			routing.SocialPostTags__c = 'post tag1;post tag2';
			routing.IsActive__c = true;
			routing.Queue_ID__c = backOfcQueue.Id;
			Database.insert(routing);

			Test.startTest();
			Database.insert(new Case[]{socialCase1, socialCase2});
			Test.stopTest();
		}
		Map<Id,Case> savedCases = new Map<Id, Case>([SELECT Id, AllocateToQueue__c,OwnerId FROM Case]);
		System.assertEquals(false, savedCases.get(socialCase1.Id).AllocateToQueue__c);
		System.assertEquals(Group.sObjectType,savedCases.get(socialCase1.Id).OwnerId.getSObjectType());

		System.assertEquals(false, savedCases.get(socialCase2.Id).AllocateToQueue__c);
		System.assertEquals(defaultOmnniQueue.Id,savedCases.get(socialCase2.Id).OwnerId);
	}
	
	/**
	  * @description	   This method tests scenario of routing case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCaseRoutingDescUpdate(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
			Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSW_BOH_Group_2' LIMIT 1];
			SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'Consumer','Email','Any',SSSWConstants.RECTYPEROUTING);
			routing.IsNew__c = true;
			routing.IsActive__c = True;
			routing.ExcludeFromNPS__c = true;
			routing.Queue_ID__c = backOfcQueue.Id;
			Database.insert(routing);
			System.debug('Routing1--->'+routing);
			
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.Origin = 'Email';
			csRec.ProductCategory__c = 'Domestic Parcels';
			csRec.ProductSubCategory__c = 'Express';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			csRec.IsNewForRouting__c  = true;
			csRec.AllocateToQueue__c = true;
			csRec.Bypass_Data_enforcement__c = true;
			Database.insert(csRec);
			
			Test.startTest();
				// CaseCommonUtility.isRouteCaseRecursive = false; // Gunith (2019-03-18): isRouteCaseRecursive not valid anymore due to Recursion logic
				csRec.Description = 'Description Updated';
				Database.update(csRec);
			Test.stopTest();			
		}
		Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
		System.assertEquals(false,cs.AllocateToQueue__c);
		System.assertEquals(Group.sObjectType,cs.OwnerId.getSObjectType());
	}

	/**
	  * @description	   This method tests scenario of routing case with no matching sssw routing
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCaseNoRouting(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
			Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSW_BOH_Group_2' LIMIT 1];
			SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'SMB','Email');
			routing.IsNew__c = true;
			routing.IsActive__c = True;
			routing.ExcludeFromNPS__c = true;
			routing.Queue_ID__c = backOfcQueue.Id;
			Database.insert(routing);
			System.debug('Routing2--->'+routing);

			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
															accRecTypeMap.get('Organisation').getRecordTypeId());
			acc.ServiceSLA__c = 'Test SLA';
			Database.insert(acc);

			Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
			Database.insert(con);
			
			Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
			Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
			csRec.Origin = 'Email';
			csRec.ProductCategory__c = 'Domestic Parcels';
			csRec.ProductSubCategory__c = 'Express';
			csRec.ReferenceId__c = '12345';
			csRec.Address2__c  = '111 Bourke Street';
			csRec.IsNewForRouting__c  = true;
			csRec.AllocateToQueue__c = true;
			Test.startTest();
				Database.insert(csRec);
			Test.stopTest();			
		}
		Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
		System.assertEquals(false,cs.AllocateToQueue__c);
		System.assertEquals(User.sObjectType,cs.OwnerId.getSObjectType());
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testLinkContactExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.assignContactIDToCase(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testValidateCaseExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
			helper.validateCase(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testSpamExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.detectPermanentSpam(new List<Case>{null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testCloseChildExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.closeChildCases(new List<Case>{null},new Map<Id,Case>{null => null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testXferCaseExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.setOwnerToCurrentUser(new List<Case>{null},new Map<Id,Case>{null => null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testAvoidCaseCloseExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.avoidCustomerClose(new List<Case>{null},new Map<Id,Case>{null => null});
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}

// Can be removed NOV-2020
//	/**
//	  * @description	   This method is for covering exception and not a valid business scenario
//	  * @param			 NA
//	  * @return			Void
//	  * @throws			NA
//	  */
//	private static testMethod void testSubscribeArticleExceptionScenario(){
//		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
//		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
//			TestUtility.severityLevelValue();
//			CaseCommonUtility helper = new CaseCommonUtility();
//			Test.startTest();
//				helper.setArticlesSubscribed(new List<Case>{null});
//			Test.stopTest();
//			Integer expCount = [SELECT count() FROM ExceptionLog__c];
//			System.assertEquals(1,expCount);
//		}
//	}
	
	/**
	  * @description	   This method is for covering exception and not a valid business scenario
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	private static testMethod void testRouteCaseExceptionScenario(){
		Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
			TestUtility.severityLevelValue();
			CaseCommonUtility helper = new CaseCommonUtility();
			Test.startTest();
				helper.routeCase(new List<Case>{null},new Map<Id,Case>{null => null}, false);
			Test.stopTest();
			Integer expCount = [SELECT count() FROM ExceptionLog__c];
			System.assertEquals(1,expCount);
		}
	}
   // StarTrack R4.0 and R4.1 Test methods
	/**
	  * @description	   StarTrack - this method is to test closing of tasks and workflow emails after closing Case
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	static testmethod void testCloseBulkTasks() {	
		
		Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(); //Query for delivery enquiry record type
		//Create sample delivery enquiry case.
		Case testCase = TestDataProvider.createTestCase();
		testCase.RecordTypeId = deliveryRecType;
		testCase.Call_Purpose__c = 'Late Delivery';
		testCase.Subject = 'Sample Case';
		testCase.Origin = 'Phone';
		testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
		testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
		Database.insert(testCase);
		
		//Create child tasks
		List<Task> newTasks = new List<Task>();
		newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(), Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING, Priority='Low'));
		newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(), Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING, Priority='Low'));
		Database.insert(newTasks);
		
		//Create child workflow emails
		List<workflow_Email__c> newWFs = new List<workflow_Email__c>();
		newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id, Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING));
		newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id, Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING));
		Database.insert(newWFs);
		
		Test.startTest();
			Case caseRec = [SELECT Id,OwnerId, Status, ResolutionCode__c, Close_Bulk_Tasks__c FROM Case WHERE Id =: testCase.Id];
			caseRec.Close_Bulk_Tasks__c = true;
			Database.update(caseRec);
			
			caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
			caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
			Database.update(caseRec);
		Test.stopTest();
		
		System.assertEquals(true, [SELECT Id, Status FROM Task WHERE Status != :StarTrack_Constants.TASK_STATUS_FINISHED AND WhatId = :testCase.Id].isEmpty());
		System.assertEquals(true, [SELECT Id, Status__c FROM workflow_Email__c WHERE Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE AND Case__c = :testCase.Id].isEmpty());
	}
	
	/**
	  * @description	   StarTrack - This method is used to test notification automation
	  * @param			 NA	 
	  * @return			Void
	  * @throws			NA
	  */
	static testmethod void testNotificationAutomationModel() {	
		
		Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
		UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
		User supportUser = new User(Alias = 'spUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');

		// to avoid MIXED_DML_EXCEPTION 
		User runAsUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(runAsUser){
			Database.insert(supportUser);
		}

		Id notificationRT = Schema.SObjectType.StarTrack_Automation_Rule__c.getRecordTypeInfosByName().get('StarTrack Notification Automation').getRecordTypeId();
		Database.insert(new StarTrack_Automation_Rule__c(RecordTypeId = notificationRT, Order__c = 1, Case_RecordType__c = 'Delivery Enquiry', Case_Status__c = 'Closed', Case_Action__c = 'Send Notification', SMS_Template__c = 'Sample', Email_Template__c = 'Delivered Consignment Notification - Customer Service'));
		Article__c consignment = new Article__c(Name = 'AJSGDH1234', Consignment_Summary_Status__c = 'Delivered');
		Database.insert(consignment);

		System.runAs(supportUser){
			Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(); //Query for delivery enquiry record type
			//Create sample delivery enquiry case.
			Case testCase = TestDataProvider.createTestCase();
			testCase.RecordTypeId = deliveryRecType;
			testCase.Call_Purpose__c = 'Late Delivery';
			testCase.Subject = 'Sample Case';
			testCase.ArticleTest__c = consignment.Id;
			testCase.Origin = 'Phone';
			testCase.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
			testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
			testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
			Database.insert(testCase);
			
			List<AuthorisedContacts__c> relContList = new List<AuthorisedContacts__c>();
			relContList.add(new AuthorisedContacts__c(First_Name__c = 'David', Last_Name__c = 'Catindoy', Contact_Email__c = 'davidcatindoy@gmail.com', Case__c = testCase.Id, Contact_Type__c = 'Sender', Initial_Contact__c = true, Notification_Required__c = true, Pref_Method_of_Contact__c = 'Email'));
			relContList.add(new AuthorisedContacts__c(First_Name__c = 'Joie', Last_Name__c = 'Castillo', Contact_Mobile_Number__c = '0412849506', Case__c = testCase.Id, Contact_Type__c = 'Receiver', Notification_Required__c = true, Pref_Method_of_Contact__c = 'Mobile'));
			relContList.add(new AuthorisedContacts__c(First_Name__c = 'Jen', Last_Name__c = 'Tan', Contact_Phone_Number__c = '0412849506', Case__c = testCase.Id, Contact_Type__c = 'Sender', Notification_Required__c = true, Pref_Method_of_Contact__c = 'Phone'));
			Database.insert(relContList);
			
			Test.startTest();
				Case caseRec = [SELECT Id, OwnerId, Status, ResolutionCode__c FROM Case WHERE Id =: testCase.Id];
				caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
				caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
				Database.update(caseRec);
				
			Test.stopTest();
			
			System.assertEquals(StarTrack_Constants.CASE_STAT_PENCUSNOTIF, [SELECT Id, Status FROM Case WHERE Id = :testCase.Id].Status);
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
	public static String makeFakeId(Schema.SObjectType sot, Integer seed)
	{
		String result = String.valueOf(seed);
		return sot.getDescribe().getKeyPrefix() +
				'0'.repeat(12-result.length()) + result;
	}

	/**
	 * Multiple Test Cases for AllocateToQueue__c after a Case status is made 'New'
	 */
	static testMethod void testMarkRenewedCasesToRoute(){

		Integer idSeed = 1;

		List<Case> casesBeforeTrigger = new List<Case>();
		Map<Id,Case> casesAfterTrigger = new Map<Id, Case>();

		// Refers to a Case which hasn't gone through any changes => shouldn't route
		Case unchanged = new Case(Id = makeFakeId(Case.SObjectType, idSeed++), Status = 'New');
		casesAfterTrigger.put(unchanged.Id, unchanged);
		casesBeforeTrigger.add(unchanged);

		// Refers to a Case.Status=New with No categories and types set => shouldn't route
		String reopenedNoTypesNoCategoriesId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedNoTypesNoCategoriesBefore = new Case(Id = reopenedNoTypesNoCategoriesId, Status = 'Closed');
		Case reopenedNoTypesNoCategoriesAfter = new Case(Id = reopenedNoTypesNoCategoriesId, Status = 'New');
		casesAfterTrigger.put(reopenedNoTypesNoCategoriesBefore.Id, reopenedNoTypesNoCategoriesBefore);
		casesBeforeTrigger.add(reopenedNoTypesNoCategoriesAfter);

		// Refers to a Case.Status=New with categories and types set => should route
		String reopenedId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedBefore = new Case(Id = reopenedId, Status = 'Closed', ProductCategory__c = 'Cat', ProductSubCategory__c = 'SubCat', EnquirySubType__c = 'SubType', Type = 'Type');
		Case reopenedAfter = new Case(Id = reopenedId, Status = 'New', ProductCategory__c = 'Cat', ProductSubCategory__c = 'SubCat', EnquirySubType__c = 'SubType', Type = 'Type');
		casesAfterTrigger.put(reopenedBefore.Id, reopenedBefore);
		casesBeforeTrigger.add(reopenedAfter);

		// Refers to a Case.Status=New and Case.RecordType as 'SSSW Delivery' => should route
		Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId();
		String reopenedSsswId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSsswBefore = new Case(Id = reopenedSsswId, Status = 'Closed', RecordTypeId = deliveryRecType);
		Case reopenedSsswAfter = new Case(Id = reopenedSsswId, Status = 'New', RecordTypeId = deliveryRecType);
		casesAfterTrigger.put(reopenedSsswBefore.Id, reopenedSsswBefore);
		casesBeforeTrigger.add(reopenedSsswAfter);

		// Refers to a Case.Status=New and Case.RecordType as 'Social Record Type' => should route
		Id socialRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Record Type').getRecordTypeId();
		String reopenedSocialId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSocialBefore = new Case(Id = reopenedSocialId, Status = 'Closed', RecordTypeId = socialRecType);
		Case reopenedSocialAfter = new Case(Id = reopenedSocialId, Status = 'New', RecordTypeId = socialRecType);
		casesAfterTrigger.put(reopenedSocialBefore.Id, reopenedSocialBefore);
		casesBeforeTrigger.add(reopenedSocialAfter);

		// Refers to a Case.Status=New, RecordType as 'SSSW Delivery' and IsHLC__c=true => shouldn't route
		String reopenedSsswHlcId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSsswHlcBefore = new Case(Id = reopenedSsswHlcId, Status = 'Closed', RecordTypeId = deliveryRecType, IsHLC__c = true);
		Case reopenedSsswHlcAfter = new Case(Id = reopenedSsswHlcId, Status = 'New', RecordTypeId = deliveryRecType, IsHLC__c = true);
		casesAfterTrigger.put(reopenedSsswHlcBefore.Id, reopenedSsswHlcBefore);
		casesBeforeTrigger.add(reopenedSsswHlcAfter);

		// Refers to a Case.Status=New, RecordType as 'SSSW Delivery' and IsCR__c=true => shouldn't route
		String reopenedSsswCrId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSsswCrBefore = new Case(Id = reopenedSsswCrId, Status = 'Closed', RecordTypeId = deliveryRecType, IsCR__c = true);
		Case reopenedSsswCrAfter = new Case(Id = reopenedSsswCrId, Status = 'New', RecordTypeId = deliveryRecType, IsCR__c = true);
		casesAfterTrigger.put(reopenedSsswCrBefore.Id, reopenedSsswCrBefore);
		casesBeforeTrigger.add(reopenedSsswCrAfter);

		// Refers to a Case.Status=New, RecordType as 'SSSW Delivery', IsCR__c=true and IsHLC__c=true => shouldn't route
		String reopenedSsswHlcCrId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSsswHlcCrBefore = new Case(Id = reopenedSsswHlcCrId, Status = 'Closed', RecordTypeId = deliveryRecType, IsHLC__c = true, IsCR__c = true);
		Case reopenedSsswHlcCrAfter = new Case(Id = reopenedSsswHlcCrId, Status = 'New', RecordTypeId = deliveryRecType, IsHLC__c = true, IsCR__c = true);
		casesAfterTrigger.put(reopenedSsswHlcCrBefore.Id, reopenedSsswHlcCrBefore);
		casesBeforeTrigger.add(reopenedSsswHlcCrAfter);

		// Refers to a Case.Status=New, RecordType as 'SSSW Delivery', AllocateToQueue__c=true => should route, but the method doesn't change the routing status
		String reopenedSsswAllocateTrueId = makeFakeId(Case.SObjectType, idSeed++);
		Case reopenedSsswAllocateTrueBefore = new Case(Id = reopenedSsswAllocateTrueId, Status = 'Closed', AllocateToQueue__c = true, RecordTypeId = deliveryRecType);
		Case reopenedSsswAllocateTrueAfter = new Case(Id = reopenedSsswAllocateTrueId, Status = 'New', AllocateToQueue__c = true, RecordTypeId = deliveryRecType);
		casesAfterTrigger.put(reopenedSsswAllocateTrueBefore.Id, reopenedSsswAllocateTrueBefore);
		casesBeforeTrigger.add(reopenedSsswAllocateTrueAfter);

		CaseCommonUtility.markRenewedCasesToRoute(casesBeforeTrigger, casesAfterTrigger);

		System.assertEquals(false, unchanged.AllocateToQueue__c, 'a Case which hasnt gone through any changes => shouldnt route');
		System.assertEquals(false, reopenedNoTypesNoCategoriesAfter.AllocateToQueue__c, 'a Case.Status=New with categories and types set => should route');
		System.assertEquals(true, reopenedAfter.AllocateToQueue__c, 'a Case.Status=New and Case.RecordType as SSSW Delivery => should route');
		System.assertEquals(true, reopenedSsswAfter.AllocateToQueue__c, 'a Case.Status=New and Case.RecordType as Social Record Type => should route');
		System.assertEquals(true, reopenedSocialAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery and IsHLC__c=true => shouldnt route');
		System.assertEquals(false, reopenedSsswHlcAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery and IsCR__c=true => shouldnt route');
		System.assertEquals(false, reopenedSsswCrAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery, IsCR__c=true and IsHLC__c=true => shouldnt route');
		System.assertEquals(false, reopenedSsswHlcCrAfter.AllocateToQueue__c, 'a Case which hasnt gone through any changes => shouldnt route');
		System.assertEquals(true, reopenedSsswAllocateTrueAfter.AllocateToQueue__c, ' a Case.Status=New, RecordType as SSSW Delivery, AllocateToQueue__c=true => should route, but the method doesnt change the routing status');
	}
	
	/***************************************************************************************************
	*  Scenario:
	*	  Populate the requestor's lookup field with current user if left empty on a case creation 
	* with 'Customer Analytics & Reporting Request (CAR)' record type
	****************************************************************************************************/
	public static testmethod void populateRequestorWithCurrentUserWhenRequestorLeftEmpty(){
		Profile prof = [SELECT Id FROM Profile WHERE Name=: ADMIN_PROFILE];
		// Create a test user with System Admin profile
		User testuser = TestUtility.createUser('SethOrg',prof.id,null);
		// run as the test user
		System.runAs(testuser){
			Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
			// set up a test organisation account from the setup
			Account testAcc  = TestDataProvider.createAccount('Test Adjustment Account', 1)[0];
			insert testAcc; 
			// query the 'CAR' case record type id
			Id CARcaseRecordTypeId = [select id from recordType where DeveloperName = 'CAR_Request'].id;
			
			Case testCase = new Case();
			// Create a new case and assign it as the 'CAR' record type
			testCase.RecordTypeId = CARcaseRecordTypeId;
			// Not Email2Case
			testCase.SuppliedEmail = null;
			// Set requestor to null
			testCase.requestor__c = null; 
			testCase.Work_Type__c = 'Parcel Post Dashboard Enquiry';
			// Assign case owner to current test user
			testCase.AccountId = testAcc.Id;
			testCase.Products_Services__c = 'Parcel Post;Star Track Express';
			testCase.Subject = 'Testing Requestor Population';
			testCase.Description = 'Test Description';

			// Set date time to 2 days ahead
			DateTime dt = System.now();
			dt.addDays(2);
			testCase.SLATargetDate__c = dt;
			
			test.startTest();
			insert testCase;
			test.stopTest();
			
			// get current user id
			Id userID = UserInfo.getUserId();
			// query the newly created case
			Case newCase = [Select id, requestor__c from Case WHERE Subject = 'Testing Requestor Population' LIMIT 1];
			// check that the requestor field is now populated with current user
			System.assertEquals(userID, newCase.Requestor__c, 'CaseCommonUtility_populateRequestorWithCurrentUserWhenRequestorLeftEmpty : Requestor field should be the current user');
			
		}
	}

	 /**
	 * Test logic in markRenewedCasesToRoute() that sets reopened Cases for routing
	 *
	 * Covers the following positive test scenarios:
	 * a) Closed Case in the Closed Omni Queue is changing to a Status where IsClosed = false
	 * 
	 * Covers the following negative testing scenarios:
	 * a) Closed Case in the Closed Omni Queue is changing to a Status where IsClosed = true
	 * 
	 */
	@isTest
	static void routeReopenedCases(){

		//Queues
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject closedOmniqueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Closed_Omnichannel_Cases' AND SobjectType = 'Case' LIMIT 1];
		custSetting.ClosedQueueId__c = closedOmniqueue.QueueId;
		Insert custSetting;

		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Queue', true));	
		Group nonOmniQueue = queues.values()[0];

		//Case Status
		CacheManager.settings.CacheEnabled__c = true;

		List<CaseStatus> caseStatuses = ApplicationTestDataFactory.getCaseStatuses(3, false);
		CaseStatus closedStatus1 = caseStatuses[0];
		closedStatus1 = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(closedStatus1, new Map<String, Object>{'IsClosed' => true});
		CaseStatus closedStatus2 = caseStatuses[1];
		closedStatus2 = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(closedStatus2, new Map<String, Object>{'IsClosed' => true});
		CaseStatus nonClosedStatus = caseStatuses[2];
		nonClosedStatus = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(nonClosedStatus, new Map<String, Object>{'IsClosed' => false});

		Set<String> closedCaseStatuses = new Set<String>{closedStatus1.MasterLabel, closedStatus2.MasterLabel};
		CacheManager.put('CASE_CLOSED_STATUSES',closedCaseStatuses );

		
		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		
		cases[0].OwnerId = closedOmniqueue.QueueId; //Case reopened and in Closed Omni queue
		cases[0].Status = nonClosedStatus.MasterLabel;

		cases[1].OwnerId = closedOmniqueue.QueueId; //Case changing from a Closed Status to another Closed Status
		cases[1].Status = closedStatus1.MasterLabel;


		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true)
		};
		oldCases[0].Status = closedStatus2.MasterLabel;
		oldCases[1].Status = closedStatus2.MasterLabel;
		
		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		
		CaseCommonUtility.markRenewedCasesToRoute(cases, new Map<Id,Case>(oldCases));

		Test.stopTest();
		
		System.assertEquals(true, cases[0].AllocateToQueue__c, 'Closed Case changing to a non-closed Status based => should route');
		System.assertEquals(false, cases[1].AllocateToQueue__c, 'Closed Case changing to another closed Status => should not route');
		
	}


	/**
	 * Test logic in routeCase() that 
	 * 1. moves closed Cases to the Closed Omni queue and
	 * 2. prevent routing triggered by AllocateToQueue based on Case Owner
	 * 
	 * For 1. Closed Cases, test scenarios are:
	 * a) Closed Case status changed from Open => Close (positive)
	 * b) Closed Case Owner changed (positive)
	 * c) Closed Case is inserted (positive)
	 * d) Closed Case in a Queue without Routing config (negative)
	 * e) Case not in a Closed Status (negative)
	 * f) Case with no change in Status (negative)
	 * 
	 * For 2. Prevent Routing based on Case Owner, test scenarios are:
	 * a) Open Case owned by an Agent (positive)
	 * b) Permanently Closed Case (positive)
	 * c) Case owned by Omni Holding Queue (positive)
	 * d) No change to AllocateToQueue (positive)
	 * e) Closed Case owned by an (negative, allow routing)
	 * 
	 */
	@IsTest
	static void closedCasesToClosedQueueAndPreventRoutingIfOwnedByUser(){

		//Setup Custom Setting values
		QM__c custSetting = QM__c.getOrgDefaults();
		Id omniClosedQueueId;
		Id omniHoldingQueueId;
		List<Group> omniQueues = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN ('SSSW_Closed_Omnichannel_Cases','SSSW_Routing_Holding_Queue')];
		for(Group omniQueue : omniQueues){			
			if(omniQueue.DeveloperName == 'SSSW_Closed_Omnichannel_Cases'){
				custSetting.ClosedQueueId__c = omniQueue.Id;
				omniClosedQueueId = omniQueue.Id;
			}

			if(omniQueue.DeveloperName == 'SSSW_Routing_Holding_Queue'){
				custSetting.HoldingQueueId__c = omniQueue.Id;
				omniHoldingQueueId = omniQueue.Id;
			}
		}
		Insert custSetting;

		QueueRoutingConfig qrc = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject>{qrc});
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));	
		Group omniQueue = queues.values()[0];
		omniQueue.QueueRoutingConfigId = qrc.Id;
		Group nonOmniQueue = queues.values()[1];

		//Agent User
		List<User> users = ApplicationTestDataFactory.getUsers(1, true);

		//Routing Rule
		SSSWRouting__c routingRule = new SSSWRouting__c();
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		routingRule.Queue_ID__c = omniQueue.Id;
		routingRule.Sequence__c = 1;
		Insert routingRule;

		//Case Status
		CacheManager.settings.CacheEnabled__c = true;

		List<CaseStatus> caseStatuses = ApplicationTestDataFactory.getCaseStatuses(3, false);
		CaseStatus closedStatus = caseStatuses[0];
		closedStatus = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(closedStatus, new Map<String, Object>{'IsClosed' => true});
		CaseStatus nonClosedStatus = caseStatuses[2];
		nonClosedStatus = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(nonClosedStatus, new Map<String, Object>{'IsClosed' => false});

		Set<String> closedCaseStatuses = new Set<String>{closedStatus.MasterLabel};
		CacheManager.put('CASE_CLOSED_STATUSES',closedCaseStatuses );
		
		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(11, true);
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();

		Map<Id, Case> validCasesUpdate = new Map<Id, Case>();
		Map<Id, Case> validCasesInsert = new Map<Id, Case>();

		for(Case csRec: cases){
			csRec.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
			csRec.Origin = 'Email';
			validCasesUpdate.put(csRec.Id, csRec);
		}

		//1. Closed Cases - POSITIVE scenarios 
		cases[0].OwnerId = omniQueue.Id; //Closed Case status changed from Open => Close
		cases[0].Status = closedStatus.MasterLabel;

		cases[1].OwnerId = omniQueue.Id; //Closed Case Owner changed 
		cases[1].Status = closedStatus.MasterLabel;

		cases[5].OwnerId = omniQueue.Id;
		cases[5].Status = closedStatus.MasterLabel;
		validCasesUpdate.remove(cases[5].id);
		validCasesInsert.put(cases[5].id, cases[5]); //Inserted as Closed Cased  

		//1. Closed Cases - NEGATIVE scenarios 
		cases[2].OwnerId = nonOmniQueue.Id; //Closed Case in a Queue without Routing config
		cases[2].Status = closedStatus.MasterLabel;

		cases[3].OwnerId = omniQueue.Id; //Case not in a Closed Status
		cases[3].Status = nonClosedStatus.MasterLabel;

		cases[4].OwnerId = omniQueue.Id; //Case with no change in both Status and OwnerId
		cases[4].Status = closedStatus.MasterLabel;


		//2. Prevent Routing - POSITIVE scenarios 
		cases[6].OwnerId = users[0].Id; //Open Case with User
		cases[6].Status = nonClosedStatus.MasterLabel;
		cases[6].Permanent_Close__c = false;
		cases[6].AllocateToQueue__c = true;
		Profile agentProfile = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
		cases[6] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[6], new Map<String, Object>{'Case_Owner_User_Profile_Name__c' => agentProfile.Name});

		cases[7].OwnerId = users[0].Id; //Permanently closed Case
		cases[7].Status = closedStatus.MasterLabel;
		cases[7].Permanent_Close__c = true;
		cases[7].AllocateToQueue__c = true;

		cases[8].OwnerId = omniHoldingQueueId; //Case in Omni Holding Queue
		cases[8].Status = nonClosedStatus.MasterLabel;
		cases[8].Permanent_Close__c = false;
		cases[8].AllocateToQueue__c = true;

		cases[9].OwnerId = omniQueue.Id; //No change to AllocateToQueue value
		cases[9].Status = nonClosedStatus.MasterLabel;
		cases[9].Permanent_Close__c = false;
		cases[9].AllocateToQueue__c = true;

		//2. Prevent Routing - NEGATIVE scenarios, allow routing
		cases[10].OwnerId = users[0].Id; //Closed Case with User
		cases[10].Status = closedStatus.MasterLabel;
		cases[10].Permanent_Close__c = false;
		cases[10].AllocateToQueue__c = true;


		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true),
			cases[6].clone(true),
			cases[7].clone(true),
			cases[8].clone(true),
			cases[9].clone(true),
			cases[10].clone(true)
		};

		//1. Closed Cases
		oldCases[0].Status = nonClosedStatus.MasterLabel;
		oldcases[1].Status = closedStatus.MasterLabel;
		oldcases[1].OwnerId = users[0].Id;
		oldcases[2].Status = nonClosedStatus.MasterLabel;
		oldcases[3].Status = nonClosedStatus.MasterLabel;
		oldcases[4].Status = closedStatus.MasterLabel;

		//2. Prevent Routing
		oldcases[5].AllocateToQueue__c = false;
		oldcases[6].AllocateToQueue__c = false;
		oldcases[7].AllocateToQueue__c = false;
		oldcases[8].AllocateToQueue__c = true;
		oldcases[9].AllocateToQueue__c = false;
		
		// =====================================
		// Stubbing
		// =====================================
		
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);	 
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();   
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockGroupsSelector.selectOmniQueues(new Set<Object>())).thenReturn(new Map<Id,Group>{omniQueue.Id => omniQueue} ); //only queues of cases that fit the criteria are queried

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseCommonUtility helper = new CaseCommonUtility();			
		helper.routeCase(validCasesUpdate.values(),new Map<Id,Case>(oldCases),false);
		helper.routeCase(validCasesInsert.values(),null,true);

		Test.stopTest();

		//1. Closed Cases
		System.assertEquals(omniClosedQueueId, cases[0].OwnerId, 'Closed Case status changed from Open to Close => moved to Closed Case Queue');
		System.assertEquals(omniClosedQueueId, cases[1].OwnerId, 'Closed Case Owner changed  => moved to Closed Case Queue');
		System.assertEquals(omniClosedQueueId, cases[5].OwnerId, 'Closed Case inserted  => moved to Closed Case Queue');
		System.assertNotEquals(omniClosedQueueId, cases[2].OwnerId, 'Closed Case in a Queue without Routing config => not in Closed Case Queue');
		System.assertNotEquals(omniClosedQueueId, cases[3].OwnerId, 'Case not in a Closed Status => not in Closed Case Queue');
		System.assertNotEquals(omniClosedQueueId, cases[4].OwnerId, 'Case with no change in Status => not in Closed Case Queue');

		//2. Prevent Routing
		System.assertEquals(users[0].Id, cases[6].OwnerId, 'Open Case with User should not have routed');
		System.assertEquals(users[0].Id, cases[7].OwnerId, 'Permanently closed Case should not have routed');
		System.assertEquals(omniHoldingQueueId, cases[8].OwnerId, 'Case in Omni Holding queue should not have routed');
		System.assertNotEquals(users[0].Id, cases[9].OwnerId, 'Case should not have routed if AllocateToQueue did not change');
		System.assertNotEquals(omniQueue.Id, cases[10].OwnerId, 'Case should be routed based on routing rule if Case is Closed but not Permanently closed');
	}

	/**
	 * Tests the logic relating to Preferred Agent routing in routeCase() 
	 * 
	 * Scenarios:
	 * a) PSR inserted with correct PreferredUserId
	 * b) PSR not inserted - no AgentWork exists
	 * c) PSR not inserted - BypassPreferredAgent is true
	 * d) PSR not inserted - PreferredAgentExpiry is blank
	 * e) PSR not inserted - has Accepted AgentWork, but in Omni Queue 
	 * 
	 */
	@isTest
	static void testAssignToPreferredAgent(){

		//Queues
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject preferredAgentQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Preferred_Agent_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.PreferredAgentQueueId__c = preferredAgentQueue.QueueId;
		custSetting.PreferredAgentSkillDeveloperNames__c = 'BOH';
		Insert custSetting;
		Id preferredAgentQueueId = preferredAgentQueue.QueueId;

		Group omniQueue = OmniChannelService.Cache.queuesWithRoutingConfig.values()[0].queue;		

		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		users[0].IsActive = true;	
		
		//DateTime
		DateTime oneHourFromNow = DateTime.now().addHours(1);

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(6, true);	
		Map<Id,Case> casesMap = new Map<Id,Case>(cases);

		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		if(ssswRecTypes.size()>0){
			Id recTypeId = ssswRecTypes.iterator().next(); 
			for(Case tempCase : cases){
				tempCase.recordTypeId = recTypeId;
			}
		}

		cases[0].OwnerId = omniQueue.Id; //a) PSR inserted with correct PreferredUserId
		cases[0].Priority = 'Low';
		cases[0].BypassPreferredAgent__c = false;
		cases[0].PreferredAgentExpiry__c = oneHourFromNow;
		cases[0].Origin = 'Email';

		cases[1].OwnerId = omniQueue.Id; //b) PSR not inserted - no Accepted Agent Work exists
		cases[1].Priority = 'Low';
		cases[1].BypassPreferredAgent__c = false;
		cases[1].PreferredAgentExpiry__c = oneHourFromNow;
		cases[1].Origin = 'Email';

		cases[2].OwnerId = omniQueue.Id; //c) PSR not inserted - BypassPreferredAgent is true
		cases[2].BypassPreferredAgent__c = true;
		cases[2].PreferredAgentExpiry__c = oneHourFromNow;
		cases[2].Origin = 'Email';

		cases[3].OwnerId = omniQueue.Id; //d) PSR not inserted - PreferredAgentExpiry is blank
		cases[3].BypassPreferredAgent__c = false;
		cases[3].PreferredAgentExpiry__c = null;
		cases[3].Origin = 'Email';

		cases[4].OwnerId = omniQueue.Id; //e) PSR not inserted - has Accepted AgentWork, but currently in Omni Queue 
		cases[4].Priority = 'Low';
		cases[4].BypassPreferredAgent__c = false;
		cases[4].PreferredAgentExpiry__c = oneHourFromNow;
		cases[4].Origin = 'Email';		

		cases[5].OwnerId = omniQueue.Id; // part of Release 2 TEMPORARY FIX
		cases[5].Priority = 'Low';
		cases[5].BypassPreferredAgent__c = false;
		cases[5].PreferredAgentExpiry__c = oneHourFromNow;
		cases[5].Origin = 'Portal';	

		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true),
			cases[5].clone(true)
		};

		for(Case tempCase : oldCases){
			tempCase.OwnerId = users[0].Id;
		}
		oldCases[4].OwnerId = omniQueue.Id;

		//AgentWorks
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(4, users[0].Id, new Set<Id>{cases[0].Id, cases[2].Id, cases[3].Id, cases[4].Id,cases[5].Id}, true);

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ServiceResourceSkillSelector mockServiceResourceSkillSelector = (ServiceResourceSkillSelector)MockUtility.mockSelector(ServiceResourceSkillSelector.class);	 
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockOmniChannelService.getCaseIdsWithLatestAcceptedAgentWorks(
			(Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id, cases[5].Id})
		)).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );

		MockUtility.Mocks.when(mockOmniChannelService.getUserIdsWithPreferredAgentSkills(
			(Set<Id>)fflib_Match.eq(new Set<Id>{ users[0].Id })
		)).thenReturn(new Set<Id>{ users[0].Id });

		MockUtility.Mocks.when(mockDatabase.dmlInsert(
			(List<SObject>)fflib_Match.anyObject(), 
			fflib_Match.anyBoolean()
		)).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		
		Test.startTest();

		CaseCommonUtility helper = new CaseCommonUtility();			
		helper.routeCase(cases, new Map<Id,Case>(oldCases),false);

		Test.stopTest();
		
		System.assertEquals(preferredAgentQueueId, cases[0].OwnerId, 'Case should be assigned to Preferred Agent Queue');		
		System.assertEquals(omniQueue.Id, cases[1].OwnerId, 'Case without accepted AgentWork should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[2].OwnerId, 'Case with BypassPreferredAgent = true should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[3].OwnerId, 'Case with blank PreferredAgentExpiry should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[4].OwnerId, 'Case that is coming from an Omni Queue should be in new Omni Queue');
		System.assertEquals(omniQueue.Id, cases[5].OwnerId, 'Case with portal-related Origin should be in Omni Queue'); // part of Release 2 TEMPORARY FIX
	}

}