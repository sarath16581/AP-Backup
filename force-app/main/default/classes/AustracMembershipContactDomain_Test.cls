/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Test class for the Membership Contact Domain (generic)
* @changelog :
*/

@isTest
private class AustracMembershipContactDomain_Test {

	private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';

	@isTest
    private static void testMethods() {
        List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(1, true);
        List<Contact> testContacts = ApplicationTestDataFactory.getContacts(1, testAccounts[0].id, true);
        Membership__c testMembership = ApplicationTestDataFactory.getMembership(1, MEMBERSHIP_STATUS_NEW, LICENSE_TYPE_NEW_MEMBERSHIP, testAccounts[0].id, testContacts[0].id, true)[0];

        // =====================================
		// Stubbing
		// =====================================
       	MembershipsSelector mockSelector = (MembershipsSelector)MockUtility.mockSelector(MembershipsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByRecordTypeName((Set<Id>)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(new Map<Id,Membership__c>{testMembership.Id => testMembership});
        MockUtility.Mocks.stopStubbing();
        
        List<MembershipContact__c> testMembershipContacts = new List<MembershipContact__c> { new MembershipContact__c(Membership__c = testMembership.id, Contact__c = testContacts[0].id,LastStatusChangedDate__c = date.today()-2, Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW)};
        ApplicationTestDataFactory.generateRecordIds(testMembershipContacts);
		
        AustracMembershipContactDomain domain = AustracMembershipContactDomain.newInstance(testMembershipContacts);
        domain.registerModules();
        System.assertEquals(1, domain.records.size(), 'Expected membership contact record');
		System.assertEquals(testMembershipContacts[0].Id, domain.records[0].Id, 'Expected membership contact record with Id');
	}
}