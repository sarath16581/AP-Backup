/***
 * @description This class is used to classify cases based on fields on the case, such as Types, etc. 
 * @changelog
 * 2024-08-20	George Nguyen	Created and added classifyUnifiedCases(...)
 * 2024-09-02	George Nguyen	Checked for on insert if the record type matches the type field
 */
public inherited sharing class CaseAutomationClassificationModule extends ApplicationModule {
	 /*
	 * Creates a new instance of the utility to facilitate dependency injection for mocking
	 * @return the new instance
	 * @deprecated
	 */
	public static CaseAutomationClassificationModule newInstance() {
		return (CaseAutomationClassificationModule)Application.Utilities.newInstance(CaseAutomationClassificationModule.class);
	}

	// Get all record types that starts with 'Unified'
	Map<String, Id> unifiedRecordTypeDeveloperNameVsIds {
		get {
			if(unifiedRecordTypeDeveloperNameVsIds == null) {
				unifiedRecordTypeDeveloperNameVsIds = new Map<String, Id>();
				for(RecordType rt: RecordTypesSelector.newInstance().selectByDeveloperNameLike(String.valueOf(Case.getsObjectType()), SSSWConstants.UNIFIED_APP).values()) {
					unifiedRecordTypeDeveloperNameVsIds.put(rt.DeveloperName, rt.Id);
				}
			}
			return unifiedRecordTypeDeveloperNameVsIds;
		}
		set;
	}

	// Constructor
	public CaseAutomationClassificationModule() {
		// Setup which triggers this module should respond to
		getTriggerEvents().enableBeforeUpdate().enableBeforeInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow)  {
		try {
			classifyUnifiedCases(records, null);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.UNIFIED_APP, CaseAutomationClassificationModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
		try {
			classifyUnifiedCases(records, existingRecords);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.UNIFIED_APP, CaseAutomationClassificationModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/*
		This method checks that the case's record type is of Unified type and when the Type changed from General Enquiry to Investigation, it will change the Record Type to UnifiedInvestigation
	*/
	void classifyUnifiedCases(List<SObject> records, Map<Id, SObject> existingRecords) {
		List<Id> unifiedRecordTypeIds = unifiedRecordTypeDeveloperNameVsIds.values();
		for(Case aCase: (List<Case>)records) {
			if(unifiedRecordTypeIds.contains(aCase.RecordTypeId) == true) {

				if(existingRecords != null) { // on update

					// if Type has changed from General Enquiry to Investigation
					if(aCase.Type == SSSWConstants.CASE_TYPE_INVESTIGATION
						&& ((Case)existingRecords.get(aCase.Id)).Type == SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY
					) {
						aCase.RecordTypeId = unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME);
						aCase.Status = SSSWConstants.CASE_STATUS_NEW;

					}

				} else { // on insert

					// If Type is set to Investigation but Record Type does not match
					if(aCase.Type == SSSWConstants.CASE_TYPE_INVESTIGATION
						&& aCase.RecordTypeId != unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME)
					) {
						aCase.RecordTypeId = unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME);
					}
				}
			}
		}
	}
}