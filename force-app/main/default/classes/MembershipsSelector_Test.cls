/***
 * @author Disha kariya
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag User SObject
 * @domain Core
 * @description Test Class covering MembershipdSelector
 * @changelog
 * 2020-04-10 - Disha Kariya - Created
 */
@IsTest
private class MembershipsSelector_Test {
    private static final String APLAC_RECORD_TYPE_NAME = 'APLAC Membership';
    private static final String LICENSE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_STATUS_NEW = 'New';
    private static final String MEMBERSHIP_CONTACT_STATUS_REVIEW = 'Review';
    private static final String MEMBERSHIP_LICENCE_TYPE_NEW_MEMBERSHIP = 'New Membership';
    private static final String MEMBERSHIP_MEMBER_TYPE_PARTNER = 'Partner';
    private static final String ABN_TEST = '12 377 614 012';


    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        MembershipsSelector selector = MembershipsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        System.debug('soql--->'+soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom membership__c\\b').matcher(soql).find(), 'Resulting query does not select from User');

        qb = selector.newQueryBuilder(new Set<Object>{MembershipsSelector.Options.FILTER_ACTIVE_STATUS});
        soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom membership__c\\b.*status__c\\s*=\\s*\'Active\'').matcher(soql).find(), soql);

        Test.stopTest();

    }

    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

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
        
        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, false)[0];
        insert personContact;
        RecordType aplacRT = [Select Id,Name From RecordType Where Name = :APLAC_RECORD_TYPE_NAME And SObjectType = 'Membership__c'];
        
        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  false)[0];
        member.Member_Type__c = MEMBERSHIP_MEMBER_TYPE_PARTNER;
        member.Licensee_Type__c = MEMBERSHIP_LICENCE_TYPE_NEW_MEMBERSHIP;
        member.Date_Signed__c = Date.today();
        member.abn__c = ABN_TEST;
        member.WCC__c =  networkFacility.Org_ID__c;

        insert member;
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        MembershipsSelector selector = MembershipsSelector.newInstance(2);
        Map<Id, Membership__c> results = selector.selectById(new Set<Id>{member.Id});
        System.assertEquals(1, results.size(), 'Expected 1 results');

        results = selector.selectById(new Set<Id>{member.Id}, new Set<Object>{MembershipsSelector.Options.FILTER_ACTIVE_STATUS});
        System.assertEquals(1, results.size(), 'Expected 1 Active result');
        System.assertEquals('Active', results.values()[0].Status__c, 'Expected Active Membership');
        

        member.recordtype = aplacRT;
        results = selector.selectByRecordTypeNames(new Set<Id>{member.Id},new Set<Object>(), new Set<String>{APLAC_RECORD_TYPE_NAME});
        System.assertEquals(1, results.size(), 'Expected 1 result');
        
        Test.stopTest();

    }
}