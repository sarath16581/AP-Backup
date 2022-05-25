/**
 * Test class for LocationsService
 * @author Mahesh Parvathaneni
 * @date 2022-04-14
 * @changelog
 */
@isTest
public with sharing class LocationsService_Test {
    
    /***
     * Test that a distance between locations is returned
     */
	@IsTest
	private static void testGetDistanceBetweenLocations() {
        // =====================================
		// Data Preparation
		// =====================================
        Location loc1 = Location.newInstance(28.635308,77.22496);
        Location loc2 = Location.newInstance(37.7749295,-122.4194155);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

        Double distance = LocationsService.getInstance().getDistanceBetweenLocations(loc1, loc2);

		Test.stopTest();

        System.assertEquals(12352.481223068238, distance, 'Inaccurate distance between locations');
	}
}