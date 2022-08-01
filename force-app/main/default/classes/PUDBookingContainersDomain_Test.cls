/***
 * @description Test class for PUDBookingContainersDomain.
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-07-25 - Dattaraj Deshmukh - Created.
 */
@IsTest
private class PUDBookingContainersDomain_Test {
    /**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void testPUDBookingContainersDomain() {
        
        // =====================================
		// Data Preparation
		// =====================================

		
        //booking containers
        List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, null, null, Date.today(), Date.today().addDays(30), null, true);

        //create containers
        //creating Booking Containers
        PUD_Container__c c1 = PUDTestDataFactory.getPUDBookingContainers(1, pudBookingList[0].Id, 'Pallets', 'Empty', true )[0];
        
        //creating job containers
        PUD_Container__c c2 = PUDTestDataFactory.getPUDJobContainers(1, pudBookingList[0].Id, null, 'Pallets', 'Full', true )[0];

        List<PUD_Container__c> newContainers = new List<PUD_Container__c>{c1,c2};

        // =====================================
		// Stubbing
		// =====================================
        // Stubbing: Not required


        // =====================================
		// Testing
		// =====================================
		ApplicationDomain.IConstructable constructableDomain = new PUDBookingContainersDomain.Constructor();
		PUDBookingContainersDomain domain = (PUDBookingContainersDomain) constructableDomain.construct(newContainers);

        //asserting booking containers are filtered
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(c1.Id, domain.records[0].Id, 'Expected record');
    }
}
