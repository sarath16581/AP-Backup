/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Test class for the membership Contact Module
* @changelog :
*/

@isTest
private class MembershipContactModule_Test {
    private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
    
    
    @isTest
    private static void testLastStatusChangedDateOnInsert() {
        // Given
        MembershipContact__c record = new MembershipContact__c(Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW);
        // When
        new MembershipContactModule().onBeforeInsert(new List<MembershipContact__c>{record},null);
    	// Then
    	System.assertEquals(Date.today(), record.LastStatusChangedDate__c,'Last Status Changed Date should be Today for inserted record');
    }
    
    
    @isTest
    private static void testLastStatusChangedDateOnUpdate() {
        // Given
        MembershipContact__c existingRecord = new MembershipContact__c(LastStatusChangedDate__c = date.today()-2, Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW);
        ApplicationTestDataFactory.generateRecordIds(new List<MembershipContact__c>{existingRecord});
        MembershipContact__c record = new MembershipContact__c(Id = existingRecord.id, LastStatusChangedDate__c =existingRecord.LastStatusChangedDate__c,  Status__c = MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED);
        // When
        new MembershipContactModule().onBeforeUpdate(new List<MembershipContact__c>{record}, new Map<Id,MembershipContact__c>{existingRecord.id => existingRecord},null);
    	// Then
    	System.assertEquals(Date.today(), record.LastStatusChangedDate__c,'Last Status Changed Date should be Today for updated record');
    }
    
    @isTest
    private static void testCreateTaskOnCompletion() {
        // Given
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Contact> personContacts = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, true);
        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', orgAccount.Id, personContacts[0].Id,  true)[0];
        MembershipContact__c existingRecord = new MembershipContact__c(Membership__c = member.id, Contact__c = personContacts[0].id,LastStatusChangedDate__c = date.today()-2, Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW);
        ApplicationTestDataFactory.generateRecordIds(new List<MembershipContact__c>{existingRecord});
        MembershipContact__c record = new MembershipContact__c(Id = existingRecord.id, Membership__c = existingRecord.Membership__c, Contact__c = existingRecord.Contact__c, LastStatusChangedDate__c = Date.today(),  Status__c = MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED);


        
        // =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
       	MembershipContactsSelector mockSelector = (MembershipContactsSelector)MockUtility.mockSelector(MembershipContactsSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
        
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectIncompleteMembershipsByMembershipIds((Set<Id>)fflib_Match.eq(new Set<id>{member.id}),(Set<Object>)fflib_Match.eq(new Set<Object>()),(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{MembershipContact__c.Membership__c}))).thenReturn(new List<AggregateResult>());
        MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        MockUtility.Mocks.stopStubbing();
        
        // When
        test.startTest();
        new MembershipContactModule().onAfterUpdate(new List<MembershipContact__c>{record}, new Map<Id,MembershipContact__c>{existingRecord.id => existingRecord},mockUow);
    	test.stopTest();
        // Then
        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(member.Id, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).whatId, 'Expected task to be created for the completed membership');	
    }
    
    @isTest
    private static void testCreateTaskOnInsertCompletedRecord() {
        // Given
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Contact> personContacts = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, true);
        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', orgAccount.Id, personContacts[0].Id,  true)[0];
        MembershipContact__c record = new MembershipContact__c(Membership__c = member.id, Contact__c = personContacts[0].id, LastStatusChangedDate__c = Date.today(),  Status__c = MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED);
        ApplicationTestDataFactory.generateRecordIds(new List<MembershipContact__c>{record});

        
        // =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
       	MembershipContactsSelector mockSelector = (MembershipContactsSelector)MockUtility.mockSelector(MembershipContactsSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
        
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectIncompleteMembershipsByMembershipIds((Set<Id>)fflib_Match.eq(new Set<id>{member.id}),(Set<Object>)fflib_Match.eq(new Set<Object>()),(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{MembershipContact__c.Membership__c}))).thenReturn(new List<AggregateResult>());
        MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        MockUtility.Mocks.stopStubbing();
        
        // When
        test.startTest();
        new MembershipContactModule().onAfterInsert(new List<MembershipContact__c>{record},mockUow);
    	test.stopTest();
        // Then
        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(member.Id, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).whatId, 'Expected task to be created for the completed membership');	
    }
    
    @isTest
    private static void testRemainingForCoverage() {
         MembershipContactModule testInstance =  MembershipContactModule.newInstance();
        	
    }
}