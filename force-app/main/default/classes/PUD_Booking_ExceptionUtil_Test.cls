/* @author Arjun Singh
 * @group Tests
 * @tag Selector
 * @tag PUD_Booking_Exception
 * @domain PUD
 * @description Test Class covering PUD_Booking_ExceptionUtil
 * @changelog
 * 2021-08-17 - arjun.singh@austpost.com.au - Created
 */
@isTest
public with sharing class PUD_Booking_ExceptionUtil_Test {
    @IsTest
    private static void ensureBookingExceptionErrorWhenJobsPushedToDispatchSystem(){
        // =====================================
		// Data Preparation
		// =====================================
        List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, null, null,  Date.today(), Date.today().addDays(30), null, true);

        List<PUD_Job__c> pudJobList = PUDTestDataFactory.getPUDJobs(7, pudBookingList[0].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);
	    pudJobList[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
	    pudJobList[1].Date__c = Date.today().addDays(1);
        pudJobList[2].Date__c = Date.today().addDays(2);
        pudJobList[3].Date__c = Date.today().addDays(3);
        pudJobList[4].Date__c = Date.today().addDays(4);
        pudJobList[5].Date__c = Date.today().addDays(5);
        pudJobList[6].Date__c = Date.today().addDays(6);

	    List<String> exceptionDaysOfWeek = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
        PUD_Booking_Exception__c bookingException = PUDTestDataFactory.getPUDBookingExceptions(1, new List<Id>{pudBookingList[0].Id}, Date.today(), Date.today().addDays(7), exceptionDaysOfWeek, true)[0];

        // =====================================
		// Stubbing
		// =====================================
        PUDBookingsSelector pudBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
        PUDJobsSelector jobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);
        
	    // set up our responses
        MockUtility.Mocks.startStubbing();
	    MockUtility.Mocks.when(jobSelector.selectByBookingIdStatusAndFromDate((Set<Id>)fflib_Match.anyObject(), (Date) fflib_Match.eqDate(Date.today()), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{pudJobList[0]});
        MockUtility.Mocks.when(pudBookingSelector.selectByParentBookingId((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Booking__c>{pudBookingList[1]});
        MockUtility.Mocks.stopStubbing();

	    // =====================================
	    // Testing
	    // =====================================
	    Test.startTest();
        PUD_Booking_ExceptionUtil.validate(new List<PUD_Booking_Exception__c>{bookingException});
	    System.assertEquals(true, bookingException.hasErrors(), 'Expected validation error if current day/future jobs has been pushed to dispatch system');
		Test.stopTest();
    }

	@IsTest
	private static void ensureBookingExceptionErrorWhenDependentBookingJobsPushedToDispatchSystem(){
		// =====================================
		// Data Preparation
		// =====================================
		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, null, null,  Date.today(), Date.today().addDays(30), null, true);
		// make pudBookingList[1] a dependent booking of pudBookingList[0]
		pudBookingList[1].Parent_Booking__c = pudBookingList[0].Id;

		// only dependent booking has jobs. parent booking has no jobs.
		List<PUD_Job__c> pudJobList = PUDTestDataFactory.getPUDJobs(3, pudBookingList[1].Id, PUDConstants.PUD_JOB_STATUS_NEW, true);
		pudJobList[0].Status__c = PUDConstants.PUD_JOB_STATUS_SCHEDULE;
		pudJobList[0].Date__c = Date.today();
		pudJobList[1].Date__c = Date.today().addDays(1);
		pudJobList[2].Date__c = Date.today().addDays(2);

		List<String> exceptionDaysOfWeek = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
		PUD_Booking_Exception__c bookingException = PUDTestDataFactory.getPUDBookingExceptions(1, new List<Id>{pudBookingList[0].Id}, Date.today(), Date.today().addDays(7), exceptionDaysOfWeek, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		PUDBookingsSelector pudBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
		PUDJobsSelector jobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(jobSelector.selectByBookingIdStatusAndFromDate((Set<Id>)fflib_Match.anyObject(), (Date) fflib_Match.eqDate(Date.today()), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>{pudJobList[0]});
		MockUtility.Mocks.when(pudBookingSelector.selectByParentBookingId((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<PUD_Booking__c>{pudBookingList[1]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		PUD_Booking_ExceptionUtil.validate(new List<PUD_Booking_Exception__c>{bookingException});
		System.assertEquals(true, bookingException.hasErrors(), 'Expected validation error if dependent booking jobs have been pushed to dispatch system');
		Test.stopTest();
	}

	@IsTest
    private static void ensureBookingExceptionSuccessfulWhenCurrentDayJobNotSentToDispatchSystem(){
        // =====================================
		// Data Preparation
		// =====================================
		List<PUD_Booking__c> pudBookingList = PUDTestDataFactory.getPUDPermanentPickupDeliveryBookings(2, null, null,  Date.today(), Date.today().addDays(30), null, true);

		List<String> exceptionDaysOfWeek = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
		PUD_Booking_Exception__c bookingException = PUDTestDataFactory.getPUDBookingExceptions(1, new List<Id>{pudBookingList[0].Id}, Date.today(), Date.today().addDays(7), exceptionDaysOfWeek, true)[0];

        // =====================================
		// Stubbing
		// =====================================
        PUDBookingsSelector pudBookingSelector = (PUDBookingsSelector)MockUtility.mockSelector(PUDBookingsSelector.class);
        PUDJobsSelector jobSelector = (PUDJobsSelector)MockUtility.mockSelector(PUDJobsSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(jobSelector.selectByBookingIdStatusAndFromDate((Set<Id>)fflib_Match.anyObject(), (Date) fflib_Match.anyDate(), (Set<String>)fflib_Match.anyObject())).thenReturn(new List<PUD_Job__c>());
        List<PUD_Booking__c> childBookingList = new List<PUD_Booking__c>{pudBookingList[1]};
        MockUtility.Mocks.when(pudBookingSelector.selectByParentBookingId((Set<Id>)fflib_Match.anyObject())).thenReturn(childBookingList);
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        PUD_Booking_ExceptionUtil.validate(new List<PUD_Booking_Exception__c>{bookingException});
	    System.assertEquals(false, bookingException.hasErrors(), 'Expected no errors if current day/future jobs are still not pushed to dispatch system');
        Test.stopTest();    
    }
}