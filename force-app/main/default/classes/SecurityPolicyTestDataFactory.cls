/**
 * @description Contains all the test data methods for Security Policy test classes
 * @author Swati Mogadala
 * @date 2022-09-21
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2022-09-21 - Swati Mogadala - Created
 */
@IsTest
public class SecurityPolicyTestDataFactory {
	/**
	 * Get Security Policy test data
	 * @param count
	 * @param ownerId
	 * @param BlockNonWindowsPlatform
	 * @param generateIds
	 * @return  `List<SecurityPolicy__c>`
	 */
	public static List<SecurityPolicy__c> getSecurityPolicies(Integer count, Id ownerId, Boolean blockNonWindowsPlatform, Boolean generateIds) {
		return (List<SecurityPolicy__c>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				SecurityPolicy__c.SObjectType,
				new Map<SObjectField, Object>{
                    SecurityPolicy__c.Name => 'Test Policy %count%',
					SecurityPolicy__c.SetupOwnerid => ownerId,
					SecurityPolicy__c.Login_BlockNonWindowsPlatform__c => blockNonWindowsPlatform
				},
				count
			),
			generateIds
		);
	}

    /**
     * Get Security Policies having enforcedProfileId Profile with all policies enforced, where as byPassUserId and Organisation having all policies NOT enforced/bypassed
     * @param byPassUserId contains the setupOwnerId who needs to be bypassed
     * @return  `List<SecurityPolicy__c>`
     */
	public static List<SecurityPolicy__c> getSampleSecurityPolicies(Id enforcedProfileId, Id byPassUserId) {
        //Generate Security Policy custom settings
        List<SecurityPolicy__c> policyList = SecurityPolicyTestDataFactory.getSecurityPolicies(3, enforcedProfileId, true, true);
        // policyList[0] is enforcedProfileId Profile with enforcement for policies like Windows platform
        policyList[0].Login_BlockNonWindowsPlatform__c = true;
        
        // policyList[1] enforcedProfileId Profile user with NO enforcement for policies like Windows platform
        policyList[1].SetupOwnerid = byPassUserId;
        policyList[1].Login_BlockNonWindowsPlatform__c = false;
        
        // policyList[2] Organisation policy with NO enforcement for policies like Windows platform
        policyList[2].SetupOwnerid = UserInfo.getOrganizationId();
        policyList[2].Login_BlockNonWindowsPlatform__c = false;
  
        return policyList;
     }

	/**
	 * Get Login event test data
	 * @param userId
	 * @param platform
	 * @param generateIds
	 * @return  `LoginEvent`
	 */
	public static LoginEvent getLoginEvent(Id userId, String platform, Boolean generateIds) {
		LoginEvent output = (LoginEvent) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(LoginEvent.SObjectType, new Map<SObjectField, Object>{}, 1),
			generateIds
		)[0];
		output = (LoginEvent) ApplicationTestDataFactory.setUnwritableFields(
			output,
			new Map<String, Object>{ 'Platform' => platform, 'UserId' => userId }
		);
		return output;
	}
	/**
	 * Call this method to get SSSWProfile ID 
	 */
    public static Id ssswProfileId {
		get {
			if(ssswProfileId == null) {
				ssswProfileId = [SELECT Id FROM profile where Name =: SecurityPolicyUtil.SSSW_AGENT_PROFILE LIMIT 1].Id;
			}
			return ssswProfileId;
		}
		private set;
	}
	/**
	 * Call this method to get System Admin Profile Id
	 */
    public static Id adminProfileId {
		get {
			if(adminProfileId == null) {
				adminProfileId = [SELECT Id FROM profile where Name =: SecurityPolicyUtil.ADMIN_PROFILE LIMIT 1].Id;
			}
			return adminProfileId;
		}
		private set;
	}
    /**
	 * Call this method to get 'System Support User' Id
	 */
    public static Id systemSupportUserId {
		get {
			if(systemSupportUserId == null) {
				systemSupportUserId = [SELECT Id FROM User WHERE Alias='ssupp' LIMIT 1].Id;
			}
			return systemSupportUserId;
		}
		private set;
	}
}