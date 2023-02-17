/**
 * @description Domain class to handle AgentWork related capability
 * @author George Nguyen
 * @group Domains
 * @domain AgentWork
 * @changelog
 * 2023-02-16	George	- created
 */
public inherited sharing class APAgentWorkDomain extends ApplicationDomain {
	public static APAgentWorkDomain newInstance(List<SObject> sObjectList) {
		return (APAgentWorkDomain) ApplicationDomain.newInstance(APAgentWorkDomain.class, sObjectList);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet();
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(validRecordTypes.contains((Id)record.get('WorkItem.RecordTypeId')) == true) { // Only process AP related AgentWork
				output.add(record);
			}
		}
		return output;
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(APAgentWorkPreferredAgentModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return APAgentWorkDomain.newInstance(sObjectList);
		}
	}
}