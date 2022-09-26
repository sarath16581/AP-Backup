/* @author Ranjeewa Silva
 * @group Tests
 * @tag Selector
 * @tag Route
 * @domain PUD
 * @description Test Class covering PUDRoutesSelector
 * @changelog
 * 2022-03-23 - Ranjeewa Silva - Created
 * 2022-07-28 - Kamil Szyc - add tests for selectByIdWithAllBookings and selectByIdAndDepotWithJobs
 * 2022-09-21 - Ranjeewa Silva - Updated tests for selecting routes with child bookings
 */
@IsTest
public with sharing class PUDRoutesSelector_Test {

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

		PUDRoutesSelector selector = PUDRoutesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting query does not select from Route');

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

		// Testing field overrides passing in field overrides for PUD_Booking__c and for related PUD_Route__c
		PUDRoutesSelector selector = PUDRoutesSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				PUD_Route__c.getSObjectType() => new Set<SObjectField>{PUD_Route__c.Depot__c}
		});

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Depot__c.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting query does not select Depot__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Name.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting selects Name but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides map with record limit
		selector = PUDRoutesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				PUD_Route__c.getSObjectType() => new Set<SObjectField>{PUD_Route__c.Depot__c}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Depot__c.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting query does not select Depot__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Name.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting selects Name but it shouldn\'t: ' + soql);

		// Testing field overrides passing in field overrides for PUD_Booking__c with record limit
		selector = PUDRoutesSelector.newInstance(0, new Set<SObjectField>{PUD_Route__c.Depot__c});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Depot__c.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting query does not select Depot__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Name.*?\\bfrom PUD_Route__c\\b').matcher(soql).find(), 'Resulting selects Name but it shouldn\'t: ' + soql);

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

		List<PUD_Route__c> routes = PUDTestDataFactory.getPUDRoutes(3, network.Id, false);
		insert routes;

		PUD_Booking_Location__c pudBookingLocation = PUDTestDataFactory.getPUDNetworkBookingLocations(1, network.Id, false)[0];
		insert pudBookingLocation;

		List<PUD_Booking__c> pudBookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(4, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), new List<String>{'Monday'}, false);
		pudBookings[0].Route_Lookup__c = routes[0].Id;
		pudBookings[1].Route_Lookup__c = routes[0].Id;
		pudBookings[2].Route_Lookup__c = routes[0].Id;
		pudBookings[3].Route_Lookup__c = routes[0].Id;

		// make pudBookings[2] an expired booking
		pudBookings[2].Effective_Date__c = Date.today().addDays(-30);
		pudBookings[2].Expiry_Date__c = Date.today().addDays(-10);

		// make pudBookings[3] a booking in 'Planned' status
		pudBookings[3].Effective_Date__c = Date.today().addDays(3);
		insert pudBookings;
		
		List<PUD_Job__c> pudJobs = PUDTestDataFactory.getPUDJobs(1, pudBookings[0].Id, 'Accepted', false);
		pudJobs[0].Route_Lookup__c = routes[0].Id;
		pudJobs[0].Date__c = Date.today();
		insert pudJobs;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		PUDRoutesSelector selector = PUDRoutesSelector.newInstance(0);

		List<PUD_Route__c> results = selector.selectById(new Set<Id>{routes[0].Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(routes[0].Id, results[0].Id, 'Expected route record not returned.');

		Map<Id, PUD_Route__c> resultsMap = new Map<Id, PUD_Route__c>(selector.selectByIdWithActiveBookings(new Set<Id>{routes[0].Id, routes[1].Id}, new Set<Id>()));
		System.assertEquals(2, resultsMap.size(), 'Expected result size of 2');
		System.assertEquals(true, resultsMap.containsKey(routes[0].Id), 'Expected route record not returned.');
		System.assertEquals(true, resultsMap.containsKey(routes[1].Id), 'Expected route record not returned.');
		System.assertEquals(2, resultsMap.get(routes[0].Id).Bookings__r.size(), 'Expected active child bookings to be populated on the route.');

		results = selector.selectByIdWithBookings(new Set<Id>{routes[0].Id}, new Set<String>{PUDConstants.PUD_BOOKING_STATUS_PLANNED, PUDConstants.PUD_BOOKING_STATUS_ACTIVE}, new Set<Id>());
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(3, results[0].Bookings__r.size(), 'Expected all active(2) and planned(1) bookings on this route to be returned.');
		
		results = selector.selectByIdAndDepotWithJobs(new Set<Id>{routes[0].Id}, null, new Set<String>(), new Set<Date>{Date.today()},new Set<Object>());
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assert(!results[0].Jobs__r.isEmpty(), 'No bookings were returned');
		Test.stopTest();
	}

}