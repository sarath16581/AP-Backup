/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Ranjeewa Silva
 * @date 2023-07-05
 * @changelog
 * 2023-07-05 - Ranjeewa Silva - Created.
 */
public inherited sharing class LeadAutomationTriggerHandler extends ApplicationTriggerHandler {

	/**
	 * These record types are using a part of pre-filtering records prior to module execution.
	 */
	private static Map<String, Set<Id>> recordTypesByKey {
		get {
			if(recordTypesByKey == null) {
				Set<Id> recordTypeIds = new RecordTypesSelector().selectByDeveloperName('Lead', new Set<String>{'BG_Standard'}).keySet();
				recordTypesByKey = new Map<String, Set<Id>> {
						'BGStandard' => recordTypeIds
				};
			}
			return recordTypesByKey;
		}
		private set;
	}

	public override SObjectType getSObjectType() {
		return Lead.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override void registerModules() {
		registerModule(LeadConversionAutomationModule.class);
		registerModule(BGStandardLeadModule.class, 'filterBGStandard');
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 * @param records list of records to filter
	 * @return filtered records indexed by filter keys.
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterBGStandard' => new List<SObject>()
		};
		for(SObject record : records) {
			Id recordTypeId = (Id)record.get('RecordTypeId');
			if(recordTypesByKey.get('BGStandard').contains(recordTypeId)) {
				filteredRecords.get('filterBGStandard').add(record);
			}
		}
		return filteredRecords;
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 * @return the list of sobject types
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			Lead.SObjectType,
			Account.SObjectType,
			Contact.SObjectType,
			Opportunity.SObjectType
		};
	}
}