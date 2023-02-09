/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag SkillRequirement SObject
 * @domain Core
 * @description Test class for SkillRequirementSelector
 * @changelog
 * 2022-11-18 George Nguyen - Created
 * 2023-02-06 - Nathan Franklin - Added test methods to cover recent work
 */
@IsTest
public with sharing class SkillRequirementSelector_Test {
	
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		SkillRequirementSelector selector = SkillRequirementSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom SkillRequirement\\b').matcher(soql).find(), 'Query from SkillRequirement object');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillLevel) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(SkillRequirement.RelatedRecordId) + '\\b').matcher(soql).find(), 'Field exists in query');
	}

	/**
	 * Scenario:
	 * Ensure field overrides produce correct query string
	 */
	@IsTest
	private static void testEnsureFieldOverridesAreCorrectlyIncludedInQueryBuilderOutput() {
		SkillRequirementSelector selector = SkillRequirementSelector.newInstance(1, new Set<SObjectField>{SkillRequirement.RelatedRecordId});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom SkillRequirement\\b').matcher(soql).find(), 'Query from SkillRequirement object: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillId) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillLevel) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(SkillRequirement.RelatedRecordId) + '\\b').matcher(soql).find(), 'Field does not exists in query: ' + soql);

		selector = SkillRequirementSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
			SkillRequirement.SObjectType => new Set<SObjectField>{SkillRequirement.RelatedRecordId},
			Skill.SObjectType => new Set<SObjectField>{Skill.DeveloperName}
		});
		qb = selector.newQueryBuilder(new Set<Object>{SkillRequirementSelector.Options.WITH_SKILLS});
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom SkillRequirement\\b').matcher(soql).find(), 'Query from SkillRequirement object: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillId) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(SkillRequirement.SkillLevel) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(SkillRequirement.RelatedRecordId) + '\\b').matcher(soql).find(), 'Field does not exist in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\bSkill\\.DeveloperName\\b').matcher(soql).find(), 'Field does not exist in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\bSkill\\.MasterLabel\\b').matcher(soql).find(), 'Field exists in query: ' + soql);

	}

	/**
	 * Scenario:
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

		SkillRequirementSelector selector = SkillRequirementSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
			SkillRequirementSelector.Options.WITH_SKILLS
		});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Skill\\..*?\\bfrom SkillRequirement\\b').matcher(soql).find(), 'Resulting query does not select Skill fields: ' + soql);

		Test.stopTest();
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		Map<Id, PendingServiceRouting> pendingServiceRoutings = new Map<Id, PendingServiceRouting>(OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true));
		Map<Id, Skill> skills = new Map<Id, Skill>(OmniChannelTestDataFactory.getSkills(2, true));
		Map<Id, SkillRequirement> skillRequirements = new Map<Id, SkillRequirement>(OmniChannelTestDataFactory.getSkillRequirements(2, skills.keySet(), pendingServiceRoutings.keySet(), true));

		SkillRequirementSelector selector = SkillRequirementSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SkillRequirementSelector.class, qa); 
		selector.selectById(skillRequirements.keySet());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId in :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SkillRequirementSelector.class, qa); 
		selector.selectByRelatedRecordIds(pendingServiceRoutings.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + SkillRequirement.RelatedRecordId + ' in :relatedRecordIds\\b').matcher(queryString).find(), 'Filters by relatedRecordIds in query');

	}

}