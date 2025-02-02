/**
* @author Dheeraj Mandavilli
* @date 2019-11-19
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_AdhocJobsPrintfromRouteControllerX class.
* NOTE: This test class is used to test the PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc and Perm with variations" from Routes Detail Page. 
* 2019-11-19 - Dheeraj Mandavilli - Created
 * 2022-07-11 - Kamil Szyc - rebuild to test new version of the controller with selectors
 * * 2022-09-15 - Dattaraj Deshmukh - Removed reference to VF page 'PUD_BookingPrint'.
*/
@IsTest
private with sharing class PUD_AdhocJobsPrintfromRouteCtrlX_Test {
	@IsTest
	static void testPrintAdHocJobsFromRouteController() {
		
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Route__c> routeList = PUDTestDataFactory.getPUDRoutes(2, networkDepot.Id, true);
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDNetworkBookingLocations(1, networkDepot.Id, true);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(2, bookingLocations[0].Id, networkDepot.Id, Date.today(), Date.today().addYears(1), new List<String>{
				'Monday', 'Friday'
		}, true);
		//
		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(routesSelector.selectByIdAndDepotWithJobs(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Id>) fflib_Match.anyObject(),
				(Set<String>) fflib_Match.anyObject(),
				(Set<Date>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject()
		))
				.thenReturn(routeList
				);
	
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		PUD_AdhocJobsPrintfromRouteControllerX testDTPrint = new PUD_AdhocJobsPrintfromRouteControllerX(new ApexPages.StandardController(routeList[0]));

		Test.stopTest();
		System.assertNotEquals(null, testDTPrint.route, 'Route record was not instantiated correctly');
	}
}