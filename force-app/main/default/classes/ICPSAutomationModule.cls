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
	public static ICPSAutomationModule newInstance() {
		return (ICPSAutomationModule)Application.Utilities.newInstance(ICPSAutomationModule.class);
	}

	public ICPSAutomationModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateHoldUntilDate(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'ICPS', ICPSAutomationModule.class.getName(), 'onBeforeInsert', 'ICPSTrigger', LoggingLevel.ERROR);
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
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) ICPSAutomationModule.newInstance();
		}
	}
}