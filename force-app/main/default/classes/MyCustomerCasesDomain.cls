/**
* @description Domain class to handle SSSW Case capability
* @author Nathan Franklin
* @date 2020-07-24
* @group Domains
* @changelog
*/
public inherited sharing class MyCustomerCasesDomain extends ApplicationDomain {

	public static MyCustomerCasesDomain newInstance(List<SObject> sObjectList) {
		return (MyCustomerCasesDomain)ApplicationDomain.newInstance(MyCustomerCasesDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(MyCustomerCaseArticlesModule.class);

		// this module checks for Closed Cases
		//registerModule(MyCustomerClosedCaseModule.class);

		registerModule(MyCustomerCaseRoutingModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet();
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(validRecordTypes.contains((Id)record.get('RecordTypeId'))) {
				output.add(record);
			}
		}
		return output;
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return MyCustomerCasesDomain.newInstance(sObjectList);
		}
	}

}