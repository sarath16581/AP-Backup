/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag QueueRoutingConfig SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-11-03 George Nguyen - Created
 */
@IsTest
public with sharing class QueueRoutingConfigSelector_Test {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		QueueRoutingConfigSelector selector = QueueRoutingConfigSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom QueueRoutingConfig\\b').matcher(soql).find(), 'Query from QueueRoutingConfig object');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.CapacityPercentage) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.CapacityWeight) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.DropAdditionalSkillsTimeout) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.IsAttributeBased) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.OverflowAssigneeId) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.PushTimeout) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.RoutingModel) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.RoutingPriority) + '\\b').matcher(soql).find(), 'Field exists in query');
        System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(QueueRoutingConfig.DeveloperName) + '\\b').matcher(soql).find(), 'Field exists in query');
	}

    @IsTest
    static void selectWithTheCorrectQueryAttributes() {
        
        Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));
        Map<Id, QueueRoutingConfig> queueRoutingConfigs = new Map<Id, QueueRoutingConfig>(ApplicationTestDataFactory.getQueueRoutingConfigs(2, true));

        QueueRoutingConfigSelector selector = QueueRoutingConfigSelector.newInstance();

        QueryBuilder qa = QueryBuilder.newInstance();
        QueryBuilder.mockFactory.put(QueueRoutingConfigSelector.class, qa); 
        selector.selectById(queueRoutingConfigs.keySet());
        String queryString = qa.toSoqlString();
        System.assertEquals(true, Pattern.compile('\\bId in :ids\\b').matcher(queryString).find(), 'Filters by Ids in query');
        
        List<String> developerNames = new List<String>{ queueRoutingConfigs.values()[0].DeveloperName, queueRoutingConfigs.values()[1].DeveloperName };
        qa = QueryBuilder.newInstance();
        QueryBuilder.mockFactory.put(QueueRoutingConfigSelector.class, qa); 
        selector.selectSkillBasedByDeveloperName(developerNames, new Set<Object>());
        queryString = qa.toSoqlString();
        System.assertEquals(true, Pattern.compile('\\b' + QueueRoutingConfig.DeveloperName + ' in :developerNames\\b').matcher(queryString).find(), 'Filters by developerNames in query');
    }

}