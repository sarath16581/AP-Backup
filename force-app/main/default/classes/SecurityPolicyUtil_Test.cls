/**
 * @description Test class for SecurityPolicyUtil
 * @author Swati Mogadala
 * @date 2022-09-21
 * @group Tests
 * @changelog
 * 2022-09-21 - Swati Mogadala - Created
 */
@isTest
public class SecurityPolicyUtil_Test {
	/**
	 * Test: Test method for getSecurityPolicyOwnerMap() 
	 * Validating that method returns a map of security policies from custom settings based on loggin user.
	 */
	@isTest
	private static void testGetSecurityPolicyOwnerMap() {
		//Generate Security policy custom settings
		User loginUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		List<SecurityPolicy__c> policyList = SecurityPolicyTestDataFactory.getSecurityPolicies(1, loginUser.ProfileId, true, true);

		// Stubbing
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector) MockUtility.mockSelector(CustomsSettingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(settingsSelector.selectBySetupOwnerId((Set<Id>) fflib_Match.anyObject())).thenReturn(policyList);
		MockUtility.Mocks.stopStubbing();

		//Testing
		Test.startTest();
			Map<Id, SecurityPolicy__c> resultMap = SecurityPolicyUtil.getSecurityPolicyOwnerMap(new Set<Id>{ loginUser.ProfileId });
		Test.stopTest();

		//Assert or verify
		System.assertequals(1, resultMap.size(), 'Security policy doesnt exist');
		System.assertequals(loginUser.ProfileId, resultMap.values()[0].SetupOwnerid, 'Security policy SetupOwnerid doesnt exist');
		((CustomsSettingsSelector) MockUtility.Mocks.verify(settingsSelector, 1)).selectBySetupOwnerId(new Set<Id>{ loginUser.ProfileId });
	}

	/**
	 * Test: Test method for isSystemSupportUser() to check is system support user exists in the org
	 */
	@isTest
	private static void testIsSystemSupportUser() {
        //insert custom setting for System support User ID
        User systemSupportUser = ApplicationTestDataFactory.getUsers(1, true)[0];
        ConfigSetting__c configSetting = new ConfigSetting__c(AutomatedCaseUser__c = systemSupportUser.Id);
		insert configSetting;
		Test.startTest();
			Boolean result = SecurityPolicyUtil.isSystemSupportUser(systemSupportUser.Id);
		Test.stopTest();
		System.assertEquals(true, result, 'System Support User Id doesnt match');
	}
}