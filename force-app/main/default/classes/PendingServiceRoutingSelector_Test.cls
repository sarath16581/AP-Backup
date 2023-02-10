/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag PendingServiceRouting SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-11-03 George Nguyen - Created
 * 2023-02-06 - Nathan Franklin - Added some tests for recent updates
 * 2023-02-08 - Noel Lim - Added method selectByLastModifiedDateLessThanEqualNDaysAgo
 */
@IsTest
public with sharing class PendingServiceRoutingSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		PendingServiceRoutingSelector selector = PendingServiceRoutingSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom PendingServiceRouting\\b').matcher(soql).find(), 'Query from PendingServiceRouting object');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.CustomRequestedDateTime) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.CapacityWeight) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.OwnerId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.PreferredUserId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.QueueId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.WorkItemId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsPreferredUserRequired) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsPushed) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.GroupId) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsPushAttempted) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsReadyForRouting) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsTransfer) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.RoutingModel) + '\\b').matcher(soql).find(), 'Field exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.RoutingType) + '\\b').matcher(soql).find(), 'Field exists in query');
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

		PendingServiceRoutingSelector selector = PendingServiceRoutingSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PendingServiceRoutingSelector.Options.WITH_WORKITEM});
		String soql = qb.toSoqlString();
		System.assertEquals(true,Pattern.compile('(?ism)WorkItem\\..*?\\bfrom pendingservicerouting\\b').matcher(soql).find(), 'Resulting query does not select WorkItem fields: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{PendingServiceRoutingSelector.Options.WITH_SKILLREQUIREMENTS});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom SkillRequirements\\b.*?\\).*?\\bfrom pendingservicerouting\\b').matcher(soql).find(), 'Resulting query does not select SkillRequirement child records: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{PendingServiceRoutingSelector.Options.EXCLUDE_ISPUSHED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bIsPushed\\s*=\\s*false\\b').matcher(soql).find(), 'Resulting query does not have IsPushed = false');

		Test.stopTest();

	}

	/**
	 * Scenario:
	 *  Ensures that the selectors QueryBuilder is generating the correct output when calling the search method
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWhenSearching() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		QueryBuilder qb = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(PendingServiceRoutingSelector.class, qb); 

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> searchParams = new Map<String, Object>{
			'limitToCaseOnly' => true,
			'limitToSkillWorkOnly' => true,
			'idGreaterThan' => '0JR000000000000',
			'orderBy' => PendingServiceRouting.CreatedById,
			'sortOrder' => 'Desc'
		};

		PendingServiceRoutingSelector selector = PendingServiceRoutingSelector.newInstance();
		
		// NOTE: records will always be empty since there is no data in the database
		//		We are assessing the query builder though, not the output
		List<PendingServiceRouting> records = selector.search(searchParams, true);

		String soql = qb.toSoqlString();

		// check the limitToCaseOnly
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom\\s+pendingservicerouting\\b.*?WorkItemId\\s+>\\s+\'500000000000000\'').matcher(soql).find(), 'Resulting query does not correctly query WorkItemId fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom\\s+pendingservicerouting\\b.*?WorkItemId\\s+<\\s+\'501000000000000\'').matcher(soql).find(), 'Resulting query does not correctly query WorkItemId fields: ' + soql);

		// check the limitToSkillWorkOnly
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom\\s+pendingservicerouting\\b.*?\\bId\\s+in\\s+\\(Select\\s+RelatedRecordId\\s+from\\s+SkillRequirement\\s*?\\)').matcher(soql).find(), 'Resulting query does not correctly limit to skills work only: ' + soql);
		
		// check the idGreaterThan
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom\\s+pendingservicerouting\\b.*?Id\\s+>\\s+:idGreaterThan').matcher(soql).find(), 'Resulting query does not correctly query based on Id: ' + soql);

		// check the orderBy & sortOrder
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom\\s+pendingservicerouting\\b.*?Order\\s+by\\s+CreatedById\\s+desc').matcher(soql).find(), 'Resulting query does not correctly order result set: ' + soql);

		Test.stopTest();
		
	}
	
	/**
	 * Scenario:
	 * Ensure field overrides produce correct query string
	 */
	@IsTest
	private static void testEnsureFieldOverridesAreCorrectlyIncludedInQueryBuilderOutput() {
		PendingServiceRoutingSelector selector = PendingServiceRoutingSelector.newInstance(1, new Set<SObjectField>{PendingServiceRouting.RoutingType});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PendingServiceRouting\\b').matcher(soql).find(), 'Query from PendingServiceRouting object: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsPushed) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.QueueId) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.RoutingType) + '\\b').matcher(soql).find(), 'Field does not exist in query: ' + soql);

		selector = PendingServiceRoutingSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
			PendingServiceRouting.SObjectType => new Set<SObjectField>{PendingServiceRouting.RoutingType},
			Case.SObjectType => new Set<SObjectField>{Case.CaseNumber}
		});
		qb = selector.newQueryBuilder(new Set<Object>{PendingServiceRoutingSelector.Options.WITH_WORKITEM});
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom PendingServiceRouting\\b').matcher(soql).find(), 'Query from PendingServiceRouting object: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.IsPushed) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.QueueId) + '\\b').matcher(soql).find(), 'Field exists in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(PendingServiceRouting.RoutingType) + '\\b').matcher(soql).find(), 'Field does not exist in query: ' + soql);
		System.assertEquals(true, Pattern.compile('\\bWorkItem\\.CaseNumber\\b').matcher(soql).find(), 'Field does not exist in query: ' + soql);
		System.assertEquals(false, Pattern.compile('\\bWorkItem\\.CreatedById\\b').matcher(soql).find(), 'Field exists in query: ' + soql);

	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		Map<Id, PendingServiceRouting> pendingServiceRoutings = new Map<Id, PendingServiceRouting>(OmniChannelTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true));

		PendingServiceRoutingSelector selector = PendingServiceRoutingSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(PendingServiceRoutingSelector.class, qa); 
		selector.selectById(pendingServiceRoutings.keySet());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bId in :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');
		
		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(PendingServiceRoutingSelector.class, qa); 
		selector.selectById(pendingServiceRoutings.keySet(), new Set<Object>{ PendingServiceRoutingSelector.Options.WITH_WORKITEM });
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bWorkItem\\.\\b').matcher(queryString).find(), 'Fields should contain the Case object (WorkItem lookup) fields in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(PendingServiceRoutingSelector.class, qa); 
		selector.selectByWorkItemId(pendingServiceRoutings.keySet(), new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + PendingServiceRouting.WorkItemId + ' in :workItemIds\\b').matcher(queryString).find(), 'Filters by workItemIds in query');

		qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(PendingServiceRoutingSelector.class, qa); 
		selector.selectByLastModifiedDateLessThanEqualNDaysAgo(3, new Set<Object>());
		queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + PendingServiceRouting.LastModifiedDate + ' <= N_DAYS_AGO:3\\b').matcher(queryString).find(), 'Filters by LastModifiedDate using N_DAYS_AGO in query');
	}
}