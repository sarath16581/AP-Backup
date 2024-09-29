/***
 * @author Disha kariya
 * @date 2020-08-24
 * @group Tests
 * @tag Selector
 * @tag Event Message SObject
 * @domain Core
 * @description Test Class covering EventMessagesSelector
 * @changelog
 * 2020-08-24 - Disha Kariya - Created
 * 2020-10-06 - Disha Kariya - Updated test for safe drop guid filter
 * 2021-06-15 - Ranjeewa Silva - Updated test for attachment guid filter
 * 2022-11-29 - Mahesh Parvathaneni - Updated test for newInstance with sort filter
 * 2022-12-15 - Mahesh Parvathaneni - Updated options FILTER_AP_NETWORK_NOT_NULL in tests
 * 2023-03-08 - Mahesh Parvathaneni - Updated options FILTER_GEO_LOCATION in tests
 * 2023-03-10 - Mahesh Parvathaneni - Removed the option FILTER_AP_NETWORK_NOT_NULL
 * 2024-09-23 - Seth Heang - added test for selectByCaseIdAndEventType
 */
@IsTest
public with sharing class EventMessagesSelector_Test {

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

		EventMessagesSelector selector = EventMessagesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		// make sure there is RecordType.DeveloperName condition
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select from Event Message');

		selector = EventMessagesSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{EventMessagesSelector.Options.WITH_OWNER, EventMessagesSelector.Options.WITH_ARTICLE,
				EventMessagesSelector.Options.WITH_RECORDTYPE, EventMessagesSelector.Options.FILTER_SAFE_DROP_GUID,
				EventMessagesSelector.Options.WITH_SIGNATURE_FIELD, EventMessagesSelector.Options.FILTER_ATTACHMENT_GUID
		});
		soql = qb.toSoqlString();

		// make sure there is Owner
		System.assertEquals(true, Pattern.compile('(?ism)Owner.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select from Owner');

		// make sure signature field was selected with selector option
		System.assertEquals(true, Pattern.compile('(?ism)SignatureXString__c.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select SignatureXString__c field');

		// make sure there is Article
		System.assertEquals(true, Pattern.compile('(?ism)Article__r.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select from Article');
		// make sure there is RecordType
		System.assertEquals(true, Pattern.compile('(?ism)RecordType.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select from RecordTypes');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EventMessage__c\\b.*Safe_Drop_GUID__c\\s*!=\\s*\'\'').matcher(soql).find(), 'Resulting query does not filter safe drop guid');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EventMessage__c\\b.*Safe_Drop_GUID__c\\s*!=\\s*NULL').matcher(soql).find(), 'Resulting query does not filter NULL safe drop guid');
		// make sure filtered by attachment guid
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EventMessage__c\\b.*AttachmentGUID__c\\s*!=\\s*NULL').matcher(soql).find(), 'Resulting query does not filter attachment guid');

		//Test sub query
		qb = selector.newQueryBuilder(new Set<Object>{EventMessagesSelector.Options.WITH_ATTACHMENT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Attachments\\b.*?\\).*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select Attachments child records: '+soql);

		//Test field override
		selector = EventMessagesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				EventMessage__c.SObjectType => new Set<SObjectField>{EventMessage__c.Booking_Reference__c, EventMessage__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Booking_Reference__c.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select Booking_Reference__c field: ' + soql);

		selector = EventMessagesSelector.newInstance(0, new Set<SObjectField>{EventMessage__c.Booking_Reference__c, EventMessage__c.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Booking_Reference__c.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select Booking_Reference__c field: ' + soql);

		selector = EventMessagesSelector.newInstance(new Set<SObjectField>{EventMessage__c.Booking_Reference__c, EventMessage__c.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Booking_Reference__c.*?\\bfrom EventMessage__c\\b').matcher(soql).find(), 'Resulting query does not select Booking_Reference__c field: ' + soql);

		selector = EventMessagesSelector.newInstance(EventMessagesSelector.sortfieldAPIName, EventMessagesSelector.sortOrder);
		qb = selector.newQueryBuilder(new Set<Object>{EventMessagesSelector.Options.FILTER_GEO_LOCATION});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EventMessage__c\\b.*EventGeoLocation__Latitude__s\\s*!=\\s*NULL').matcher(soql).find(), 'Resulting query does not filter NULL geolocation latitude');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom EventMessage__c\\b.*EventGeoLocation__Longitude__s\\s*!=\\s*NULL').matcher(soql).find(), 'Resulting query does not filter NULL geolocation longitude');


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
		MockUtility.disableTriggerExecution();

		Article__c article = ApplicationTestDataFactory.getConsignments(1, false)[0];
		insert article;

		Network__c network = ApplicationTestDataFactory.getNetworks(1, false)[0];
		insert network;

		Case testCase = ApplicationTestDataFactoryCase.getCases(1, false)[0];
		insert testCase;

		Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
		List<EventMessage__c> events = ApplicationTestDataFactory.getEventMessages(2, article.Id, false);
		events[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
		events[1].EventType__c = eventMessageType.get('Delivered')[0].Label;
		events[0].EventGeoLocation__Longitude__s = 151.62805;
		events[0].EventGeoLocation__Latitude__s = -32.927406;
		insert events;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventMessagesSelector selector = EventMessagesSelector.newInstance(20);
		Map<Id, EventMessage__c> results = selector.selectById(new Set<Id>{events[0].Id, events[1].Id});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = EventMessagesSelector.newInstance();
		results = selector.selectByArticleId(new Set<Id>{article.Id});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = EventMessagesSelector.newInstance();
		results = selector.selectByArticleId(new Set<Id>{article.Id}, new Set<String>{eventMessageType.get('AttemptedDelivery')[0].Label});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		selector = EventMessagesSelector.newInstance();
		results = selector.selectByArticleId(new Set<Id>{article.Id}, new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		selector = EventMessagesSelector.newInstance();
		List<EventMessage__c> resultsList = selector.selectByArticleNumber(new Set<String>{'CON1231'}, new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE});
		System.assertEquals(2, resultsList.size(), 'Expected result size of 2');
		System.assertNotEquals(null, resultsList[0].Article__r, 'Expected article object');

		selector = EventMessagesSelector.newInstance();
		List<EventMessage__c> eventsList = selector.selectByArticleNumber(new Set<String>{'CON1231'}, new Set<Object>{EventMessagesSelector.Options.FILTER_GEO_LOCATION});
		System.assertEquals(1, eventsList.size(), 'Expected result size of 1');

		selector = EventMessagesSelector.newInstance();
		resultsList = selector.selectByCaseIdAndEventType(new Set<Id>{ testCase.Id }, new Set<String>{ events[1].EventType__c });
		System.assertEquals(1, eventsList.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}