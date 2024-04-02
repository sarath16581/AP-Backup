/**
 * @domain Tests
 * @changelog
 * 2022-02-17 - Alex Volkov - Updated data setup to reflect changes to case comment creation
 *                            Commented out redundant dataSetUp calls
 * 2022-06-15 - Hasantha Liyanage - DDS-10974 change of how the parseInsertedCaseResultsAndCreateComment is accessed as per the refactoring
 * 2023-06-02 - StephenL DDS-16136 added test methods for getLoggedInUserCaseList, including both the matching by user id and match apcn logic
 * 2024-03-25 - Naveen Rajanna - INC2216801 - Test coverage for updateCase method
 */
@IsTest
public class ChasCustomCaseListAndDetailTest {
	
	
	@TestSetup
	static void dataSetUp() {
		try{
			//-- Create Case
			Id SSSWGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
				.get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();
			String origin = 'Web'; 
			String type = 'General Enquiry';
			String typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
			String enquirySubType = 'Tracking';
			String  productCategory = 'Domestic Parcels';
			String productSubCategory = 'Parcel Post';
			String CHASEnquiryType='Complaints & feedback';
			Case toBeCreateCase = new Case(
				RecordTypeId=SSSWGeneralRecordTypeId,
				Origin=origin,
				First_Name__c = 'Given Name',
				Last_Name__c='A',
				SuppliedEmail='a@gmail.com',
				SuppliedPhone='099999999',
				Subject='subject1',
				Type=type,
				Type_and_Product__c = typeAndProduct,
				EnquirySubType__c = enquirySubType,
				ProductCategory__c = productCategory,
				ProductSubCategory__c = productSubCategory,
				CHASEnquiryType__c = CHASEnquiryType,
				ValueofContents__c =25);
			 //-- Crating Case
			Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase });
			//-- Parse Case results and create Case Comment
			ChasBase.SharingBypass lSharingBypass = new ChasBase.SharingBypass();
			lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, new ChasBase.CaseWrapper(), new List<CaseComment>{new CaseComment(CommentBody = 'Test comment Body')});
			//-- Create Case Comment
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR, 'ChasCustomCaseListAndDetailTest::dataSetUp() ==>Error occoured while creating Case/Case comment in data setup of test class==>'+ex);
		}
		
	}
	
	/**
	* Success Case of create Case with 'Compalint and feedback'
	* */
	@IsTest
	public static void fetchCaseCommentsTest() {
		Boolean isSuccess = true; 
		
		try{
			//dataSetUp();
			
			Test.startTest();
			Case caseObJ = [SELECT Id FROM Case WHERE Subject='subject1' LIMIT 1];
			ChasCustomCaseListAndDetailController.fetchCaseComments(caseObJ.Id);
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
	/**
	* Success Case of create case comment 
	* */
	@IsTest
	public static void createCaseCommentTest() {
		Boolean isSuccess = true; 
		
		try{
			//dataSetUp();
			
			Test.startTest();
			Case caseObJ = [SELECT Id FROM Case WHERE Subject='subject1' LIMIT 1];
			ChasCustomCaseListAndDetailController.creatCaseComment(caseObJ.Id, 'comment body desc');
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
		
	/**
* Success Case to get current current user name
* */
	@IsTest
	public static void getCurrentUserNameTest() {
		Boolean isSuccess = true; 
		
		try{
			
			Test.startTest();
			ChasCustomCaseListAndDetailController.getCurrentUserName();
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
	/**
	* Success Case to get current current user name
	* */
	@IsTest
	public static void updateCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseToUpdate = ApplicationTestDataFactory.getCases(1, true)[0];
		caseToUpdate.Status='Closed';
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ChasCustomCaseListAndDetailController.updateCase(caseToUpdate);
		Test.stopTest();
		System.Assert.areEqual(1, MockUtility.mockDMLUpdatedRecords.size());
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpdate((List<SObject>) fflib_Match.anyObject());
	}
	
	/**
	* Failed Case to get current current user name
	* */
	@IsTest
	public static void updateCaseFail() {
		Boolean isSuccess = true; 
		
		try{
			Test.startTest();
			Case caseObJ = [SELECT Id FROM Case WHERE Subject='subject1' LIMIT 1];
			caseObJ.Status = 'invalid';
			ChasCustomCaseListAndDetailController.updateCase(caseObJ);
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
	/**
	* Success Case to get current current user name
	* */
	@IsTest
	public static void getCaseStatusTest() {
		Boolean isSuccess = true; 
		
		try{
			//dataSetUp();
			Test.startTest();
			Case caseObJ = [SELECT Id FROM Case WHERE Subject='subject1' LIMIT 1];
			ChasCustomCaseListAndDetailController.getCaseStatus(caseObJ.Id);
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
	/**
	* Success get logged in user Cases by having the case's CreatedById and Running User's Id matching
	* */
	@IsTest
	public static void getCurrentUserCases_matchingUserId() {
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		contacts.get(0).APCN__c = '1231';
		contacts.get(1).APCN__c = '9999';
		insert contacts;

		Case selectedCase = [SELECT Id, ContactId FROM Case WHERE Subject = 'subject1' LIMIT 1];
		selectedCase.ContactId = contacts.get(0).Id; // this is 1231
		update selectedCase;

		Boolean hasException = false;
		try {
			List<Case> selectedCases = ChasCustomCaseListAndDetailController.getLoggedInUserCaseList();
			Case newCase = selectedCases.get(0);
			System.assertEquals(UserInfo.getUserId(), newCase.CreatedById, 'Case selected by match running user id and CreatedByID');
		} catch (Exception ex) {
			hasException = true;
		}
		System.assert(!hasException);
	}

	/**
	* Success get logged in user Cases by having the case's contact's APCN and Running User's APCN matching
	* */
	@IsTest
	public static void getCurrentUserCases_matchingAPCN() {
		final String testAPCN = '1234';

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
		contacts.get(0).APCN__c = testAPCN;
		insert contacts;

		Case selectedCase = [SELECT Id, ContactId FROM Case WHERE Subject = 'subject1' LIMIT 1];
		selectedCase.ContactId = contacts.get(0).Id;
		update selectedCase;

		Test.startTest();
		User portalUserRecord = TestUtility.createPortalUser('Testing0', APCommunityUserUtility_Test.ddcConsumerCommunityProfileId, contacts.get(0).Id) ;
		insert portalUserRecord;

		portalUserRecord = [SELECT Id,Contact.APCN__c FROM User WHERE Id = :portalUserRecord.Id];
		Test.stopTest();
		System.runAs(portalUserRecord) {
			Boolean hasException = false;
			try {
				List<Case> cases = ChasCustomCaseListAndDetailController.getLoggedInUserCaseList();
				System.assertEquals(1, cases.size(), 'There should be only one case selected by having the match APCN');
				System.assertEquals(testAPCN, cases.get(0).Contact.APCN__c, 'The case should have the test APCN attached');
				System.assertEquals(testAPCN, portalUserRecord.Contact.APCN__c, 'The portalUserRecord should have the test APCN attached');
				System.assertNotEquals(portalUserRecord.Id, cases.get(0).CreatedById, 'The case was not created by the portalUserRecord, should not have matching user id');
			} catch (Exception ex) {
				hasException = true;
			}
			System.assert(!hasException);
		}
	}
	
	/**
	* Success Case of fetch get Case Status Excepton case
	* */
	@IsTest
	public static void getCaseStatusExceptionTest() {
		Boolean isSuccess = true; 
		
		try{
			//dataSetUp();
			
			Test.startTest();
			//Case caseObJ = [SELECT Id FROM Case where Subject='subject1' Limit 1];
			ChasCustomCaseListAndDetailController.getCaseStatus('1234');
			Test.stopTest();
			
		}catch(Exception e){
			isSuccess = false;
		}
		System.assert(isSuccess); 
	}
	
}