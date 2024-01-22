/**
 * @description Domain class to handle AgentWork related capability on AP Cases
 * @author George Nguyen
 * @group Domains
 * @domain AgentWork
 * @changelog
 * 2023-02-16	George	- created
 * 2023-04-14 - Noel Lim - Updated class name from APCaseAgentWorkDomain to AgentWorkAPCaseDomain
 */
public inherited sharing class AgentWorkAPCaseDomain extends ApplicationDomain {
	public static AgentWorkAPCaseDomain newInstance(List<SObject> sObjectList) {
		return (AgentWorkAPCaseDomain) ApplicationDomain.newInstance(AgentWorkAPCaseDomain.class, sObjectList);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		Set<Id> validRecordTypeIds = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet();
		List<SObject> output = new List<SObject>();
		Set<Id> caseIds = new Set<Id>();
		for(SObject record : records) { 
			caseIds.add((Id)record.get('WorkItemId'));
		}
		
		Map<Id, Case> validCases = new Map<Id, Case>(CasesSelector.newInstance().selectByIdsAndRecordTypeIds(caseIds, validRecordTypeIds, new Set<Object>()));

		for(SObject record : records) {
			if(validCases.containsKey((Id)record.get('WorkItemId')) == true) { // Only process AP related AgentWork
				output.add(record);
			}
		}
		return output;
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(AgentWorkAPCaseAutomationModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return AgentWorkAPCaseDomain.newInstance(sObjectList);
		}
	}
}