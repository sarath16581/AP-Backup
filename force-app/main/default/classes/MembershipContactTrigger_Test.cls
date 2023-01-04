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
    private static final String MEMBERSHIP_LICENCE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_MEMBER_TYPE_PARTNER = 'Partner';
    private static final String ABN_TEST = '12 377 614 012';
	@isTest
    static void testCreateMembershipContact() {
        // Given
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        orgAccount.abn__c = ABN_TEST;
        insert orgAccount;

        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        networkFacility.Org_ID__c = '12345';
        insert networkFacility;

        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
        facilityAccount.abn__c = ABN_TEST;
        insert facilityAccount;

        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,false)[0];
        licenceAccount.abn__c = ABN_TEST;
        insert licenceAccount;

        List<Contact> personContacts = ApplicationTestDataFactory.getContacts(2, orgAccount.Id, false);
        personContacts[1].accountId = licenceAccount.Id;
        insert personContacts;

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContacts[0].Id,  false)[0];
        member.Member_Type__c = MEMBERSHIP_MEMBER_TYPE_PARTNER;
        member.Licensee_Type__c = MEMBERSHIP_LICENCE_TYPE_NEW_MEMBERSHIP;
        member.Date_Signed__c = Date.today();
        member.abn__c = ABN_TEST;
        member.WCC__c =  networkFacility.Org_ID__c;
        
        
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