/**
 * @author Nathan Franklin
 * @date 2023-02-06
 * @changelog
 */
@IsTest
private with sharing class SkillsSelector_Test {

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

		SkillsSelector selector = SkillsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom skill\\b').matcher(soql).find(), 'Resulting query does not select from Skill');

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Skill.DeveloperName
		};
		selector = SkillsSelector.newInstance(1, fieldOverrides);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\blimit 1\\b').matcher(soql).find(), 'Resulting query does not have limit');

		Map<SObjectType, Set<SObjectField>> fieldOverridesMap = new Map<SObjectType, Set<SObjectField>>{
			Skill.getSObjectType() => new Set<SObjectField>{
				Skill.DeveloperName
			}
		};
		selector = SkillsSelector.newInstance(1, fieldOverridesMap);
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bDeveloperName\\b').matcher(soql).find(), 'Resulting query does not have fieldoverrides');

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

		// grab any random skill
		List<Skill> skills = [Select Id From Skill LIMIT 2];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SkillsSelector selector = SkillsSelector.newInstance(1);
		List<Skill> results = selector.selectById(new Set<Id>{skills[0].Id, skills[1].Id});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		selector = SkillsSelector.newInstance(0);
		results = selector.selectById(new Set<Id>{skills[0].Id, skills[1].Id});
		System.assertEquals(2, results.size(), 'Result count was wrong');

		Test.stopTest();
	}
}