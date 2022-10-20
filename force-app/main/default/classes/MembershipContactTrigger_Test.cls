/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : test class to cover Membership Contact Trigger
* @changelog :
*/

@isTest
private class MembershipContactTrigger_Test {
    private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
	@isTest
    static void testCreateMembershipContact() {
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
        
        MembershipContact__c testMembershipContact = new MembershipContact__c(Membership__c = member.Id, Contact__c = personContacts[1].id, Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW);

        // WHEN
		test.startTest();
        insert testMembershipContact;
        test.stopTest();
        
        // THEN
        system.assertNotEquals(null, testMembershipContact.id,'Membership Contact should be inserted');
    }
}