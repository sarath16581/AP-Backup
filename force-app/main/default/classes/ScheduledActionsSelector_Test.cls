/**
 * @author Seth Heang
 * @group Tests
 * @tag Selector
 * @tag ScheduledAction__c SObject
 * @domain Core
 * @description Test class for ScheduledActionsSelector
 * @changelog
 * 2024-07-26 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
public with sharing class ScheduledActionsSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		ScheduledActionsSelector selector = ScheduledActionsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?is)\\bfrom ScheduledAction__c\\b').matcher(soql).find(), 'Query from ScheduledAction__c object');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(ScheduledAction__c.Id) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(ScheduledAction__c.Id) + ' does not exist in query');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(ScheduledAction__c.Case__c) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(ScheduledAction__c.Case__c) + ' does not exist in query');
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactory.getCases(1, true)[0];
		String actionType = ScheduledAction__c.ActionType__c.getDescribe().getPicklistValues()[0].getLabel();
		Map<Id, ScheduledAction__c> scheduledActions = new Map<Id, ScheduledAction__c>(ApplicationTestDataFactory.getScheduledActions(2, 'Test Scheduled Action', actionType, System.now(), caseTest.Id, true));

		// =====================================
		// Testing
		// =====================================
		ScheduledActionsSelector selector = ScheduledActionsSelector.newInstance();
		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ScheduledActionsSelector.class, qa);
		selector.selectById(scheduledActions.keySet());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId in :ids\\b').matcher(queryString).find(), 'Filters by Ids in query but Ids does not exist: ' + queryString);

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ScheduledActionsSelector.class, qa);
		selector.selectById(scheduledActions.keySet(), new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE });
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Case__r\\..*?\\bfrom ScheduledAction__c\\b').matcher(queryString).find(), 'Fields should contain the Case object fields in query: ' + queryString);

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(ScheduledActionsSelector.class, qa);
		selector.selectByCaseId(new Set<Id>{ caseTest.Id });
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + ScheduledAction__c.Case__c + ' in :caseIds\\b').matcher(queryString).find(), 'Filters by caseIds in query but caseIds does not exist: ' + queryString);
	}
}