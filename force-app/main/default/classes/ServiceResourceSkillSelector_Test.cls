/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag ServiceResourceSkill SObject
 * @domain Core
 * @description Test class for ServiceResourceSkillSelector
 * @changelog
 * 2022-11-18 George Nguyen - Created
 */
@IsTest
public with sharing class ServiceResourceSkillSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		ServiceResourceSkillSelector selector = ServiceResourceSkillSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ServiceResourceSkill\\b').matcher(soql).find(), 'Query from ServiceResourceSkill object');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(ServiceResourceSkill.SkillId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(ServiceResourceSkill.SkillLevel) + '\\b').matcher(soql).find(), 'Field exists in query');
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		Map<Id, PendingServiceRouting> pendingServiceRoutings = new Map<Id, PendingServiceRouting>(OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true));
		Map<Id, Skill> skills = new Map<Id, Skill>(OmniChannelTestDataFactory.getSkills(2, true));
		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(OmniChannelTestDataFactory.getServiceResources(1, 'A', true));
		Map<Id, ServiceResourceSkill> serviceResourceSkills = new Map<Id, ServiceResourceSkill>(OmniChannelTestDataFactory.getServiceResourceSkills(2, skills.keySet(), serviceResources.keySet(), true));


		ServiceResourceSkillSelector selector = ServiceResourceSkillSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ServiceResourceSkillSelector.class, qa); 
		selector.selectById(serviceResourceSkills.keySet());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId IN :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ServiceResourceSkillSelector.class, qa); 
		selector.selectByActiveServiceResourceRelatedRecordIds(pendingServiceRoutings.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + ServiceResource.getsObjectType() + '.' + ServiceResource.RelatedRecordId + ' IN :relatedRecordIds AND ' + ServiceResource.getsObjectType() + '.' + ServiceResource.IsActive + ' = TRUE\\b').matcher(queryString).find(), 'Filters by relatedRecordIds in query');

	}

}