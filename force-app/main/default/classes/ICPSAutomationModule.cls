/**
 * @description
 * Domain Module to update ICPS
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Harry Wang
 * @date 2022-06-21
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-21 - Harry Wang - Created
*/
public inherited sharing class ICPSAutomationModule extends ApplicationDomain.Module {
	/**
	 * list of field types required to be capitalized
	 */
	private static final Set<SObjectField> CAP_FIELDS {
		get {
			if (CAP_FIELDS == null) {
				CAP_FIELDS = new Set<SObjectField> {
						ICPS__c.Contents__c, ICPS__c.ReceiverName__c, ICPS__c.ReceiverCareOf__c,
						ICPS__c.ReceiverStreetLine1__c, ICPS__c.ReceiverStreetLine2__c, ICPS__c.ReceiverCity__c, ICPS__c.ReceiverPostalCode__c,
						ICPS__c.ReceiverState__c, ICPS__c.SenderName__c, ICPS__c.SenderStreetLine1__c, ICPS__c.SenderStreetLine2__c,
						ICPS__c.SenderCity__c, ICPS__c.SenderPostalCode__c, ICPS__c.SenderState__c, ICPS__c.SenderCountry__c
				};
			}
			return CAP_FIELDS;
		}
		set;
	}

	public static ICPSAutomationModule newInstance() {
		return (ICPSAutomationModule)Application.Utilities.newInstance(ICPSAutomationModule.class);
	}

	public ICPSAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateHoldUntilDate(records);
			capitalizeFields(records, null);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSAutomationModule.class.getName(), 'onBeforeInsert', 'ICPSTrigger', LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			capitalizeFields(records, existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSAutomationModule.class.getName(), 'onBeforeUpdate', 'ICPSTrigger', LoggingLevel.ERROR);
		}
	}

	/**
	 * This method is used to update Hold Until date as record created date plus days retrieved from ICPS Settings
	 * @param records list of ICPS records to be updated
	 */
	@TestVisible
	private void updateHoldUntilDate(List<SObject> records) {
		Decimal holdingDays = 0;
		ICPSSettings__mdt icpsSettings = ICPSSettings__mdt.getInstance('ICPS_Settings');
		if (icpsSettings != null && icpsSettings.HoldingDateDays__c != null) {
			holdingDays = icpsSettings.HoldingDateDays__c;
		}

		for (ICPS__c icps: (List<ICPS__c>) records) {
			icps.HoldUntilDate__c = Date.today().addDays(holdingDays.intValue());
		}
	}

	/**
	 * Some fields are required to be capitalized
	 */
	@TestVisible
	private void capitalizeFields(List<SObject> records, Map<Id, SObject> existingRecords) {
		for (ICPS__c icps: (List<ICPS__c>) records) {
			for (SObjectField fieldName: CAP_FIELDS) {
				String newValue = (String)icps.get(fieldName);
				if (newValue != null && (existingRecords == null || !newValue.equals(existingRecords.get(icps.Id).get(fieldName)))) {
					icps.put(fieldName, String.isNotBlank(newValue) ? newValue.toUpperCase() : newValue);
				}
			}
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ICPSAutomationModule.newInstance();
		}
	}
}