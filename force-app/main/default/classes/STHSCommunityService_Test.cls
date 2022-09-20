/**
 * @File Name          : STHSCommunityService_Test.cls
 * @Description        : Test class for STHSCommunityService
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class STHSCommunityService_Test {

    private static Map<Object, String> formData;

    @testSetup
    static void testSetup() { 
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c(
            Check_for_Duplicate_Email__c = true, ST_Credit_Claim_Inbound_Email_Prefix__c='ccie', DHL1__c='dhlcold.chain@startrack.com.au', DHL2__c='dhl.apple@startrack.com.au', DHL3__c='dhlservices@startrack.com.au', DHL4__c='mailbox.dhlservices@startrack.com.au', DHL5__c='mailbox.dhlservices@startrack.com', BSC_Apple__c='apple@startrack.com.au', BSC_Defence_Force__c='defence@startrack.com.au', BSC_Dell_Schenker__c='dell.sydney@startrack.com.au', BSC_Phillips_Schenker__c='schenkerphillips@startrack.com.au', ST_Acc_Mgr_Supp__c='account.managers@startrack.com.au', BSC_DHL_Road__c='dhlsupplychain@startrack.com.au', BSC_Fedex_Enq__c='fedex.enquiries@startrack.com.au', BSC_Fedex_Pick__c='fedexpkups@startrack.com.au', BSC_HP_Schenker__c='schenkerhp@startrack.com.au', BSC_Optus__c='optus@startrack.com.au', BSC_Samsung__c='samsung@startrack.com.au', BSC_Stop_Delivery__c='stop.delivery@startrack.com.au', BSC_Telstra__c='telstrateam@startrack.com.au', BSC_Optus_Stop_Delivery__c='optusstop@startrack.com.au', Business_Solutions_From_Email__c='businesscentre@startrack.com.au', Investigators_From_Email__c='customerservice@startrack.com.au', Credit_Dispute_From_Email__c='credit.claims@startrack.com.au', Transit_Warranty_From_Email__c='transit.warranty@startrack.com.au', VOC_From_Email__c='customer.satisfaction@startrack.com.au', General_Enquiry_From_Address__c='customerservice@startrack.com.au', Default_From_Email__c='businesscentre@startrack.com.au', Startrackdamages__c='damages@startrack.com.au'
        );
        insert(customSetting);
    }
    
    private static Map<Object, String> formDataSetup() {
        if (formData == null) {
            formData = new Map<Object, String>();
            //form data setup
            formData.put('enquiry', 'Product & Sales');
            formData.put('reference', '34TE345634562');
            formData.put('firstName', 'UserFName');
            formData.put('lastName', 'UserLName');
            formData.put('phone', '0303456456');
            formData.put('email', 'test.user@test.com');
            formData.put('feedbackDetails', 'feedbackDetails');
        }
        return formData.clone();
    }

    /**
	 * Scenario: Testing to set the default case values
	 */
	@IsTest
	private static void testGetCaseDefaultValues() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();

        
		// =====================================
		// Stubbing
		// =====================================
        AssignmentRulesSelector mockAssignmentRulesSelector = (AssignmentRulesSelector)MockUtility.mockSelector(AssignmentRulesSelector.class);
        AssignmentRule ar = ApplicationTestDataFactory.getAssignmentRules(1, STHSConstants.CASE_OBJ, true)[0];

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAssignmentRulesSelector.selectActiveRulesBySObjectType(STHSConstants.CASE_OBJ)).thenReturn(new Map<Id, AssignmentRule>{ar.Id => ar});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        Case caseObj = new Case();        
        STHSCommunityService service = STHSCommunityService.getInstance();
        service.getFormCaseData(caseObj, formData);        
        service.getCaseDefaultValues(caseObj);

        Test.stopTest();

        System.assertNotEquals(null, caseObj.Status, 'Expected Status of the case to be populated but instead got null.');

	}

    /**
	 * Scenario: Testing to set the default case object values from form data
	 */
	@IsTest
	private static void testGetFormCaseData() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();

		// =====================================
		// Stubbing
		// =====================================
        // None

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        Case caseObj = new Case();
        STHSCommunityService service = STHSCommunityService.getInstance();
        service.getFormCaseData(caseObj, formData);

        Test.stopTest();

        System.assertNotEquals(null, caseObj.SuppliedEmail, 'Expected Supplied Email of the case to be populated but instead got null.');

	}

    /**
	 * Scenario: Testing to perform the DML Insert operation
	 */
	@IsTest
	private static void testInsertRecords() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();
        List<Case> caseList = ApplicationTestDataFactory.getCases(1, true);

		// =====================================
		// Stubbing
		// =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        STHSCommunityService service = STHSCommunityService.getInstance();
        service.insertRecords(caseList);

        Test.stopTest();

        System.assertEquals(1, MockUtility.mockDMLInsertedRecords.size(), 'Expected case record has been inserted.');

        // should have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}

    /**
	 * Scenario: Testing to query the case using CasesSelector
	 */
	@IsTest
	private static void testGetCaseNumber() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();
        Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
        caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{'CaseNumber' => '475123'});

		// =====================================
		// Stubbing
		// =====================================
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{caseRecord.Id})).thenReturn(new Map<Id, Case>{caseRecord.Id => caseRecord});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        STHSCommunityService service = STHSCommunityService.getInstance();
        String caseNumber = service.getCaseNumber(caseRecord.Id);

        Test.stopTest();

        System.assertNotEquals(null, caseNumber, 'Expected CaseNumber of the newly inserted case to be populated but instead got null.');

        // should have attempted to call CasesSelector
        ((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{caseRecord.Id}));
	}

    /**
	 * Scenario: Testing to build the case comments
	 */
	@IsTest
	private static void testBuildCaseCommentsWithFormData() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();
        String commentBody;

		// =====================================
		// Stubbing
		// =====================================
        // None

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        STHSCommunityService service = STHSCommunityService.getInstance();
        commentBody = service.buildCaseCommentsWithFormData(commentBody, formData);

        Test.stopTest();

        System.assertNotEquals(null, commentBody, 'Expected case comments to be populated but instead got null.');

	}

}