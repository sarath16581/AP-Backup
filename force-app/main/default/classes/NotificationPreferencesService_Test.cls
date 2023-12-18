/***
 * @author Disha Kariya
 * @date 2021-05-20
 * @group Tests
 * @description Test Scenarios for Notification Preferences Service
 * @changelog
 */
@IsTest
public with sharing class NotificationPreferencesService_Test {
	
	@IsTest
	public static void testGetNotificationPreferencesAPCNSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock(null, null, true, null));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		NotificationPreferencesService service = NotificationPreferencesService.getInstance();
		Map<String, List<String>> searchString = new Map<String, List<String>>{'apcn' => new List<String>{'1022879741'}};
		NotificationPreferencesService.NotificationPreferencesResponse result = service.getNotificationPreferences(searchString);
		
		Test.stopTest();
		System.assertNotEquals(0, result.preferences.size(), 'Notification preferences not found.');
	}
	
	@IsTest
	public static void testGetNotificationPreferencesEmailPhoneSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock(null, null, true, null));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		NotificationPreferencesService service = NotificationPreferencesService.getInstance();
		Map<String, List<String>> searchString = new Map<String, List<String>>{'apcn' => new List<String>{'1022879741'},
																			   'email' => new List<String>{'test@test.com'},
																			   'phone' => new List<String>{'00000000'}};
		NotificationPreferencesService.NotificationPreferencesResponse result = service.getNotificationPreferences(searchString);
		
		Test.stopTest();
		System.assertNotEquals(0, result.preferences.size(), 'Notification preferences not found.');
	}
	
	@IsTest
	public static void testSetNotificationPreferencesSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock(null, null, true, null));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		NotificationPreferencesService service = NotificationPreferencesService.getInstance();
		String result = service.setNotificationPreferences('1022879741', true);
		
		Test.stopTest();
		System.assertEquals(true, result.contains('Notification'), 'Notification preferences not found.');
	}
}