/**
 * @description Utility class for Transaction Security policies
 * @author Swati Mogadala
 * @date 2022-09-21
 * @group Util
 * @changelog
 * 2022-09-21 - Swati Mogadala - Created
 */
public class SecurityPolicyUtil {
	public static final String PERMITTEDPLATFORM = 'Windows';
	public static final String ADMIN_PROFILE = 'System Administrator';
    public static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';

	/**
	 * Get transaction policies from custom setting filtered by setupOwnerIds
	 * @param targetIds contains setupOwnerIds
	 * @return  `Map<Id, SecurityPolicy__c>`
	 */
	public static Map<Id, SecurityPolicy__c> getSecurityPolicyOwnerMap(Set<Id> targetIds) {
		CustomsSettingsSelector policySelector = CustomsSettingsSelector.newInstance(
			SecurityPolicy__c.SObjectType,
			new Set<SObjectField>{
				SecurityPolicy__c.Id,
				SecurityPolicy__c.Name,
				SecurityPolicy__c.SetupOwnerid,
				SecurityPolicy__c.Login_BlockNonWindowsPlatform__c
			}
		);
		List<SecurityPolicy__c> policies = policySelector.selectBySetupOwnerid(targetIds);
		Map<Id, SecurityPolicy__c> securityPolicyOwnerMap = new Map<Id, SecurityPolicy__c>();

		for (SecurityPolicy__c obj : policies) {
			securityPolicyOwnerMap.put(obj.SetupOwnerId, obj);
		}
		return securityPolicyOwnerMap;
	}

	/**
	 * Check if userId is System Support User
	 * @param userId
	 * @return  `Boolean`
	 */
	public static Boolean isSystemSupportUser(Id userId) {
		// fetch Id of the System Support user from the Custom Setting
		ConfigSetting__c configSetting = ConfigSetting__c.getInstance();
		String systemSupportUserId = configSetting.AutomatedCaseUser__c;
		return userId.equals(systemSupportUserId);
	}
}
