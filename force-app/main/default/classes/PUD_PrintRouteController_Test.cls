/**
* @author Kamil Szyc
* @date 2022-06-24
* @group PUD
* @tag PUD_Route__c
* @domain PUD
* @description Controller test class to for printing CCP routes with bookings.
 * @changelog
 * 2022-06-24 - created
 */

@IsTest
private class PUD_PrintRouteController_Test {
	@IsTest
	static void testGetBookingsForMultipleRoutes() {

		//Create test Depot
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1,true)[0];
		List<PUD_Route__c> routeList = PUDTestDataFactory.getPUDRoutes(2,networkDepot.Id, false);

		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector)MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(routesSelector.selectByIdWithAllBookings(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject(),
				(Map<SObjectType, Set<SObjectField>>) fflib_Match.anyObject())
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
		Network__c networkDepot = ApplicationTestDataFactory.getNetworks(1,true)[0];
		PUD_Route__c route1 = PUDTestDataFactory.getPUDRoutes(1,networkDepot.Id, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		//
		PUDRoutesSelector routesSelector = (PUDRoutesSelector)MockUtility.mockSelector(PUDRoutesSelector.class);
		// set up responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(routesSelector.selectByIdWithAllBookings(
				(Set<Id>) fflib_Match.anyObject(),
				(Set<Object>) fflib_Match.anyObject(),
				(Map<SObjectType, Set<SObjectField>>) fflib_Match.anyObject())
		)
				.thenReturn(new List<PUD_Route__c>{route1}
				);
		MockUtility.Mocks.stopStubbing();


		Test.startTest();

		PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
		Test.setCurrentPage(pageRef);

		PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardController(route1));
		Test.stopTest();
		System.assertNotEquals(null, testRoutesPrint.route, 'The selector has not returned a route');
	}
}