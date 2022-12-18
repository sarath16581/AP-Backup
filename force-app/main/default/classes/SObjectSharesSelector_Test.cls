/* @author Ranjeewa Silva
 * @group Tests
 * @tag Selector
 * @domain Core
 * @description Test Class covering SObjectSharesSelector
 * @changelog
 * 2022-12-02 - Ranjeewa Silva - created.
 */
@IsTest
private class SObjectSharesSelector_Test {

	/**
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
		SObjectSharesSelector selector = SObjectSharesSelector.newInstance(APR__Share.getSObjectType());
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APR__Share\\b').matcher(soql).find(), 'Resulting query does not select from corresponding share object');

		Test.stopTest();
	}

	/**
	 *  Ensures that the selectors QueryBuilder is generating the correct output with field overrides
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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
		Map<SObjectType, Set<SObjectField>> objectWithFieldsMap = new Map<SObjectType, Set<SObjectField>>();
		objectWithFieldsMap.put(APR__Share.getSObjectType() , new Set<SObjectField>{APR__Share.RowCause});

		SObjectSharesSelector selector = SObjectSharesSelector.newInstance(APR__Share.getSObjectType(), 0, objectWithFieldsMap);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
		String soql = qb.toSoqlString();
		// field overrides not supported with Owner as it could be a user or a group.
		System.assertEquals(false, Pattern.compile('(?ism)AccessLevel\\b.*?\\bfrom APR__Share\\b').matcher(soql).find(), 'Resulting selects AccessLevel but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)RowCause\\b.*?\\bfrom APR__Share\\b').matcher(soql).find(), 'Resulting query does not select RowCause field: ' + soql);

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
		// this integration test creates APR__Share records (test data) which is asserted at the end. disabling the
		// APR trigger execution here as the test does not want additional APR__Share records created through triggers.
		// this should probably be part of the MockUtility.disableTriggerExecution() framework method above. Adding in
		// this here for the moment.
		SystemSwitch__c settings = new SystemSwitch__c(DisableTriggers__c = true, ObjectTriggersToBeDisabled__c= 'APR__c');
		insert settings;

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, false);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		parentAccounts[0].Sales_Segment__c = 'Enterprise & Strategic NSW 1';
		parentAccounts[0].LEGACY_ID__c = '60000000';

		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;
		parentAccounts[1].Sales_Segment__c = 'Intermediaries';
		parentAccounts[1].LEGACY_ID__c = '60000002';

		insert(parentAccounts);

		List<Billing_Account__c> billingAccounts =  new List<Billing_Account__c>();
		for (Account parentAccount: parentAccounts) {
			billingAccounts.add(ApplicationTestDataFactory.getBillingAccounts(1, parentAccount.Id, 'SAP CRM', false)[0]);
		}
		insert (billingAccounts);

		List<APR__c> aprs = new List<APR__c>();
		for (Billing_Account__c billingAccount: billingAccounts) {
			APR__c apr = ApplicationTestDataFactory.getAPRs(1, billingAccount.Id, null, false)[0];
			apr.Legal_Entity_Name_LookUp__c = billingAccount.Organisation__c;
			aprs.add(apr);
		}
		insert(aprs);

		Group publicGroup = ApplicationTestDataFactory.getGroups(1, 'Regular', false)[0];
		publicGroup.Email = null;
		insert(publicGroup);

		List<APR__Share> aprShares = new List<APR__Share>();
		aprShares.add(new APR__Share(ParentId=aprs[0].Id, UserOrGroupId=publicGroup.Id, AccessLevel='Edit', RowCause=Schema.APR__Share.RowCause.SalesTeamSharing__c));
		aprShares.add(new APR__Share(ParentId=aprs[0].Id, UserOrGroupId=publicGroup.Id, AccessLevel='Edit', RowCause='Manual'));
		aprShares.add(new APR__Share(ParentId=aprs[1].Id, UserOrGroupId=publicGroup.Id, AccessLevel='Edit', RowCause=Schema.APR__Share.RowCause.SalesTeamSharing__c));
		insert(aprShares);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		SObjectSharesSelector selector = SObjectSharesSelector.newInstance(APR__Share.SObjectType, 0);
		List<APR__Share> results = (List<APR__Share>)selector.selectByParentIdAndRowCause(new Set<Id>{aprs[0].Id}, new Set<String>{Schema.APR__Share.RowCause.SalesTeamSharing__c});
		System.assertEquals(1, results.size(), 'Expected only one APR share matching both ParentId and RowCause, but received ['+results.size()+'].');
		System.assertEquals(aprShares[0].Id, results[0].Id, 'Expected share record not returned in results');
		Test.stopTest();
	}

}