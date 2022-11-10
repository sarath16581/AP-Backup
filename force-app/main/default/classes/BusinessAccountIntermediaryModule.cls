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
public inherited sharing class BusinessAccountIntermediaryModule extends ApplicationDomain.Module {

	public static BusinessAccountIntermediaryModule newInstance() {
		return (BusinessAccountIntermediaryModule)Application.Utilities.newInstance(BusinessAccountIntermediaryModule.class);
	}

	// Setup which trigger events this module should respond to
	public BusinessAccountIntermediaryModule() {
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
	@TestVisible
	private void stampSalesTeamType(List<Account> records, Map<Id, SObject> existingRecords) {
		try {
			Map<String, List<String>> salesTeamMap = AP_FieldDescribeUtil.getDependentPicklistValues(Account.SalesTeamType__c.getDescribe().getSobjectField(), Account.Sales_Segment__c.getDescribe().getSobjectField());
			for (Account acc: records) {
				Account eAcc;
				if (existingRecords != null && !existingRecords.isEmpty()) {
					eAcc = (Account)existingRecords.get(acc.Id);
				}
				List<String> types = salesTeamMap.get(acc.Sales_Segment__c);
				if (types.size() != 1) {
					throw new SalesIntermediaryService.IntermediaryException('Multiple or null Sales Team retrieved');
				}

				String newSalesTeamType = types[0];
				if (acc.Sales_Segment__c != null && (eAcc == null || (eAcc != null && (eAcc.SalesTeamType__c == null || eAcc.SalesTeamType__c != newSalesTeamType)))) {
					acc.SalesTeamType__c = types[0];
				}

			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getUserId(), 'Intermediary', BusinessAccountIntermediaryModule.class.getName(), 'onBeforeInsert', 'AccountTriggerClass', LoggingLevel.ERROR, '');
		}
	}

	/**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)BusinessAccountIntermediaryModule.newInstance();
		}
	}
}