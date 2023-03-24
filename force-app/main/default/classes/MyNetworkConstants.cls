/**
* @author Dattaraj Deshmukh
* @date 18/11/2022
* @domain MyNetwork
* @description Class to define constants for myNetwork domain.
* @changelog
* 18/11/2022 - Dattaraj Deshmukh - Created.
* 20/03/2023 - Mahesh Parvathaneni - SF-854 - Updated status 'Closed - Required More information' to 'More information required'.
*/
public inherited sharing class MyNetworkConstants {
   //StarTrack_General_Enquiry, StarTrack_Pickup_Booking_Enquiry, StarTrack_Voice_of_Customer, StarTrack_PUD_Enquiry
	public static final String[] STAR_TRACK_RECORD_TYPES = new String[]{'StarTrack_PUD_Enquiry', 'StarTrack_General_Enquiry', 'StarTrack_Pickup_Booking_Enquiry', 
	'StarTrack_Voice_of_Customer'}; 
	

	public static final Map<String, String> MY_NETWORK_PORTAL_LIST_VIEWS = new Map<String, String> {
		'All_Cases' => 'All Cases',
		'Enterprise_customers' => 'Enterprise customers/high value customers',
		'Facility_reported' => 'Facility reported damages-eParcel and wine damages',
		'Cases_updated' => 'Updated Cases',
		'star_track_cases' => 'StarTrack Cases'
	};

	public static final String CASE_STATUS_WAITING_ON_OPERATIONS='Waiting on operations';
	public static final String CASE_STATUS_NETWORK_RESPONDED='Network Responded';
	public static final String CASE_UPDATE_OPERATIONS_RESPONDED='Operations Responded';
	public static final String CASE_STATUS_CLOSED='Closed';

	public static final String CASE_INVESTIGATION_NEW_STATUS='New';
	public static final String CASE_INVESTIGATION_IN_PROGRESS_STATUS='In Progress';
	public static final String CASE_INVESTIGATION_RESPONDED_STATUS='Responded';
	public static final String CASE_INVESTIGATION_CLOSED_STATUS='Closed';
	public static final String CASE_INVESTIGATION_MORE_INFO_REQUIRED='More information required';
}