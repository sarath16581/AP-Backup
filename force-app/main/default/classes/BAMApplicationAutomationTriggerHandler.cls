/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @changelog
 */

public inherited sharing class BAMApplicationAutomationTriggerHandler extends ApplicationTriggerHandler {

	/**
	 * These record types are using a part of pre-filtering records prior to module execution.
	 */
	private static Map<String, Set<Id>> recordTypesByKey {
		get {
			if(recordTypesByKey == null) {
				recordTypesByKey = new Map<String, Set<Id>>{
					'BAM' => new Set<Id>()
				};
				List<RecordType> recordTypes = new RecordTypesSelector().selectByDeveloperNamesLike('BAMApplication__c', new Set<String>{'BAM'}).values();

				for(RecordType rt : recordTypes) {
					if(rt.DeveloperName.startsWithIgnoreCase('BAM')) {
						recordTypesByKey.get('BAM').add(rt.Id);
					}
				}
			}
			return recordTypesByKey;
		}
		private set;
	}

	public override SObjectType getSObjectType() {
		return BAMApplication__c.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
			'filterBAM' => new List<SObject>()
		};
		for(SObject record : records) {
			Id recordTypeId = (Id)record.get('RecordTypeId');
			if(recordTypesByKey.get('BAM').contains(recordTypeId)) {
				filteredRecords.get('filterBAM').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {
		//Logic relating to BAMApplication records
		// 1.validation of billing account filter on BAMApplication__c record
		registerModule(BAMApplicationAutomationModule.class, 'filterBAM');
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			BAMApplication__c.SObjectType
		};
	}

}