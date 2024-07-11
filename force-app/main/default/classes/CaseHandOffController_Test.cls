/**
* @description Test class for CaseHandOffController
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
**/
@isTest
public class CaseHandOffController_Test {
    @isTest
    static void testUpdateCase() {

		List<Case> cases = ApplicationTestDataFactory.getCases(1,false);        
		cases[0].RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Investigation').getRecordTypeId();
        cases[0].CaseOriginator__c = '3rd Party';
        cases[0].Status = 'New';
		INSERT cases;        
        
        // Call the method
        Test.startTest();
        //CaseHandOffController.handOffCase(cases[0], 'Test comment', 'AustraliaPost', 'UnifiedAusPostHandoffTriageQueue', 'UnifiedInvestigation');
        Test.stopTest();

        // Verify the updates
        Id caseSSSWGeneralEnquiryRecordTyped = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
        Id  caseSSSWentitlement = CaseHandOffController.getSSSWEntitlementId();
        Case testCase = [SELECT Id, CaseTransferDate__c, RecordTypeId, CaseOriginator__c, EntitlementId  FROM Case WHERE Id = :cases[0].Id];
        
        System.assertNotEquals(null, testCase.CaseTransferDate__c, 'Case transfer date should be updated');
        System.assertEquals('Customer', testCase.CaseOriginator__c, 'Case Originatorshould be set to Customer');        
        System.assertEquals(caseSSSWentitlement, testCase.EntitlementId, 'Case Entitlement should be set to Standard Entitlement - SSSW');        
        System.assertEquals(caseSSSWGeneralEnquiryRecordTyped, testCase.RecordTypeId, 'Record type should be set to SSSWGeneralEnquiry');

        // Verify case comment insertion
        CaseComment[] caseComments = [SELECT Id FROM CaseComment WHERE ParentId = :testCase.Id];
        System.assertEquals(1, caseComments.size(), 'One case comment should be inserted');
    }


	public static testmethod void runTest() {
		// Mock Data Records
		RecordType rtUnifiedInvestigation = new RecordType(
			Id = fflib_IDGenerator.generate(RecordType.getSObjectType()),
			DeveloperName = 'UnifiedInvestigation'
		);

		Contact testContact = new Contact(
			Id = fflib_IDGenerator.generate(Contact.SObjectType)
		);

		Case apCase = new Case(			
			Id = fflib_IDGenerator.generate(Case.SObjectType),
			RecordType = rtUnifiedInvestigation,
			RecordTypeId = rtUnifiedInvestigation.Id,
			CaseOriginator__c = '3rd Party', 
			Status = 'New'
			// Address3__c, 
			// Address3Country__c, 
			// Address3Line2__c, 
			// Address3Postcode__c, 
			// Address3State__c, 
			// Address3Suburb__c,			
			// Address4__c, 
			// Address4Country__c, 
			// Address4Line2__c, 
			// Address4Postcode__c, 
			// Address4State__c, 
			// Address4Suburb__c, 
			// ArticleTest__c,			
			// ContactId, 
			// CaseNumber, 
			// Contact.AccountId, 
			// CaseTransferDate__c, 
			// CHASEnquiryType__c,			
			// CaseTransferReason__c, 
			// EnquirySubType__c, 
			// EntitlementId, 
			// ProductCategory__c, 
			// ProductSubCategory__c, 
			// Subject,			
			// Type, 
			// ReferenceID__c
		);

		ImpactedArticle__c testImpactedArticle = new ImpactedArticle__c(
			Article__c = '',
			ArticleId__c = ''
		);

		Case stCase = new Case(

		);

		// ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		EntitlementsSelector mockEntitlements = (EntitlementsSelector)MockUtility.mockSelector(EntitlementsSelector.class);
		ImpactedArticlesSelector mockImpactedArticles = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())
		).thenReturn(
			new Map<Id,Case>{ apCase.Id => apCase }
		);

		MockUtility.Mocks.when(
			mockEntitlements.selectByNameAndAccountName((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())
		).thenReturn(
			new Entitlement(Id = fflib_IdGenerator.generate(Entitlement.SObjectType))
		);

		MockUtility.Mocks.when(
			mockImpactedArticles.selectByCaseId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())
		).thenReturn(
			new List<ImpactedArticle__c>{ testImpactedArticle }
		);

		MockUtility.Mocks.when(
			mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())
		).thenAnswer(
			new MockUtility.AnswerGenericDMLUpdated()
		);

		MockUtility.Mocks.when(
			mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())
		).thenAnswer(
			new MockUtility.AnswerGenericDMLInserted()
		);

		MockUtility.Mocks.stopStubbing();

		// Test Actual scenarios

		CaseHandOffController.CaseHandOffWrapper request = new CaseHandOffController.CaseHandOffWrapper();

		request.articleId = '';
		request.businessUnit = 'AustraliaPost';
		request.caseId = apCase.Id;
		request.caseRecordType = 'UnifiedInvestigation';
		request.comment = 'Testing';
		request.contactCenter = 'UnifiedAusPostHandoffTriageQueue';
		request.handoffReason = 'Network contact required';

		CaseHandOffController.handoffCase(request);
	}
}