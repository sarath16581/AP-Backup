/**
 * @description       : Test class for MyNetworkConstants
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2023-01-23 - Dattaraj Deshmukh - created
 * 2023-03-20 - Mahesh Parvathaneni - SF-854 - Updated status 'Closed - Required More information' to 'More information required'.
 **/
@IsTest
private class MyNetworkConstants_Test {
	@IsTest
	static void constantValues() {
		System.assertEquals(MyNetworkConstants.CASE_STATUS_WAITING_ON_OPERATIONS, 'Waiting on operations');
		System.assertEquals(MyNetworkConstants.CASE_STATUS_NETWORK_RESPONDED, 'Network Responded');
		System.assertEquals(MyNetworkConstants.CASE_UPDATE_OPERATIONS_RESPONDED, 'Operations Responded');
		System.assertEquals(MyNetworkConstants.CASE_STATUS_CLOSED, 'Closed');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_NEW_STATUS, 'New');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS, 'In Progress');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_RESPONDED_STATUS, 'Responded');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS, 'Closed');
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_MORE_INFO_REQUIRED, 'More information required');
		System.assertNotEquals(null, MyNetworkConstants.STAR_TRACK_RECORD_TYPES);
		System.assertNotEquals(null, MyNetworkConstants.MY_NETWORK_PORTAL_LIST_VIEWS);
	}

}