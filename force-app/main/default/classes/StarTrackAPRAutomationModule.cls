/**
 * @description Module class for StarTrackAPRDomain
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Domain
 * @domain APR
 * @changelog
 * @Test StarTrackAPRAutomationModule_Test
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 * 2023-08-18 Jacob Isaac REQ3267427
 */

public inherited sharing class StarTrackAPRAutomationModule extends ApplicationDomain.Module {
	public static StarTrackAPRAutomationModule newInstance() {
		return (StarTrackAPRAutomationModule) Application.Utilities.newInstance(StarTrackAPRAutomationModule.class);
	}

	// Setup which triggers this module should respond to
	public StarTrackAPRAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateAPRFields((List<APR__c>) records, null);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(
				ex,
				UserInfo.getOrganizationId(),
				StarTrack_Constants.STARTRACK,
				StarTrackAPRAutomationModule.class.getName(),
				'onBeforeInsert',
				'APR Trigger',
				LoggingLevel.ERROR
			);
		}
	}

	public override void onBeforeUpdate(
		List<SObject> records,
		Map<Id, SObject> existingRecords,
		ApplicationUnitOfWork uow
	) {
		try {
			updateAPRFields((List<APR__c>) records, (Map<Id, APR__c>) existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(
				ex,
				UserInfo.getOrganizationId(),
				StarTrack_Constants.STARTRACK,
				StarTrackAPRAutomationModule.class.getName(),
				'onBeforeUpdate',
				'APR Trigger',
				LoggingLevel.ERROR
			);
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) StarTrackAPRAutomationModule.newInstance();
		}
	}

	/**
	 * Set APR object fields
	 */
	public void updateAPRFields(List<APR__c> records, Map<Id, APR__c> existingRecords) {
		Boolean isInsert = (existingRecords == null);
		for (APR__c apr : records) {
			// Get old APR__c if it is update
			APR__c oldAPR = !isInsert ? existingRecords.get(apr.Id) : null;

			//If Processed_Date__c is blank and Entered in Team / PeopleSoft box is ticked - Update Processed Date to today
			if (apr.Processed_Date__c == null && apr.Entered_in_Team_PeopleSoft__c) {
				apr.Processed_Date__c = System.today();
			}

			//If Communicated_to_customer_Date__c is blank and Communicated to customer box is ticked - Update respective flag to today - REQ2738326
			if (apr.Communicated_to_customer_Date__c == null && apr.Communicated_to_customer__c) {
				apr.Communicated_to_customer_Date__c = System.today();
			}

			//Status has been set or Changed
			if (apr.Status__c != null && (isInsert || (oldAPR != null && (oldAPR.Status__c != apr.Status__c)))) {

				//REQ3267427 - Removed logic to nullify the fields since there are new validation rules being added
				//Status is Open or Unresolved - Update Effective Date and Conclusion Date to null
				// if (APRConstants.STATUS_OPEN_UNRESOLVED.contains(apr.Status__c)) {
				// 	apr.Confirmed_Date__c = null;
				// 	apr.Confirmed_Rate__c = null;
				// 	apr.Conclusion_Date__c = null;
				// }

				//Status is one of Account Lost - Update Effective Date and Conclusion Date
				if (APRConstants.STATUS_VERFIED_MULTIPLE.contains(apr.Status__c)) {
					if(apr.Published_Date__c != null) {
						apr.Conclusion_Date__c = date.valueOf((apr.Published_Date__c.year() + 1) + '-10-31');
						apr.Confirmed_Date__c = apr.Published_Date__c;
					}

					//REQ3267427 - Removed Status value and inactivating logic
					//Status is Exemption - Update Confirmed Rate to 0
					// if (APRConstants.STATUS_EXEMPTION.equalsIgnoreCase(apr.Status__c)) {
					// 	apr.Confirmed_Rate__c = 0;
					// }
				}
			}

			//Confirmed Rate is blank, Status is Account Lost - Update Confirmed Rate
			if (
				apr.Confirmed_Rate__c == null &&
				apr.Published_Rate__c != null &&
				APRConstants.STATUS_ACCOUNTLOST.equalsIgnoreCase(apr.Status__c)
			) {
				apr.Confirmed_Rate__c = apr.Published_Rate__c;
			}
		}
	}
}