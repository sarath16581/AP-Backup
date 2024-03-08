/**
 * @description Enhanced Apex Transaction Security for LoginEvent and ReportEvent transactions.
 * @author Naveen Rajanna
 * @date 2024-02-20
 * @changelog
 * 2024-02-20 - Naveen Rajanna - created - REQ3445775.
 */

global class TransactionSecurityPolicyManager implements TxnSecurity.EventCondition {

	/**
	 * Evaluates whether the given event satisfies certain conditions.
	 * If conditions are met, the action defined in the Transaction Security Policy is triggered.
	 * @param event
	 * @return `Boolean`
	 */
	public Boolean evaluate(SObject event) {
		try {
			switch on event {
				when LoginEvent loginEvent {
					return evaluateLoginEvent(loginEvent);
				}
				when ReportEvent reportEvent {
					return evaluateReportEvent(reportEvent);
				}
				when else {
					return false;
				}
			}
		} catch (Exception e) {
			System.debug('Exception has occurred ' + e);
			return false;
		}
	}

	/**
	 * Method to evaluate login event attributes
	 * return false straight away if one of the following
	 * a. if logged in user is 'System Support'
	 * b. if logged in user profile is 'System Administrator'
	 * else based on TransactionSecurityPolicySetting__c.LoginEventWindowsPlatformValidation__c validate if Windows Platform
	 * @param loginEvent
	 * @return `Boolean`
	 */
	private Boolean evaluateLoginEvent(LoginEvent loginEvent) {
		if (shouldBypassLoginEvent(loginEvent)) {
			return false;
		}
		
		return TransactionSecurityPolicySetting__c.getInstance(loginEvent.UserId).LoginEventWindowsPlatformValidation__c 
			&& !isLoginEventFromWindowsPlatform(loginEvent);
	}

	private Boolean shouldBypassLoginEvent(LoginEvent loginEvent) {
		return TransactionSecurityPolicyUtil.isSystemSupportUser(loginEvent.UserId) || 
			TransactionSecurityPolicyUtil.isSystemAdministrator(loginEvent.UserId);
	}

	private Boolean isLoginEventFromWindowsPlatform(LoginEvent loginEvent) {
		return loginEvent.Platform.toUpperCase().contains(TransactionSecurityPolicyUtil.WINDOWS_PLATFORM);
	}

	/**
	 * Method to evaluate report event attributes
	 * return false straight away if one of the following
	 * a. if report event rows processed is less than configured value
	 * b. if report event operation is not configured value
	 * else based on TransactionSecurityPolicySetting__c.ReportEventSensitiveFieldValidation__c validate if sensitive fields exists
	 * @param reportEvent
	 * @return `Boolean`
	 */
	private Boolean evaluateReportEvent(ReportEvent reportEvent) {
		if (shouldBypassReportEvent(reportEvent)) {
			return false;
		}

		return TransactionSecurityPolicySetting__c.getInstance(reportEvent.UserId).ReportEventSensitiveFieldValidation__c 
			&& validateSensitiveFields(reportEvent);
	}

	private Boolean shouldBypassReportEvent(ReportEvent reportEvent) {
		return reportEvent.RowsProcessed < TransactionSecurityPolicyUtil.CONFIG_ROWS_PROCESSED ||
			!TransactionSecurityPolicyUtil.CONFIG_OPERATION.contains(reportEvent.Operation);
	}

	private Boolean validateSensitiveFields(ReportEvent reportEvent) {
		// reportEvent.QueriedEntities doesn't always contain all the objects, Parse fields by object from column headers
		Map<String, Set<String>> reportFieldsByObjectMap = TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(reportEvent.ColumnHeaders);
		
		// Extract sensitive objects found in the report
		Set<String> sensitiveObjects = new Set<String>(TransactionSecurityPolicyUtil.CONFIG_SENSITIVE_FIELDS_OBJECT);
		Set<String> sensitiveObjectsFound = new Set<String>(reportFieldsByObjectMap.keySet());
		sensitiveObjectsFound.retainAll(sensitiveObjects);
		
		// Check if any sensitive objects are found
		if (sensitiveObjectsFound.isEmpty()) {
			return false;
		}

		// Retrieve sensitive fields for the sensitive objects found
		Set<String> sensitiveFields = TransactionSecurityPolicyUtil.getSensitiveFieldsByObjects(sensitiveObjectsFound);
		
		// Get all report fields
		Set<String> reportFields = new Set<String>();
		for (Set<String> values : reportFieldsByObjectMap.values()) {
			reportFields.addAll(values);
		}
		Set<String> sensitiveFieldsFound = new Set<String>(reportFields);
		sensitiveFieldsFound.retainAll(sensitiveFields);

		return !sensitiveFieldsFound.isEmpty();
	}
}