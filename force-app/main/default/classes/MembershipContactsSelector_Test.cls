/***
 * @author George Nguyen
 * @date 2022-10-19
 * @group Tests
 * @tag Selector
 * @tag User SObject
 * @domain Core
 * @description Test Class covering MembershipContactsSelector
 * @changelog
 * 2022-10-19 - George Nguyen - Created
 */
@IsTest
public with sharing class MembershipContactsSelector_Test {
    private static final string MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
    @IsTest
    static void ensureCorrectSObjectType() {
        System.assertEquals(MembershipContact__c.getSObjectType(), MembershipContactsSelector.newInstance(1).getSObjectType(), 'Should be MembershipContact__c');
    }

    @IsTest
    static void ensureTheSpecifiedFieldsAreIncluded() {
        Set<SObjectField> fieldList = MembershipContactsSelector.newInstance().getSObjectFieldList();
        System.assert(fieldList.contains(MembershipContact__c.Status__c), 'Should contain');
        System.assert(fieldList.contains(MembershipContact__c.LastStatusChangedDate__c), 'Should contain');
    }

    @IsTest
	private static void ensureQueryBuilderProducesCorrectString() {
		Test.startTest();
		MembershipContactsSelector selector = MembershipContactsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?is)\\bfrom MembershipContact__c\\b').matcher(soql).find(),
			'Resulting query does not select from MembershipContact__c'
		);
		Test.stopTest();
	}

	@IsTest
	private static void queryingActualDB() {
		MockUtility.disableTriggerExecution();

		Account orgAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		orgAccount.ABN__c = '12345678910';
		insert orgAccount;
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
		insert networkFacility;
        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
		insert facilityAccount;
        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,false)[0];
		insert licenceAccount;
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, orgAccount.Id, false);
		contacts[1].AccountId = licenceAccount.Id;		
		insert contacts;

        List<Membership__c> memberships = ApplicationTestDataFactory.getMembership(2, 'Active', 'New Membership', licenceAccount.Id, contacts[0].Id,  false);
		memberships[0].ABN__c = orgAccount.ABN__c;
		memberships[0].Member_Type__c = 'Partner';

		memberships[1].ABN__c = orgAccount.ABN__c;
		memberships[1].Member_Type__c = 'Partner';

		insert memberships;
        List<MembershipContact__c> membershipContacts = new List<MembershipContact__c>();
        MembershipContacts.add(new MembershipContact__c (Membership__c = memberships[0].id, Contact__c = contacts[1].id, Status__c = MEMBERSHIP_CONTACT_STATUS_REVIEW ,CompletionDate__c = null ));
        MembershipContacts.add(new MembershipContact__c (Membership__c = memberships[1].id, Contact__c = contacts[1].id, Status__c = MembershipContactsSelector.MEMBERSHIP_CONTACT_STATUS_COMPLETED, CompletionDate__c = Datetime.now().date()));

        insert membershipContacts;

        Map<Id, MembershipContact__c> membershipContactsMap = new Map<Id, MembershipContact__c>(membershipContacts);

		Test.startTest();

		MembershipContactsSelector selector = MembershipContactsSelector.newInstance();
		Map<Id, MembershipContact__c> results = new Map<Id, MembershipContact__c>(selector.selectById(membershipContactsMap.keySet()));
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		Map<Id, Membership__c> membershipsMap = new Map<Id, Membership__c>(memberships);
		List<AggregateResult> aggregateResults = selector.selectIncompleteMembershipsByMembershipIds(
																	membershipsMap.keySet(), 
																	new Set<Object>(), 
																	new Set<SObjectField> {MembershipContact__c.Membership__c}
																);

		System.assertEquals(1, aggregateResults.size(), 'Expected result size of 1');    
		System.assertEquals(memberships[0].Id, (Id)aggregateResults[0].get('Membership__c'), 'Expected the membership id');    

		Test.stopTest();
	}
}