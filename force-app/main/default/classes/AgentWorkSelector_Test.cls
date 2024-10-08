/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag AgentWork SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-10-20 George Nguyen - Created
 * 2024-08-12 - Ranjeewa Silva - Added test to verify search method behaviour.
 * 2024-09-30 - Ranjeewa Silva - Updated to verify filtering in 'selectAcceptedAgentWorkByCaseIdsAndActiveUser' by AgentWork.Case__c
 */
@IsTest
public with sharing class AgentWorkSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		AgentWorkSelector selector = AgentWorkSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom AgentWork\\b').matcher(soql).find(), 'Query from AgentWork object');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(AgentWork.WorkItemId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(AgentWork.Status) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(AgentWork.UserId) + '\\b').matcher(soql).find(), 'Field exists in query');
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Map<Id, AgentWork> agentWorks = new Map<Id, AgentWork>(OmniChannelTestDataFactory.getAgentWorks(2, UserInfo.getUserId(), cases.keySet(), true));

		AgentWorkSelector selector = AgentWorkSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(AgentWorkSelector.class, qa); 
		selector.selectById(agentWorks.keySet());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId in :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');
		
		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(AgentWorkSelector.class, qa); 
		selector.selectById(agentWorks.keySet(), new Set<Object>{ AgentWorkSelector.Options.WITH_USER, AgentWorkSelector.Options.WITH_CASE });
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bUser\\.\\b').matcher(queryString).find(), 'Fields should contain the User object fields in query');
		System.assertEquals(true, Pattern.compile('\\bWorkItem\\.\\b').matcher(queryString).find(), 'Fields should contain the Case object (WorkItem lookup) fields in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(AgentWorkSelector.class, qa); 
		selector.selectByWorkItemIds(agentWorks.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + AgentWork.WorkItemId + ' in :workItemIds\\b').matcher(queryString).find(), 'Filters by workItemIds in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(AgentWorkSelector.class, qa); 
		selector.selectByAcceptedWorkItemIds(agentWorks.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + AgentWork.WorkItemId + ' in :workItemIds AND ' + AgentWork.AcceptDateTime + ' != NULL\\b').matcher(queryString).find(), 'Filters by workItemIds and AcceptDateTime not null in query');
		System.assertEquals(true, Pattern.compile('\\bORDER BY ' + AgentWork.WorkItemId + ' ASC, ' + AgentWork.AcceptDateTime + ' DESC').matcher(queryString).find(), 'Order by work item id and date in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(AgentWorkSelector.class, qa); 
		selector.selectAcceptedAgentWorkByCaseIdsAndActiveUser(cases.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + AgentWork.Case__c + ' in :caseIds AND ' + AgentWork.AcceptDateTime + ' != NULL AND User.IsActive = TRUE\\b').matcher(queryString).find(), 'Filters by caseIds and AcceptDateTime not null in query');
		System.assertEquals(true, Pattern.compile('\\bORDER BY ' + AgentWork.Case__c + ' ASC, ' + AgentWork.AcceptDateTime + ' DESC').matcher(queryString).find(), 'Order by case id and date in query');
	}

	/**
	 * Test to ensure that the search method QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {
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

		Map<String, Object> searchParams;

		AgentWorkSelector selector = AgentWorkSelector.newInstance();

		searchParams = new Map<String, Object>{
				'workItemIds' => new Set<Id>{'500000000000000'},
				'status' => new Set<String>{'Opened'}
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from AgentWork\\s+where\\b.*?\\bWorkItemId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter work item.');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from AgentWork\\s+where\\b.*?\\bStatus\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter status.');
		Assert.isTrue(Pattern.compile('(?ism)\\s+from AgentWork\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
				'workItemIds' => new Set<Id>{'500000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from AgentWork\\s+where\\b.*?\\bWorkItemId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter by Work Item.');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from AgentWork\\s+where\\b.*?\\bStatus\\s+In\\b').matcher(soql).find(), 'Resulting query filter status, but it should not.');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		// make sure an exception is thrown for invalid search parameters
		searchParams = new Map<String, Object>{
				'invalidParam' => new Set<String>{'somevalue'},
				'workItemIds' => new Set<Id>{'500000000000000'}
		};

		try {
			soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		} catch (Exception e) {
			// ensure correct type of exception thrown
			Assert.isInstanceOfType(e, ApplicationSelector.SelectorException.class);
		}

		Test.stopTest();
	}

}