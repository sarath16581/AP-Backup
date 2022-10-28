/**
 * @description Apex class for Transaction Security Policy for LoginEvent Transaction Event type
 * @author Swati Mogadala
 * @date 2022-09-21
 * @group Test
 * @changelog
 * 2022-09-21 - Swati Mogadala - Created
 */
global class LimitLoginSecurityPolicy implements TxnSecurity.EventCondition {
	/**
	 * Evaluates an event against a transaction security policy created in Real-Time Event Monitoring
	 * If the event triggers the policy, the method returns true
	 * @param event contains Transaction Event type
	 * @return  `Boolean`
	 */
	public Boolean evaluate(SObject event) {
		try {
			switch on event {
				when LoginEvent loginEvent {
					return handleLoginEvent(loginEvent); // invokes for every loginevent
				}
				when null {
					return false;
				}
				when else {
					return false; // For any other platform event returns false
				}
			}
		} catch (Exception e) {
			
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(),'Limit Login event policy','LimitLoginSecurityPolicy','evaluate',null,LoggingLevel.ERROR);
			return false;
		}
	}

	/**
	 * Method to evaluate login event atributes against any exisiting policies
	 * Bypass 'System Support' user and all users with 'System Admin' profile
	 * @param loginEvent
	 * @return  `Boolean`
	 */
	private Boolean handleLoginEvent(LoginEvent loginEvent) {
		if (SecurityPolicyUtil.isSystemSupportUser(loginEvent.UserId)) {
			// Always bypass for System Support user
			return false;
		}

		User targetUser = UsersSelector.newInstance()
			.selectById(new Set<Id>{ loginEvent.UserId }, new Set<Object>{ UsersSelector.Options.WITH_PROFILE })
			.values()[0];
		
		if (targetUser.Profile.Name.equals(SecurityPolicyUtil.ADMIN_PROFILE)) {
			// Bypass all System Admin users for all login events
			return false;
		}

		// Fetch a map of policies from the custom setting based on user, profile, and organisation settings for the current logging user
		// Would return a maximum of 3 rows
		Set<Id> targetIds = new Set<Id>{ loginEvent.UserId, targetUser.ProfileId, UserInfo.getOrganizationId() };
		System.debug('NRLOG '+targetIds);
		Map<Id, SecurityPolicy__c> setUpOwnerMap = SecurityPolicyUtil.getSecurityPolicyOwnerMap(targetIds);
		Id setupOwnerId;
		System.debug('NRLOG '+setUpOwnerMap);
		if (setupOwnerMap.containsKey(loginEvent.UserId)) {
			setupOwnerId = loginEvent.UserId; // User setting overrides other settings
		} else if (setupOwnerMap.containsKey(targetUser.ProfileId)) {
			setupOwnerId = targetUser.ProfileId; // Profile setting overrides org setting
		} else {
			setupOwnerId = UserInfo.getOrganizationId(); // Default setting
		}
		System.debug('NRLOG '+setupOwnerId);
		return evaluateLoginPolicies(setupOwnerMap.get(setupOwnerId), loginEvent); // Evaluates login polices as per existing custom setting
	}

	/**
	 * This method would evaluate the loginevent for different policies
	 * If more policies, add new methods for each policy, and returnthe Logical OR outcome of each policy
	 * @param policySetting contains SecurityPolicy__c from Custom Settings
	 * @param loginEvent contains login transaction event
	 * @return  `Boolean`
	 */
	private Boolean evaluateLoginPolicies(SecurityPolicy__c policySetting, LoginEvent event) {
		if(policySetting == null) { return false; } // if policy doesn't exist it should allow login
		return platformCheck(policySetting, event);
	}

	/**
	 * Platform check policy - checks if non Windows platform and blocks login if enforced (Login_BlockNonWindowsPlatform__c is checked in policy settings)
	 * @param policySetting contains SecurityPolicy__c from Custom Settings
	 * @param loginEvent contains login transaction event
	 * @return  `Boolean`
	 */
	private Boolean platformCheck(SecurityPolicy__c policySetting, LoginEvent loginEvent) {
		System.debug('NRLOG '+policySetting);
		System.debug('NRLOG '+!(loginEvent.Platform.containsIgnoreCase(SecurityPolicyUtil.PERMITTEDPLATFORM)));

		if (policySetting.Login_BlockNonWindowsPlatform__c && !(loginEvent.Platform.containsIgnoreCase(SecurityPolicyUtil.PERMITTEDPLATFORM))
		) {
			return true; // Block login attempts from Non-Windows platform
		} else {
			return false; // Do not block login attempt
		}
	}
}