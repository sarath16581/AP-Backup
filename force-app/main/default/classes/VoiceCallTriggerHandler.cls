/***
 * @description VoiceCall trigger handler
 * NOTE: Invokes all the logic upon DML for the VoiceCall object
 * @author Paul Perry
 * @date 2024-08-27
 * @changelog
 * 2024-08-27 Paul Perry - create it
 */
public inherited sharing class VoiceCallTriggerHandler extends ApplicationTriggerHandler {
	private final String FILTER_ALLWITHVENDORKEY = 'allWithVendorCallKey';

	public override SObjectType getSObjectType() {
		return VoiceCall.SObjectType;
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
			FILTER_ALLWITHVENDORKEY => new List<SObject>()
		};

		for (SObject record : records) {
			if (String.isNotBlank((String)record.get(VoiceCall.VendorCallKey))) {
				filteredRecords.get(FILTER_ALLWITHVENDORKEY).add(record);
			}
		}

		return filteredRecords;
	}

	/**
	 * List of modules that are registered within this Trigger Handler
	 */
	public override void registerModules() {
		// SVC/Unified
		// - Synchronise custom attributes to Call Interaction
		registerModule(GenesysVoiceCallModule.class, FILTER_ALLWITHVENDORKEY);
		// - Synchronise VoiceCall attributes across consult/conferance/transferred calls
		registerModule(UnifiedVoiceCallModule.class, FILTER_ALLWITHVENDORKEY);
		// populate the case id on both the relevant agent work records and the contactrequest records themselves
		// This provides an easy to reference lookup to the case the record is associated with
		registerModule(CaseRecordPopulationModule.class);
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			AgentWork.SObjectType,VoiceCall.SObjectType
		};
	}
}