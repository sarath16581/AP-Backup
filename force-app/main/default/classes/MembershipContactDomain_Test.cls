/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : 
* @changelog :
*/

@isTest
private class MembershipContactDomain_Test {
	private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
    
	@isTest
    private static void testMethods() {
        List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(1, true);
        List<Contact> testContacts = ApplicationTestDataFactory.getContacts(1, testAccounts[0].id, true);
        List<Membership__c> testMemberships = ApplicationTestDataFactory.getMembership(1, MEMBERSHIP_STATUS_NEW, LICENSE_TYPE_NEW_MEMBERSHIP, testAccounts[0].id, testContacts[0].id, true);
        List<MembershipContact__c> testMembershipContacts =ApplicationTestDataFactory.getMembershipContact(1, testMemberships[0].Id, testContacts[0].id, MEMBERSHIP_CONTACT_STATUS_REVIEW,true);
		
		ApplicationDomain.IConstructable constructableDomain = new MembershipContactDomain.Constructor();
		MembershipContactDomain domain = (MembershipContactDomain)constructableDomain.construct(testMembershipContacts);
		
		System.assertEquals(testMembershipContacts[0].Id, domain.records[0].Id, 'Expected membership contact record');
    }
}