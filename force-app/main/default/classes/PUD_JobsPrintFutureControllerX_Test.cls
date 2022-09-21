/**
* @author Dheeraj Mandavilli
* @date 2020-03-25
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_JobsPrintFutureControllerX class.
* NOTE: This test class is used to test the PUD_FutureJobsPrintView VF Page upon clicking "Print Route" from Routes Detail Page. 
* 2020-03-25 - Dheeraj Mandavilli - Created
 * 2022-07-11 - Kamil Szyc - rebuild to test new version of the controller with selectors
 * 2022-09-15 - Dattaraj Deshmukh - Removed reference to VF page 'PUD_BookingPrint'.
*/
@IsTest
public with sharing class PUD_JobsPrintFutureControllerX_Test {

	@IsTest
	static void testJobsPrintFutureController() {

		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Route__c> routeList = PUDTestDataFactory.getPUDRoutes(2, networkDepot.Id, true);
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDNetworkBookingLocations(1, networkDepot.Id, true);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(2, bookingLocations[0].Id, networkDepot.Id, Date.today(), Date.today().addYears(1), new List<String>{
				'Monday', 'Friday'
		}, true);
		// =====================================
		// Stubbing
		// =====================================
		
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

		PUD_JobsPrintFutureControllerX testDTPrint = new PUD_JobsPrintFutureControllerX(new ApexPages.StandardController(routeList[0]));

		Test.stopTest();
		System.assertNotEquals(null, testDTPrint.route, 'Route record was not instantiated correctly');
	}

}