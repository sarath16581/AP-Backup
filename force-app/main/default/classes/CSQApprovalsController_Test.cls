@isTest
public with sharing class CSQApprovalsController_Test {
	private static final String
		APPROVAL_PROC_RESULT_POS = '{ "success" : true  }',
		APPROVAL_PROC_RESULT_NEG = '{ "success" : false, "errors" : [{ "fields" : ["Status__c"], "message" : "Incorrect value for restricted picklist" }] }';

	/***
	 * Regular scenario without errors to handle
	 */
	@isTest
	private static void runTestPositive(){
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
			Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		Pick_Up_Location__c puLoc = new Pick_Up_Location__c(
			Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
			CSQ__c = csq.Id
		);

		// ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		PickUpLocationSelector mockPUL = (PickUpLocationSelector)MockUtility.mockSelector(PickUpLocationSelector.class);
		UserRecordAccessSelector mockURASelector = (UserRecordAccessSelector)MockUtility.mockSelector(UserRecordAccessSelector.class);
	
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockURASelector.selectById((Id)fflib_Match.eq(csq.Id))
		).thenReturn(
			(UserRecordAccess)UserRecordAccessSelector_Test.mockUserRecordAccess(csq.Id)
		);

		MockUtility.Mocks.when(
			mockPUL.selectById((Set<Id>)fflib_Match.anyObject())
		).thenReturn(
			(Map<Id,Pick_Up_Location__c>)new Map<Id,Pick_Up_Location__c>{ puLoc.Id => puLoc }
		);

		MockUtility.Mocks.when(
			mockURASelector.selectById((Id)fflib_Match.eq(puLoc.Id))
		).thenReturn(
			(UserRecordAccess)UserRecordAccessSelector_Test.mockUserRecordAccess(puLoc.Id)
		);

		MockUtility.Mocks.when(
			mockDatabase.submitForApproval(
				(Id)fflib_Match.eq(csq.Id),
				(String)fflib_Match.eq('comments')
			)
		).thenReturn(
			(Approval.ProcessResult)JSON.deserialize(
				APPROVAL_PROC_RESULT_NEG,
				Approval.ProcessResult.class
			)
		);

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		
		/**
		 * Testing submit for approval for CSQ records
		 */
		try {
			CSQApprovalsController.submitForApproval(csq.Id, 'comments');
			System.assert(false, 'No exception expected');			
		} catch(Exception ex) {
			System.assert(true, 'Expected exception');
		}

		/**
		 * Testing status update for Pick-Up Location
		 */
		try {
			CSQApprovalsController.updatePickupLocationStatus(puLoc.Id, 'pending', 'comments');
			System.assert(true, 'No exception expected');
		} catch(Exception ex) {
			System.assert(false, 'No exception expected');
		}

		Test.stopTest();		
	}

	/***
	 * Negative scenario with errors to handle
	 */
	@isTest
	private static void runTestNegative(){
		Customer_Scoping_Questionnaire__c csq = new Customer_Scoping_Questionnaire__c(
			Id = fflib_IDGenerator.generate(Customer_Scoping_Questionnaire__c.SObjectType)
		);

		Pick_Up_Location__c puLoc = new Pick_Up_Location__c(
			Id = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType),
			CSQ__c = csq.Id
		);

		Approval.ProcessResult negativeApprovalResult = (Approval.ProcessResult)JSON.deserialize(
			APPROVAL_PROC_RESULT_NEG,
			Approval.ProcessResult.class
		);

		// ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UserRecordAccessSelector mockURASelector = (UserRecordAccessSelector)MockUtility.mockSelector(
			UserRecordAccessSelector.class
		);
	
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockURASelector.selectById((Id)fflib_Match.eq(puLoc.Id))
		).thenReturn(
			(UserRecordAccess)UserRecordAccessSelector_Test.mockUserRecordAccess(
				puLoc.Id,
				UserRecordAccessSelector_Test.ACCESS_RO
			)
		);

		MockUtility.Mocks.when(
			mockDatabase.submitForApproval(
				(Id)fflib_Match.eq(csq.Id),
				(String)fflib_Match.eq('comments')
			)
		).thenReturn(
			negativeApprovalResult
		);

		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		
		Exception ex = CSQApprovalsController.convertProcessResult(
			negativeApprovalResult
		);

		System.assert(ex != null, 'Exception expected');
		System.assert(ex instanceOf DMLException, 'Incorrect Exception');

		/**
		 * Testing submit for approval for CSQ records
		 */
		try {
			CSQApprovalsController.submitForApproval(csq.Id, 'comments');
			System.assert(false, 'No exception expected');			
		} catch(Exception dmlEx) {
			System.assert(true, 'Expected exception');
		}

		/**
		 * Testing status update for Pick-Up Location
		 */
		try {
			CSQApprovalsController.updatePickupLocationStatus(puLoc.Id, 'pending', 'comments');
			System.assert(false, 'No exception expected');			
		} catch(AuraHandledException ahEx) {
			System.assert(true, 'Expected exception');
		}

		CSQCloneService.CloneResult cr = CSQApprovalsController.cloneCSQTree(null, new List<String>{ 'reapprove' });
		System.assert(cr.dmlResults.isEmpty(), 'Result set should be null');

		Test.stopTest();		
	}
}