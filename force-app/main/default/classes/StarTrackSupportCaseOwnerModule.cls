/**
 * Domain Modules should NEVER be called directly. Domain modules should only ever be called from a domain class
 *
 * This has been a port of parts of the StarTrack Case Automation process builder | PBRP 2021.
 * It deals with the following nodes:
 * 1. Case Owner Changed - updates case status to "Awaiting Investigation" and
 * updates related caseMilestones completiondate to current date time
 *
 * @author Madhusudhan
 * @date 2021-06-18
 * @channel Domain
 * @domain StarTrack
 * @changelog
 * 2021-11-09 Naveen Rajanna REQ2656153 - Added null check to avoid null pointer exception
 * 2022-08-25 Mahesh Parvathaneni DDS-11558 - Added logic for STHS tracking form to not to update the case status
 * 2023-06-14 - Nathan Franklin - uplift to domainless architecture
 */

public inherited sharing class StarTrackSupportCaseOwnerModule extends ApplicationModule {
	
	/**
	 * @deprecated
	 */
	public static StarTrackSupportCaseOwnerModule newInstance() {
		return (StarTrackSupportCaseOwnerModule) Application.Utilities.newInstance(
			StarTrackSupportCaseOwnerModule.class
		);
	}

	// Setup which triggers this module should respond to
	public StarTrackSupportCaseOwnerModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	// Grab the investigatorResponse from custom settings.
	public static Id investigatorResponse {
		get {
			if (investigatorResponse == null) {
				investigatorResponse = StarTrack_Settings__c.getInstance().StarTrack_Investigator_Response__c;
			}
			return investigatorResponse;
		}
		private set;
	}

	// Get Applicable record types for cases
	public static Map<Id, RecordType> caseRecordTypes {
		get {
			if (caseRecordTypes == null) {
				caseRecordTypes = new RecordTypesSelector()
					.selectByDeveloperName(
						'Case',
						new Set<String>{
							'StarTrack_Credit_Dispute_Claim',
							'StarTrack_General_Enquiry',
							'StarTrack_PUD_Enquiry',
							'StarTrack_Pickup_Booking_Enquiry',
							'StarTrack_Sales_Enquiry',
							'StarTrack_Transit_Warranty_Claim'
						}
					);
			}
			return caseRecordTypes;
		}
		private set;
	}

	/**
	 * Called when Case is getting updated, updates case status and caseMilestones
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Set<String> excludedStatuses = new Set<String>{ 'Awaiting Investigation', 'Awaiting Approval' };

			System.debug('StarTrackSupportCaseOwnerModule:onBeforeUpdate');
			// get a list records that were changed for easy access
			// changed records will be based on monitored fields for this module
			Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{
					Case.RecordTypeId,
					Case.OwnerId,
					Case.Approval_Status__c,
					Case.LDC_System_Check__c
				}
			);

			Map<Id, Case> casesToProcess = new Map<Id, Case>();

			// Loop through our records to figure out what actions need to be taken
			for (Case c : (List<Case>) records) {
				Set<SObjectField> changedFields = changedRecords.get(c.Id);
				System.debug('changedFields :' + changedFields);
				if (changedFields != null && !changedFields.isEmpty()) { //REQ2656153 - Added null check to avoid null pointer exception
					// StarTrack Case Automation: Case Owner Changed (Decision node)
					/**
					 * StartTrack recordtypes and Case owner changed and No access to BSP and
					 * status doesn't contain 'Awaiting Investigation' & 'Awaiting Approval' and
					 * Call_Purpose__c not equal to 'Card Left' and status not equals 'Waiting on operations' and
					 * Approval_Status__c not changed and not System support user
					 * 
					 * Updates case's status to Awaiting Investigation and CaseMileStones Completion Date to NOW().
					 * 
					 * When Case is transfered from call center to investigator generals team
					 */
					// Get old case
					Case oldCase = existingRecords != null ? (Case) existingRecords.get(c.Id) : null;
					//DDS-11558 Added condition to not to execute the logic if case created by AP Integration User from StarTrack Web form
					Boolean isCaseCreatedFromSTHSForm = c.Origin == STHSConstants.CASE_ORIGIN_WEB && c.Status == STHSConstants.CASE_STATUS_NEW && 
						oldCase.OwnerId == AP_INTEGRATION_USER_ID;
					if (caseRecordTypes.keySet().contains(c.RecordTypeId) && changedFields.contains(Case.OwnerId) && !BspConstants.CURRENT_USER_CAN_ACCESS_BSP && !excludedStatuses.contains(c.Status) &&
						//Removing LDC check as it is no longer used by business
						//&& !(changedFields.contains(Case.LDC_System_Check__c) && c.LDC_System_Check__c)
						!('Card Left'.equalsIgnoreCase(c.Call_Purpose__c) && 'Waiting on operations'.equalsIgnoreCase(c.Status)) && !changedFields.contains(Case.Approval_Status__c) && !IS_SYSTEM_SUPPORT_USER && !isCaseCreatedFromSTHSForm) {
						c.Status = 'Awaiting Investigation';
						//Add cases to update milestones
						casesToProcess.put(c.Id, c);
					}
				}
			}

			// Update CaseMilestones
			if (!casesToProcess.isEmpty()) {
				List<CaseMilestone> updateCaseMilestones = new List<caseMilestone>();
				// Select related milestones
				Map<Id, CaseMilestone> caseMilestones = CaseMilestonesSelector.newInstance().selectByCase(casesToProcess.keySet());
				for (CaseMilestone milestone : caseMilestones.values()) {
					if (String.valueOf(milestone.MilestoneTypeId) == investigatorResponse) {
						updateCaseMilestones.add(new CaseMilestone(Id = milestone.Id, CompletionDate = DateTime.now()));
					}
				}
				uow.registerDirty(updateCaseMilestones);
			}
			// Error Logged to Exception object for analysis
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseOwnerModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * System Support user check
	 */
	public static final Boolean IS_SYSTEM_SUPPORT_USER {
		get {
			if (IS_SYSTEM_SUPPORT_USER == null) {
				IS_SYSTEM_SUPPORT_USER = 'System Support'.equalsIgnoreCase(UserInfo.getName());
			}
			return IS_SYSTEM_SUPPORT_USER;
		}
		private set;
	}

	/**
	 * AP Integration user Id
	 */
	public static final Id AP_INTEGRATION_USER_ID {
		get {
			if (AP_INTEGRATION_USER_ID == null) {
				AP_INTEGRATION_USER_ID = UsersSelector.newInstance().selectByName(new Set<String>{'AP Integration'}).values()[0].Id;
			}
			return AP_INTEGRATION_USER_ID;
		}
		private set;
	}
}