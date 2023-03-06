/**
* @description Domain class to handle Business Account related capability
* @author Harry Wang
* @group Domains
* @domain Account
* @Test BusinessAccountDomain_Test
* @changelog
* 2022-11-04 - Harry Wang - Created.
*/
public inherited sharing class BusinessAccountDomain extends ApplicationDomain {

	public static BusinessAccountDomain newInstance(List<SObject> sObjectList) {
		return (BusinessAccountDomain)ApplicationDomain.newInstance(BusinessAccountDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(SalesAutomationModule.class);
		registerModule(SalesAccountChildSObjectSharingModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		Application.Profiler.start('BusinessAccountDomain.filter');
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).keySet();
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(validRecordTypes.contains((Id)record.get('RecordTypeId'))) {
				output.add(record);
			}
		}
		Application.Profiler.stop('BusinessAccountDomain.filter');
		return output;
	}
}