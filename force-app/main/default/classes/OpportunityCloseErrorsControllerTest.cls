/* @author 
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Opportunity
 * @domain Core
 * @description test class for OpportunityCloseErrosController
 * @changelog
 * 2020-08-14 - arjun.singh@austpost.com.au - Created
 */
@IsTest
public with sharing class OpportunityCloseErrorsControllerTest {

    @IsTest
	private static void getCloseOpportunityErrorsTest() {
		// =====================================
		// Data Preparation
		// =====================================

		// need a opportunity record
		list<account> accList = ApplicationTestDataFactory.getAccounts(1, true);
		list<Opportunity> oppList = ApplicationTestDataFactory.getOpportunities(1, accList[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		OpportunitiesSelector selector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		oppList[0].StageName='Negotiate';
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{oppList[0].Id => oppList[0]};
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize('{"success":true}', Database.SaveResult.class);
		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};  
		System.Savepoint sSavePoint = Database.setSavepoint();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(sSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(svResultList);
		MockUtility.Mocks.when(selector.selectById(new Set<Id>{oppList[0].Id})).thenReturn(mockOPPMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> resultMap = OpportunityCloseErrorsController.getCloseOpportunityErrors(string.valueOf(oppList[0].Id));		
		System.debug('resultMap>>>>'+resultMap);
		System.assertEquals(resultMap.get(OpportunityCloseErrorsController.KEY_STATUS), OpportunityCloseErrorsController.OK);        
		//Make sure Roll back was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlRollback((System.SavePoint)fflib_Match.anyObject());
		Test.stopTest();
    }
    /**
     * Test when valdiation rules fires for close won opportunity
     */
    @IsTest
	private static void getCloseOpportunityErrorsWithValidationRuleTest() {
		// =====================================
		// Data Preparation
		List<Apexpages.Message> messages = new List<Apexpages.Message>();
		messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'This is my error'));
		// =====================================
		
		// need a opportunity record
		list<account> accList = ApplicationTestDataFactory.getAccounts(1, true);
		list<Opportunity> oppList = ApplicationTestDataFactory.getOpportunities(1, accList[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		OpportunitiesSelector selector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// set up our responses
		MockUtility.Mocks.startStubbing();
		oppList[0].StageName='Negotiate';
		Map<Id, Opportunity> mockOPPMap = new Map<Id, Opportunity>{oppList[0].Id => oppList[0]};
		Database.SaveResult sr = (Database.SaveResult)JSON.deserialize('{"success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.SaveResult.class);
		list<Database.SaveResult> svResultList = new  list<Database.SaveResult>{sr};  
		System.Savepoint sSavePoint = Database.setSavepoint();
		MockUtility.Mocks.when(mockDatabase.dmlSetSavePoint()).thenReturn(sSavePoint);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean())).thenReturn(svResultList);
		MockUtility.Mocks.when(selector.selectById(new Set<Id>{oppList[0].Id})).thenReturn(mockOPPMap);
		ApexPageMessagesSelector messagesSelector = (ApexPageMessagesSelector)MockUtility.mockSelector(ApexPageMessagesSelector.class);
		MockUtility.Mocks.when(messagesSelector.getPageMessages()).thenReturn(messages);
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(oppList[0]);
        OpportunityCloseErrorsController cntrl = new OpportunityCloseErrorsController(sc);
        
        PageReference pageRef = Page.OpportunityValidationErrors;
        pageRef.getParameters().put('id', String.valueOf(oppList[0].Id));
        Test.setCurrentPage(pageRef);		
		Map<String, Object> resultMap = OpportunityCloseErrorsController.getCloseOpportunityErrors(string.valueOf(oppList[0].Id));		
        System.assert(resultMap.containsKey(OpportunityCloseErrorsController.KEY_ERRORS)); 
        //Make sure Roll back was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlRollback((System.SavePoint)fflib_Match.anyObject());       
		((ApexPageMessagesSelector)MockUtility.Mocks.verify(messagesSelector, 3)).getPageMessages();
		Test.stopTest();
    }
    /**
     * Test when no opprtunity found
     */
    @IsTest
	private static void noOpportunityFoundTest() {
		// =====================================
		// Data Preparation
		// =====================================
		
		// need a opportunity record
		list<account> accList = ApplicationTestDataFactory.getAccounts(1, true);
		list<Opportunity> oppList = ApplicationTestDataFactory.getOpportunities(1, accList[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		// stub the database so we don't need to insert new records
		OpportunitiesSelector selector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		oppList[0].StageName='Negotiate';
		MockUtility.Mocks.when(selector.selectById(new Set<Id>{oppList[0].Id})).thenReturn(null);
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> resultMap = OpportunityCloseErrorsController.getCloseOpportunityErrors(string.valueOf(oppList[0].Id));
		Test.stopTest();
        System.assertEquals(resultMap.get(OpportunityCloseErrorsController.KEY_STATUS), OpportunityCloseErrorsController.ERROR);        
        
    }
}