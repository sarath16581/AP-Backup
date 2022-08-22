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

		MockUtility.Mocks.when(routesSelector.selectByIdWithAllBookings(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject())
		)
				.thenReturn(routeList
				);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);
		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardSetController(new List<PUD_Route__c>(routeList)));
		Test.stopTest();

		System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a list of routes');
		System.assert(!testRoutesPrint.routes.isEmpty(), 'Expected routes were not returned by the controller');
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

		MockUtility.Mocks.when(routesSelector.selectByIdWithAllBookings(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject())
		)
				.thenReturn(new List<PUD_Route__c>{route1}
				);
		MockUtility.Mocks.stopStubbing();


		Test.startTest();

		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);

		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardController(route1));
		Test.stopTest();
		System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a route');
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
		// Stubbing - NOT REQUIRED
		// =====================================
		
	
		Test.startTest();

		PUDPrintableRouteWrapper routeWrapper = new PUDPrintableRouteWrapper(route1);

		Test.stopTest();
		//assert that bookings are added 
		System.assertNotEquals(null, routeWrapper.bookings, 'Bookings wrapper is expected to be populated');
		
		//assert start and end time are formatted in HHMM format
		System.assertEquals('0700', routeWrapper.getStartTimeString(), 'Expected to format Start Time in HHMM format');
		System.assertEquals('0705', routeWrapper.getEndTimeString(), 'Expected to format End Time in HHMM format');
		
	}
}