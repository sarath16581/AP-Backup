/**
 * @author alexvolkov
 * @date 26/5/21
 * @group Tests
 * @description Test class for AuthzAccessManager
 */

/**
--------------------------------------- History --------------------------------------------------
26.05.2021    alex.volkov@auspost.com.au    Initial creation
**/

@IsTest
private with sharing class AuthzAccessManager_Test
{
	@IsTest
	private static void testGetToken()
	{
		Test.setMock(HttpCalloutMock.class, new GenericHttpCalloutMock(null, null, true, null));
		Test.startTest();
		System.assertNotEquals(null, AuthzAccessManager.getAccessToken(AuthzAccessManager.RunMode.STANDARD).access_token);
		Test.stopTest();
	}
}