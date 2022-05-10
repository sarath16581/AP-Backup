/* @author Arjun Singh
 * @group Tests
 * @tag Selector
 * @tag PUD Booking
 * @domain PUD
 * @description Test Class covering PUDBookingsSelector
 * @changelog
 * 2021-08-16 - arjun.singh@austpost.com.au - Created
 * 2022-03-24 - Ranjeewa Silva - Refactored the test class and added more test scenarios for testing selector options and field overrides.
 */
@IsTest
public with sharing class PUDBookingsSelector_Test {
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
	PUDBookingsSelector selector = PUDBookingsSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select from PUD_Booking__c');

	Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output with selector options and field overrides
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

		PUDBookingsSelector selector = PUDBookingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_ROUTE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Route_Lookup__r\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Route fields');

		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_PARENT_BOOKING});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Parent_Booking__r\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select parent booking fields');

		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_RECORDTYPE, PUDBookingsSelector.Options.WITH_ROUTE, PUDBookingsSelector.Options.WITH_PARENT_BOOKING});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?is)Route_Lookup__r\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Route fields');
		System.assertEquals(true, Pattern.compile('(?is)Parent_Booking__r\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select parent booking fields');

		// Testing field overrides passing in field overrides for PUD_Booking__c and for related PUD_Route__c
		selector = PUDBookingsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				PUD_Booking__c.getSObjectType() => new Set<SObjectField>{PUD_Booking__c.Sunday__c},
				PUD_Route__c.getSObjectType() => new Set<SObjectField>{PUD_Route__c.CreatedDate}
		});

		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_ROUTE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Sunday__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Sunday__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Status__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Route_Lookup__r\\.CreatedDate.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select CreatedDate field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Route_Lookup__r\\.Depot__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Route_Lookup__r.Depot__c but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides map with record limit
		selector = PUDBookingsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				PUD_Booking__c.getSObjectType() => new Set<SObjectField>{PUD_Booking__c.Sunday__c},
				PUD_Route__c.getSObjectType() => new Set<SObjectField>{PUD_Route__c.CreatedDate}
		});
		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_ROUTE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Sunday__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Sunday__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Status__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Route_Lookup__r\\.CreatedDate.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select CreatedDate field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Route_Lookup__r\\.Depot__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Route_Lookup__r.Depot__c but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides for PUD_Booking__c with record limit
		selector = PUDBookingsSelector.newInstance(0, new Set<SObjectField>{PUD_Booking__c.Sunday__c});
		qb = selector.newQueryBuilder(new Set<Object>{PUDBookingsSelector.Options.WITH_ROUTE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Sunday__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Sunday__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Status__c.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
		System.assertEquals(true, Pattern.compile('(?is)Route_Lookup__r\\..*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Route fields');

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

		Network__c network = ApplicationTestDataFactory.getNetworks(1, false)[0];
		network.recordTypeId = PUDTestDataFactory.businessHubNetworkRecordType;
		network.ORG_UNIT_ADDR_2__c ='1 Main St';
		network.ORG_UNIT_ADDR_3__c ='Melbourne';
		network.State__c  ='VIC';
		network.Post_Code__c ='3121';
		insert network;

		PUD_Booking_Location__c pudBookingLocation = PUDTestDataFactory.getPUDNetworkBookingLocations(1, network.Id, false)[0];
		insert pudBookingLocation;

		List<PUD_Booking__c> pudBookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), new List<String>{'Monday'}, false);
		insert pudBookings;

		pudBookings[1].Parent_Booking__c = pudBookings[0].Id;
		update pudBookings[1];


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		PUDBookingsSelector selector = PUDBookingsSelector.newInstance(0);

		List<PUD_Booking__c> results = selector.selectById(new Set<Id>{pudBookings[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(pudBookings[0].Id, results[0].Id, 'Expected booking record not returned.');

		results = selector.selectByParentBookingId(new Set<Id>{pudBookings[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(pudBookings[1].Id, results[0].Id, 'Expected booking record not returned.');

		Test.stopTest();	
	}
}