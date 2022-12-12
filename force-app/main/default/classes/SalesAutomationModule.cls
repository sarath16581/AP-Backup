/**
 * @description
 * Domain Module to handle business account object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Harry Wang
 * @group Domain
 * @domain Account
 * @Test BusinessAccountIntermediaryModule_Test
 * @changelog
 * 2022-11-04 - Harry Wang - Created.
 */
public inherited sharing class SalesAutomationModule extends ApplicationDomain.Module {

	public static SalesAutomationModule newInstance() {
		return (SalesAutomationModule)Application.Utilities.newInstance(SalesAutomationModule.class);
	}

	// Setup which trigger events this module should respond to
	public SalesAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		stampSalesTeamType((List<Account>)records, null);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		stampSalesTeamType((List<Account>)records, existingRecords);
	}

	/**
	 * This method is used to stamp sales team type based on dependent sales team(segment)
	 * @param records list of account records to be updated
	 * @param existingRecords Map of existing account records if triggerred from update
	 */
	private void stampSalesTeamType(List<Account> records, Map<Id, SObject> existingRecords) {
		try {
			Map<String, List<String>> salesTeamMap = AP_FieldDescribeUtil.getDependentPicklistValues(Account.SalesTeamType__c.getDescribe().getSobjectField(), Account.Sales_Segment__c.getDescribe().getSobjectField());
			List<String> logMessages = new List<String>();
			List<String> additionalInfo = new List<String>();
			for (Account acc: records) {
				Account eAcc;
				if (existingRecords != null && !existingRecords.isEmpty()) {
					eAcc = (Account)existingRecords.get(acc.Id);
				}
				List<String> types = salesTeamMap.get(acc.Sales_Segment__c);
				if (types.size() != 1) {
					logMessages.add('Stamping sales team type failed: ' + acc.Id);
					additionalInfo.add('Multiple or null Sales Team retrieved for ' + acc.Sales_Segment__c);
				} else {
					String newSalesTeamType = types[0];
					if (acc.Sales_Segment__c != null && (eAcc == null || (eAcc != null && (eAcc.SalesTeamType__c == null || eAcc.SalesTeamType__c != newSalesTeamType)))) {
						acc.SalesTeamType__c = newSalesTeamType;
					}
				}
			}

			// Logging failure message
			if (!logMessages.isEmpty() && !additionalInfo.isEmpty()) {
				ApplicationLogger.getInstance().logMessage(logMessages, additionalInfo, 'Sales Intermediary', SalesAutomationModule.class.getName(), 'stampSalesTeamType', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
			}
		} catch (Exception e) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales Intermediary', SalesAutomationModule.class.getName(), 'stampSalesTeamType', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) SalesAutomationModule.newInstance();
		}
	}
}