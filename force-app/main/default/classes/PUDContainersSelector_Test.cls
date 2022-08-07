/* @author Dattaraj Deshmukh
 * @group Tests
 * @tag Selector
 * @tag PUD Container
 * @domain PUD
 * @description Test Class covering PUDContainersSelector
 * @changelog
 * 2022-07-23 - Dattaraj Deshmukh - Created
 */
@IsTest
private class PUDContainersSelector_Test {
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
	PUDContainersSelector selector = PUDContainersSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query does not select from PUD_Container__c');

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

		PUDContainersSelector selector = PUDContainersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PUDContainersSelector.Options.FILTER_BOOKING_CONTAINERS});
		String soql = qb.toSoqlString();
		//System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		
		// Testing field overrides passing in field overrides for PUD_Container__c and for related PUD_Route__c
		selector = PUDContainersSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
            PUD_Container__c.getSObjectType() => new Set<SObjectField>{PUD_Container__c.Type__c}
				
		});

		qb = selector.newQueryBuilder(new Set<Object>());
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Type__c.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query does not select Type__c field: ' + soql);

		// Testing field overrides passing in field overrides map with record limit
		selector = PUDContainersSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
            PUD_Container__c.getSObjectType() => new Set<SObjectField>{PUD_Container__c.Type__c}
		});
		qb = selector.newQueryBuilder(new Set<Object>());
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Type__c.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query does not select Type__c field: ' + soql);

		// Testing field overrides passing in field overrides for PUD_Container__c with record limit
		selector = PUDContainersSelector.newInstance(0, new Set<SObjectField>{PUD_Container__c.Type__c});
		qb = selector.newQueryBuilder(new Set<Object>());
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Type__c.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query does not select Type__c field: ' + soql);

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

        PUDContainersSelector selector = PUDContainersSelector.newInstance(0, new Set<SObjectField>{PUD_Container__c.Name});
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();

        System.assertEquals(false, Pattern.compile('(?ism)Expected_Quantity__c\\b.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting selects Condition__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Name\\b.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query should select Name field: ' + soql);

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
		objectWithFieldsMap.put(PUD_Container__c.getSObjectType() , new Set<SObjectField>{PUD_Container__c.Name});

        PUDContainersSelector selector = PUDContainersSelector.newInstance(0, objectWithFieldsMap);
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();
		System.assertEquals(false, Pattern.compile('(?ism)Expected_Quantity__c\\b.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting selects Expected_Quantity__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)Name\\b.*?\\bfrom PUD_Container__c\\b').matcher(soql).find(), 'Resulting query should select Name field: ' + soql);

		

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

		List<PUD_Job__c> pudJobs = PUDTestDataFactory.getPUDJobs(3, pudBooking.Id, PUDConstants.PUD_JOB_STATUS_NEW, false);
		// today's job is in 'Schedule' status
		pudJobs[0].Date__c = Date.today();
		pudJobs[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;

		// other jobs are for next 2 days and they both are in 'New' status
		pudJobs[1].Date__c = Date.today().addDays(1);
		pudJobs[2].Date__c = Date.today().addDays(2);
		insert pudJobs;

		PUD_Container__c bookingContainer = PUDTestDataFactory.getPUDBookingContainers(1, pudBooking.Id, 'Pallets', 'Empty', false )[0];
        insert bookingContainer;

        List<PUD_Container__c> jobContainers = PUDTestDataFactory.getPUDJobContainers(3, pudBooking.Id, null, 'Pallets', 'Empty', false );
        jobContainers[0].Job__c = pudJobs[0].Id;
        jobContainers[1].Job__c = pudJobs[1].Id;
        jobContainers[2].Job__c = pudJobs[2].Id;
        
        insert jobContainers;


		// =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================

		Test.startTest();
		PUDContainersSelector selector = PUDContainersSelector.newInstance(0);
		List<PUD_Container__c> results = new List<PUD_Container__c>(selector.selectById(new Set<Id>{bookingContainer.Id}));
		System.assertEquals(1, results.size(), 'Expected result size of 1');

        PUDContainersSelector selector2 = PUDContainersSelector.newInstance();
		List<PUD_Container__c> results1 = selector2.selectByJobIds(new Set<Id>{pudJobs[0].Id, pudJobs[1].Id, pudJobs[2].Id}, new Set<Object>());
        System.assertEquals(3, results1.size(), 'Expected result size of 3');

		List<PUD_Container__c> results2 = new List<PUD_Container__c>(selector.selectBookingContainersByBookingIds(new Set<Id>{pudBooking.Id}, new Set<Object>()));
		System.assertEquals(1, results2.size(), 'Expected result size of 1');

		Test.stopTest();	
	}
}