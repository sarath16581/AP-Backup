/**
 * @description Test data methods for Security Policy test classes
 * @author Naveen Rajanna
 * @date 2024-02-20
 * @group Tests
 * @changelog
 * 2024-02-20 - Naveen Rajanna - created - REQ3445775.
*/
@IsTest
public class TransactionSecurityPolicyTestDataFactory {
	
	/**
	 * Generate Transaction Security Policy Setting
	 * @param count
	 * @param setupOwnerId
	 * @param loginEventWindowsPlatformValidation
	 * @param reportEventSensitiveFieldValidation
	 * @param generateIds
	 * @return  `List<TransactionSecurityPolicySetting__c>`
	 */
	public static List<TransactionSecurityPolicySetting__c> generateTransactionSecurityPolicySetting(Integer count, Id setupOwnerId, Boolean loginEventWindowsPlatformValidation, Boolean reportEventSensitiveFieldValidation, Boolean generateIds) {
		return (List<TransactionSecurityPolicySetting__c>) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(
				TransactionSecurityPolicySetting__c.SObjectType,
				new Map<SObjectField, Object>{
					TransactionSecurityPolicySetting__c.Name => 'Test Policy %count%',
					TransactionSecurityPolicySetting__c.SetupOwnerId => setupOwnerId,
					TransactionSecurityPolicySetting__c.LoginEventWindowsPlatformValidation__c => loginEventWindowsPlatformValidation,
					TransactionSecurityPolicySetting__c.ReportEventSensitiveFieldValidation__c => reportEventSensitiveFieldValidation
				},
				count
			),
			generateIds
		);
	}

	/**
	 * Get Login event test data
	 * @param userId
	 * @param platform
	 * @param generateIds
	 * @return  `LoginEvent`
	 */
	public static LoginEvent getLoginEvent(Id userId, String platform, Boolean generateIds) {
		LoginEvent loginEvent = (LoginEvent) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(LoginEvent.SObjectType, new Map<SObjectField, Object>{}, 1),
			generateIds
		)[0];
		loginEvent = (LoginEvent) ApplicationTestDataFactory.setUnwritableFields(
			loginEvent,
			new Map<String, Object>{ 'UserId' => userId, 'Platform' => platform }
		);
		return loginEvent;
	}

	/**
	 * Get Report event test data
	 * @param userId
	 * @param queriedEntities
	 * @param reportColumns
	 * @param operation
	 * @param rowsProcessed
	 * @param generateIds
	 * @return  `ReportEvent`
	 */

	public static ReportEvent getReportEvent(Id userId, String queriedEntities, String reportColumns, String operation, Integer rowsProcessed, Boolean generateIds) {
		ReportEvent reportEvent = (ReportEvent) ApplicationTestDataFactory.maybeGenerateIds(
			ApplicationTestDataFactory.populateSObjects(ReportEvent.SObjectType, new Map<SObjectField, Object>{}, 1),
			generateIds
		)[0];
		reportEvent = (ReportEvent) ApplicationTestDataFactory.setUnwritableFields(
			reportEvent,
			new Map<String, Object>{ 'UserId' => userId, 'QueriedEntities' => queriedEntities, 'ColumnHeaders' => reportColumns, 'Operation' => operation, 'RowsProcessed' => rowsProcessed}
		);
		return reportEvent;
	}
}