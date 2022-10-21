/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : 
* @changelog :
*/

@isTest
private class MembershipContactModule_Test {
    private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
    
    @isTest
    private static void testTaskCreationForCompletedMembershipContacts() {

        // Given
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert orgAccount;

        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        insert networkFacility;

        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
        insert facilityAccount;

        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,false)[0];
        insert licenceAccount;

        List<Contact> personContacts = ApplicationTestDataFactory.getContacts(2, orgAccount.Id, false);
        personContacts[1].accountId = licenceAccount.Id;
        insert personContacts;

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContacts[0].Id,  false)[0];
        insert member;
        
        MembershipContact__c testMembershipContact = ApplicationTestDataFactory.getMembershipContact(1, member.Id, personContacts[1].id, MEMBERSHIP_CONTACT_STATUS_REVIEW,false)[0];
        insert testMembershipContact;
        // WHEN
		test.startTest();
        testMembershipContact.Status__c = MembershipContactModule.MEMBERSHIP_CONTACT_STATUS_COMPLETED;
        testMembershipContact.CompletionDate__c = date.today();
        update testMembershipContact;
        // THEN
		List<Task> createdTasks = [SELECT id FROM Task WHERE whatId = :member.id AND subject = :MembershipContactModule.TASK_SUBJECT LIMIT 1];
        system.assertEquals(1, createdTasks.size(),'Task should be created for completed memberships');
    }
}