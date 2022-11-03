/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag PendingServiceRouting SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-11-03 George Nguyen - Created
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

    @IsTest
    static void selectWithTheCorrectQueryAttributes() {
        
        Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
        Id serviceChannelId = ApplicationTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
        Map<Id, PendingServiceRouting> pendingServiceRoutings = new Map<Id, PendingServiceRouting>(ApplicationTestDataFactory.getPendingServiceRoutings(2, serviceChannelId, cases.keySet(), true));

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

    }

}
