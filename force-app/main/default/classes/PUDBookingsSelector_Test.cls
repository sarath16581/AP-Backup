/* @author Arjun Singh
 * @group Tests
 * @tag Selector
 * @tag PUD Booking
 * @domain PUD
 * @description Test Class covering PUDBookingsSelector
 * @changelog
 * 2021-08-16 - arjun.singh@austpost.com.au - Created
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
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

        PUDBookingsSelector selector = PUDBookingsSelector.newInstance(0, new Set<SObjectField>{PUD_Booking__c.Status__c});
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();

	    // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(false, Pattern.compile('(?ism)\\Article_Count__c\\b.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Article_Count__c but it shouldn\'t: ' + soql);
        //System.assertEquals(true, Pattern.compile('(?ism)\\Status__c\\b.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Status__c field: ' + soql);

        Test.stopTest();

    }
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverridesMap() {

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
		Map<SObjectType, Set<SObjectField>> objectWithFieldsMap = new Map<SObjectType, Set<SObjectField>>();
		objectWithFieldsMap.put(PUD_Booking__c.getSObjectType() , new Set<SObjectField>{PUD_Booking__c.Status__c});

        PUDBookingsSelector selector = PUDBookingsSelector.newInstance(0, objectWithFieldsMap);
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(false, Pattern.compile('(?ism)\\Article_Count__c\\b.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting selects Article_Count__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\Status__c\\b.*?\\bfrom PUD_Booking__c\\b').matcher(soql).find(), 'Resulting query does not select Status__c field: ' + soql);

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

		PUD_Booking__c pudBooking = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(1, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), new List<String>{'Monday'}, false)[0];
		insert pudBooking;

		Set<Id> pudBookingIds = new Set<Id>{pudBooking.Id};
		// =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================

		Test.startTest();
		PUDBookingsSelector selector = PUDBookingsSelector.newInstance(0);
		List<PUD_Booking__c> results = selector.selectById(pudBookingIds);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();	
	}

    /**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorWithParentIdIntegration() {
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

		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, pudBookingLocation.Id, network.Id, Date.today(), Date.today().addDays(90), new List<String>{'Monday'}, false);
		insert pudBookingList;

        pudBookingList[1].Parent_Booking__c = pudBookingList[0].Id;
        update pudBookingList[1];

		Set<Id> pudBookingIds = new Set<Id>{pudBookingList[0].Id};
		// =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================

		Test.startTest();
		PUDBookingsSelector selector = PUDBookingsSelector.newInstance(0);
		List<PUD_Booking__c> results = selector.selectByParentBookingId(pudBookingIds);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();	
	}
}