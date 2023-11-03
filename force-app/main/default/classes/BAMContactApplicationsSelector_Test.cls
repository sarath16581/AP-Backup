/**
 * @author Hasantha Liyanage
 * @date 2023-10-02
 * @group Test
 * @domain BAM
 * @description BAMContactApplicationsSelector selector Test
 * @changelog
 * 2023-10-02 - Hasantha Liyanage  - Created
 */

@IsTest
private class BAMContactApplicationsSelector_Test {
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

		BAMContactApplicationsSelector selector = BAMContactApplicationsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom BAMContactApplication__c\\b').matcher(soql).find(), 'Resulting query does not select from BAMContactApplication__c');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		BAMContactApplicationsSelector selector = BAMContactApplicationsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
				BAMContactApplicationsSelector.Options.WITH_CONTACT
		});
		String soql = qb.toSoqlString();
		system.debug(soql);
		System.assertEquals(true, Pattern.compile('(?is)Contact__r\\..*?\\bfrom BAMContactApplication__c\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');

	}
}