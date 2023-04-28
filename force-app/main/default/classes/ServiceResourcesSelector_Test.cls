/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag ServiceResource SObject
 * @domain Core
 * @description Test class for ServiceResourcesSelector
 * @changelog
 * 2023-04-18 George Nguyen - Created
 */
@IsTest
public with sharing class ServiceResourcesSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		ServiceResourcesSelector selector = ServiceResourcesSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom ServiceResource\\b').matcher(soql).find(), 'Query from ServiceResource object');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(ServiceResource.RelatedRecordId) + '\\b').matcher(soql).find(), 'Field exists in query');
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		ServiceResourcesSelector selector = ServiceResourcesSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ServiceResourcesSelector.class, qa); 
		selector.selectById(new Set<Id>());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId IN :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');
	}

}