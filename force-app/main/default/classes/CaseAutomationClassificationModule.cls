/***
 * @description This class is used to classify cases based on fields on the case, such as Types, etc. 
 * @changelog
 * 2024-08-20	George Nguyen	Created and added classifyUnifiedCases(...)
 * 2024-09-02	George Nguyen	Checked for on insert if the record type matches the type field. Included default values for when Type changes from Geneal Enquiry to Investigation
 * 2024-09-03	George Nguyen	Included default values on Insert for type and subtype
 * 2024-09-09 - Ranjeewa Silva - Updated to send email notification to customer on converting general enquiry unified case to investigation type.
 * 2024-09-11 - Vasu Gorakati   CSLU-1413 Service Cloud Voice Work Summaries
 */
public inherited sharing class CaseAutomationClassificationModule extends ApplicationModule {

	// email alerts to use for customer notifications on converting general enquiry unified cases to investigation type.
	@TestVisible private static final String EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_AP = 'UnifiedGeneralEnquiryToInvestigationAP';
	@TestVisible private static final String EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_ST = 'UnifiedGeneralEnquiryToInvestigationST';

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
			classifyUnifiedCases(records, null, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.UNIFIED_APP, CaseAutomationClassificationModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
		try {
			classifyUnifiedCases(records, existingRecords, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.UNIFIED_APP, CaseAutomationClassificationModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
		This method checks that the case's record type is of Unified type and when the Type changed from General Enquiry to Investigation, it will change the Record Type to UnifiedInvestigation
	*/
	void classifyUnifiedCases(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		List<Id> unifiedRecordTypeIds = unifiedRecordTypeDeveloperNameVsIds.values();
		// currently this is not using ApplicationRecursion by design. it has been established that Case.Type will not be
		// updated recursively within the same transaction and ApplicationEmailService already handles recursion scenarios.
		// use of ApplicationRecursion for current use cases add unnecessary overheads with no foreseeable benefits.
		for(Case aCase: (List<Case>)records) {
			if(unifiedRecordTypeIds.contains(aCase.RecordTypeId) == true) {

				if(existingRecords != null) { // on update

					// This addresses the limitation of mapping work summaries directly to the Subject field due to TextArea constraints.
					// As a workaround, the Last Interaction Summary maps the Einstein Work Summary,
					// and the following code copies the value from Last Interaction Summary to the Subject field.


					if (acase.LastInteractionSummary__c != null &&
						acase.LastInteractionSummary__c != ((Case)existingRecords.get(aCase.Id)).LastInteractionSummary__c
					) {
						acase.Subject = acase.LastInteractionSummary__c;
					}

					// if Type has changed from General Enquiry to Investigation
					if(aCase.Type == SSSWConstants.CASE_TYPE_INVESTIGATION
						&& ((Case)existingRecords.get(aCase.Id)).Type == SSSWConstants.CASE_TYPE_GENERAL_ENQUIRY
					) {
						aCase.RecordTypeId = unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME);
						aCase.Status = SSSWConstants.CASE_STATUS_NEW;
						aCase.Type_and_Product__c = SSSWConstants.CASE_TYPE_AND_PRODUCT_UNIFIED_MODEL;
						aCase.EnquirySubType__c = SSSWConstants.CASE_ENQUIRY_SUBTYPE_LATE_ITEM;

						if (String.isNotBlank(aCase.ContactEmail) && aCase.ProductSubCategory__c != null) {
							// queue email notification to notify customer on unified investigation case that has
							// been converted from unified general enquiry case. note that the email framework handles
							// recursion scenarios (if any).
							String emailAlertName = aCase.ProductSubCategory__c.containsIgnoreCase('StarTrack')
									? EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_ST
									: EMAIL_ALERT_UNIFIED_GENERAL_ENQUIRY_TO_INVESTIGATION_AP;
							uow.queueEmailNotification(aCase.Id, Case.SObjectType, emailAlertName);
						}
					}
				} else { // on insert

					// If Type is set to Investigation but Record Type does not match, set default values
					if(aCase.Type == SSSWConstants.CASE_TYPE_INVESTIGATION
						&& aCase.RecordTypeId != unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME)
					) {
						aCase.RecordTypeId = unifiedRecordTypeDeveloperNameVsIds.get(SSSWConstants.UNIFIED_INVESTIGATION_DEVELOPER_NAME);
						aCase.Type_and_Product__c = SSSWConstants.CASE_TYPE_AND_PRODUCT_UNIFIED_MODEL;
						aCase.EnquirySubType__c = SSSWConstants.CASE_ENQUIRY_SUBTYPE_LATE_ITEM;
					}
				}
			}
		}
	}
}