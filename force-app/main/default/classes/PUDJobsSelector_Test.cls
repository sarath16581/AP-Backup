/* @author Arjun Singh
 * @group Tests
 * @tag Selector
 * @tag Accounts
 * @domain Core
 * @description Test Class covering PUDJobsSelector
 * @changelog
 * 2021-07-28 - arjun.singh@austpost.com.au - Created
 * 2022-08-24-  Dattaraj Deshmukh - Added 'Pickup_Booking_Settings__c' custom setting 
 *              and updated params in 'selectJobsByDateAndStatusQueryLocator' method to pass date range.
 */
 @IsTest
public with sharing class PUDJobsSelector_Test {
    
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
	PUDJobsSelector selector = PUDJobsSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PUD_Job__c\\b').matcher(soql).find(), 'Resulting query does not select from PUD_Job__c');

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

        PUDJobsSelector selector = PUDJobsSelector.newInstance(0, new Set<SObjectField>{PUD_Job__c.Status__c});
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(false, Pattern.compile('(?ism)\\Send_to_Dispatch_System__c\\b.*?\\bfrom PUD_Job__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\Status__c\\b.*?\\bfrom PUD_Job__c\\b').matcher(soql).find(), 'Resulting query does not select Case__c field: ' + soql);

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
		objectWithFieldsMap.put(PUD_Job__c.getSObjectType() , new Set<SObjectField>{PUD_Job__c.Status__c});

        PUDJobsSelector selector = PUDJobsSelector.newInstance(0, objectWithFieldsMap);
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
        String soql = qb.toSoqlString();
        // field overrides not supported with Owner as it could be a user or a group.
        System.assertEquals(false, Pattern.compile('(?ism)\\Send_to_Dispatch_System__c\\b.*?\\bfrom PUD_Job__c\\b').matcher(soql).find(), 'Resulting selects Status__c but it shouldn\'t: ' + soql);
        System.assertEquals(true, Pattern.compile('(?ism)\\Status__c\\b.*?\\bfrom PUD_Job__c\\b').matcher(soql).find(), 'Resulting query does not select Case__c field: ' + soql);

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

		//PUD_Route__c pudRoute = ApplicationTestDataFactory.getPUDRoutes(1, network.Id, false)[0];
        //insert pudRoute;

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

		// =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================

		Test.startTest();
		PUDJobsSelector selector = PUDJobsSelector.newInstance(0);
		Map<Id, PUD_Job__c> results = new Map<Id, PUD_Job__c>(selector.selectById(new Set<Id>{pudJobs[0].Id, pudJobs[1].Id}));
		System.assertEquals(2, results.size(), 'Expected result size of 2');
		System.assertEquals(true, results.containsKey(pudJobs[0].Id), 'Expected Job record not returned in results');
		System.assertEquals(true, results.containsKey(pudJobs[1].Id), 'Expected Job record not returned in results');

		Database.QueryLocator jobsQueryLocator = selector.selectJobsByDateAndStatusQueryLocator(PUDUtility.JOB_DISPATCH_FROM_DATE, PUDUtility.JOB_DISPATCH_TO_DATE, PUDConstants.PUD_JOB_STATUS_NEW);
		System.assertNotEquals(null, jobsQueryLocator, 'Expected a valid query locator, but got null');

		results = new Map<Id, PUD_Job__c>(selector.selectByBookingIdStatusAndFromDate(new Set<Id>{pudBooking.Id}, Date.today(), new Set<String>{PUDConstants.PUD_JOB_STATUS_SCHEDULE}));
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();	
	}
}