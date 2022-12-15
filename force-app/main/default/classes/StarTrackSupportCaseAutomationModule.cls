/**
 * Domain Modules should NEVER be called directly. Domain modules should only ever be called from a domain class
 *
 * This has been a port of parts of the StarTrack Case Automation process builder. It deals with the following nodes:
 * 1. Clear Case Update Time when Case_Update field is updated to null
 * 2. Populate Case Subject - Update case subject if article or Pickup_Booking_Reference__c is not null
 * 3. Reopen Case - Update FCR__c to false when case status is changed
 * 
 * @Test StarTrackSupCaseAutomationModule_Test
 * 
 * @changelog
 * 2022-12-15	Noel Lim - update logic in onBeforeUpdate to fix a NullException bug for cases generated from Startrack Support portal
 */

public inherited sharing class StarTrackSupportCaseAutomationModule extends ApplicationDomain.Module {
	public static StarTrackSupportCaseAutomationModule newInstance() {
		return (StarTrackSupportCaseAutomationModule) Application.Utilities.newInstance(
			StarTrackSupportCaseAutomationModule.class
		);
	}

	// Setup which triggers this module should respond to
	public StarTrackSupportCaseAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	// Get Applicable record types for cases
	public static Map<Id, RecordType> caseRecordTypes {
		get {
			if (caseRecordTypes == null) {
				caseRecordTypes = new RecordTypesSelector()
					.selectByDeveloperName(
						'Case',
						new Set<String>{
							'StarTrack_General_Enquiry',
							'StarTrack_PUD_Enquiry',
							'StarTrack_Pickup_Booking_Enquiry',
							'StarTrack_Sales_Enquiry'
						}
					);
			}
			return caseRecordTypes;
		}
		private set;
	}

	/**
	 * Called when a new Case is being inserted.
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		// StarTrack Case Automation: Populate Case Subject (Decision node)
		try {
			setCaseSubjects((List<Case>) records);

			List<Case> validCases = new List<Case>();
			for(Case c : (List<Case>)records) {
				if(omniQueues.containsKey(c.OwnerId) == true && String.isBlank(c.Priority) == false) {
					validCases.add(c);
				}
			}
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, true);


		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseAutomationModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Called when a new Case is being updated - Raman | PBRP.
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			// get a list records that were changed for easy access
			// changed records will be based on monitored fields for this module
			Map<Id, Set<SObjectField>> changedRecords = getIsChanged(
				records,
				existingRecords,
				new Set<SObjectField>{ Case.RecordTypeId, Case.Case_Update__c, Case.Status, Case.OwnerId, Case.Priority }
			);

			// get reccordTypeId for Delivery Enquiry and Booking Enquiry record types
			Set<String> caseUpdateTimeResetRecordTypeNames = new Set<String>{'StarTrack_PUD_Enquiry', 'StarTrack_Pickup_Booking_Enquiry'};
			Set<Id> caseUpdateTimeResetRecordTypes = new Set<Id>();
			for (RecordType rt : caseRecordTypes.values()) {
				if (caseUpdateTimeResetRecordTypeNames.contains(rt.DeveloperName)) {
					caseUpdateTimeResetRecordTypes.add(rt.Id);
				}
			}
			Set<String> fcrIgnoredCaseStatuses = new Set<String>{ 'Reopened', 'New' };

			List<Case> validCasesInOmniQueues = new List<Case>();

			// loop through our records to figure out what actions need to be taken
			for (Case c : (List<Case>) records) {
				Set<SObjectField> changedFields = changedRecords.get(c.Id);
				if (changedFields != null && !changedFields.isEmpty()) {
					// StarTrack Case Automation: Clear Case Update Time
					if (caseUpdateTimeResetRecordTypes.contains(c.RecordTypeId) && changedFields.contains(Case.Case_Update__c) && String.isEmpty(c.Case_Update__c)) {
						c.Case_Update_Time__c = null; 
					}
					
					// StarTrack Case Automation: Reopen Case (Decision node)
					String previousStatus = String.valueOf(existingRecords.get(c.Id).get('Status'));
					if (changedFields.contains(Case.Status) && c.FCR__c &&
							(
								(!fcrIgnoredCaseStatuses.contains(c.Status) && !fcrIgnoredCaseStatuses.contains(previousStatus)) || 
								(fcrIgnoredCaseStatuses.contains(previousStatus) && !'Closed'.equalsIgnoreCase(c.Status) && !'New'.equalsIgnoreCase(c.Status))
							)) {
						
						c.FCR__c = false;
					}

					if(omniQueues.containsKey(c.OwnerId) == true 
						&& (changedFields.contains(Case.OwnerId) || changedFields.contains(Case.Priority))) {
						validCasesInOmniQueues.add(c);
					}
				}	
			}

			// StarTrack Case Automation: Populate Case Subject (Decision node)
			setCaseSubjects((List<Case>) records);

			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCasesInOmniQueues, false);

		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCaseAutomationModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	private Map<Id, Group> omniQueues {
		get {
			if(omniQueues == null) {
				omniQueues = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
			}
			return omniQueues;
		}
		set;
	}

	/**
	 * StarTrack Case Automation: Populate Case Subject (Decision node)
	 */
	private void setCaseSubjects(List<Case> cases) {
		Id pickupBookingRecordTypeId = null;
		for (RecordType rt : caseRecordTypes.values()) {
			if ('StarTrack_Pickup_Booking_Enquiry'.equalsIgnoreCase(rt.DeveloperName)) {
				pickupBookingRecordTypeId = rt.Id;
				break;
			}
		}

		Set<String> excludedOrigins = new Set<String>{ 'Email', 'Web' };
		for (Case c : cases) {
			if (caseRecordTypes.keySet().contains(c.RecordTypeId) && !excludedOrigins.contains(c.Origin) && !String.isEmpty(c.Call_Purpose__c) && String.isEmpty(c.Subject)) {
				//Update Case Subject
				if (!String.isBlank(c.ArticleTest__c)) {
					c.Subject = c.Call_Purpose__c + ':' + c.Calc_Case_Consignment__c;
				}

				//Update Case Subject - PUB
				if (c.RecordTypeId == pickupBookingRecordTypeId && !String.isEmpty(c.Pickup_Booking_Reference__c)) {
					c.Subject = c.Call_Purpose__c + ':' + c.Pickup_Booking_Reference__c;
				}
			}
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) StarTrackSupportCaseAutomationModule.newInstance();
		}
	}
}