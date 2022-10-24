/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag AgentWork SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-10-20 George Nguyen - Created
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
        Map<Id, AgentWork> agentWorks = new Map<Id, AgentWork>(ApplicationTestDataFactory.getAgentWorks(2, UserInfo.getUserId(), cases.keySet(), true));

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
    }

}
