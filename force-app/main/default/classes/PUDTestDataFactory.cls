/**
* @description Contains all the test data methods for PUD test classes
* @author Ranjeewa Silva
* @date 2021-08-31
* @group Tests
* @tags mocking, apex mocks, tests, data factory, test data
* @changelog
* 2021-08-31 - Ranjeewa Silva - Created
* 2022-03-23 - Ranjeewa Silva - Added helper methods to return Adhoc bookings
* 2022-07-25 - Dattaraj Deshmukh - Added helper method to return Job Containers
*/
@IsTest
public class PUDTestDataFactory {

	public static List<PUD_Route__c> getPUDRoutes(Integer count, Id networkId, Boolean generateIds) {
		return (List<PUD_Route__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Route__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Route__c.Name => 'TestRoute%count%',
				PUD_Route__c.Depot__c => networkId
		}, count), generateIds);
	}

	public static List<PUD_Booking_Location__c> getPUDCustomerBookingLocations(Integer count, Id customerId, Boolean generateIds) {
		return (List<PUD_Booking_Location__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Booking_Location__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Booking_Location__c.Name => 'TestCustomerBookingLocation%count%',
				PUD_Booking_Location__c.Customer__c => customerId,
				PUD_Booking_Location__c.RecordTypeId => customerBookingLocationRecordType,
				PUD_Booking_Location__c.Street__c => '1 Main St',
				PUD_Booking_Location__c.City__c => 'Melbourne',
				PUD_Booking_Location__c.State__c => 'VIC',
				PUD_Booking_Location__c.Post_Code__c => '3121'
		}, count), generateIds);
	}

	public static List<PUD_Booking_Location__c> getPUDNetworkBookingLocations(Integer count, Id networkId, Boolean generateIds) {
		return (List<PUD_Booking_Location__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Booking_Location__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Booking_Location__c.Name => 'TestNetworkBookingLocation%count%',
				PUD_Booking_Location__c.Network__c => networkId,
				PUD_Booking_Location__c.RecordTypeId => networkBookingLocationRecordType,
				PUD_Booking_Location__c.Street__c => '1 Main St',
				PUD_Booking_Location__c.City__c => 'Melbourne',
				PUD_Booking_Location__c.State__c => 'VIC',
				PUD_Booking_Location__c.Post_Code__c => '3121'
		}, count), generateIds);
	}

	public static List<PUD_Booking__c> getPUDAdhocPickupDeliveryBookings(Integer count, Id bookingLocationId, Id depotId, Date effectiveDate, Date expiryDate, List<String> daysOfWeek, Boolean generateIds) {
		return getPUDBookings(count, adhocPickupDeliveryBookingRecordType, bookingLocationId, depotId, effectiveDate, expiryDate, daysOfWeek, generateIds);
	}

	public static List<PUD_Booking__c> getPUDPermanentPickupDeliveryBookings(Integer count, Id bookingLocationId, Id depotId, Date effectiveDate, Date expiryDate, List<String> daysOfWeek, Boolean generateIds) {
		return getPUDBookings(count, permanentPickupDeliveryBookingRecordType, bookingLocationId, depotId, effectiveDate, expiryDate, daysOfWeek, generateIds);
	}

	private static List<PUD_Booking__c> getPUDBookings(Integer count, Id recordTypeId, Id bookingLocationId, Id depotId, Date effectiveDate, Date expiryDate, List<String> daysOfWeek, Boolean generateIds) {
		return (List<PUD_Booking__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Booking__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Booking__c.Booking_Location__c => bookingLocationId,
				PUD_Booking__c.Depot__c => depotId,
				PUD_Booking__c.RecordTypeId => recordTypeId,
				PUD_Booking__c.Effective_Date__c => effectiveDate,
				PUD_Booking__c.Expiry_Date__C => expiryDate,
				PUD_Booking__c.Monday__c => (daysOfWeek != null && daysOfWeek.contains('Monday')),
				PUD_Booking__c.Tuesday__c => (daysOfWeek != null && daysOfWeek.contains('Tuesday')),
				PUD_Booking__c.Wednesday__c => (daysOfWeek != null && daysOfWeek.contains('Wednesday')),
				PUD_Booking__c.Thursday__c => (daysOfWeek != null && daysOfWeek.contains('Thursday')),
				PUD_Booking__c.Friday__c => (daysOfWeek != null && daysOfWeek.contains('Friday')),
				PUD_Booking__c.Saturday__c => (daysOfWeek != null && daysOfWeek.contains('Saturday')),
				PUD_Booking__c.Sunday__c => (daysOfWeek != null && daysOfWeek.contains('Sunday'))
		}, count), generateIds);
	}

	public static List<PUD_Job__c> getPUDJobs(Integer count, Id bookingId, String status, Boolean generateIds) {
		return (List<PUD_Job__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Job__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Job__c.Booking__c => bookingId,
				PUD_Job__c.Date__c => Date.today(),
				PUD_Job__c.Status__c => status
		}, count), generateIds);
	}

	public static List<PUD_Booking_Exception__c> getPUDBookingExceptions(Integer count, List<Id> bookingIds, Date startDate, Date endDate, List<String> daysOfWeek, Boolean generateIds) {
		return (List<PUD_Booking_Exception__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Booking_Exception__c.SObjectType, new Map<SObjectField, Object> {
				PUD_Booking_Exception__c.Booking__c => bookingIds,
				PUD_Booking_Exception__c.Start_Date__c => startDate,
				PUD_Booking_Exception__c.End_Date__c => endDate,
				PUD_Booking_Exception__c.Monday__c => (daysOfWeek != null && daysOfWeek.contains('Monday')),
				PUD_Booking_Exception__c.Tuesday__c => (daysOfWeek != null && daysOfWeek.contains('Tuesday')),
				PUD_Booking_Exception__c.Wednesday__c => (daysOfWeek != null && daysOfWeek.contains('Wednesday')),
				PUD_Booking_Exception__c.Thursday__c => (daysOfWeek != null && daysOfWeek.contains('Thursday')),
				PUD_Booking_Exception__c.Friday__c => (daysOfWeek != null && daysOfWeek.contains('Friday')),
				PUD_Booking_Exception__c.Saturday__c => (daysOfWeek != null && daysOfWeek.contains('Saturday')),
				PUD_Booking_Exception__c.Sunday__c => (daysOfWeek != null && daysOfWeek.contains('Sunday'))
		}, count), generateIds);
	}

	public static List<PUD_Container__c> getPUDJobContainers(Integer count, Id bookingId, Id jobId, String type, String condition, Boolean generateIds) {
		return (List<PUD_Container__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Container__c.SObjectType, new Map<SObjectField, Object> {
			PUD_Container__c.Booking__c => bookingId,
			PUD_Container__c.Job__c => jobId,
			PUD_Container__c.Type__c => type,
			PUD_Container__c.Condition__c => condition,
			PUD_Container__c.RecordTypeId => jobContainerRecordType
		}, count), generateIds);
	}

	public static List<PUD_Container__c> getPUDBookingContainers(Integer count, Id bookingId, String type, String condition, Boolean generateIds) {
		return (List<PUD_Container__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PUD_Container__c.SObjectType, new Map<SObjectField, Object> {
			PUD_Container__c.Booking__c => bookingId,
			PUD_Container__c.Type__c => type,
			PUD_Container__c.Condition__c => condition,
			PUD_Container__c.RecordTypeId => bookingContainerRecordType
		}, count), generateIds);
	}


	public static Id networkBookingLocationRecordType {
		get {
			if(networkBookingLocationRecordType == null) {
				networkBookingLocationRecordType = Schema.SObjectType.PUD_Booking_Location__c.getRecordTypeInfosByDeveloperName().get('AP_Network').getRecordTypeId();
			}
			return networkBookingLocationRecordType;
		}
		private set;
	}

	public static Id customerBookingLocationRecordType {
		get {
			if(customerBookingLocationRecordType == null) {
				customerBookingLocationRecordType = Schema.SObjectType.PUD_Booking_Location__c.getRecordTypeInfosByDeveloperName().get('AP_Customer').getRecordTypeId();
			}
			return customerBookingLocationRecordType;
		}
		private set;
	}

	public static Id permanentPickupDeliveryBookingRecordType {
		get {
			if(permanentPickupDeliveryBookingRecordType == null) {
				permanentPickupDeliveryBookingRecordType = Schema.SObjectType.PUD_Booking__c.getRecordTypeInfosByDeveloperName().get('AP_Permanent_Pickup').getRecordTypeId();
			}
			return permanentPickupDeliveryBookingRecordType;
		}
		private set;
	}

	public static Id adhocPickupDeliveryBookingRecordType {
		get {
			if(adhocPickupDeliveryBookingRecordType == null) {
				adhocPickupDeliveryBookingRecordType = Schema.SObjectType.PUD_Booking__c.getRecordTypeInfosByDeveloperName().get('AP_Adhoc_Pickup').getRecordTypeId();
			}
			return adhocPickupDeliveryBookingRecordType;
		}
		private set;
	}

	public static Id businessHubNetworkRecordType {
		get {
			if(businessHubNetworkRecordType == null) {
				businessHubNetworkRecordType = Schema.SObjectType.Network__c.getRecordTypeInfosByDeveloperName().get('Business_Hub_3').getRecordTypeId();
			}
			return businessHubNetworkRecordType;
		}
		private set;
	}

	public static Id jobContainerRecordType {
		get {
			if(jobContainerRecordType == null) {
				jobContainerRecordType = Schema.SObjectType.PUD_Container__c.getRecordTypeInfosByDeveloperName().get('Job_Container').getRecordTypeId();
			}
			return jobContainerRecordType;
		}
		private set;
	}

	public static Id bookingContainerRecordType {
		get {
			if(bookingContainerRecordType == null) {
				bookingContainerRecordType = Schema.SObjectType.PUD_Container__c.getRecordTypeInfosByDeveloperName().get('Booking_Container').getRecordTypeId();
			}
			return bookingContainerRecordType;
		}
		private set;
	}
}