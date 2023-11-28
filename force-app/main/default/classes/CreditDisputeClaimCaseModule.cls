/**************************************************
Description: This module is to include the business logics for credit dispute claim cases
History:
--------------------------------------------------
2023-11-23 - Thang Nguyen - Created
**************************************************/

public inherited sharing class CreditDisputeClaimCaseModule extends ApplicationModule {
	@TestVisible private static final String BUSINESSUNIT_AUSTRALIAPOST = 'Australia Post';
	@TestVisible private static final String BUSINESSUNIT_STARTRACK = 'StarTrack';

	/**
	 * @deprecated
	 */
	public static CreditDisputeClaimCaseModule newInstance() {
		return (CreditDisputeClaimCaseModule) Application.Utilities.newInstance(CreditDisputeClaimCaseModule.class);
	}

	// Setup which triggers this module should respond to
	public CreditDisputeClaimCaseModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	// Grab the Australia_Post_Credit_Disputes_Queue Id
	public static Id apCreditDisputeQueueId {
		get {
			if (apCreditDisputeQueueId == null) {
				apCreditDisputeQueueId = new GroupsSelector().selectByDeveloperName(new Set<String>{
						'Australia_Post_Credit_Disputes_Queue'
				}).values()[0].Id;
			}
			return apCreditDisputeQueueId;
		}
		private set;
	}

	// Grab the StarTrack_Credit_Claims_Queue Id
	public static Id stCreditDisputeQueueId {
		get {
			if (stCreditDisputeQueueId == null) {
				stCreditDisputeQueueId = new GroupsSelector().selectByDeveloperName(new Set<String>{
						'StarTrack_Credit_Claims_Queue'
				}).values()[0].Id;
			}
			return stCreditDisputeQueueId;
		}
		private set;
	}

	/**
	* Called before a case is inserted.
	* Performs below operations
	* 1. Update the Business Unit field based on the owner
	*/
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateBusinessUnit(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, CreditDisputeClaimCaseModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * @Description : Update the Business_Unit__c field if the owner is the Australia_Post_Credit_Disputes_Queue
	 * @param : records list of cases which has been updated.
	 * @param : uow ApplicationUnitOfWork
	 * @return : null
	 */
	private void updateBusinessUnit(List<SObject> records) {
		for (Case c : (List<Case>) records) {
			if (c.OwnerId == apCreditDisputeQueueId && String.isEmpty(c.Business_Unit__c)) {
				c.Business_Unit__c = BUSINESSUNIT_AUSTRALIAPOST;
			}
			if (c.OwnerId == stCreditDisputeQueueId && String.isEmpty(c.Business_Unit__c)) {
				c.Business_Unit__c = BUSINESSUNIT_STARTRACK;
			}
		}
	}

}