/**
* @author Kamil Szyc
* @date 2022-06-24
* @group PUD
* @tag PUD_Route__c
* @domain PUD
* @description Controller test class to for printing CCP routes with bookings.
 * @changelog
 * 2022-06-24 - Kamil Szyc - created
 * 2022-08-08 - Dattaraj Deshmukh - updated test class to cover wrapper classes referred in 'PUD_PrintRouteController'
 * 2022-09-01- Dattaraj Deshmukh - updated test class to cover overnight routes scenario. Added method 'testOvernightRoutes()'
 * 2022-09-21- Ranjeewa Silva - Updated tests for selecting routes with child bookings
 */

@IsTest
private class PUD_PrintRouteController_Test {
	@IsTest
	static void testGetBookingsForMultipleRoutes() {

		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Route__c> routeList = PUDTestDataFactory.getPUDRoutes(2, networkDepot.Id, false);

		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(routesSelector.selectByIdWithBookings(
				(Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
		).thenReturn(routeList);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);
		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardSetController(new List<PUD_Route__c>(routeList)));
		Test.stopTest();

		System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a list of routes');
		System.assertEquals(2, testRoutesPrint.routes.size(), 'Expected routes were not returned by the controller');
	}
	@IsTest
	static void testGetBookingsForSingleRoute() {
		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		PUD_Route__c route1 = PUDTestDataFactory.getPUDRoutes(1, networkDepot.Id, false)[0];

		//set start and end time for route
		route1.Start_Time__c = Time.newInstance(7, 0, 0, 0);
		route1.End_Time__c = Time.newInstance(7, 5, 0, 0);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(5, null, networkDepot.Id, Date.today(), Date.today().addDays(5), new List<String>{'Monday','Tuesday'}, true);
		
		//set 3 bookings as Meal Break bookings, set start time and Dwell Time planned
		bookings[0].Booking_Type__c = PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK;
		bookings[0].Start_Time__c = Time.newInstance(7, 0, 0, 0);
		bookings[0].Dwell_Time_Planned__c = 5;

		bookings[1].Booking_Type__c = PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK;
		bookings[1].Start_Time__c = Time.newInstance(10, 0, 0, 0);
		bookings[1].Dwell_Time_Planned__c = 15;
		
		//associating bookings with a route.
		route1 = (PUD_Route__c)ApplicationTestDataFactory.setChildRelationships(route1, new Map<String, List<SObject>>{'Bookings__r' => bookings});

		
		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(routesSelector.selectByIdWithBookings(
				(Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
		).thenReturn(new List<PUD_Route__c>{route1});

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);

		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardController(route1));
		Test.stopTest();
		System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a route');
		System.assertEquals(1, testRoutesPrint.routes.size(), 'Expected only one route, but received [' + testRoutesPrint.routes.size() + ']');
		System.assertEquals(5, testRoutesPrint.routes[0].bookings.size(), 'Expected number of bookings not returned with the route.');
		System.assertEquals(2, testRoutesPrint.routes[0].mealBreaks.size(), 'Expected number of meal break bookings not returned with the route.');
	}

	@IsTest
	static void testRouteBookingWrappers() {
		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		PUD_Route__c route1 = PUDTestDataFactory.getPUDRoutes(1, networkDepot.Id, false)[0];

		//set start and end time for route
		route1.Start_Time__c = Time.newInstance(7, 0, 0, 0);
		route1.End_Time__c = Time.newInstance(7, 5, 0, 0);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(5, null, networkDepot.Id, Date.today(), Date.today().addDays(5), new List<String>{'Monday','Tuesday'}, true);
		
		//set 2 bookings as Meal Break bookings, set start time and Dwell Time planned
		bookings[0].Booking_Type__c = PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK;
		bookings[0].Start_Time__c = Time.newInstance(7, 0, 0, 0);
		bookings[0].Dwell_Time_Planned__c = 5;

		bookings[1].Booking_Type__c = PUDConstants.PUD_BOOKING_TYPE_MEAL_BREAK;
		bookings[1].Start_Time__c = Time.newInstance(10, 0, 0, 0);
		bookings[1].Dwell_Time_Planned__c = 15;
		
		//associating bookings with a route.
		route1 = (PUD_Route__c)ApplicationTestDataFactory.setChildRelationships(route1, new Map<String, List<SObject>>{'Bookings__r' => bookings});

		
		// =====================================
		// Stubbing - NOT REQUIRED
		// =====================================
		
	
		Test.startTest();

		PUDPrintableRouteWrapper routeWrapper = new PUDPrintableRouteWrapper(route1);
		PUDPrintableBookingWrapper bookingWrapper = new PUDPrintableBookingWrapper(bookings[0]);

		Test.stopTest();
		//assert that bookings are added 
		System.assertNotEquals(null, routeWrapper.bookings, 'Bookings wrapper is expected to be populated');
		
		//assert routes start and end time are formatted in HHMM format
		System.assertEquals('0700 - 0705', routeWrapper.getRouteDuration(), 'Expected to format route duration with hyphen');

		//assert bookings start and end time are formatted in HHMM format
		System.assertEquals('0700', bookingWrapper.getStartTimeString(), 'Expected to format Start Time in HHMM format');
		System.assertEquals('0705', bookingWrapper.getEndTimeString(), 'Expected to format end Time in HHMM format');

		//assert booking duration
		System.assertEquals('0700 - 0705', bookingWrapper.getBookingDuration(), 'Expected to format booking duration with hyphen');
		
	}

	@IsTest
	static void testOvernightRoutes() {
		
		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		PUD_Route__c route1 = PUDTestDataFactory.getPUDRoutes(1, networkDepot.Id, false)[0];

		//set start and end time as 2200 - 0600 hrs ( 10.00PM - 6.00AM)
		//Setting route's start and end time as below will mark route as Overnight Route
		route1.Start_Time__c = Time.newInstance(22, 0, 0, 0);
		route1.End_Time__c = Time.newInstance(6, 0, 0, 0);


		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(5, null, networkDepot.Id, Date.today(), Date.today().addDays(5), new List<String>{'Monday','Tuesday'}, true);
		
	
			
		//setting start and dwelling time for booking[0], booking[1], booking[3] (1st, 2nd and 4th booking in list)
		bookings[0].Start_Time__c = Time.newInstance(2, 0, 0, 0);
		bookings[0].Dwell_Time_Planned__c = 15;

		bookings[1].Start_Time__c = Time.newInstance(3, 0, 0, 0);
		bookings[1].Dwell_Time_Planned__c = 15;

		bookings[3].Start_Time__c = Time.newInstance(5, 0, 0, 0);
		bookings[3].Dwell_Time_Planned__c = 15;
		
		//If booking's start time > Route.Start_Time__c, then such booking is an overnight booking.
		//setting start time as 11.00pm and dwelling time for booking[2]. (3rd booking in list)
		bookings[2].Start_Time__c = Time.newInstance(23, 0, 0, 0);
		bookings[2].Dwell_Time_Planned__c = 15;

		//setting start time as 11.30pm and dwelling time for booking[2]. (5th booking in list)
		bookings[4].Start_Time__c = Time.newInstance(23, 30, 0, 0);
		bookings[4].Dwell_Time_Planned__c = 15;

	
		//associating bookings with a route.
		route1 = (PUD_Route__c)ApplicationTestDataFactory.setChildRelationships(route1, new Map<String, List<SObject>>{'Bookings__r' => bookings});

		//populating formula field on Route object.
		//Since we are doing any DMLs, formula fields need to be populated for mocked record.
		//setting route as Overnight Route.
		route1 = (PUD_Route__c) ApplicationTestDataFactory.setUnwritableFields(route1, new Map<String, Object>{'Overnight_Route__c' => true});
		
		// =====================================
		// Stubbing - 
		// =====================================
		
		PUDRoutesSelector routesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(routesSelector.selectByIdWithBookings(
				(Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
		).thenReturn(new List<PUD_Route__c>{route1});

		MockUtility.Mocks.stopStubbing();


		//start test
		Test.startTest();

		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);

		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardController(route1));
		Test.stopTest();

		//asserts routes are selected
		System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a route');

		//asserting that bookings are sorted and overnight bookings after normal bookings.
		//bookings at position 1 and 2 should be listed as per start time on booking. 
		//ie. Bookings starting on 1st Day should be listed before bookings starting on 2nd Day
		//bookings[2] and bookings[4] (3rd and 5th bookings) start Day 1  ie. between (2200hrs - 2400hrs)
		system.assertEquals(testRoutesPrint.routes[0].bookings[0].booking.Id, bookings[2].Id, 'Expected booking at 2300-2330 to appear first.');
		system.assertEquals(testRoutesPrint.routes[0].bookings[1].booking.Id, bookings[4].Id, 'Expected booking at 2330-2345 to appear second.');
				
	}
}	