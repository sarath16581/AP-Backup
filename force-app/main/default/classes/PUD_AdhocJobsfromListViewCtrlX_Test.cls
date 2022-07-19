/**
* @author Dheeraj Mandavilli
* @date 2019-11-28
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_AdhocJobsfromListViewControllerX class.
* NOTE: This test class is used to test the PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc Jobs" from Routes List View. 
* 2019-11-28 - Dheeraj Mandavilli - Created
* 2022-07-12 - Kamil Szyc - refactor tests to reflect changes to the controller. Add mocks for selector classes related tests.
*/
@IsTest
private with sharing class PUD_AdhocJobsfromListViewCtrlX_Test {
	@IsTest
	static void testPUD_AdhocJobsfromListViewControllerX(){

		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1, true)[0];
		List<PUD_Route__c> routeList = PUDTestDataFactory.getPUDRoutes(2, networkDepot.Id, true);
		List<PUD_Booking_Location__c> bookingLocations = PUDTestDataFactory.getPUDNetworkBookingLocations(1, networkDepot.Id, true);
		List<PUD_Booking__c> bookings = PUDTestDataFactory.getPUDAdhocPickupDeliveryBookings(2, bookingLocations[0].Id, networkDepot.Id, Date.today(), Date.today().addYears(1), new List<String>{
				'Monday', 'Friday'
		}, true);
		List<PUD_Job__c> jobs = PUDTestDataFactory.getPUDJobs(3, bookings[0].Id, PUDConstants.PUD_JOB_STATUS_ACCEPTED, true);
		//
		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector) MockUtility.mockSelector(PUDRoutesSelector.class);
		PUDJobsSelector jobsSelector = (PUDJobsSelector) MockUtility.mockSelector(PUDJobsSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(routesSelector.selectByIdWithJobs(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<String>) fflib_Match.anyObject(),
				(Set<Date>) fflib_Match.anyObject(),
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject(),
				(Map<SObjectType,Set<SObjectField>>) fflib_Match.anyObject())
		)
				.thenReturn(routeList
				);
		MockUtility.Mocks.when(jobsSelector.selectJobsByBookingRecordTypesJobDatesAndDepotIds(
				(Set<String>) fflib_Match.anyObject(),
				(Set<Date>) fflib_Match.anyObject(),
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject()
		))
				.thenReturn(jobs);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		PageReference pageRef = Page.PUD_JobPrint;
		Test.setCurrentPage(pageRef);

		PUD_AdhocJobsfromListViewControllerX testDTPrint = new PUD_AdhocJobsfromListViewControllerX(new ApexPages.StandardSetController(new List<PUD_Route__c>(routeList)));

		Test.stopTest();
		System.assertNotEquals(null, testDTPrint.routes, 'Routes records were not instantiated correctly');
		System.assert(!testDTPrint.routes.isEmpty(), 'Routes in the controller were not populated correctly');
	}
}